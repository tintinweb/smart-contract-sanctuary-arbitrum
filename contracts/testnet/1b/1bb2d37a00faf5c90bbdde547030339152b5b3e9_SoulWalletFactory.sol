// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "./SoulWalletProxy.sol";
import "./SoulWallet.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SoulWalletFactory
 * @author soulwallet team
 * @notice A factory contract to create soul wallets
 * @dev This contract is called by the entrypoint which uses the "initCode" to create and return the sender's wallet address
 */
contract SoulWalletFactory is Ownable {
    uint256 private immutable _WALLETIMPL;
    IEntryPoint public immutable entryPoint;
    string public constant VERSION = "0.0.1";

    event SoulWalletCreation(address indexed proxy);

    /**
     * @dev Initializes the factory with the wallet implementation and entry point addresses
     * @param _walletImpl Address of the SoulWallet implementation
     * @param _entryPoint Address of the EntryPoint contract
     * @param _owner Address of the contract owner
     */
    constructor(address _walletImpl, address _entryPoint, address _owner) Ownable(_owner) {
        require(_walletImpl != address(0), "Invalid wallet implementation address");
        _WALLETIMPL = uint256(uint160(_walletImpl));
        require(_entryPoint != address(0), "Invalid entry point address");
        entryPoint = IEntryPoint(_entryPoint);
    }

    /**
     * @notice Returns the wallet implementation address
     * @return Address of the wallet implementation
     */
    function walletImpl() external view returns (address) {
        return address(uint160(_WALLETIMPL));
    }

    function _calcSalt(bytes memory _initializer, bytes32 _salt) private pure returns (bytes32 salt) {
        return keccak256(abi.encodePacked(keccak256(_initializer), _salt));
    }

    /**
     * @dev Deploys the SoulWallet using a proxy and returns the proxy's address
     * @param _initializer Initialization data
     * @param _salt Salt for the create2 deployment
     * @return proxy Address of the deployed proxy
     */
    function createWallet(bytes memory _initializer, bytes32 _salt) external returns (address proxy) {
        bytes memory deploymentData = abi.encodePacked(type(SoulWalletProxy).creationCode, _WALLETIMPL);
        bytes32 salt = _calcSalt(_initializer, _salt);
        assembly ("memory-safe") {
            proxy := create2(0x0, add(deploymentData, 0x20), mload(deploymentData), salt)
        }
        if (proxy == address(0)) {
            revert();
        }
        assembly ("memory-safe") {
            let succ := call(gas(), proxy, 0, add(_initializer, 0x20), mload(_initializer), 0, 0)
            if eq(succ, 0) { revert(0, 0) }
        }
        emit SoulWalletCreation(proxy);
    }

    /**
     * @notice Returns the proxy's creation code
     * @dev Used by soulwalletlib to calculate the SoulWallet address
     * @return Byte array representing the proxy's creation code
     */
    function proxyCode() external pure returns (bytes memory) {
        return _proxyCode();
    }

    function _proxyCode() private pure returns (bytes memory) {
        return type(SoulWalletProxy).creationCode;
    }

    /**
     * @notice Calculates the counterfactual address of the SoulWallet as it would be returned by `createWallet`
     * @param _initializer Initialization data
     * @param _salt Salt for the create2 deployment
     * @return proxy Counterfactual address of the SoulWallet
     */
    function getWalletAddress(bytes memory _initializer, bytes32 _salt) external view returns (address proxy) {
        bytes memory deploymentData = abi.encodePacked(type(SoulWalletProxy).creationCode, _WALLETIMPL);
        bytes32 salt = _calcSalt(_initializer, _salt);
        proxy = Create2.computeAddress(salt, keccak256(deploymentData));
    }

    /**
     * @notice Deposits ETH to the entry point on behalf of the contract
     */
    function deposit() public payable {
        entryPoint.depositTo{value: msg.value}(address(this));
    }

    /**
     * @notice Allows the owner to withdraw ETH from entrypoint contract
     * @param withdrawAddress Address to receive the withdrawn ETH
     * @param amount Amount of ETH to withdraw
     */
    function withdrawTo(address payable withdrawAddress, uint256 amount) public onlyOwner {
        entryPoint.withdrawTo(withdrawAddress, amount);
    }

    /**
     * @notice Allows the owner to add stake to the entry point
     * @param unstakeDelaySec Duration (in seconds) after which the stake can be unlocked
     */
    function addStake(uint32 unstakeDelaySec) external payable onlyOwner {
        entryPoint.addStake{value: msg.value}(unstakeDelaySec);
    }

    /**
     * @notice Allows the owner to unlock their stake from the entry point
     */
    function unlockStake() external onlyOwner {
        entryPoint.unlockStake();
    }

    /**
     * @notice Allows the owner to withdraw their stake from the entry point
     * @param withdrawAddress Address to receive the withdrawn stake
     */
    function withdrawStake(address payable withdrawAddress) external onlyOwner {
        entryPoint.withdrawStake(withdrawAddress);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title SoulWalletProxy
 * @notice A proxy contract that forwards calls to an implementation contract
 * @dev This proxy uses the EIP-1967 standard for storage slots
 */
contract SoulWalletProxy {
    /**
     * @notice Storage slot with the address of the current implementation
     * @dev This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @notice Initializes the proxy with the address of the initial implementation contract
     * @param logic Address of the initial implementation
     */
    constructor(address logic) {
        assembly ("memory-safe") {
            sstore(_IMPLEMENTATION_SLOT, logic)
        }
    }

    /**
     * @notice Fallback function which forwards all calls to the implementation contract
     * @dev Uses delegatecall to ensure the context remains within the proxy
     */
    fallback() external payable {
        assembly {
            /* not memory-safe */
            let _singleton := and(sload(_IMPLEMENTATION_SLOT), 0xffffffffffffffffffffffffffffffffffffffff)
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@account-abstraction/contracts/core/BaseAccount.sol";
import "./interfaces/ISoulWallet.sol";
import "./base/EntryPointManager.sol";
import "./base/ExecutionManager.sol";
import "./base/PluginManager.sol";
import "./base/ModuleManager.sol";
import "./base/OwnerManager.sol";
import "./helper/SignatureValidator.sol";
import "./handler/ERC1271Handler.sol";
import "./base/FallbackManager.sol";
import "./base/UpgradeManager.sol";
import "./base/ValidatorManager.sol";

/// @title SoulWallet
/// @author  SoulWallet team
/// @notice logic contract of SoulWallet
/// @dev Draft contract - may be subject to changes
contract SoulWallet is
    Initializable,
    ISoulWallet,
    BaseAccount,
    EntryPointManager,
    OwnerManager,
    SignatureValidator,
    PluginManager,
    ModuleManager,
    UpgradeManager,
    ExecutionManager,
    FallbackManager,
    ERC1271Handler,
    ValidatorManager
{
    /// @notice Creates a new SoulWallet instance
    /// @param _EntryPoint Address of the entry point
    /// @param _validator Address of the validator
    constructor(IEntryPoint _EntryPoint, IValidator _validator)
        EntryPointManager(_EntryPoint)
        ValidatorManager(_validator)
    {
        _disableInitializers();
    }

    /// @notice Initializes the SoulWallet with given parameters
    /// @param owners List of owner addresses (passkey public key hash or eoa address)
    /// @param defalutCallbackHandler Default callback handler address
    /// @param modules List of module data
    /// @param plugins List of plugin data
    function initialize(
        bytes32[] calldata owners,
        address defalutCallbackHandler,
        bytes[] calldata modules,
        bytes[] calldata plugins
    ) external initializer {
        _addOwners(owners);
        _setFallbackHandler(defalutCallbackHandler);
        for (uint256 i = 0; i < modules.length;) {
            _addModule(modules[i]);
            unchecked {
                i++;
            }
        }
        for (uint256 i = 0; i < plugins.length;) {
            _addPlugin(plugins[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Gets the address of the entry point
    /// @return IEntryPoint Address of the entry point
    function entryPoint() public view override(BaseAccount) returns (IEntryPoint) {
        return EntryPointManager._entryPoint();
    }

    /// @notice Validates the user's signature
    /// @param userOp User operation details
    /// @param userOpHash Hash of the user operation
    /// @return validationData Data related to validation process
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
        internal
        virtual
        override
        returns (uint256 validationData)
    {
        bool sigValid;
        bytes calldata guardHookInputData;
        (validationData, sigValid, guardHookInputData) = _isValidUserOp(userOpHash, userOp.signature);

        /* 
          Why using the current "non-gas-optimized" approach instead of using 
          `sigValid = sigValid && guardHook(userOp, userOpHash, guardHookInputData);` :
          
          When data is executed on the blockchain, if `sigValid = true`, the gas cost remains consistent.
          However, the benefits of using this approach are quite apparent:
          By using "semi-valid" signatures off-chain to estimate gas fee (sigValid will always be false), 
          the estimated fee can include a portion of the execution cost of `guardHook`. 
         */
        bool guardHookResult = guardHook(userOp, userOpHash, guardHookInputData);

        // equivalence code: `(sigFailed ? 1 : 0) | (uint256(validUntil) << 160) | (uint256(validAfter) << (160 + 48))`
        // validUntil and validAfter is already packed in signatureData.validationData,
        // and aggregator is address(0), so we just need to add sigFailed flag.
        validationData = validationData | ((sigValid && guardHookResult) ? 0 : SIG_VALIDATION_FAILED);
    }

    /// @notice Upgrades the contract to a new implementation
    /// @param newImplementation Address of the new implementation
    /// @dev Can only be called from an external module for security reasons
    function upgradeTo(address newImplementation) external onlyModule {
        UpgradeManager._upgradeTo(newImplementation);
    }

    /// @notice Handles the upgrade from an old implementation
    /// @param oldImplementation Address of the old implementation
    function upgradeFrom(address oldImplementation) external pure override {
        (oldImplementation);
        revert Errors.NOT_IMPLEMENTED(); //Initial version no need data migration
    }
}

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

/**
 ** Account-Abstraction (EIP-4337) singleton EntryPoint implementation.
 ** Only one instance required on each chain.
 **/
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "./UserOperation.sol";
import "./IStakeManager.sol";
import "./IAggregator.sol";
import "./INonceManager.sol";

interface IEntryPoint is IStakeManager, INonceManager {

    /***
     * An event emitted after each successful request
     * @param userOpHash - unique identifier for the request (hash its entire content, except signature).
     * @param sender - the account that generates this request.
     * @param paymaster - if non-null, the paymaster that pays for this request.
     * @param nonce - the nonce value from the request.
     * @param success - true if the sender transaction succeeded, false if reverted.
     * @param actualGasCost - actual amount paid (by account or paymaster) for this UserOperation.
     * @param actualGasUsed - total gas used by this UserOperation (including preVerification, creation, validation and execution).
     */
    event UserOperationEvent(bytes32 indexed userOpHash, address indexed sender, address indexed paymaster, uint256 nonce, bool success, uint256 actualGasCost, uint256 actualGasUsed);

    /**
     * account "sender" was deployed.
     * @param userOpHash the userOp that deployed this account. UserOperationEvent will follow.
     * @param sender the account that is deployed
     * @param factory the factory used to deploy this account (in the initCode)
     * @param paymaster the paymaster used by this UserOp
     */
    event AccountDeployed(bytes32 indexed userOpHash, address indexed sender, address factory, address paymaster);

    /**
     * An event emitted if the UserOperation "callData" reverted with non-zero length
     * @param userOpHash the request unique identifier.
     * @param sender the sender of this request
     * @param nonce the nonce used in the request
     * @param revertReason - the return bytes from the (reverted) call to "callData".
     */
    event UserOperationRevertReason(bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason);

    /**
     * an event emitted by handleOps(), before starting the execution loop.
     * any event emitted before this event, is part of the validation.
     */
    event BeforeExecution();

    /**
     * signature aggregator used by the following UserOperationEvents within this bundle.
     */
    event SignatureAggregatorChanged(address indexed aggregator);

    /**
     * a custom revert error of handleOps, to identify the offending op.
     *  NOTE: if simulateValidation passes successfully, there should be no reason for handleOps to fail on it.
     *  @param opIndex - index into the array of ops to the failed one (in simulateValidation, this is always zero)
     *  @param reason - revert reason
     *      The string starts with a unique code "AAmn", where "m" is "1" for factory, "2" for account and "3" for paymaster issues,
     *      so a failure can be attributed to the correct entity.
     *   Should be caught in off-chain handleOps simulation and not happen on-chain.
     *   Useful for mitigating DoS attempts against batchers or for troubleshooting of factory/account/paymaster reverts.
     */
    error FailedOp(uint256 opIndex, string reason);

    /**
     * error case when a signature aggregator fails to verify the aggregated signature it had created.
     */
    error SignatureValidationFailed(address aggregator);

    /**
     * Successful result from simulateValidation.
     * @param returnInfo gas and time-range returned values
     * @param senderInfo stake information about the sender
     * @param factoryInfo stake information about the factory (if any)
     * @param paymasterInfo stake information about the paymaster (if any)
     */
    error ValidationResult(ReturnInfo returnInfo,
        StakeInfo senderInfo, StakeInfo factoryInfo, StakeInfo paymasterInfo);

    /**
     * Successful result from simulateValidation, if the account returns a signature aggregator
     * @param returnInfo gas and time-range returned values
     * @param senderInfo stake information about the sender
     * @param factoryInfo stake information about the factory (if any)
     * @param paymasterInfo stake information about the paymaster (if any)
     * @param aggregatorInfo signature aggregation info (if the account requires signature aggregator)
     *      bundler MUST use it to verify the signature, or reject the UserOperation
     */
    error ValidationResultWithAggregation(ReturnInfo returnInfo,
        StakeInfo senderInfo, StakeInfo factoryInfo, StakeInfo paymasterInfo,
        AggregatorStakeInfo aggregatorInfo);

    /**
     * return value of getSenderAddress
     */
    error SenderAddressResult(address sender);

    /**
     * return value of simulateHandleOp
     */
    error ExecutionResult(uint256 preOpGas, uint256 paid, uint48 validAfter, uint48 validUntil, bool targetSuccess, bytes targetResult);

    //UserOps handled, per aggregator
    struct UserOpsPerAggregator {
        UserOperation[] userOps;

        // aggregator address
        IAggregator aggregator;
        // aggregated signature
        bytes signature;
    }

    /**
     * Execute a batch of UserOperation.
     * no signature aggregator is used.
     * if any account requires an aggregator (that is, it returned an aggregator when
     * performing simulateValidation), then handleAggregatedOps() must be used instead.
     * @param ops the operations to execute
     * @param beneficiary the address to receive the fees
     */
    function handleOps(UserOperation[] calldata ops, address payable beneficiary) external;

    /**
     * Execute a batch of UserOperation with Aggregators
     * @param opsPerAggregator the operations to execute, grouped by aggregator (or address(0) for no-aggregator accounts)
     * @param beneficiary the address to receive the fees
     */
    function handleAggregatedOps(
        UserOpsPerAggregator[] calldata opsPerAggregator,
        address payable beneficiary
    ) external;

    /**
     * generate a request Id - unique identifier for this request.
     * the request ID is a hash over the content of the userOp (except the signature), the entrypoint and the chainid.
     */
    function getUserOpHash(UserOperation calldata userOp) external view returns (bytes32);

    /**
     * Simulate a call to account.validateUserOp and paymaster.validatePaymasterUserOp.
     * @dev this method always revert. Successful result is ValidationResult error. other errors are failures.
     * @dev The node must also verify it doesn't use banned opcodes, and that it doesn't reference storage outside the account's data.
     * @param userOp the user operation to validate.
     */
    function simulateValidation(UserOperation calldata userOp) external;

    /**
     * gas and return values during simulation
     * @param preOpGas the gas used for validation (including preValidationGas)
     * @param prefund the required prefund for this operation
     * @param sigFailed validateUserOp's (or paymaster's) signature check failed
     * @param validAfter - first timestamp this UserOp is valid (merging account and paymaster time-range)
     * @param validUntil - last timestamp this UserOp is valid (merging account and paymaster time-range)
     * @param paymasterContext returned by validatePaymasterUserOp (to be passed into postOp)
     */
    struct ReturnInfo {
        uint256 preOpGas;
        uint256 prefund;
        bool sigFailed;
        uint48 validAfter;
        uint48 validUntil;
        bytes paymasterContext;
    }

    /**
     * returned aggregated signature info.
     * the aggregator returned by the account, and its current stake.
     */
    struct AggregatorStakeInfo {
        address aggregator;
        StakeInfo stakeInfo;
    }

    /**
     * Get counterfactual sender address.
     *  Calculate the sender contract address that will be generated by the initCode and salt in the UserOperation.
     * this method always revert, and returns the address in SenderAddressResult error
     * @param initCode the constructor code to be passed into the UserOperation.
     */
    function getSenderAddress(bytes memory initCode) external;


    /**
     * simulate full execution of a UserOperation (including both validation and target execution)
     * this method will always revert with "ExecutionResult".
     * it performs full validation of the UserOperation, but ignores signature error.
     * an optional target address is called after the userop succeeds, and its value is returned
     * (before the entire call is reverted)
     * Note that in order to collect the the success/failure of the target call, it must be executed
     * with trace enabled to track the emitted events.
     * @param op the UserOperation to simulate
     * @param target if nonzero, a target address to call after userop simulation. If called, the targetSuccess and targetResult
     *        are set to the return from that call.
     * @param targetCallData callData to pass to target address
     */
    function simulateHandleOp(UserOperation calldata op, address target, bytes calldata targetCallData) external;
}

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
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-empty-blocks */

import "../interfaces/IAccount.sol";
import "../interfaces/IEntryPoint.sol";
import "./Helpers.sol";

/**
 * Basic account implementation.
 * this contract provides the basic logic for implementing the IAccount interface  - validateUserOp
 * specific account implementation should inherit it and provide the account-specific logic
 */
abstract contract BaseAccount is IAccount {
    using UserOperationLib for UserOperation;

    //return value in case of signature failure, with no time-range.
    // equivalent to _packValidationData(true,0,0);
    uint256 constant internal SIG_VALIDATION_FAILED = 1;

    /**
     * Return the account nonce.
     * This method returns the next sequential nonce.
     * For a nonce of a specific key, use `entrypoint.getNonce(account, key)`
     */
    function getNonce() public view virtual returns (uint256) {
        return entryPoint().getNonce(address(this), 0);
    }

    /**
     * return the entryPoint used by this account.
     * subclass should return the current entryPoint used by this account.
     */
    function entryPoint() public view virtual returns (IEntryPoint);

    /**
     * Validate user's signature and nonce.
     * subclass doesn't need to override this method. Instead, it should override the specific internal validation methods.
     */
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
    external override virtual returns (uint256 validationData) {
        _requireFromEntryPoint();
        validationData = _validateSignature(userOp, userOpHash);
        _validateNonce(userOp.nonce);
        _payPrefund(missingAccountFunds);
    }

    /**
     * ensure the request comes from the known entrypoint.
     */
    function _requireFromEntryPoint() internal virtual view {
        require(msg.sender == address(entryPoint()), "account: not from EntryPoint");
    }

    /**
     * validate the signature is valid for this message.
     * @param userOp validate the userOp.signature field
     * @param userOpHash convenient field: the hash of the request, to check the signature against
     *          (also hashes the entrypoint and chain id)
     * @return validationData signature and time-range of this operation
     *      <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
     *         otherwise, an address of an "authorizer" contract.
     *      <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
     *      <6-byte> validAfter - first timestamp this operation is valid
     *      If the account doesn't use time-range, it is enough to return SIG_VALIDATION_FAILED value (1) for signature failure.
     *      Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
    internal virtual returns (uint256 validationData);

    /**
     * Validate the nonce of the UserOperation.
     * This method may validate the nonce requirement of this account.
     * e.g.
     * To limit the nonce to use sequenced UserOps only (no "out of order" UserOps):
     *      `require(nonce < type(uint64).max)`
     * For a hypothetical account that *requires* the nonce to be out-of-order:
     *      `require(nonce & type(uint64).max == 0)`
     *
     * The actual nonce uniqueness is managed by the EntryPoint, and thus no other
     * action is needed by the account itself.
     *
     * @param nonce to validate
     *
     * solhint-disable-next-line no-empty-blocks
     */
    function _validateNonce(uint256 nonce) internal view virtual {
    }

    /**
     * sends to the entrypoint (msg.sender) the missing funds for this transaction.
     * subclass MAY override this method for better funds management
     * (e.g. send to the entryPoint more than the minimum required, so that in future transactions
     * it will not be required to send again)
     * @param missingAccountFunds the minimum value this method should send the entrypoint.
     *  this value MAY be zero, in case there is enough deposit, or the userOp has a paymaster.
     */
    function _payPrefund(uint256 missingAccountFunds) internal virtual {
        if (missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{value : missingAccountFunds, gas : type(uint256).max}("");
            (success);
            //ignore failure (its EntryPoint's job to verify, not account.)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./IExecutionManager.sol";
import "./IModuleManager.sol";
import "./IOwnerManager.sol";
import "./IPluginManager.sol";
import "./IFallbackManager.sol";
import "@account-abstraction/contracts/interfaces/IAccount.sol";
import "./IUpgradable.sol";

/**
 * @title SoulWallet Interface
 * @dev This interface aggregates multiple sub-interfaces to represent the functionalities of the SoulWallet
 * It encompasses account management, execution management, module management, owner management, plugin management,
 * fallback management, and upgradeability
 */
interface ISoulWallet is
    IAccount,
    IExecutionManager,
    IModuleManager,
    IOwnerManager,
    IPluginManager,
    IFallbackManager,
    IUpgradable
{}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../authority/EntryPointAuth.sol";

abstract contract EntryPointManager is EntryPointAuth {
    IEntryPoint private immutable _ENTRY_POINT;

    constructor(IEntryPoint entryPoint) {
        _ENTRY_POINT = entryPoint;
    }

    function _entryPoint() internal view override returns (IEntryPoint) {
        return _ENTRY_POINT;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../authority/Authority.sol";
import "./PluginManager.sol";
import "../interfaces/IExecutionManager.sol";

/**
 * @title ExecutionManager
 * @notice Manages the execution of transactions and batches of transactions
 * @dev Inherits functionality from IExecutionManager, Authority, and PluginManager
 */
abstract contract ExecutionManager is IExecutionManager, Authority, PluginManager {
    /**
     * @notice Execute a transaction
     * @param dest The destination address for the transaction
     * @param value The amount of ether to be sent with the transaction
     * @param func The calldata for the transaction
     */
    function execute(address dest, uint256 value, bytes calldata func) external override onlyEntryPoint {
        _call(dest, value, func);
    }

    /**
     * @notice Execute a sequence of transactions without any associated ether
     * @param dest List of destination addresses for each transaction
     * @param func List of calldata for each transaction
     */
    function executeBatch(address[] calldata dest, bytes[] calldata func) external override onlyEntryPoint {
        for (uint256 i = 0; i < dest.length;) {
            _call(dest[i], 0, func[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Execute a sequence of transactions, each potentially having associated ether
     * @param dest List of destination addresses for each transaction
     * @param value List of ether amounts for each transaction
     * @param func List of calldata for each transaction
     */
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func)
        external
        override
        onlyEntryPoint
    {
        for (uint256 i = 0; i < dest.length;) {
            _call(dest[i], value[i], func[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Internal function to handle the call logic
     * @param target Address of the target contract
     * @param value Ether to be sent with the transaction
     * @param data Calldata for the transaction
     */
    function _call(address target, uint256 value, bytes memory data) private executeHook(target, value, data) {
        assembly ("memory-safe") {
            let result := call(gas(), target, value, add(data, 0x20), mload(data), 0, 0)
            if iszero(result) {
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../interfaces/IPluginManager.sol";
import "../interfaces/IPlugin.sol";
import "../libraries/AccountStorage.sol";
import "../authority/Authority.sol";
import "../libraries/AddressLinkedList.sol";
import "../interfaces/IPluggable.sol";
import "../interfaces/IPluginStorage.sol";

/**
 * @title PluginManager
 * @dev This contract manages plugins and provides associated utility functions
 */
abstract contract PluginManager is IPluginManager, Authority, IPluginStorage {
    uint8 private constant _GUARD_HOOK = 1 << 0;
    uint8 private constant _PRE_HOOK = 1 << 1;
    uint8 private constant _POST_HOOK = 1 << 2;

    using AddressLinkedList for mapping(address => address);
    /**
     * @dev Adds a new plugin
     * @param pluginAndData The plugin address and associated data
     */

    function addPlugin(bytes calldata pluginAndData) external override onlyModule {
        _addPlugin(pluginAndData);
    }

    function _addPlugin(bytes calldata pluginAndData) internal {
        if (pluginAndData.length < 20) {
            revert Errors.PLUGIN_ADDRESS_EMPTY();
        }
        address pluginAddress = address(bytes20(pluginAndData[:20]));
        bytes calldata initData = pluginAndData[20:];
        IPlugin aPlugin = IPlugin(pluginAddress);
        if (!aPlugin.supportsInterface(type(IPlugin).interfaceId)) {
            revert Errors.PLUGIN_NOT_SUPPORT_INTERFACE();
        }
        AccountStorage.Layout storage l = AccountStorage.layout();
        uint8 hookType = aPlugin.supportsHook();

        if (hookType & 7 /*  _GUARD_HOOK | _PRE_HOOK | _POST_HOOK */ == 0) {
            revert Errors.PLUGIN_HOOK_TYPE_ERROR();
        }

        if (hookType & _GUARD_HOOK == _GUARD_HOOK) {
            l.guardHookPlugins.add(pluginAddress);
        }
        if (hookType & _PRE_HOOK == _PRE_HOOK) {
            l.preHookPlugins.add(pluginAddress);
        }
        if (hookType & _POST_HOOK == _POST_HOOK) {
            l.postHookPlugins.add(pluginAddress);
        }
        l.plugins.add(pluginAddress);
        if (!call(pluginAddress, abi.encodeWithSelector(IPluggable.walletInit.selector, initData))) {
            revert Errors.PLUGIN_INIT_FAILED();
        }
        emit PluginAdded(pluginAddress);
    }
    /**
     * @dev Removes a plugin
     * @param plugin Address of the plugin to be removed
     */

    function removePlugin(address plugin) external override onlyModule {
        AccountStorage.Layout storage l = AccountStorage.layout();
        l.plugins.remove(plugin);
        bool success = call(plugin, abi.encodeWithSelector(IPluggable.walletDeInit.selector));
        if (success) {
            emit PluginRemoved(plugin);
        } else {
            emit PluginRemovedWithError(plugin);
        }
        l.guardHookPlugins.tryRemove(plugin);
        l.preHookPlugins.tryRemove(plugin);
        l.postHookPlugins.tryRemove(plugin);
    }
    /**
     * @dev Checks if a plugin is authorized
     * @param plugin Address of the plugin
     * @return Returns true if the plugin is authorized, false otherwise
     */

    function isAuthorizedPlugin(address plugin) external view override returns (bool) {
        return AccountStorage.layout().plugins.isExist(plugin);
    }
    /**
     * @dev Lists plugins based on the hook type
     * @param hookType Type of the hook
     * @return plugins An array of plugin addresses
     */

    function listPlugin(uint8 hookType) external view override returns (address[] memory plugins) {
        if (hookType == 0) {
            mapping(address => address) storage _plugins = AccountStorage.layout().plugins;
            plugins = _plugins.list(AddressLinkedList.SENTINEL_ADDRESS, _plugins.size());
        } else if (hookType == _GUARD_HOOK) {
            mapping(address => address) storage _plugins = AccountStorage.layout().guardHookPlugins;
            plugins = _plugins.list(AddressLinkedList.SENTINEL_ADDRESS, _plugins.size());
        } else if (hookType == _PRE_HOOK) {
            mapping(address => address) storage _plugins = AccountStorage.layout().preHookPlugins;
            plugins = _plugins.list(AddressLinkedList.SENTINEL_ADDRESS, _plugins.size());
        } else if (hookType == _POST_HOOK) {
            mapping(address => address) storage _plugins = AccountStorage.layout().postHookPlugins;
            plugins = _plugins.list(AddressLinkedList.SENTINEL_ADDRESS, _plugins.size());
        } else {
            revert Errors.PLUGIN_HOOK_TYPE_ERROR();
        }
    }

    function _nextGuardHookData(bytes calldata guardHookData, uint256 cursor)
        private
        pure
        returns (address _guardAddr, uint256 _cursorFrom, uint256 _cursorEnd)
    {
        uint256 dataLen = guardHookData.length;
        uint48 guardSigLen;
        if (dataLen > cursor) {
            unchecked {
                _cursorEnd = cursor + 20;
            }
            bytes calldata _guardAddrBytes = guardHookData[cursor:_cursorEnd];
            assembly ("memory-safe") {
                _guardAddr := shr(0x60, calldataload(_guardAddrBytes.offset))
            }
            require(_guardAddr != address(0));
            unchecked {
                cursor = _cursorEnd;
                _cursorEnd = cursor + 6;
            }
            bytes calldata _guardSigLen = guardHookData[cursor:_cursorEnd];
            assembly ("memory-safe") {
                guardSigLen := shr(0xd0, calldataload(_guardSigLen.offset))
            }
            unchecked {
                cursor = _cursorEnd;
                _cursorEnd = cursor + guardSigLen;
            }
            _cursorFrom = cursor;
        }
    }
    /**
     * @dev Hooks a user operation with associated data
     * @param userOp User operation details
     * @param userOpHash Hash of the user operation
     * @param guardHookData Data for the guard hook
     * @return Returns true if the hook was successful, false otherwise
     */

    function guardHook(UserOperation calldata userOp, bytes32 userOpHash, bytes calldata guardHookData)
        internal
        returns (bool)
    {
        AccountStorage.Layout storage l = AccountStorage.layout();
        mapping(address => address) storage _plugins = l.guardHookPlugins;

        /* 
            +--------------------------------------------------------------------------------+  
            |                            multi-guardHookInputData                            |  
            +--------------------------------------------------------------------------------+  
            |   guardHookInputData  |  guardHookInputData   |   ...  |  guardHookInputData   |
            +-----------------------+--------------------------------------------------------+  
            |     dynamic data      |     dynamic data      |   ...  |     dynamic data      |
            +--------------------------------------------------------------------------------+

            +----------------------------------------------------------------------+  
            |                                guardHookInputData                    |  
            +----------------------------------------------------------------------+  
            |   guardHook address  |   input data length   |      input data       |
            +----------------------+-----------------------------------------------+  
            |        20bytes       |     6bytes(uint48)    |         bytes         |
            +----------------------------------------------------------------------+
         */
        address _guardAddr;
        uint256 _cursorFrom;
        uint256 _cursorEnd;
        (_guardAddr, _cursorFrom, _cursorEnd) = _nextGuardHookData(guardHookData, _cursorEnd);

        address addr = _plugins[AddressLinkedList.SENTINEL_ADDRESS];
        while (uint160(addr) > AddressLinkedList.SENTINEL_UINT) {
            {
                bytes calldata currentGuardHookData;
                address plugin = addr;
                if (plugin == _guardAddr) {
                    currentGuardHookData = guardHookData[_cursorFrom:_cursorEnd];
                    // next
                    _guardAddr = address(0);
                    if (_cursorEnd > 0) {
                        (_guardAddr, _cursorFrom, _cursorEnd) = _nextGuardHookData(guardHookData, _cursorEnd);
                    }
                } else {
                    currentGuardHookData = guardHookData[0:0];
                }
                bool success =
                    call(plugin, abi.encodeCall(IPlugin.guardHook, (userOp, userOpHash, currentGuardHookData)));
                if (!success) {
                    return false;
                }
            }
            addr = _plugins[addr];
        }
        if (_guardAddr != address(0)) {
            revert Errors.INVALID_GUARD_HOOK_DATA();
        }
        return true;
    }
    /**
     * @dev Executes hooks around a transaction
     * @param target Address of the transaction target
     * @param value Amount of ether to send with the transaction
     * @param data Data of the transaction
     */

    modifier executeHook(address target, uint256 value, bytes memory data) {
        AccountStorage.Layout storage l = AccountStorage.layout();
        {
            mapping(address => address) storage _preHookPlugins = l.preHookPlugins;
            address addr = _preHookPlugins[AddressLinkedList.SENTINEL_ADDRESS];
            while (uint160(addr) > AddressLinkedList.SENTINEL_UINT) {
                {
                    address plugin = addr;
                    if (!call(plugin, abi.encodeCall(IPlugin.preHook, (target, value, data)))) {
                        revert Errors.PLUGIN_PRE_HOOK_FAILED();
                    }
                }
                addr = _preHookPlugins[addr];
            }
        }
        _;
        {
            mapping(address => address) storage _postHookPlugins = l.postHookPlugins;

            address addr = _postHookPlugins[AddressLinkedList.SENTINEL_ADDRESS];
            while (uint160(addr) > AddressLinkedList.SENTINEL_UINT) {
                {
                    address plugin = addr;
                    if (!call(plugin, abi.encodeCall(IPlugin.postHook, (target, value, data)))) {
                        revert Errors.PLUGIN_POST_HOOK_FAILED();
                    }
                }
                addr = _postHookPlugins[addr];
            }
        }
    }

    function call(address target, bytes memory data) private returns (bool success) {
        assembly ("memory-safe") {
            success := call(gas(), target, 0, add(data, 0x20), mload(data), 0, 0)
        }
    }
    /**
     * @dev Ensures that the function is only called by an authorized plugin
     */

    modifier onlyPlugin() {
        if (AccountStorage.layout().plugins[msg.sender] == address(0)) {
            revert Errors.PLUGIN_NOT_REGISTERED();
        }
        _;
    }
    /**
     * @dev Stores data for a plugin
     * @param key Key to store the data against
     * @param value Data to be stored
     */

    function pluginDataStore(bytes32 key, bytes calldata value) external override onlyPlugin {
        AccountStorage.layout().pluginDataBytes[msg.sender][key] = value;
    }
    /**
     * @dev Loads data of a plugin
     * @param plugin Address of the plugin
     * @param key Key for which data needs to be loaded
     * @return Returns the loaded data
     */

    function pluginDataLoad(address plugin, bytes32 key) external view override returns (bytes memory) {
        return AccountStorage.layout().pluginDataBytes[plugin][key];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../libraries/AccountStorage.sol";
import "../authority/Authority.sol";
import "../interfaces/IModuleManager.sol";
import "../interfaces/IPluginManager.sol";
import "../libraries/AddressLinkedList.sol";
import "../libraries/SelectorLinkedList.sol";

/**
 * @title ModuleManager
 * @notice Manages the modules that are added to, or removed from, the wallet
 * @dev Inherits functionalities from IModuleManager and Authority
 */
abstract contract ModuleManager is IModuleManager, Authority {
    using AddressLinkedList for mapping(address => address);
    using SelectorLinkedList for mapping(bytes4 => bytes4);

    /// @dev Returns the mapping of modules
    function _modulesMapping() private view returns (mapping(address => address) storage modules) {
        modules = AccountStorage.layout().modules;
    }

    /// @dev Returns the mapping of module selectors
    function _moduleSelectorsMapping()
        private
        view
        returns (mapping(address => mapping(bytes4 => bytes4)) storage moduleSelectors)
    {
        moduleSelectors = AccountStorage.layout().moduleSelectors;
    }
    /// @dev Checks if the sender is an authorized module

    function _isAuthorizedModule() internal view override returns (bool) {
        address module = msg.sender;
        if (!_modulesMapping().isExist(module)) {
            return false;
        }
        mapping(address => mapping(bytes4 => bytes4)) storage moduleSelectors = _moduleSelectorsMapping();
        return moduleSelectors[module].isExist(msg.sig);
    }
    /**
     * @notice Check if a module is authorized
     * @param module Address of the module
     * @return A boolean indicating the authorization status
     */

    function isAuthorizedModule(address module) external view override returns (bool) {
        return _modulesMapping().isExist(module);
    }

    /**
     * @notice Add a new module
     * @param moduleAndData Byte data containing the module address and initialization data
     */
    function addModule(bytes calldata moduleAndData) external override onlyModule {
        _addModule(moduleAndData);
    }
    /// @dev Internal function to add a module

    function _addModule(bytes calldata moduleAndData) internal {
        if (moduleAndData.length < 20) {
            revert Errors.MODULE_ADDRESS_EMPTY();
        }
        address moduleAddress = address(bytes20(moduleAndData[:20]));
        bytes calldata initData = moduleAndData[20:];
        IModule aModule = IModule(moduleAddress);
        if (!aModule.supportsInterface(type(IModule).interfaceId)) {
            revert Errors.MODULE_NOT_SUPPORT_INTERFACE();
        }
        bytes4[] memory requiredFunctions = aModule.requiredFunctions();
        if (requiredFunctions.length == 0) {
            revert Errors.MODULE_SELECTORS_EMPTY();
        }
        mapping(address => address) storage modules = _modulesMapping();
        modules.add(moduleAddress);
        mapping(address => mapping(bytes4 => bytes4)) storage moduleSelectors = _moduleSelectorsMapping();
        moduleSelectors[moduleAddress].add(requiredFunctions);
        aModule.walletInit(initData);
        emit ModuleAdded(moduleAddress);
    }
    /**
     * @notice Remove a module
     * @param module Address of the module to be removed
     */

    function removeModule(address module) external override onlyModule {
        mapping(address => address) storage modules = _modulesMapping();
        modules.remove(module);

        mapping(address => mapping(bytes4 => bytes4)) storage moduleSelectors = _moduleSelectorsMapping();
        moduleSelectors[module].clear();

        try IModule(module).walletDeInit() {
            emit ModuleRemoved(module);
        } catch {
            emit ModuleRemovedWithError(module);
        }
    }
    /**
     * @notice List all the modules and their associated selectors
     * @return modules An array of module addresses
     * @return selectors A two-dimensional array of selectors
     */

    function listModule() external view override returns (address[] memory modules, bytes4[][] memory selectors) {
        mapping(address => address) storage _modules = _modulesMapping();
        uint256 moduleSize = _modulesMapping().size();
        modules = new address[](moduleSize);
        mapping(address => mapping(bytes4 => bytes4)) storage moduleSelectors = _moduleSelectorsMapping();
        selectors = new bytes4[][](moduleSize);

        uint256 i = 0;
        address addr = _modules[AddressLinkedList.SENTINEL_ADDRESS];
        while (uint160(addr) > AddressLinkedList.SENTINEL_UINT) {
            {
                modules[i] = addr;
                mapping(bytes4 => bytes4) storage moduleSelector = moduleSelectors[addr];

                {
                    uint256 selectorSize = moduleSelector.size();
                    bytes4[] memory _selectors = new bytes4[](selectorSize);
                    uint256 j = 0;
                    bytes4 selector = moduleSelector[SelectorLinkedList.SENTINEL_SELECTOR];
                    while (uint32(selector) > SelectorLinkedList.SENTINEL_UINT) {
                        _selectors[j] = selector;

                        selector = moduleSelector[selector];
                        unchecked {
                            j++;
                        }
                    }
                    selectors[i] = _selectors;
                }
            }

            addr = _modules[addr];
            unchecked {
                i++;
            }
        }
    }
    /**
     * @notice Execute a transaction from a module
     * @param to Address to which the transaction should be executed
     * @param value Amount of ETH (in wei) to be sent
     * @param data Transaction data
     */

    function executeFromModule(address to, uint256 value, bytes memory data) external override onlyModule {
        if (to == address(this)) revert Errors.MODULE_EXECUTE_FROM_MODULE_RECURSIVE();
        assembly {
            /* not memory-safe */
            let result := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
            if iszero(result) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../libraries/AccountStorage.sol";
import "../authority/Authority.sol";
import "../interfaces/IOwnerManager.sol";
import "../libraries/Bytes32LinkedList.sol";
import "../libraries/Errors.sol";

/**
 * @title OwnerManager
 * @notice Manages the owners of the wallet, allowing for addition, removal, and listing of owners
 * The owner should be of bytes32 type. Currently, an owner is an eoa key or the public key of the passkey
 * @dev Inherits functionalities from IOwnerManager and Authority
 */
abstract contract OwnerManager is IOwnerManager, Authority {
    using Bytes32LinkedList for mapping(bytes32 => bytes32);

    /**
     * @notice Helper function to get the owner mapping from account storage
     * @return owners Mapping of current owners
     */
    function _ownerMapping() private view returns (mapping(bytes32 => bytes32) storage owners) {
        owners = AccountStorage.layout().owners;
    }
    /**
     * @notice Checks if the provided owner is a current owner
     * @param owner Address in bytes32 format to check
     * @return true if provided owner is a current owner, false otherwise
     */

    function _isOwner(bytes32 owner) internal view override returns (bool) {
        return _ownerMapping().isExist(owner);
    }
    /**
     * @notice External function to check if the provided owner is a current owner
     * @param owner Address in bytes32 format to check
     * @return true if provided owner is a current owner, false otherwise
     */

    function isOwner(bytes32 owner) external view override returns (bool) {
        return _isOwner(owner);
    }
    /**
     * @notice Clears all owners
     */

    function _clearOwner() private {
        _ownerMapping().clear();
        emit OwnerCleared();
    }
    /**
     * @notice Resets the owner to a new owner
     * @param newOwner The new owner address in bytes32 format
     */

    function resetOwner(bytes32 newOwner) external override onlySelfOrModule {
        _clearOwner();
        _addOwner(newOwner);
    }
    /**
     * @notice Resets the owners to a new set of owners
     * @param newOwners An array of new owner addresses in bytes32 format
     */

    function resetOwners(bytes32[] calldata newOwners) external override onlySelfOrModule {
        _clearOwner();
        _addOwners(newOwners);
    }
    /**
     * @notice Adds multiple owners
     * @param owners An array of owner addresses in bytes32 format to add
     */

    function _addOwners(bytes32[] calldata owners) internal {
        for (uint256 i = 0; i < owners.length;) {
            _addOwner(owners[i]);
            unchecked {
                i++;
            }
        }
    }
    /**
     * @notice Adds a single owner
     * @param owner The owner address in bytes32 format to add
     */

    function addOwner(bytes32 owner) external override onlySelfOrModule {
        _addOwner(owner);
    }
    /**
     * @notice Adds multiple owners
     * @param owners An array of owner addresses in bytes32 format to add
     */

    function addOwners(bytes32[] calldata owners) external override onlySelfOrModule {
        _addOwners(owners);
    }
    /**
     * @notice Adds a single owner
     * @param owner The owner address in bytes32 format to add
     */

    function _addOwner(bytes32 owner) internal {
        _ownerMapping().add(owner);
        emit OwnerAdded(owner);
    }
    /**
     * @notice Removes a single owner
     * @param owner The owner address in bytes32 format to remove
     */

    function removeOwner(bytes32 owner) external override onlySelfOrModule {
        _ownerMapping().remove(owner);
        if (_ownerMapping().isEmpty()) {
            revert Errors.NO_OWNER();
        }
        emit OwnerRemoved(owner);
    }
    /**
     * @notice Lists all current owners
     * @return owners An array of current owner addresses in bytes32 format
     */

    function listOwner() external view override returns (bytes32[] memory owners) {
        uint256 size = _ownerMapping().size();
        owners = _ownerMapping().list(Bytes32LinkedList.SENTINEL_BYTES32, size);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../authority/OwnerAuth.sol";
import "../base/Validator.sol";
import "../libraries/Errors.sol";
import "../libraries/TypeConversion.sol";
import "../libraries/SignatureDecoder.sol";

/**
 * @title SignatureValidator
 * @dev This contract provides functionality for validating cryptographic signatures
 */
abstract contract SignatureValidator is OwnerAuth, Validator {
    using ECDSA for bytes32;
    using TypeConversion for address;
    /**
     * @dev Encodes the raw hash using a validator to prevent replay attacks
     * If the same owner signs the message for different smart contract accounts,
     * this function uses EIP-712-like encoding to encode the raw hash
     * @param rawHash The raw hash to encode
     * @return encodeRawHash The encoded hash
     */

    function _encodeRawHash(bytes32 rawHash) internal view returns (bytes32 encodeRawHash) {
        return validator().encodeRawHash(rawHash);
    }
    /**
     * @dev Validates an EIP1271 signature
     * @param rawHash The raw hash against which the signature is to be checked
     * @param rawSignature The signature to validate
     * @return validationData The data used for validation
     * @return sigValid A boolean indicating if the signature is valid or not
     */

    function _isValidate1271Signature(bytes32 rawHash, bytes calldata rawSignature)
        internal
        view
        returns (uint256 validationData, bool sigValid)
    {
        bytes32 recovered;
        bool success;
        bytes calldata guardHookInputData;
        bytes calldata validatorSignature;

        (guardHookInputData, validatorSignature) = SignatureDecoder.decodeSignature(rawSignature);

        // To prevent potential attacks, prohibit the use of guardHookInputData with EIP1271 signatures.
        require(guardHookInputData.length == 0);

        (validationData, recovered, success) = validator().recover1271Signature(rawHash, validatorSignature);

        if (!success) {
            sigValid = false;
        } else {
            sigValid = _isOwner(recovered);
        }
    }
    /**
     * @dev Validates a user operation signature
     * @param userOpHash The hash of the user operation
     * @param userOpSignature The signature of the user operation
     * @return validationData same as defined in EIP4337
     * @return sigValid A boolean indicating if the signature is valid or not
     * @return guardHookInputData Input data for the guard hook
     */

    function _isValidUserOp(bytes32 userOpHash, bytes calldata userOpSignature)
        internal
        view
        returns (uint256 validationData, bool sigValid, bytes calldata guardHookInputData)
    {
        bytes32 recovered;
        bool success;
        bytes calldata validatorSignature;

        (guardHookInputData, validatorSignature) = SignatureDecoder.decodeSignature(userOpSignature);

        (validationData, recovered, success) = validator().recoverSignature(userOpHash, validatorSignature);
        if (!success) {
            sigValid = false;
        } else {
            sigValid = _isOwner(recovered);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../helper/SignatureValidator.sol";
import "@account-abstraction/contracts/core/Helpers.sol";
import "../interfaces/IERC1271Handler.sol";
import "../authority/Authority.sol";
import "../libraries/AccountStorage.sol";

/**
 * @title ERC1271Handler
 * @dev This contract provides functionality to handle ERC1271 signature validations
 */
abstract contract ERC1271Handler is Authority, IERC1271Handler, SignatureValidator {
    // Magic value indicating a valid signature for ERC-1271 contracts
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 internal constant MAGICVALUE = 0x1626ba7e;
    // Constants indicating different invalid states
    bytes4 internal constant INVALID_ID = 0xffffffff;
    bytes4 internal constant INVALID_TIME_RANGE = 0xfffffffe;
    /**
     * @dev Provides access to the mapping of approved hashes from the AccountStorage
     * @return The mapping of approved hashes
     */

    function _approvedHashes() private view returns (mapping(bytes32 => uint256) storage) {
        return AccountStorage.layout().approvedHashes;
    }
    /**
     * @dev Checks if a given signature is valid for the provided hash
     * @param rawHash The raw hash to check the signature against
     * @param signature The provided signature
     * @return magicValue A bytes4 magic value indicating the result of the signature check
     */

    function isValidSignature(bytes32 rawHash, bytes calldata signature)
        external
        view
        override
        returns (bytes4 magicValue)
    {
        bytes32 datahash = _encodeRawHash(rawHash);
        if (signature.length > 0) {
            (uint256 _validationData, bool sigValid) = _isValidate1271Signature(datahash, signature);
            if (!sigValid) {
                return INVALID_ID;
            }
            if (_validationData > 0) {
                ValidationData memory validationData = _parseValidationData(_validationData);
                bool outOfTimeRange =
                    (block.timestamp > validationData.validUntil) || (block.timestamp < validationData.validAfter);
                if (outOfTimeRange) {
                    return INVALID_TIME_RANGE;
                }
            }
            return MAGICVALUE;
        }

        mapping(bytes32 => uint256) storage approvedHashes = _approvedHashes();
        uint256 status = approvedHashes[datahash];
        if (status == 1) {
            // approved
            return MAGICVALUE;
        } else {
            return INVALID_ID;
        }
    }
    /**
     * @dev Approves a given hash
     * @param hash The hash to be approved
     */

    function approveHash(bytes32 hash) external override onlySelfOrModule {
        mapping(bytes32 => uint256) storage approvedHashes = _approvedHashes();
        if (approvedHashes[hash] == 1) {
            revert Errors.HASH_ALREADY_APPROVED();
        }
        approvedHashes[hash] = 1;
        emit ApproveHash(hash);
    }
    /**
     * @dev Rejects a given hash
     * @param hash The hash to be rejected
     */

    function rejectHash(bytes32 hash) external override onlySelfOrModule {
        mapping(bytes32 => uint256) storage approvedHashes = _approvedHashes();
        if (approvedHashes[hash] == 0) {
            revert Errors.HASH_ALREADY_REJECTED();
        }
        approvedHashes[hash] = 0;
        emit RejectHash(hash);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../interfaces/IFallbackManager.sol";
import "../authority/Authority.sol";
import "../libraries/AccountStorage.sol";

/**
 * @title FallbackManager
 * @notice Manages the fallback behavior for the contract
 * @dev Inherits functionalities from Authority and IFallbackManager
 */
abstract contract FallbackManager is Authority, IFallbackManager {
    /// @notice A payable function that allows the contract to receive ether
    receive() external payable {}

    /**
     * @dev Sets the address of the fallback handler contract
     * @param fallbackContract The address of the new fallback handler contract
     */
    function _setFallbackHandler(address fallbackContract) internal {
        AccountStorage.layout().defaultFallbackContract = fallbackContract;
    }

    /**
     * @notice Fallback function that forwards all requests to the fallback handler contract
     * @dev The request is forwarded using a STATICCALL
     * It ensures that the state of the contract doesn't change even if the fallback function has state-changing operations
     */
    fallback() external payable {
        address fallbackContract = AccountStorage.layout().defaultFallbackContract;
        assembly {
            /* not memory-safe */
            calldatacopy(0, 0, calldatasize())
            let result := staticcall(gas(), fallbackContract, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @notice Sets the address of the fallback handler and emits the FallbackChanged event
     * @param fallbackContract The address of the new fallback handler
     */
    function setFallbackHandler(address fallbackContract) external override onlySelfOrModule {
        _setFallbackHandler(fallbackContract);
        emit FallbackChanged(fallbackContract);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../interfaces/IUpgradable.sol";
import "../libraries/Errors.sol";
/**
 * @title UpgradeManager
 * @dev This contract allows for the logic of a proxy to be upgraded
 */

abstract contract UpgradeManager is IUpgradable {
    /**
     * @dev Storage slot with the address of the current implementation
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    /**
     * @dev Upgrades the logic to a new implementation
     * @param newImplementation Address of the new implementation
     */

    function _upgradeTo(address newImplementation) internal {
        bool isContract;
        assembly ("memory-safe") {
            isContract := gt(extcodesize(newImplementation), 0)
        }
        if (!isContract) {
            revert Errors.INVALID_LOGIC_ADDRESS();
        }
        address oldImplementation;
        assembly ("memory-safe") {
            oldImplementation := and(sload(_IMPLEMENTATION_SLOT), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        if (oldImplementation == newImplementation) {
            revert Errors.SAME_LOGIC_ADDRESS();
        }
        assembly ("memory-safe") {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }

        // delegatecall to new implementation
        (bool success,) =
            newImplementation.delegatecall(abi.encodeWithSelector(IUpgradable.upgradeFrom.selector, oldImplementation));
        if (!success) {
            revert Errors.UPGRADE_FAILED();
        }
        emit Upgraded(oldImplementation, newImplementation);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../interfaces/IValidator.sol";
import "./Validator.sol";

/**
 * @title ValidatorManager
 * @dev This abstract contract extends the Validator contract and manages a single instance of IValidator
 */
abstract contract ValidatorManager is Validator {
    /// @dev The IValidator interface instance
    IValidator private immutable _VALIDATOR;
    /**
     * @dev Constructs the ValidatorManager contracs
     * @param aValidator The IValidator interface instance
     */

    constructor(IValidator aValidator) {
        _VALIDATOR = aValidator;
    }
    /**
     * @dev Gets the IValidator interface instance
     * @return The IValidator interface instance
     */

    function validator() public view override returns (IValidator) {
        return _VALIDATOR;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

import {calldataKeccak} from "../core/Helpers.sol";

/**
 * User Operation struct
 * @param sender the sender account of this request.
     * @param nonce unique value the sender uses to verify it is not a replay.
     * @param initCode if set, the account contract will be created by this constructor/
     * @param callData the method call to execute on this account.
     * @param callGasLimit the gas limit passed to the callData method call.
     * @param verificationGasLimit gas used for validateUserOp and validatePaymasterUserOp.
     * @param preVerificationGas gas not calculated by the handleOps method, but added to the gas paid. Covers batch overhead.
     * @param maxFeePerGas same as EIP-1559 gas parameter.
     * @param maxPriorityFeePerGas same as EIP-1559 gas parameter.
     * @param paymasterAndData if set, this field holds the paymaster address and paymaster-specific data. the paymaster will pay for the transaction instead of the sender.
     * @param signature sender-verified signature over the entire request, the EntryPoint address and the chain ID.
     */
    struct UserOperation {

        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
        uint256 preVerificationGas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        bytes paymasterAndData;
        bytes signature;
    }

/**
 * Utility functions helpful when working with UserOperation structs.
 */
library UserOperationLib {

    function getSender(UserOperation calldata userOp) internal pure returns (address) {
        address data;
        //read sender from userOp, which is first userOp member (saves 800 gas...)
        assembly {data := calldataload(userOp)}
        return address(uint160(data));
    }

    //relayer/block builder might submit the TX with higher priorityFee, but the user should not
    // pay above what he signed for.
    function gasPrice(UserOperation calldata userOp) internal view returns (uint256) {
    unchecked {
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        if (maxFeePerGas == maxPriorityFeePerGas) {
            //legacy mode (for networks that don't support basefee opcode)
            return maxFeePerGas;
        }
        return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
    }
    }

    function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret) {
        address sender = getSender(userOp);
        uint256 nonce = userOp.nonce;
        bytes32 hashInitCode = calldataKeccak(userOp.initCode);
        bytes32 hashCallData = calldataKeccak(userOp.callData);
        uint256 callGasLimit = userOp.callGasLimit;
        uint256 verificationGasLimit = userOp.verificationGasLimit;
        uint256 preVerificationGas = userOp.preVerificationGas;
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        bytes32 hashPaymasterAndData = calldataKeccak(userOp.paymasterAndData);

        return abi.encode(
            sender, nonce,
            hashInitCode, hashCallData,
            callGasLimit, verificationGasLimit, preVerificationGas,
            maxFeePerGas, maxPriorityFeePerGas,
            hashPaymasterAndData
        );
    }

    function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.12;

/**
 * manage deposits and stakes.
 * deposit is just a balance used to pay for UserOperations (either by a paymaster or an account)
 * stake is value locked for at least "unstakeDelay" by the staked entity.
 */
interface IStakeManager {

    event Deposited(
        address indexed account,
        uint256 totalDeposit
    );

    event Withdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 amount
    );

    /// Emitted when stake or unstake delay are modified
    event StakeLocked(
        address indexed account,
        uint256 totalStaked,
        uint256 unstakeDelaySec
    );

    /// Emitted once a stake is scheduled for withdrawal
    event StakeUnlocked(
        address indexed account,
        uint256 withdrawTime
    );

    event StakeWithdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 amount
    );

    /**
     * @param deposit the entity's deposit
     * @param staked true if this entity is staked.
     * @param stake actual amount of ether staked for this entity.
     * @param unstakeDelaySec minimum delay to withdraw the stake.
     * @param withdrawTime - first block timestamp where 'withdrawStake' will be callable, or zero if already locked
     * @dev sizes were chosen so that (deposit,staked, stake) fit into one cell (used during handleOps)
     *    and the rest fit into a 2nd cell.
     *    112 bit allows for 10^15 eth
     *    48 bit for full timestamp
     *    32 bit allows 150 years for unstake delay
     */
    struct DepositInfo {
        uint112 deposit;
        bool staked;
        uint112 stake;
        uint32 unstakeDelaySec;
        uint48 withdrawTime;
    }

    //API struct used by getStakeInfo and simulateValidation
    struct StakeInfo {
        uint256 stake;
        uint256 unstakeDelaySec;
    }

    /// @return info - full deposit information of given account
    function getDepositInfo(address account) external view returns (DepositInfo memory info);

    /// @return the deposit (for gas payment) of the account
    function balanceOf(address account) external view returns (uint256);

    /**
     * add to the deposit of the given account
     */
    function depositTo(address account) external payable;

    /**
     * add to the account's stake - amount and delay
     * any pending unstake is first cancelled.
     * @param _unstakeDelaySec the new lock duration before the deposit can be withdrawn.
     */
    function addStake(uint32 _unstakeDelaySec) external payable;

    /**
     * attempt to unlock the stake.
     * the value can be withdrawn (using withdrawStake) after the unstake delay.
     */
    function unlockStake() external;

    /**
     * withdraw from the (unlocked) stake.
     * must first call unlockStake and wait for the unstakeDelay to pass
     * @param withdrawAddress the address to send withdrawn value.
     */
    function withdrawStake(address payable withdrawAddress) external;

    /**
     * withdraw from the deposit.
     * @param withdrawAddress the address to send withdrawn value.
     * @param withdrawAmount the amount to withdraw.
     */
    function withdrawTo(address payable withdrawAddress, uint256 withdrawAmount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

/**
 * Aggregated Signatures validator.
 */
interface IAggregator {

    /**
     * validate aggregated signature.
     * revert if the aggregated signature does not match the given list of operations.
     */
    function validateSignatures(UserOperation[] calldata userOps, bytes calldata signature) external view;

    /**
     * validate signature of a single userOp
     * This method is should be called by bundler after EntryPoint.simulateValidation() returns (reverts) with ValidationResultWithAggregation
     * First it validates the signature over the userOp. Then it returns data to be used when creating the handleOps.
     * @param userOp the userOperation received from the user.
     * @return sigForUserOp the value to put into the signature field of the userOp when calling handleOps.
     *    (usually empty, unless account and aggregator support some kind of "multisig"
     */
    function validateUserOpSignature(UserOperation calldata userOp)
    external view returns (bytes memory sigForUserOp);

    /**
     * aggregate multiple signatures into a single value.
     * This method is called off-chain to calculate the signature to pass with handleOps()
     * bundler MAY use optimized custom code perform this aggregation
     * @param userOps array of UserOperations to collect the signatures from.
     * @return aggregatedSignature the aggregated signature
     */
    function aggregateSignatures(UserOperation[] calldata userOps) external view returns (bytes memory aggregatedSignature);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface INonceManager {

    /**
     * Return the next nonce for this sender.
     * Within a given key, the nonce values are sequenced (starting with zero, and incremented by one on each userop)
     * But UserOp with different keys can come with arbitrary order.
     *
     * @param sender the account address
     * @param key the high 192 bit of the nonce
     * @return nonce a full nonce to pass for next UserOp with this sender.
     */
    function getNonce(address sender, uint192 key)
    external view returns (uint256 nonce);

    /**
     * Manually increment the nonce of the sender.
     * This method is exposed just for completeness..
     * Account does NOT need to call it, neither during validation, nor elsewhere,
     * as the EntryPoint will update the nonce regardless.
     * Possible use-case is call it with various keys to "initialize" their nonces to one, so that future
     * UserOperations will not pay extra for the first transaction with a given key.
     */
    function incrementNonce(uint192 key) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

interface IAccount {

    /**
     * Validate user's signature and nonce
     * the entryPoint will make the call to the recipient only if this validation call returns successfully.
     * signature failure should be reported by returning SIG_VALIDATION_FAILED (1).
     * This allows making a "simulation call" without a valid signature
     * Other failures (e.g. nonce mismatch, or invalid signature format) should still revert to signal failure.
     *
     * @dev Must validate caller is the entryPoint.
     *      Must validate the signature and nonce
     * @param userOp the operation that is about to be executed.
     * @param userOpHash hash of the user's request data. can be used as the basis for signature.
     * @param missingAccountFunds missing funds on the account's deposit in the entrypoint.
     *      This is the minimum amount to transfer to the sender(entryPoint) to be able to make the call.
     *      The excess is left as a deposit in the entrypoint, for future calls.
     *      can be withdrawn anytime using "entryPoint.withdrawTo()"
     *      In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.
     * @return validationData packaged ValidationData structure. use `_packValidationData` and `_unpackValidationData` to encode and decode
     *      <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
     *         otherwise, an address of an "authorizer" contract.
     *      <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
     *      <6-byte> validAfter - first timestamp this operation is valid
     *      If an account doesn't use time-range, it is enough to return SIG_VALIDATION_FAILED value (1) for signature failure.
     *      Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
    external returns (uint256 validationData);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

/**
 * returned data from validateUserOp.
 * validateUserOp returns a uint256, with is created by `_packedValidationData` and parsed by `_parseValidationData`
 * @param aggregator - address(0) - the account validated the signature by itself.
 *              address(1) - the account failed to validate the signature.
 *              otherwise - this is an address of a signature aggregator that must be used to validate the signature.
 * @param validAfter - this UserOp is valid only after this timestamp.
 * @param validaUntil - this UserOp is valid only up to this timestamp.
 */
    struct ValidationData {
        address aggregator;
        uint48 validAfter;
        uint48 validUntil;
    }

//extract sigFailed, validAfter, validUntil.
// also convert zero validUntil to type(uint48).max
    function _parseValidationData(uint validationData) pure returns (ValidationData memory data) {
        address aggregator = address(uint160(validationData));
        uint48 validUntil = uint48(validationData >> 160);
        if (validUntil == 0) {
            validUntil = type(uint48).max;
        }
        uint48 validAfter = uint48(validationData >> (48 + 160));
        return ValidationData(aggregator, validAfter, validUntil);
    }

// intersect account and paymaster ranges.
    function _intersectTimeRange(uint256 validationData, uint256 paymasterValidationData) pure returns (ValidationData memory) {
        ValidationData memory accountValidationData = _parseValidationData(validationData);
        ValidationData memory pmValidationData = _parseValidationData(paymasterValidationData);
        address aggregator = accountValidationData.aggregator;
        if (aggregator == address(0)) {
            aggregator = pmValidationData.aggregator;
        }
        uint48 validAfter = accountValidationData.validAfter;
        uint48 validUntil = accountValidationData.validUntil;
        uint48 pmValidAfter = pmValidationData.validAfter;
        uint48 pmValidUntil = pmValidationData.validUntil;

        if (validAfter < pmValidAfter) validAfter = pmValidAfter;
        if (validUntil > pmValidUntil) validUntil = pmValidUntil;
        return ValidationData(aggregator, validAfter, validUntil);
    }

/**
 * helper to pack the return value for validateUserOp
 * @param data - the ValidationData to pack
 */
    function _packValidationData(ValidationData memory data) pure returns (uint256) {
        return uint160(data.aggregator) | (uint256(data.validUntil) << 160) | (uint256(data.validAfter) << (160 + 48));
    }

/**
 * helper to pack the return value for validateUserOp, when not using an aggregator
 * @param sigFailed - true for signature failure, false for success
 * @param validUntil last timestamp this UserOperation is valid (or zero for infinite)
 * @param validAfter first timestamp this UserOperation is valid
 */
    function _packValidationData(bool sigFailed, uint48 validUntil, uint48 validAfter) pure returns (uint256) {
        return (sigFailed ? 1 : 0) | (uint256(validUntil) << 160) | (uint256(validAfter) << (160 + 48));
    }

/**
 * keccak function over calldata.
 * @dev copy calldata into memory, do keccak and drop allocated memory. Strangely, this is more efficient than letting solidity do it.
 */
    function calldataKeccak(bytes calldata data) pure returns (bytes32 ret) {
        assembly {
            let mem := mload(0x40)
            let len := data.length
            calldatacopy(mem, data.offset, len)
            ret := keccak256(mem, len)
        }
    }

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title IExecutionManager
 * @dev Interface for executing transactions or batch of transactions
 * The execution can be a single transaction or multiple transactions in sequence
 */
interface IExecutionManager {
    /**
     * @notice Executes a single transaction
     * @dev This can be invoked directly by the owner or by an entry point
     *
     * @param dest The destination address for the transaction
     * @param value The amount of Ether (in wei) to transfer along with the transaction. Can be 0 for non-ETH transfers
     * @param func The function call data to be executed
     */
    function execute(address dest, uint256 value, bytes calldata func) external;

    /**
     * @notice Executes a sequence of transactions with the same Ether value for each
     * @dev All transactions in the batch will carry 0 Ether value
     * @param dest An array of destination addresses for each transaction in the batch
     * @param func An array of function call data for each transaction in the batch
     */
    function executeBatch(address[] calldata dest, bytes[] calldata func) external;

    /**
     * @notice Executes a sequence of transactions with specified Ether values for each
     * @dev The values for Ether transfer are specified for each transaction
     * @param dest An array of destination addresses for each transaction in the batch
     * @param value An array of amounts of Ether (in wei) to transfer for each transaction in the batch
     * @param func An array of function call data for each transaction in the batch
     */
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./IModule.sol";

/**
 * @title Module Manager Interface
 * @dev This interface defines the management functionalities for handling modules
 * within the system. Modules are components that can be added to or removed from the
 * smart contract to extend its functionalities. The manager ensures that only authorized
 * modules can execute certain functionalities
 */
interface IModuleManager {
    /**
     * @notice Emitted when a new module is successfully added
     * @param module The address of the newly added module
     */
    event ModuleAdded(address indexed module);
    /**
     * @notice Emitted when a module is successfully removed
     * @param module The address of the removed module
     */
    event ModuleRemoved(address indexed module);
    /**
     * @notice Emitted when there's an error while removing a module
     * @param module The address of the module that was attempted to be removed
     */
    event ModuleRemovedWithError(address indexed module);

    /**
     * @notice Adds a new module to the system
     * @param moduleAndData The module to be added and its associated initialization data
     */
    function addModule(bytes calldata moduleAndData) external;
    /**
     * @notice Removes a module from the system
     * @param  module The address of the module to be removed
     */
    function removeModule(address module) external;

    /**
     * @notice Checks if a module is authorized within the system
     * @param module The address of the module to check
     * @return True if the module is authorized, false otherwise
     */
    function isAuthorizedModule(address module) external returns (bool);
    /**
     * @notice Provides a list of all added modules and their respective authorized function selectors
     * @return modules An array of the addresses of all added modules
     * @return selectors A 2D array where each inner array represents the function selectors
     * that the corresponding module in the 'modules' array is allowed to call
     */
    function listModule() external view returns (address[] memory modules, bytes4[][] memory selectors);
    /**
     * @notice Allows a module to execute a function within the system. This ensures that the
     * module can only call functions it is permitted to, based on its declared `requiredFunctions`
     * @param dest The address of the destination contract where the function will be executed
     * @param value The amount of ether (in wei) to be sent with the function call
     * @param func The function data to be executed
     */
    function executeFromModule(address dest, uint256 value, bytes calldata func) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title Owner Manager Interface
 * @dev This interface defines the management functionalities for handling owners within the system.
 * Owners are identified by a unique bytes32 ID. This design allows for a flexible representation
 * of ownership – whether it be an Ethereum address, a hash of an off-chain public key, or any other
 * unique identifier.
 */
interface IOwnerManager {
    /**
     * @notice Emitted when a new owner is successfully added
     * @param owner The bytes32 ID of the newly added owner
     */
    event OwnerAdded(bytes32 indexed owner);

    /**
     * @notice Emitted when an owner is successfully removed
     * @param owner The bytes32 ID of the removed owner
     */
    event OwnerRemoved(bytes32 indexed owner);

    /**
     * @notice Emitted when all owners are cleared from the system
     */
    event OwnerCleared();

    /**
     * @notice Checks if a given bytes32 ID corresponds to an owner within the system
     * @param owner The bytes32 ID to check
     * @return True if the ID corresponds to an owner, false otherwise
     */
    function isOwner(bytes32 owner) external view returns (bool);

    /**
     * @notice Adds a new owner to the system
     * @param owner The bytes32 ID of the owner to be added
     */
    function addOwner(bytes32 owner) external;

    /**
     * @notice Removes an existing owner from the system
     * @param owner The bytes32 ID of the owner to be removed
     */
    function removeOwner(bytes32 owner) external;

    /**
     * @notice Resets the entire owner set, replacing it with a single new owner
     * @param newOwner The bytes32 ID of the new owner
     */
    function resetOwner(bytes32 newOwner) external;

    /**
     * @notice Adds multiple new owners to the system
     * @param owners An array of bytes32 IDs representing the owners to be added
     */
    function addOwners(bytes32[] calldata owners) external;

    /**
     * @notice Resets the entire owner set, replacing it with a new set of owners
     * @param newOwners An array of bytes32 IDs representing the new set of owners
     */
    function resetOwners(bytes32[] calldata newOwners) external;

    /**
     * @notice Provides a list of all added owners
     * @return owners An array of bytes32 IDs representing the owners
     */
    function listOwner() external view returns (bytes32[] memory owners);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./IPlugin.sol";

/**
 * @title Plugin Manager Interface
 * @dev This interface provides functionalities for adding, removing, and querying plugins
 */
interface IPluginManager {
    event PluginAdded(address indexed plugin);
    event PluginRemoved(address indexed plugin);
    event PluginRemovedWithError(address indexed plugin);

    /**
     * @notice Add a new plugin along with its initialization data
     * @param pluginAndData The plugin address concatenated with its initialization data
     */
    function addPlugin(bytes calldata pluginAndData) external;

    /**
     * @notice Remove a plugin from the system
     * @param plugin The address of the plugin to be removed
     */
    function removePlugin(address plugin) external;

    /**
     * @notice Checks if a plugin is authorized
     * @param plugin The address of the plugin to check
     * @return True if the plugin is authorized, otherwise false
     */
    function isAuthorizedPlugin(address plugin) external returns (bool);

    /**
     * @notice List all plugins of a specific hook type
     * @param hookType The type of the hook for which to list plugins
     * @return plugins An array of plugin addresses corresponding to the hookType
     */
    function listPlugin(uint8 hookType) external view returns (address[] memory plugins);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title IFallbackManager
 * @dev Interface for setting and managing the fallback contract.
 * The fallback contract is called when no other function matches the provided function signature.
 */
interface IFallbackManager {
    /**
     * @notice Emitted when the fallback contract is changed
     * @param fallbackContract The address of the newly set fallback contract
     */
    event FallbackChanged(address indexed fallbackContract);
    /**
     * @notice Set a new fallback contract
     * @dev This function allows setting a new address as the fallback contract. The fallback contract will receive
     * all calls made to this contract that do not match any other function
     * @param fallbackContract The address of the fallback contract to be set
     */

    function setFallbackHandler(address fallbackContract) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title Upgradable Interface
 * @dev This interface provides functionalities to upgrade the implementation of a contract
 * It emits an event when the implementation is changed, either to a new version or from an old version
 */
interface IUpgradable {
    event Upgraded(address indexed oldImplementation, address indexed newImplementation);

    /**
     * @dev Upgrade the current implementation to the provided new implementation address
     * @param newImplementation The address of the new contract implementation
     */
    function upgradeTo(address newImplementation) external;

    /**
     * @dev Upgrade from the current implementation, given the old implementation address
     * @param oldImplementation The address of the old contract implementation that is being replaced
     */
    function upgradeFrom(address oldImplementation) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "../libraries/Errors.sol";

/**
 * @title EntryPointAuth
 * @notice Abstract contract to provide EntryPoint based authentication
 * @dev Requires the inheriting contracts to implement the `_entryPoint` method
 */
abstract contract EntryPointAuth {
    /**
     * @notice Expected to return the associated entry point for the contract
     * @dev Must be implemented by inheriting contracts
     * @return The EntryPoint associated with the contract
     */
    function _entryPoint() internal view virtual returns (IEntryPoint);

    /*
        Data Flow:

        A: from entryPoint
            # msg.sender:    entryPoint
            # address(this): soulwalletProxy
            ┌────────────┐     ┌────────┐
            │ entryPoint │ ──► │  here  │
            └────────────┘     └────────┘
    * @notice Modifier to ensure the caller is the expected entry point
    * @dev If not called from the expected entry point, it will revert
    */
    modifier onlyEntryPoint() {
        if (msg.sender != address(_entryPoint())) {
            revert Errors.CALLER_MUST_BE_ENTRYPOINT();
        }
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./EntryPointAuth.sol";
import "./OwnerAuth.sol";
import "../interfaces/IExecutionManager.sol";
import "../interfaces/IModuleManager.sol";
import "../libraries/Errors.sol";
import "./ModuleAuth.sol";

/**
 * @title Authority
 * @notice An abstract contract that provides authorization mechanisms
 * @dev Inherits various authorization patterns including EntryPoint, Owner, and Module-based authentication
 */
abstract contract Authority is EntryPointAuth, OwnerAuth, ModuleAuth {
    /**
     * @notice Ensures the calling contract is either the Authority contract itself or an authorized module
     * @dev Uses the inherited `_isAuthorizedModule()` from ModuleAuth for module-based authentication
     */
    modifier onlySelfOrModule() {
        if (msg.sender != address(this) && !_isAuthorizedModule()) {
            revert Errors.CALLER_MUST_BE_SELF_OR_MODULE();
        }
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@account-abstraction/contracts/interfaces/UserOperation.sol";
import "./IPluggable.sol";

/**
 * @title Plugin Interface
 * @dev This interface provides functionalities for hooks and interactions of plugins within a wallet or contract
 */
interface IPlugin is IPluggable {
    /**
     * @notice Specifies the types of hooks a plugin supports
     * @return hookType An 8-bit value where:
     *         - GuardHook is represented by 1<<0
     *         - PreHook is represented by 1<<1
     *         - PostHook is represented by 1<<2
     */
    function supportsHook() external pure returns (uint8 hookType);

    /**
     * @notice A hook that guards the user operation
     * @dev For security, plugins should revert when they do not need guardData but guardData.length > 0
     * @param userOp The user operation being performed
     * @param userOpHash The hash of the user operation
     * @param guardData Additional data for the guard
     */
    function guardHook(UserOperation calldata userOp, bytes32 userOpHash, bytes calldata guardData) external;

    /**
     * @notice A hook that's executed before the actual operation
     * @param target The target address of the operation
     * @param value The amount of ether (in wei) involved in the operation
     * @param data The calldata for the operation
     */
    function preHook(address target, uint256 value, bytes calldata data) external;

    /**
     * @notice A hook that's executed after the actual operation
     * @param target The target address of the operation
     * @param value The amount of ether (in wei) involved in the operation
     * @param data The calldata for the operation
     */
    function postHook(address target, uint256 value, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

/**
 * @title AccountStorage
 * @notice A library that defines the storage layout for the SoulWallet account or contract.
 */
library AccountStorage {
    bytes32 private constant _ACCOUNT_SLOT = keccak256("soulwallet.contracts.AccountStorage");

    struct Layout {
        // ┌───────────────────┐
        // │     base data     │
        mapping(bytes32 => bytes32) owners;
        address defaultFallbackContract;
        uint256[50] __gap_0;
        // └───────────────────┘

        // ┌───────────────────┐
        // │      EIP1271      │
        mapping(bytes32 => uint256) approvedHashes;
        uint256[50] __gap_1;
        // └───────────────────┘

        // ┌───────────────────┐
        // │       Module      │
        mapping(address => address) modules;
        mapping(address => mapping(bytes4 => bytes4)) moduleSelectors;
        uint256[50] __gap_2;
        // └───────────────────┘

        // ┌───────────────────┐
        // │       Plugin      │
        mapping(address => address) plugins;
        mapping(address => address) guardHookPlugins;
        mapping(address => address) preHookPlugins;
        mapping(address => address) postHookPlugins;
        mapping(address => mapping(bytes32 => bytes)) pluginDataBytes;
        uint256[50] __gap_3;
    }
    // └───────────────────┘

    /**
     * @notice Returns the layout of the storage for the account or contract.
     * @return l The layout of the storage.
     */
    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = _ACCOUNT_SLOT;
        assembly ("memory-safe") {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../libraries/Errors.sol";

/**
 * @title Address Linked List
 * @notice This library provides utility functions to manage a linked list of addresses
 */
library AddressLinkedList {
    address internal constant SENTINEL_ADDRESS = address(1);
    uint160 internal constant SENTINEL_UINT = 1;
    /**
     * @dev Modifier that checks if an address is valid.
     */

    modifier onlyAddress(address addr) {
        if (uint160(addr) <= SENTINEL_UINT) {
            revert Errors.INVALID_ADDRESS();
        }
        _;
    }
    /**
     * @notice Adds an address to the linked list.
     * @param self The linked list mapping.
     * @param addr The address to be added.
     */

    function add(mapping(address => address) storage self, address addr) internal onlyAddress(addr) {
        if (self[addr] != address(0)) {
            revert Errors.ADDRESS_ALREADY_EXISTS();
        }
        address _prev = self[SENTINEL_ADDRESS];
        if (_prev == address(0)) {
            self[SENTINEL_ADDRESS] = addr;
            self[addr] = SENTINEL_ADDRESS;
        } else {
            self[SENTINEL_ADDRESS] = addr;
            self[addr] = _prev;
        }
    }
    /**
     * @notice Replaces an old address with a new one in the linked list.
     * @param self The linked list mapping.
     * @param oldAddr The old address to be replaced.
     * @param newAddr The new address.
     */

    function replace(mapping(address => address) storage self, address oldAddr, address newAddr) internal {
        if (!isExist(self, oldAddr)) {
            revert Errors.ADDRESS_NOT_EXISTS();
        }
        if (isExist(self, newAddr)) {
            revert Errors.ADDRESS_ALREADY_EXISTS();
        }

        address cursor = SENTINEL_ADDRESS;
        while (true) {
            address _addr = self[cursor];
            if (_addr == oldAddr) {
                address next = self[_addr];
                self[newAddr] = next;
                self[cursor] = newAddr;
                self[_addr] = address(0);
                return;
            }
            cursor = _addr;
        }
    }
    /**
     * @notice Removes an address from the linked list.
     * @param self The linked list mapping.
     * @param addr The address to be removed.
     */

    function remove(mapping(address => address) storage self, address addr) internal {
        if (!tryRemove(self, addr)) {
            revert Errors.ADDRESS_NOT_EXISTS();
        }
    }
    /**
     * @notice Tries to remove an address from the linked list.
     * @param self The linked list mapping.
     * @param addr The address to be removed.
     * @return Returns true if removal is successful, false otherwise.
     */

    function tryRemove(mapping(address => address) storage self, address addr) internal returns (bool) {
        if (isExist(self, addr)) {
            address cursor = SENTINEL_ADDRESS;
            while (true) {
                address _addr = self[cursor];
                if (_addr == addr) {
                    address next = self[_addr];
                    self[cursor] = next;
                    self[_addr] = address(0);
                    return true;
                }
                cursor = _addr;
            }
        }
        return false;
    }
    /**
     * @notice Clears all addresses from the linked list.
     * @param self The linked list mapping.
     */

    function clear(mapping(address => address) storage self) internal {
        for (address addr = self[SENTINEL_ADDRESS]; uint160(addr) > SENTINEL_UINT; addr = self[addr]) {
            self[addr] = address(0);
        }
        self[SENTINEL_ADDRESS] = address(0);
    }
    /**
     * @notice Checks if an address exists in the linked list.
     * @param self The linked list mapping.
     * @param addr The address to check.
     * @return Returns true if the address exists, false otherwise.
     */

    function isExist(mapping(address => address) storage self, address addr)
        internal
        view
        onlyAddress(addr)
        returns (bool)
    {
        return self[addr] != address(0);
    }
    /**
     * @notice Returns the size of the linked list.
     * @param self The linked list mapping.
     * @return Returns the size of the linked list.
     */

    function size(mapping(address => address) storage self) internal view returns (uint256) {
        uint256 result = 0;
        address addr = self[SENTINEL_ADDRESS];
        while (uint160(addr) > SENTINEL_UINT) {
            addr = self[addr];
            unchecked {
                result++;
            }
        }
        return result;
    }
    /**
     * @notice Checks if the linked list is empty.
     * @param self The linked list mapping.
     * @return Returns true if the linked list is empty, false otherwise.
     */

    function isEmpty(mapping(address => address) storage self) internal view returns (bool) {
        return self[SENTINEL_ADDRESS] == address(0);
    }

    /**
     * @notice Returns a list of addresses from the linked list.
     * @param self The linked list mapping.
     * @param from The starting address.
     * @param limit The number of addresses to return.
     * @return Returns an array of addresses.
     */
    function list(mapping(address => address) storage self, address from, uint256 limit)
        internal
        view
        returns (address[] memory)
    {
        address[] memory result = new address[](limit);
        uint256 i = 0;
        address addr = self[from];
        while (uint160(addr) > SENTINEL_UINT && i < limit) {
            result[i] = addr;
            addr = self[addr];
            unchecked {
                i++;
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Pluggable Interface
 * @dev This interface provides functionalities for initializing and deinitializing wallet-related plugins or modules
 */
interface IPluggable is IERC165 {
    /**
     * @notice Initializes a specific module or plugin for the wallet with the provided data
     * @param data Initialization data required for the module or plugin
     */
    function walletInit(bytes calldata data) external;

    /**
     * @notice Deinitializes a specific module or plugin from the wallet
     */
    function walletDeInit() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title Plugin Storage Interface
 * @dev This interface defines the functionalities to store and load data for plugins
 */
interface IPluginStorage {
    /**
     * @notice Store data for a plugin
     * @param key The key under which the value should be stored
     * @param value The value to be stored
     */
    function pluginDataStore(bytes32 key, bytes calldata value) external;

    /**
     * @notice Load data for a specific plugin using a key
     * @param plugin The address of the plugin for which data should be loaded
     * @param key The key under which the data is stored
     * @return The data stored under the given key for the specified plugin
     */
    function pluginDataLoad(address plugin, bytes32 key) external view returns (bytes memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../libraries/Errors.sol";

library SelectorLinkedList {
    bytes4 internal constant SENTINEL_SELECTOR = 0x00000001;
    uint32 internal constant SENTINEL_UINT = 1;

    function isSafeSelector(bytes4 selector) internal pure returns (bool) {
        return uint32(selector) > SENTINEL_UINT;
    }

    modifier onlySelector(bytes4 selector) {
        if (!isSafeSelector(selector)) {
            revert Errors.INVALID_SELECTOR();
        }
        _;
    }

    function add(mapping(bytes4 => bytes4) storage self, bytes4 selector) internal onlySelector(selector) {
        if (self[selector] != 0) {
            revert Errors.SELECTOR_ALREADY_EXISTS();
        }
        bytes4 _prev = self[SENTINEL_SELECTOR];
        if (_prev == 0) {
            self[SENTINEL_SELECTOR] = selector;
            self[selector] = SENTINEL_SELECTOR;
        } else {
            self[SENTINEL_SELECTOR] = selector;
            self[selector] = _prev;
        }
    }

    function add(mapping(bytes4 => bytes4) storage self, bytes4[] memory selectors) internal {
        for (uint256 i = 0; i < selectors.length;) {
            add(self, selectors[i]);
            unchecked {
                i++;
            }
        }
    }

    function replace(mapping(bytes4 => bytes4) storage self, bytes4 oldSelector, bytes4 newSelector) internal {
        if (!isExist(self, oldSelector)) {
            revert Errors.SELECTOR_NOT_EXISTS();
        }
        if (isExist(self, newSelector)) {
            revert Errors.SELECTOR_ALREADY_EXISTS();
        }

        bytes4 cursor = SENTINEL_SELECTOR;
        while (true) {
            bytes4 _selector = self[cursor];
            if (_selector == oldSelector) {
                bytes4 next = self[_selector];
                self[newSelector] = next;
                self[cursor] = newSelector;
                self[_selector] = 0;
                return;
            }
            cursor = _selector;
        }
    }

    function remove(mapping(bytes4 => bytes4) storage self, bytes4 selector) internal {
        if (!isExist(self, selector)) {
            revert Errors.SELECTOR_NOT_EXISTS();
        }

        bytes4 cursor = SENTINEL_SELECTOR;
        while (true) {
            bytes4 _selector = self[cursor];
            if (_selector == selector) {
                bytes4 next = self[_selector];
                if (next == SENTINEL_SELECTOR && cursor == SENTINEL_SELECTOR) {
                    self[SENTINEL_SELECTOR] = 0;
                } else {
                    self[cursor] = next;
                }
                self[_selector] = 0;
                return;
            }
            cursor = _selector;
        }
    }

    function clear(mapping(bytes4 => bytes4) storage self) internal {
        for (bytes4 selector = self[SENTINEL_SELECTOR]; uint32(selector) > SENTINEL_UINT; selector = self[selector]) {
            self[selector] = 0;
        }
        self[SENTINEL_SELECTOR] = 0;
    }

    function isExist(mapping(bytes4 => bytes4) storage self, bytes4 selector)
        internal
        view
        onlySelector(selector)
        returns (bool)
    {
        return self[selector] != 0;
    }

    function size(mapping(bytes4 => bytes4) storage self) internal view returns (uint256) {
        uint256 result = 0;
        bytes4 selector = self[SENTINEL_SELECTOR];
        while (uint32(selector) > SENTINEL_UINT) {
            selector = self[selector];
            unchecked {
                result++;
            }
        }
        return result;
    }

    function isEmpty(mapping(bytes4 => bytes4) storage self) internal view returns (bool) {
        return self[SENTINEL_SELECTOR] == 0;
    }

    function list(mapping(bytes4 => bytes4) storage self, bytes4 from, uint256 limit)
        internal
        view
        returns (bytes4[] memory)
    {
        bytes4[] memory result = new bytes4[](limit);
        uint256 i = 0;
        bytes4 selector = self[from];
        while (uint32(selector) > SENTINEL_UINT && i < limit) {
            result[i] = selector;
            selector = self[selector];
            unchecked {
                i++;
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../libraries/Errors.sol";

library Bytes32LinkedList {
    bytes32 internal constant SENTINEL_BYTES32 = 0x0000000000000000000000000000000000000000000000000000000000000001;

    modifier onlyBytes32(bytes32 data) {
        if (data <= SENTINEL_BYTES32) {
            revert Errors.INVALID_DATA();
        }
        _;
    }

    function add(mapping(bytes32 => bytes32) storage self, bytes32 data) internal onlyBytes32(data) {
        if (self[data] != bytes32(0)) {
            revert Errors.DATA_ALREADY_EXISTS();
        }
        bytes32 _prev = self[SENTINEL_BYTES32];
        if (_prev == bytes32(0)) {
            self[SENTINEL_BYTES32] = data;
            self[data] = SENTINEL_BYTES32;
        } else {
            self[SENTINEL_BYTES32] = data;
            self[data] = _prev;
        }
    }

    function replace(mapping(bytes32 => bytes32) storage self, bytes32 oldData, bytes32 newData) internal {
        if (!isExist(self, oldData)) {
            revert Errors.DATA_NOT_EXISTS();
        }
        if (isExist(self, newData)) {
            revert Errors.DATA_ALREADY_EXISTS();
        }

        bytes32 cursor = SENTINEL_BYTES32;
        while (true) {
            bytes32 _data = self[cursor];
            if (_data == oldData) {
                bytes32 next = self[_data];
                self[newData] = next;
                self[cursor] = newData;
                self[_data] = bytes32(0);
                return;
            }
            cursor = _data;
        }
    }

    function remove(mapping(bytes32 => bytes32) storage self, bytes32 data) internal {
        if (!tryRemove(self, data)) {
            revert Errors.DATA_NOT_EXISTS();
        }
    }

    function tryRemove(mapping(bytes32 => bytes32) storage self, bytes32 data) internal returns (bool) {
        if (isExist(self, data)) {
            bytes32 cursor = SENTINEL_BYTES32;
            while (true) {
                bytes32 _data = self[cursor];
                if (_data == data) {
                    bytes32 next = self[_data];
                    self[cursor] = next;
                    self[_data] = bytes32(0);
                    return true;
                }
                cursor = _data;
            }
        }
        return false;
    }

    function clear(mapping(bytes32 => bytes32) storage self) internal {
        for (bytes32 data = self[SENTINEL_BYTES32]; data > SENTINEL_BYTES32; data = self[data]) {
            self[data] = bytes32(0);
        }
        self[SENTINEL_BYTES32] = bytes32(0);
    }

    function isExist(mapping(bytes32 => bytes32) storage self, bytes32 data)
        internal
        view
        onlyBytes32(data)
        returns (bool)
    {
        return self[data] != bytes32(0);
    }

    function size(mapping(bytes32 => bytes32) storage self) internal view returns (uint256) {
        uint256 result = 0;
        bytes32 data = self[SENTINEL_BYTES32];
        while (data > SENTINEL_BYTES32) {
            data = self[data];
            unchecked {
                result++;
            }
        }
        return result;
    }

    function isEmpty(mapping(bytes32 => bytes32) storage self) internal view returns (bool) {
        return self[SENTINEL_BYTES32] == bytes32(0);
    }

    function list(mapping(bytes32 => bytes32) storage self, bytes32 from, uint256 limit)
        internal
        view
        returns (bytes32[] memory)
    {
        bytes32[] memory result = new bytes32[](limit);
        uint256 i = 0;
        bytes32 data = self[from];
        while (data > SENTINEL_BYTES32 && i < limit) {
            result[i] = data;
            data = self[data];
            unchecked {
                i++;
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

library Errors {
    error ADDRESS_ALREADY_EXISTS();
    error ADDRESS_NOT_EXISTS();
    error DATA_ALREADY_EXISTS();
    error DATA_NOT_EXISTS();
    error CALLER_MUST_BE_ENTRYPOINT();
    error CALLER_MUST_BE_SELF_OR_MODULE();
    error CALLER_MUST_BE_MODULE();
    error HASH_ALREADY_APPROVED();
    error HASH_ALREADY_REJECTED();
    error INVALID_ADDRESS();
    error INVALID_GUARD_HOOK_DATA();
    error INVALID_SELECTOR();
    error INVALID_SIGNTYPE();
    error MODULE_ADDRESS_EMPTY();
    error MODULE_NOT_SUPPORT_INTERFACE();
    error MODULE_SELECTOR_UNAUTHORIZED();
    error MODULE_SELECTORS_EMPTY();
    error MODULE_EXECUTE_FROM_MODULE_RECURSIVE();
    error NO_OWNER();
    error PLUGIN_ADDRESS_EMPTY();
    error PLUGIN_HOOK_TYPE_ERROR();
    error PLUGIN_INIT_FAILED();
    error PLUGIN_NOT_SUPPORT_INTERFACE();
    error PLUGIN_POST_HOOK_FAILED();
    error PLUGIN_PRE_HOOK_FAILED();
    error PLUGIN_NOT_REGISTERED();
    error SELECTOR_ALREADY_EXISTS();
    error SELECTOR_NOT_EXISTS();
    error UNSUPPORTED_SIGNTYPE();
    error INVALID_LOGIC_ADDRESS();
    error SAME_LOGIC_ADDRESS();
    error UPGRADE_FAILED();
    error NOT_IMPLEMENTED();
    error INVALID_SIGNATURE();
    error ALERADY_INITIALIZED();
    error INVALID_KEY();
    error NOT_INITIALIZED();
    error INVALID_TIME_RANGE();
    error UNAUTHORIZED();
    error INVALID_DATA();
    error GUARDIAN_SIGNATURE_INVALID();
    error UNTRUSTED_KEYSTORE_LOGIC();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.20;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
    }

    /**
     * @dev The signature derives the `address(0)`.
     */
    error ECDSAInvalidSignature();

    /**
     * @dev The signature has an invalid length.
     */
    error ECDSAInvalidSignatureLength(uint256 length);

    /**
     * @dev The signature has an S value that is in the upper half order.
     */
    error ECDSAInvalidSignatureS(bytes32 s);

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with `signature` or an error. This will not
     * return address(0) without also returning an error description. Errors are documented using an enum (error type)
     * and a bytes32 providing additional information about the error.
     *
     * If no error is returned, then the address can be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError, bytes32) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength, bytes32(signature.length));
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, signature);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError, bytes32) {
        unchecked {
            bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            // We do not check for an overflow here since the shift operation results in 0 or 1.
            uint8 v = uint8((uint256(vs) >> 255) + 27);
            return tryRecover(hash, v, r, s);
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, r, vs);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError, bytes32) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS, s);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature, bytes32(0));
        }

        return (signer, RecoverError.NoError, bytes32(0));
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, v, r, s);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Optionally reverts with the corresponding custom error according to the `error` argument provided.
     */
    function _throwError(RecoverError error, bytes32 errorArg) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert ECDSAInvalidSignature();
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert ECDSAInvalidSignatureLength(uint256(errorArg));
        } else if (error == RecoverError.InvalidSignatureS) {
            revert ECDSAInvalidSignatureS(errorArg);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title OwnerAuth
 * @notice Abstract contract to provide Owner-based authentication
 * @dev Requires the inheriting contracts to implement the `_isOwner` method
 */
abstract contract OwnerAuth {
    /**
     * @notice Expected to return whether the provided owner identifier matches the owner context
     * @dev Must be implemented by inheriting contracts
     * @param owner The owner identifier to be checked
     * @return True if the provided owner identifier matches the current owner context, otherwise false
     */
    function _isOwner(bytes32 owner) internal view virtual returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../interfaces/IValidator.sol";
/**
 * @title Validator
 * @dev This abstract contract provides a method to retrieve an IValidator interface
 */

abstract contract Validator {
    /**
     * @dev Gets the IValidator interface
     * @return An instance of the IValidator interface
     */
    function validator() public view virtual returns (IValidator);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;
/**
 * @title TypeConversion
 * @notice A library to facilitate address to bytes32 conversions
 */

library TypeConversion {
    /**
     * @notice Converts an address to bytes32
     * @param addr The address to be converted
     * @return Resulting bytes32 representation of the input address
     */
    function toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
    /**
     * @notice Converts an array of addresses to an array of bytes32
     * @param addresses Array of addresses to be converted
     * @return Array of bytes32 representations of the input addresses
     */

    function addressesToBytes32Array(address[] memory addresses) internal pure returns (bytes32[] memory) {
        bytes32[] memory result = new bytes32[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            result[i] = toBytes32(addresses[i]);
        }
        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../libraries/Errors.sol";

library SignatureDecoder {
    /*
    signature format

    +-----------------------------------------------------------------------------------------------------+
    |                                           |                                                         |
    |                                           |                   validator signature                   |
    |                                           |                                                         |
    +---------------+---------------------------+--------------------------+-----------------------------+
    |     data type | data type dynamic data    |     signature type       |       signature data        |
    +---------------+---------------------------+--------------------------+-----------------------------+
    |               |                           |                          |                             |
    |    1 byte     |      ..........           |        1 byte            |          ......             |
    |               |                           |                          |                             |
    +-----------------------------------------------------------------------------------------------------+


    A: data type 0: no plugin data
    +-----------------------------------------------------------------------------------------------------+
    |                                           |                                                         |
    |                                           |                   validator signature                   |
    |                                           |                                                         |
    +---------------+---------------------------+--------------------------+-----------------------------+
    |     data type | data type dynamic data    |     signature type       |       signature data        |
    +---------------+---------------------------+--------------------------+-----------------------------+
    |               |                           |                          |                             |
    |     0x00      |      empty bytes          |        1 byte            |          ......             |
    |               |                           |                          |                             |
    +-----------------------------------------------------------------------------------------------------+




     B: data type 1: plugin data

    +-----------------------------------------------------------------------------------------------------+
    |                                           |                                                         |
    |                                           |                   validator signature                   |
    |                                           |                                                         |
    +---------------+---------------------------+--------------------------+-----------------------------+
    |     data type | data type dynamic data    |     signature type       |       signature data        |
    +---------------+---------------------------+--------------------------+-----------------------------+
    |               |                           |                          |                             |
    |     0x01      |      .............        |        1 byte            |          ......             |
    |               |                           |                          |                             |
    +-----------------------------------------------------------------------------------------------------+



    +-------------------------+-------------------------------------+
    |                                                               |
    |                  data type dynamic data                       |
    |                                                               |
    +-------------------------+-------------------------------------+
    | dynamic data length     | multi-guardHookInputData            |
    +-------------------------+-------------------------------------+
    | uint256 32 bytes        | dynamic data without length header  |
    +-------------------------+-------------------------------------+


    +--------------------------------------------------------------------------------+
    |                            multi-guardHookInputData                            |
    +--------------------------------------------------------------------------------+
    |   guardHookInputData  |  guardHookInputData   |   ...  |  guardHookInputData   |
    +-----------------------+-----------------------+--------+-----------------------+
    |     dynamic data      |     dynamic data      |   ...  |     dynamic data      |
    +--------------------------------------------------------------------------------+

    +----------------------------------------------------------------------+
    |                                guardHookInputData                    |
    +----------------------------------------------------------------------+
    |   guardHook address  |   input data length   |      input data       |
    +----------------------+-----------------------+-----------------------+
    |        20bytes       |     6bytes(uint48)    |         bytes         |
    +----------------------------------------------------------------------+

    Note: The order of guardHookInputData must be the same as the order in PluginManager.guardHook()!

     */

    function decodeSignature(bytes calldata userOpsignature)
        internal
        pure
        returns (bytes calldata guardHookInputData, bytes calldata validatorSignature)
    {
        /*
            When the calldata slice doesn't match the actual length at the index,
            it will revert, so we don't need additional checks.
         */

        uint8 dataType = uint8(bytes1(userOpsignature[0:1]));

        if (dataType == 0x0) {
            // empty guardHookInputData
            guardHookInputData = userOpsignature[0:0];
            validatorSignature = userOpsignature[1:];
        } else if (dataType == 0x01) {
            uint256 dynamicDataLength = uint256(bytes32(userOpsignature[1:33]));
            uint256 validatorSignatureOffset = 33 + dynamicDataLength;
            guardHookInputData = userOpsignature[33:validatorSignatureOffset];
            validatorSignature = userOpsignature[validatorSignatureOffset:];
        } else {
            revert("Unsupported data type");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/interfaces/IERC1271.sol";

/**
 * @title IERC1271Handler
 * @dev This interface extends the IERC1271 interface by adding functionality to approve and reject hashes
 * The main intention is to manage the approval status of specific signed hashes
 */
interface IERC1271Handler is IERC1271 {
    /**
     * @dev Emitted when a hash has been approved.
     * @param hash The approved hash.
     */
    event ApproveHash(bytes32 indexed hash);
    /**
     * @dev Emitted when a hash has been rejected
     * @param hash The rejected hash
     */
    event RejectHash(bytes32 indexed hash);
    /**
     * @notice Approves the given hash
     * @param hash The hash to approve
     */

    function approveHash(bytes32 hash) external;
    /**
     * @notice Rejects the given hash
     * @param hash The hash to reject
     */
    function rejectHash(bytes32 hash) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title Validator Interface
 * @dev This interface defines the functionalities for signature validation and hash encoding
 */
interface IValidator {
    /**
     * @dev Recover the signer of a given raw hash using the provided raw signature
     * @param rawHash The raw hash that was signed
     * @param rawSignature The signature data
     * @return validationData same as defined in EIP4337
     * @return recovered The recovered signer's signing key from the signature
     * @return success A boolean indicating the success of the recovery
     */
    function recoverSignature(bytes32 rawHash, bytes calldata rawSignature)
        external
        view
        returns (uint256 validationData, bytes32 recovered, bool success);

    /**
     * @dev Recover the signer of a given raw hash using the provided raw signature according to EIP-1271 standards
     * @param rawHash The raw hash that was signed
     * @param rawSignature The signature data
     * @return validationData same as defined in EIP4337
     * @return recovered  The recovered signer's signing key from the signature
     * @return success A boolean indicating the success of the recovery
     */
    function recover1271Signature(bytes32 rawHash, bytes calldata rawSignature)
        external
        view
        returns (uint256 validationData, bytes32 recovered, bool success);

    /**
     * @dev Encode a raw hash to prevent replay attacks
     * @param rawHash The raw hash to encode
     * @return The encoded hash
     */
    function encodeRawHash(bytes32 rawHash) external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./IPluggable.sol";

/**
 * @title Module Interface
 * @dev This interface defines the funcations that a module needed access in the smart contract wallet
 * Modules are key components that can be plugged into the main contract to enhance its functionalities
 * For security reasons, a module can only call functions in the smart contract that it has explicitly
 * listed via the `requiredFunctions` method
 */
interface IModule is IPluggable {
    /**
     * @notice Provides a list of function selectors that the module is allowed to call
     * within the smart contract. When a module is added to the smart contract, it's restricted
     * to only call these functions. This ensures that modules have explicit and limited permissions,
     * enhancing the security of the smart contract (e.g., a "Daily Limit" module shouldn't be able to
     * change the owner)
     *
     * @return An array of function selectors that this module is permitted to call
     */
    function requiredFunctions() external pure returns (bytes4[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../libraries/Errors.sol";

/**
 * @title ModuleAuth
 * @notice Abstract contract to provide Module-based authentication
 * @dev Requires the inheriting contracts to implement the `_isAuthorizedModule` method
 */
abstract contract ModuleAuth {
    /**
     * @notice Expected to return whether the current context is authorized as a module
     * @dev Must be implemented by inheriting contracts
     * @return True if the context is an authorized module, otherwise false
     */
    function _isAuthorizedModule() internal view virtual returns (bool);

    /**
     * @notice Modifier to ensure the caller is an authorized module
     * @dev If not called from an authorized module, it will revert
     */
    modifier onlyModule() {
        if (!_isAuthorizedModule()) {
            revert Errors.CALLER_MUST_BE_MODULE();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC1271.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}