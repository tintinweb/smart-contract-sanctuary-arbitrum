pragma solidity ^0.8.0;

import "kernel/sdk/moduleBase/PolicyBase.sol";

enum Status {
    NA,
    Live,
    Deprecated
}

struct GasPolicyConfig {
    uint128 allowed;
    bool enforcePaymaster;
    address allowedPaymaster;
}

contract GasPolicy is PolicyBase {
    mapping(address => uint256) public usedIds;
    mapping(bytes32 id => mapping(address => Status)) public status;
    mapping(bytes32 id => mapping(address => GasPolicyConfig)) public gasPolicyConfig;

    function isInitialized(address wallet) external view override returns (bool) {
        return usedIds[wallet] > 0;
    }

    function checkUserOpPolicy(bytes32 id, PackedUserOperation calldata userOp)
        external
        payable
        override
        returns (uint256)
    {
        require(status[id][msg.sender] == Status.Live);
        (uint256 verificationGasLimit, uint256 callGasLimit) =
            (uint128(bytes16(userOp.accountGasLimits)), uint128(uint256(userOp.accountGasLimits)));
        uint256 maxFeePerGas = uint128(uint256(userOp.gasFees));
        uint128 maxAmount = uint128((userOp.preVerificationGas + verificationGasLimit + callGasLimit) * maxFeePerGas);
        if (gasPolicyConfig[id][msg.sender].enforcePaymaster) {
            if (
                gasPolicyConfig[id][msg.sender].allowedPaymaster != address(0)
                    && address(bytes20(userOp.paymasterAndData[0:20])) != gasPolicyConfig[id][msg.sender].allowedPaymaster
            ) {
                return 1;
            }
        }
        if (maxAmount > gasPolicyConfig[id][msg.sender].allowed) {
            return 1;
        }
        gasPolicyConfig[id][msg.sender].allowed -= maxAmount;
        return 0;
    }

    function checkSignaturePolicy(bytes32 id, address sender, bytes32 hash, bytes calldata sig)
        external
        view
        override
        returns (uint256)
    {
        require(status[id][msg.sender] == Status.Live);
        return 0;
    }

    function _policyOninstall(bytes32 id, bytes calldata _data) internal override {
        require(status[id][msg.sender] == Status.NA);
        (uint128 allowed, bool enforcePaymaster, address allowedPaymaster) = abi.decode(_data, (uint128, bool, address));
        gasPolicyConfig[id][msg.sender] = GasPolicyConfig(allowed, enforcePaymaster, allowedPaymaster);
        status[id][msg.sender] = Status.Live;
        usedIds[msg.sender]++;
    }

    function _policyOnUninstall(bytes32 id, bytes calldata _data) internal override {
        require(status[id][msg.sender] == Status.Live);
        status[id][msg.sender] = Status.Deprecated;
        usedIds[msg.sender]--;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPolicy} from "../../interfaces/IERC7579Modules.sol";
import {PackedUserOperation} from "../../interfaces/PackedUserOperation.sol";

abstract contract PolicyBase is IPolicy {
    function onInstall(bytes calldata data) external payable {
        bytes32 id = bytes32(data[0:32]);
        bytes calldata _data = data[32:];
        _policyOninstall(id, _data);
    }

    function onUninstall(bytes calldata data) external payable {
        bytes32 id = bytes32(data[0:32]);
        bytes calldata _data = data[32:];
        _policyOnUninstall(id, _data);
    }

    function isModuleType(uint256 id) external pure returns (bool) {
        return id == 5;
    }

    function isInitialized(address) external view virtual returns (bool); // TODO : not sure if this is the right way to do it
    function checkUserOpPolicy(bytes32 id, PackedUserOperation calldata userOp)
        external
        payable
        virtual
        returns (uint256);
    function checkSignaturePolicy(bytes32 id, address sender, bytes32 hash, bytes calldata sig)
        external
        view
        virtual
        returns (uint256);

    function _policyOninstall(bytes32 id, bytes calldata _data) internal virtual;
    function _policyOnUninstall(bytes32 id, bytes calldata _data) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {PackedUserOperation} from "./PackedUserOperation.sol";

uint256 constant VALIDATION_SUCCESS = 0;
uint256 constant VALIDATION_FAILED = 1;

uint256 constant MODULE_TYPE_VALIDATOR = 1;
uint256 constant MODULE_TYPE_EXECUTOR = 2;
uint256 constant MODULE_TYPE_FALLBACK = 3;
uint256 constant MODULE_TYPE_HOOK = 4;
uint256 constant MODULE_TYPE_POLICY = 5;
uint256 constant MODULE_TYPE_SIGNER = 6;
uint256 constant MODULE_TYPE_ACTION = 7;

interface IModule {
    error AlreadyInitialized(address smartAccount);
    error NotInitialized(address smartAccount);

    /**
     * @dev This function is called by the smart account during installation of the module
     * @param data arbitrary data that may be required on the module during `onInstall`
     * initialization
     *
     * MUST revert on error (i.e. if module is already enabled)
     */
    function onInstall(bytes calldata data) external payable;

    /**
     * @dev This function is called by the smart account during uninstallation of the module
     * @param data arbitrary data that may be required on the module during `onUninstall`
     * de-initialization
     *
     * MUST revert on error
     */
    function onUninstall(bytes calldata data) external payable;

    /**
     * @dev Returns boolean value if module is a certain type
     * @param moduleTypeId the module type ID according the ERC-7579 spec
     *
     * MUST return true if the module is of the given type and false otherwise
     */
    function isModuleType(uint256 moduleTypeId) external view returns (bool);

    /**
     * @dev Returns if the module was already initialized for a provided smartaccount
     */
    function isInitialized(address smartAccount) external view returns (bool);
}

interface IValidator is IModule {
    error InvalidTargetAddress(address target);

    /**
     * @dev Validates a transaction on behalf of the account.
     *         This function is intended to be called by the MSA during the ERC-4337 validaton phase
     *         Note: solely relying on bytes32 hash and signature is not suffcient for some
     * validation implementations (i.e. SessionKeys often need access to userOp.calldata)
     * @param userOp The user operation to be validated. The userOp MUST NOT contain any metadata.
     * The MSA MUST clean up the userOp before sending it to the validator.
     * @param userOpHash The hash of the user operation to be validated
     * @return return value according to ERC-4337
     */
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash)
        external
        payable
        returns (uint256);

    /**
     * Validator can be used for ERC-1271 validation
     */
    function isValidSignatureWithSender(address sender, bytes32 hash, bytes calldata data)
        external
        view
        returns (bytes4);
}

interface IExecutor is IModule {}

interface IHook is IModule {
    function preCheck(address msgSender, bytes calldata msgData) external payable returns (bytes memory hookData);
    function postCheck(bytes calldata hookData) external payable returns (bool success);
}

interface IFallback is IModule {}

interface IPolicy is IModule {
    function checkUserOpPolicy(bytes32 id, PackedUserOperation calldata userOp) external payable returns (uint256);
    function checkSignaturePolicy(bytes32 id, address sender, bytes32 hash, bytes calldata sig)
        external
        view
        returns (uint256);
}

interface ISigner is IModule {
    function checkUserOpSignature(bytes32 id, PackedUserOperation calldata userOp, bytes32 userOpHash)
        external
        payable
        returns (uint256);
    function checkSignature(bytes32 id, address sender, bytes32 hash, bytes calldata sig)
        external
        view
        returns (bytes4);
}

interface IAction is IModule {}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

/**
 * User Operation struct
 * @param sender                - The sender account of this request.
 * @param nonce                 - Unique value the sender uses to verify it is not a replay.
 * @param initCode              - If set, the account contract will be created by this constructor/
 * @param callData              - The method call to execute on this account.
 * @param accountGasLimits      - Packed gas limits for validateUserOp and gas limit passed to the callData method call.
 * @param preVerificationGas    - Gas not calculated by the handleOps method, but added to the gas paid.
 *                                Covers batch overhead.
 * @param gasFees                - packed gas fields maxFeePerGas and maxPriorityFeePerGas - Same as EIP-1559 gas parameter.
 * @param paymasterAndData      - If set, this field holds the paymaster address, verification gas limit, postOp gas limit and paymaster-specific extra data
 *                                The paymaster will pay for the transaction instead of the sender.
 * @param signature             - Sender-verified signature over the entire request, the EntryPoint address and the chain ID.
 */
struct PackedUserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    bytes32 accountGasLimits;
    uint256 preVerificationGas;
    bytes32 gasFees; //maxPriorityFee and maxFeePerGas;
    bytes paymasterAndData;
    bytes signature;
}