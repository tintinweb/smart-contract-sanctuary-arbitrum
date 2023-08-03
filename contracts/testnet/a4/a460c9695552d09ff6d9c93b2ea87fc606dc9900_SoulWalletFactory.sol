// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "./SoulWalletProxy.sol";
import "./SoulWallet.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @author  soulwallet team.
 * @title   A factory contract to create soul wallet.
 * @dev     it is called by the entrypoint which call the "initCode" factory to create and return the sender wallet address.
 * @notice  .
 */

contract SoulWalletFactory is Ownable {
    uint256 private immutable _WALLETIMPL;
    IEntryPoint public immutable entryPoint;
    string public constant VERSION = "0.0.1";

    event SoulWalletCreation(address proxy);

    constructor(address _walletImpl, address _entryPoint, address _owner) {
        require(_walletImpl != address(0));
        _WALLETIMPL = uint256(uint160(_walletImpl));
        require(_entryPoint != address(0));
        entryPoint = IEntryPoint(_entryPoint);
        transferOwnership(_owner);
    }

    function walletImpl() external view returns (address) {
        return address(uint160(_WALLETIMPL));
    }

    function _calcSalt(bytes memory _initializer, bytes32 _salt) private pure returns (bytes32 salt) {
        salt = keccak256(abi.encodePacked(keccak256(_initializer), _salt));
    }

    /**
     * @notice  deploy the soul wallet contract using proxy and returns the address of the proxy. should be called by entrypoint with useropeartoin.initcode > 0
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
        return proxy;
    }

    /**
     * @notice  returns the proxy creationCode external method.
     * @dev     used by soulwalletlib to calcudate the soul wallet address.
     * @return  bytes  .
     */
    function proxyCode() external pure returns (bytes memory) {
        return _proxyCode();
    }

    /**
     * @notice  returns the proxy creationCode private method.
     * @dev     .
     * @return  bytes  .
     */
    function _proxyCode() private pure returns (bytes memory) {
        return type(SoulWalletProxy).creationCode;
    }

    /**
     * @notice  return the counterfactual address of soul wallet as it would be return by createWallet()
     */
    function getWalletAddress(bytes memory _initializer, bytes32 _salt) external view returns (address proxy) {
        bytes memory deploymentData = abi.encodePacked(type(SoulWalletProxy).creationCode, _WALLETIMPL);
        bytes32 salt = _calcSalt(_initializer, _salt);
        proxy = Create2.computeAddress(salt, keccak256(deploymentData));
    }

    function deposit() public payable {
        entryPoint.depositTo{value: msg.value}(address(this));
    }

    function withdrawTo(address payable withdrawAddress, uint256 amount) public onlyOwner {
        entryPoint.withdrawTo(withdrawAddress, amount);
    }

    function addStake(uint32 unstakeDelaySec) external payable onlyOwner {
        entryPoint.addStake{value: msg.value}(unstakeDelaySec);
    }

    function unlockStake() external onlyOwner {
        entryPoint.unlockStake();
    }

    function withdrawStake(address payable withdrawAddress) external onlyOwner {
        entryPoint.withdrawStake(withdrawAddress);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract SoulWalletProxy {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Initializes the contract setting the implementation
     *
     * @param logic Address of the initial implementation.
     */
    constructor(address logic) {
        assembly ("memory-safe") {
            sstore(_IMPLEMENTATION_SLOT, logic)
        }
    }

    /**
     * @dev Fallback function
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
pragma solidity ^0.8.17;

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

// Draft
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
    ERC1271Handler
{
    constructor(IEntryPoint _EntryPoint) EntryPointManager(_EntryPoint) {
        _disableInitializers();
    }

    function initialize(
        address anOwner,
        address defalutCallbackHandler,
        bytes[] calldata modules,
        bytes[] calldata plugins
    ) external initializer {
        _addOwner(anOwner);
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

    function entryPoint() public view override(BaseAccount) returns (IEntryPoint) {
        return EntryPointManager._entryPoint();
    }

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

    function upgradeTo(address newImplementation) external onlyModule {
        UpgradeManager._upgradeTo(newImplementation);
    }

    function upgradeFrom(address oldImplementation) external pure override {
        (oldImplementation);
        revert Errors.NOT_IMPLEMENTED(); //Initial version no need data migration
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
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
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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
pragma solidity ^0.8.17;

import "./IExecutionManager.sol";
import "./IModuleManager.sol";
import "./IOwnerManager.sol";
import "./IPluginManager.sol";
import "./IFallbackManager.sol";
import "@account-abstraction/contracts/interfaces/IAccount.sol";
import "./IUpgradable.sol";

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
pragma solidity ^0.8.17;

import "../authority/EntryPointAuth.sol";

abstract contract EntryPointManager is EntryPointAuth {
    IEntryPoint private immutable _ENTRY_POINT;

    constructor(IEntryPoint anEntryPoint) {
        _ENTRY_POINT = anEntryPoint;
    }

    function _entryPoint() internal view override returns (IEntryPoint) {
        return _ENTRY_POINT;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../authority/Authority.sol";
import "./PluginManager.sol";
import "../interfaces/IExecutionManager.sol";

abstract contract ExecutionManager is IExecutionManager, Authority, PluginManager {
    /**
     * execute a transaction
     */
    function execute(address dest, uint256 value, bytes calldata func) external override onlyEntryPoint {
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
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
     * execute a sequence of transactions
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
pragma solidity ^0.8.17;

import "../interfaces/IPluginManager.sol";
import "../interfaces/IPlugin.sol";
import "../libraries/AccountStorage.sol";
import "../authority/Authority.sol";
import "../libraries/AddressLinkedList.sol";
import "../interfaces/IPluggable.sol";
import "../interfaces/IPluginStorage.sol";

abstract contract PluginManager is IPluginManager, Authority, IPluginStorage {
    uint8 private constant _GUARD_HOOK = 1 << 0;
    uint8 private constant _PRE_HOOK = 1 << 1;
    uint8 private constant _POST_HOOK = 1 << 2;

    using AddressLinkedList for mapping(address => address);

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

    function isAuthorizedPlugin(address plugin) external view override returns (bool) {
        return AccountStorage.layout().plugins.isExist(plugin);
    }

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

    modifier onlyPlugin() {
        if (AccountStorage.layout().plugins[msg.sender] == address(0)) {
            revert Errors.PLUGIN_NOT_REGISTERED();
        }
        _;
    }

    function pluginDataStore(bytes32 key, bytes calldata value) external override onlyPlugin {
        AccountStorage.layout().pluginDataBytes[msg.sender][key] = value;
    }

    function pluginDataLoad(address plugin, bytes32 key) external view override returns (bytes memory) {
        return AccountStorage.layout().pluginDataBytes[plugin][key];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../libraries/AccountStorage.sol";
import "../authority/Authority.sol";
import "../interfaces/IModuleManager.sol";
import "../interfaces/IPluginManager.sol";
import "../libraries/AddressLinkedList.sol";
import "../libraries/SelectorLinkedList.sol";

abstract contract ModuleManager is IModuleManager, Authority {
    using AddressLinkedList for mapping(address => address);
    using SelectorLinkedList for mapping(bytes4 => bytes4);

    function _modulesMapping() private view returns (mapping(address => address) storage modules) {
        modules = AccountStorage.layout().modules;
    }

    function _moduleSelectorsMapping()
        private
        view
        returns (mapping(address => mapping(bytes4 => bytes4)) storage moduleSelectors)
    {
        moduleSelectors = AccountStorage.layout().moduleSelectors;
    }

    function _isAuthorizedModule() internal view override returns (bool) {
        address module = msg.sender;
        if (!_modulesMapping().isExist(module)) {
            return false;
        }
        mapping(address => mapping(bytes4 => bytes4)) storage moduleSelectors = _moduleSelectorsMapping();
        return moduleSelectors[module].isExist(msg.sig);
    }

    function isAuthorizedModule(address module) external view override returns (bool) {
        return _modulesMapping().isExist(module);
    }

    function addModule(bytes calldata moduleAndData) external override onlyModule {
        _addModule(moduleAndData);
    }

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
pragma solidity ^0.8.17;

import "../libraries/AccountStorage.sol";
import "../authority/Authority.sol";
import "../interfaces/IOwnerManager.sol";
import "../libraries/AddressLinkedList.sol";
import "../libraries/Errors.sol";

abstract contract OwnerManager is IOwnerManager, Authority {
    using AddressLinkedList for mapping(address => address);

    function _ownerMapping() private view returns (mapping(address => address) storage owners) {
        owners = AccountStorage.layout().owners;
    }

    function _isOwner(address addr) internal view override returns (bool) {
        return _ownerMapping().isExist(addr);
    }

    function isOwner(address addr) external view override returns (bool) {
        return _isOwner(addr);
    }

    function _clearOwner() private {
        _ownerMapping().clear();
        emit OwnerCleared();
    }

    function resetOwner(address newOwner) external override onlySelfOrModule {
        _clearOwner();
        _addOwner(newOwner);
    }

    function resetOwners(address[] calldata newOwners) external override onlySelfOrModule {
        _clearOwner();
        _addOwners(newOwners);
    }

    function _addOwners(address[] calldata owners) private {
        for (uint256 i = 0; i < owners.length;) {
            _addOwner(owners[i]);
            unchecked {
                i++;
            }
        }
    }

    function addOwner(address owner) external override onlySelfOrModule {
        _addOwner(owner);
    }

    function addOwners(address[] calldata owners) external override onlySelfOrModule {
        _addOwners(owners);
    }

    function _addOwner(address owner) internal {
        _ownerMapping().add(owner);
        emit OwnerAdded(owner);
    }

    function removeOwner(address owner) external override onlySelfOrModule {
        _ownerMapping().remove(owner);
        if (_ownerMapping().isEmpty()) {
            revert Errors.NO_OWNER();
        }
        emit OwnerRemoved(owner);
    }

    function listOwner() external view override returns (address[] memory owners) {
        uint256 size = _ownerMapping().size();
        owners = _ownerMapping().list(AddressLinkedList.SENTINEL_ADDRESS, size);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../authority/OwnerAuth.sol";
import "../libraries/SignatureDecoder.sol";
import "../libraries/Errors.sol";

abstract contract SignatureValidator is OwnerAuth {
    using ECDSA for bytes32;

    /**
     * @dev pack hash message with `signatureData.validationData`
     */
    function _packSignatureHash(bytes32 hash, uint8 signType, uint256 validationData)
        private
        pure
        returns (bytes32 packedHash)
    {
        if (signType == 0) {
            packedHash = hash;
        } else if (signType == 1) {
            packedHash = keccak256(abi.encodePacked(hash, validationData));
        } else {
            revert Errors.INVALID_SIGNTYPE();
        }
    }

    function _isValidateSignature(bytes32 rawHash, bytes calldata rawSignature)
        internal
        view
        returns (uint256 validationData, bool sigValid)
    {
        uint8 signType;
        bytes calldata signature;
        bytes calldata guardHookInputData;
        (signType, signature, validationData, guardHookInputData) = SignatureDecoder.decodeSignature(rawSignature);

        bytes32 hash = _packSignatureHash(rawHash, signType, validationData).toEthSignedMessageHash();
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error != ECDSA.RecoverError.NoError) {
            sigValid = false;
        } else {
            sigValid = _isOwner(recovered);
        }
    }

    function _isValidUserOp(bytes32 userOpHash, bytes calldata userOpSignature)
        internal
        view
        returns (uint256 validationData, bool sigValid, bytes calldata guardHookInputData)
    {
        uint8 signType;
        bytes calldata signature;
        (signType, signature, validationData, guardHookInputData) = SignatureDecoder.decodeSignature(userOpSignature);
        bytes32 hash = _packSignatureHash(userOpHash, signType, validationData).toEthSignedMessageHash();
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error != ECDSA.RecoverError.NoError) {
            sigValid = false;
        } else {
            sigValid = _isOwner(recovered);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../helper/SignatureValidator.sol";
import "@account-abstraction/contracts/core/Helpers.sol";
import "../interfaces/IERC1271Handler.sol";
import "../authority/Authority.sol";
import "../libraries/AccountStorage.sol";

abstract contract ERC1271Handler is Authority, IERC1271Handler, SignatureValidator {
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 internal constant MAGICVALUE = 0x1626ba7e;
    bytes4 internal constant INVALID_ID = 0xffffffff;
    bytes4 internal constant INVALID_TIME_RANGE = 0xfffffffe;

    function _approvedHashes() private view returns (mapping(bytes32 => uint256) storage) {
        return AccountStorage.layout().approvedHashes;
    }

    function isValidSignature(bytes32 hash, bytes calldata signature)
        external
        view
        override
        returns (bytes4 magicValue)
    {
        if (signature.length > 0) {
            (uint256 _validationData, bool sigValid) = _isValidateSignature(hash, signature);
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
        uint256 status = approvedHashes[hash];
        if (status == 1) {
            // approved
            return MAGICVALUE;
        } else {
            return INVALID_ID;
        }
    }

    function approveHash(bytes32 hash) external override onlySelfOrModule {
        mapping(bytes32 => uint256) storage approvedHashes = _approvedHashes();
        if (approvedHashes[hash] == 1) {
            revert Errors.HASH_ALREADY_APPROVED();
        }
        approvedHashes[hash] = 1;
        emit ApproveHash(hash);
    }

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
pragma solidity ^0.8.17;

import "../interfaces/IFallbackManager.sol";
import "../authority/Authority.sol";
import "../libraries/AccountStorage.sol";

abstract contract FallbackManager is Authority, IFallbackManager {
    receive() external payable {}

    function _setFallbackHandler(address fallbackContract) internal {
        AccountStorage.layout().defaultFallbackContract = fallbackContract;
    }

    fallback() external payable {
        // all requests are forwarded to the fallback contract use STATICCALL
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

    function setFallbackHandler(address fallbackContract) external override onlySelfOrModule {
        _setFallbackHandler(fallbackContract);
        emit FallbackChanged(fallbackContract);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../interfaces/IUpgradable.sol";
import "../libraries/Errors.sol";

abstract contract UpgradeManager is IUpgradable {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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
pragma solidity ^0.8.17;

interface IExecutionManager {
    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(address dest, uint256 value, bytes calldata func) external;

    /**
     * execute a sequence of transactions
     */
    function executeBatch(address[] calldata dest, bytes[] calldata func) external;

    /**
     * execute a sequence of transactions
     */
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "./IModule.sol";

interface IModuleManager {
    event ModuleAdded(address indexed module);
    event ModuleRemoved(address indexed module);
    event ModuleRemovedWithError(address indexed module);

    function addModule(bytes calldata moduleAndData) external;

    function removeModule(address) external;

    function isAuthorizedModule(address module) external returns (bool);

    function listModule() external view returns (address[] memory modules, bytes4[][] memory selectors);

    function executeFromModule(address dest, uint256 value, bytes calldata func) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IOwnerManager {
    event OwnerCleared();
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);

    function isOwner(address addr) external view returns (bool);

    function resetOwner(address newOwner) external;

    function addOwner(address owner) external;

    function addOwners(address[] calldata owners) external;

    function resetOwners(address[] calldata newOwners) external;

    function removeOwner(address owner) external;

    function listOwner() external returns (address[] memory owners);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "./IPlugin.sol";

interface IPluginManager {
    event PluginAdded(address indexed plugin);
    event PluginRemoved(address indexed plugin);
    event PluginRemovedWithError(address indexed plugin);

    function addPlugin(bytes calldata pluginAndData) external;

    function removePlugin(address plugin) external;

    function isAuthorizedPlugin(address plugin) external returns (bool);

    function listPlugin(uint8 hookType) external view returns (address[] memory plugins);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IFallbackManager {
    event FallbackChanged(address indexed fallbackContract);

    function setFallbackHandler(address fallbackContract) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IUpgradable {
    event Upgraded(address indexed oldImplementation, address indexed newImplementation);

    function upgradeTo(address newImplementation) external;
    function upgradeFrom(address oldImplementation) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "../libraries/Errors.sol";

abstract contract EntryPointAuth {
    function _entryPoint() internal view virtual returns (IEntryPoint);

    /*
        Data Flow:

        A: from entryPoint
            # msg.sender:    entryPoint
            # address(this): soulwalletProxy
            ┌────────────┐     ┌────────┐
            │ entryPoint │ ──► │  here  │
            └────────────┘     └────────┘

    */
    modifier onlyEntryPoint() {
        if (msg.sender != address(_entryPoint())) {
            revert Errors.CALLER_MUST_BE_ENTRYPOINT();
        }
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "./EntryPointAuth.sol";
import "./OwnerAuth.sol";
import "../interfaces/IExecutionManager.sol";
import "../interfaces/IModuleManager.sol";
import "../libraries/Errors.sol";
import "./ModuleAuth.sol";

abstract contract Authority is EntryPointAuth, OwnerAuth, ModuleAuth {
    modifier onlySelfOrModule() {
        if (msg.sender != address(this) && !_isAuthorizedModule()) {
            revert Errors.CALLER_MUST_BE_SELF_OR_MODULE();
        }
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@account-abstraction/contracts/interfaces/UserOperation.sol";
import "./IPluggable.sol";

interface IPlugin is IPluggable {
    /**
     * @dev
     * hookType structure:
     * GuardHook: 1<<0
     * PreHook:   1<<1
     * PostHook:  1<<2
     */
    function supportsHook() external pure returns (uint8 hookType);

    /**
     * @dev For flexibility, guardData does not participate in the userOp signature verification.
     *      Plugins must revert when they do not need guardData but guardData.length > 0(for security reasons)
     */
    function guardHook(UserOperation calldata userOp, bytes32 userOpHash, bytes calldata guardData) external;

    function preHook(address target, uint256 value, bytes calldata data) external;

    function postHook(address target, uint256 value, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

library AccountStorage {
    bytes32 private constant _ACCOUNT_SLOT = keccak256("soulwallet.contracts.AccountStorage");

    struct Layout {
        // ┌───────────────────┐
        // │     base data     │
        mapping(address => address) owners;
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
        // └───────────────────┘
    }

    //#TODO

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = _ACCOUNT_SLOT;
        assembly ("memory-safe") {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../libraries/Errors.sol";

library AddressLinkedList {
    address internal constant SENTINEL_ADDRESS = address(1);
    uint160 internal constant SENTINEL_UINT = 1;

    modifier onlyAddress(address addr) {
        if (uint160(addr) <= SENTINEL_UINT) {
            revert Errors.INVALID_ADDRESS();
        }
        _;
    }

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

    function remove(mapping(address => address) storage self, address addr) internal {
        if (!tryRemove(self, addr)) {
            revert Errors.ADDRESS_NOT_EXISTS();
        }
    }

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

    function clear(mapping(address => address) storage self) internal {
        for (address addr = self[SENTINEL_ADDRESS]; uint160(addr) > SENTINEL_UINT; addr = self[addr]) {
            self[addr] = address(0);
        }
        self[SENTINEL_ADDRESS] = address(0);
    }

    function isExist(mapping(address => address) storage self, address addr)
        internal
        view
        onlyAddress(addr)
        returns (bool)
    {
        return self[addr] != address(0);
    }

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

    function isEmpty(mapping(address => address) storage self) internal view returns (bool) {
        return self[SENTINEL_ADDRESS] == address(0);
    }

    /**
     * @dev This function is just an example, please copy this code directly when you need it, you should not call this function
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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IPluggable is IERC165 {
    function walletInit(bytes calldata data) external;
    function walletDeInit() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

interface IPluginStorage {
    function pluginDataStore(bytes32 key, bytes calldata value) external;
    function pluginDataLoad(address plugin, bytes32 key) external view returns (bytes memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

library Errors {
    error ADDRESS_ALREADY_EXISTS();
    error ADDRESS_NOT_EXISTS();
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
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
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
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
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

abstract contract OwnerAuth {
    function _isOwner(address addr) internal view virtual returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../libraries/Errors.sol";

library SignatureDecoder {
    /*
    
    A:
        # `signType` 0x00:
        +----------------------------------------+
        |            raw signature               |
        +----------------------------------------+
        |             length:65                  |
        +----------------------------------------+

    B:
        # `dynamic structure` definition:
        +--------------------------------------------------+
        |      `signType`      |       `dynamic data`      |
        |----------------------+---------------------------|
        |      uint8 1byte     |             ...           |
        +--------------------------------------------------+

        # `signType` 0x01:
        - EOA signature with validationData ( validAfter and validUntil ) and Plugin guardHook input data
        +--------------------------------------------------------------------------------------+  
        |                                   dynamic data                                       |  
        +--------------------------------------------------------------------------------------+  
        |     validationData    |        signature        |    multi-guardHookInputData       |
        +-----------------------+--------------------------------------------------------------+  
        |    uint256 32 bytes   |   65 length signature   | dynamic data without length header |
        +--------------------------------------------------------------------------------------+

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
        Note: The order of guardHookInputData must be the same as the order in PluginManager.guardHook()!


        # `signType` 0x02: (Not implemented yet)
        - EIP-1271 signature without validationData
        +-----------------------------------------------------------------+
        |                        dynamic data                             |
        +-----------------------------------------------------------------+
        |         signer       |  signature (dynamic with length header)  |
        +----------------------+------------------------------------------+
        |    address 20 byte   |       dynamic with length header         |
        +-----------------------------------------------------------------+

     */

    function decodeSignature(bytes calldata userOpsignature)
        internal
        pure
        returns (uint8 signType, bytes calldata signature, uint256 validationData, bytes calldata guardHookInputData)
    {
        if (userOpsignature.length == 65) {
            signature = userOpsignature;
            guardHookInputData = userOpsignature[0:0];
        } else {
            signType = uint8(userOpsignature[0]);
            if (signType == 0x1) {
                validationData = abi.decode(userOpsignature[1:33], (uint256));
                signature = userOpsignature[33:98];
                guardHookInputData = userOpsignature[98:];
            } else {
                revert Errors.UNSUPPORTED_SIGNTYPE();
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC1271.sol";

interface IERC1271Handler is IERC1271 {
    event ApproveHash(bytes32 indexed hash);
    event RejectHash(bytes32 indexed hash);

    function approveHash(bytes32 hash) external;
    function rejectHash(bytes32 hash) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "./IPluggable.sol";

interface IModule is IPluggable {
    function requiredFunctions() external pure returns (bytes4[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "../libraries/Errors.sol";

abstract contract ModuleAuth {
    function _isAuthorizedModule() internal view virtual returns (bool);

    modifier onlyModule() {
        if (!_isAuthorizedModule()) {
            revert Errors.CALLER_MUST_BE_MODULE();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}