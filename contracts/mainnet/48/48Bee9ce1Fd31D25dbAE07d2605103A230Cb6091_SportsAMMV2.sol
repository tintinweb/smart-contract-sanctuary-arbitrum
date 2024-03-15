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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/Clones.sol)

pragma solidity ^0.8.20;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 */
library Clones {
    /**
     * @dev A clone instance deployment failed.
     */
    error ERC1167FailedCreateClone();

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        if (instance == address(0)) {
            revert ERC1167FailedCreateClone();
        }
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        if (instance == address(0)) {
            revert ERC1167FailedCreateClone();
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.20;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the Merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates Merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     *@dev The multiproof provided is not valid.
     */
    error MerkleProofInvalidMultiproof();

    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all Merkle trees admit multiproofs. See {processMultiProof} for details.
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all Merkle trees admit multiproofs. See {processMultiProof} for details.
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all Merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the Merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        if (leavesLen + proofLen != totalHashes + 1) {
            revert MerkleProofInvalidMultiproof();
        }

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            if (proofPos != proofLen) {
                revert MerkleProofInvalidMultiproof();
            }
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all Merkle trees admit multiproofs. See {processMultiProof} for details.
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the Merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        if (leavesLen + proofLen != totalHashes + 1) {
            revert MerkleProofInvalidMultiproof();
        }

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            if (proofPos != proofLen) {
                revert MerkleProofInvalidMultiproof();
            }
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Sorts the pair (a, b) and hashes the result.
     */
    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    /**
     * @dev Implementation of keccak256(abi.encode(a, b)) that doesn't allocate or expand memory.
     */
    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IMultiCollateralOnOffRamp {
    function onramp(address collateral, uint collateralAmount) external returns (uint);

    function onrampWithEth(uint amount) external payable returns (uint);

    function getMinimumReceived(address collateral, uint amount) external view returns (uint);

    function getMinimumNeeded(address collateral, uint amount) external view returns (uint);

    function WETH9() external view returns (address);

    function offrampIntoEth(uint amount) external returns (uint);

    function offramp(address collateral, uint amount) external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

interface IReferrals {
    function referrals(address) external view returns (address);

    function getReferrerFee(address) external view returns (uint);

    function sportReferrals(address) external view returns (address);

    function setReferrer(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IStakingThales {
    function updateVolume(address account, uint amount) external;

    /* ========== VIEWS / VARIABLES ==========  */
    function totalStakedAmount() external view returns (uint);

    function stakedBalanceOf(address account) external view returns (uint);

    function currentPeriodRewards() external view returns (uint);

    function currentPeriodFees() external view returns (uint);

    function getLastPeriodOfClaimedRewards(address account) external view returns (uint);

    function getRewardsAvailable(address account) external view returns (uint);

    function getRewardFeesAvailable(address account) external view returns (uint);

    function getAlreadyClaimedRewards(address account) external view returns (uint);

    function getContractRewardFunds() external view returns (uint);

    function getContractFeeFunds() external view returns (uint);

    function getAMMVolume(address account) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ISportsAMMV2ResultManager.sol";

interface ISportsAMMV2 {
    struct CombinedPosition {
        uint16 typeId;
        uint8 position;
        int24 line;
    }

    struct TradeData {
        bytes32 gameId;
        uint16 sportId;
        uint16 typeId;
        uint maturity;
        uint8 status;
        int24 line;
        uint16 playerId;
        uint[] odds;
        bytes32[] merkleProof;
        uint8 position;
        CombinedPosition[][] combinedPositions;
    }

    function defaultCollateral() external view returns (IERC20);

    function resultManager() external view returns (ISportsAMMV2ResultManager);

    function minBuyInAmount() external view returns (uint);

    function maxTicketSize() external view returns (uint);

    function maxSupportedAmount() external view returns (uint);

    function maxSupportedOdds() external view returns (uint);

    function safeBoxFee() external view returns (uint);

    function resolveTicket(
        address _ticketOwner,
        bool _hasUserWon,
        bool _cancelled,
        uint _buyInAmount,
        address _ticketCreator
    ) external;

    function exerciseTicket(address _ticket) external;

    function getTicketsPerGame(uint _index, uint _pageSize, bytes32 _gameId) external view returns (address[] memory);

    function numOfTicketsPerGame(bytes32 _gameId) external view returns (uint);

    function getActiveTicketsPerUser(uint _index, uint _pageSize, address _user) external view returns (address[] memory);

    function numOfActiveTicketsPerUser(address _user) external view returns (uint);

    function getResolvedTicketsPerUser(uint _index, uint _pageSize, address _user) external view returns (address[] memory);

    function numOfResolvedTicketsPerUser(address _user) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISportsAMMV2LiquidityPool {
    function commitTrade(address ticket, uint amount) external;

    function transferToPool(address ticket, uint amount) external;

    function getTicketPool(address _ticket) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISportsAMMV2Manager {
    function isWhitelistedAddress(address _address) external view returns (bool);

    function transformCollateral(uint value, address collateral) external view returns (uint);

    function reverseTransformCollateral(uint value, address collateral) external view returns (uint);

    function decimals() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISportsAMMV2.sol";

interface ISportsAMMV2ResultManager {
    enum MarketPositionStatus {
        Open,
        Cancelled,
        Winning,
        Losing
    }

    function isMarketResolved(
        bytes32 _gameId,
        uint16 _typeId,
        uint16 _playerId,
        int24 _line,
        ISportsAMMV2.CombinedPosition[] memory combinedPositions
    ) external view returns (bool isResolved);

    function getMarketPositionStatus(
        bytes32 _gameId,
        uint16 _typeId,
        uint16 _playerId,
        int24 _line,
        uint _position,
        ISportsAMMV2.CombinedPosition[] memory _combinedPositions
    ) external view returns (MarketPositionStatus status);

    function isWinningMarketPosition(
        bytes32 _gameId,
        uint16 _typeId,
        uint16 _playerId,
        int24 _line,
        uint _position,
        ISportsAMMV2.CombinedPosition[] memory _combinedPositions
    ) external view returns (bool isWinning);

    function isCancelledMarketPosition(
        bytes32 _gameId,
        uint16 _typeId,
        uint16 _playerId,
        int24 _line,
        uint _position,
        ISportsAMMV2.CombinedPosition[] memory _combinedPositions
    ) external view returns (bool isCancelled);

    function getResultsPerMarket(
        bytes32 _gameId,
        uint16 _typeId,
        uint16 _playerId
    ) external view returns (int24[] memory results);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISportsAMMV2RiskManager {
    function calculateCapToBeUsed(
        bytes32 _gameId,
        uint16 _sportId,
        uint16 _typeId,
        uint16 _playerId,
        int24 _line,
        uint _maturity
    ) external view returns (uint cap);

    function isTotalSpendingLessThanTotalRisk(
        uint _totalSpent,
        bytes32 _gameId,
        uint16 _sportId,
        uint16 _typeId,
        uint16 _playerId,
        int24 _line,
        uint _maturity
    ) external view returns (bool _isNotRisky);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

// internal
import "../utils/proxy/ProxyReentrancyGuard.sol";
import "../utils/proxy/ProxyOwned.sol";
import "../utils/proxy/ProxyPausable.sol";
import "../utils/libraries/AddressSetLib.sol";

import "@thales-dao/contracts/contracts/interfaces/IReferrals.sol";
import "@thales-dao/contracts/contracts/interfaces/IMultiCollateralOnOffRamp.sol";
import "@thales-dao/contracts/contracts/interfaces/IStakingThales.sol";

import "./Ticket.sol";
import "../interfaces/ISportsAMMV2.sol";
import "../interfaces/ISportsAMMV2Manager.sol";
import "../interfaces/ISportsAMMV2RiskManager.sol";
import "../interfaces/ISportsAMMV2ResultManager.sol";
import "../interfaces/ISportsAMMV2LiquidityPool.sol";

/// @title Sports AMM V2 contract
/// @author vladan
contract SportsAMMV2 is Initializable, ProxyOwned, ProxyPausable, ProxyReentrancyGuard {
    /* ========== LIBRARIES ========== */

    using SafeERC20 for IERC20;
    using AddressSetLib for AddressSetLib.AddressSet;

    /* ========== CONST VARIABLES ========== */

    uint private constant ONE = 1e18;
    uint private constant MAX_APPROVAL = type(uint256).max;

    /* ========== STATE VARIABLES ========== */

    // merkle tree root per game
    mapping(bytes32 => bytes32) public rootPerGame;

    // the default token used for payment
    IERC20 public defaultCollateral;

    // manager address
    ISportsAMMV2Manager public manager;

    // risk manager address
    ISportsAMMV2RiskManager public riskManager;

    // risk manager address
    ISportsAMMV2ResultManager public resultManager;

    // referrals address
    IReferrals public referrals;

    // ticket mastercopy address
    address public ticketMastercopy;

    // safe box address
    address public safeBox;

    // safe box fee paid on each trade
    uint public safeBoxFee;

    // safe box fee per specific address paid on each trade
    mapping(address => uint) public safeBoxFeePerAddress;

    // minimum ticket buy-in amount
    uint public minBuyInAmount;

    // maximum ticket size
    uint public maxTicketSize;

    // maximum supported payout amount
    uint public maxSupportedAmount;

    // maximum supported ticket odds
    uint public maxSupportedOdds;

    // stores active tickets
    AddressSetLib.AddressSet internal knownTickets;

    // multi-collateral on/off ramp address
    IMultiCollateralOnOffRamp public multiCollateralOnOffRamp;

    // is multi-collateral enabled
    bool public multicollateralEnabled;

    // stores current risk per market and position, market defined with gameId -> sportId -> typeId -> playerId -> line
    mapping(bytes32 => mapping(uint => mapping(uint => mapping(uint => mapping(int => mapping(uint => uint))))))
        public riskPerMarketAndPosition;

    // the period of time in seconds before a market is matured and begins to be restricted for AMM trading
    uint public minimalTimeLeftToMaturity;

    // the period of time in seconds after mauturity when ticket expires
    uint public expiryDuration;

    // liquidity pool address
    ISportsAMMV2LiquidityPool public liquidityPool;

    // staking thales address
    IStakingThales public stakingThales;

    // spent on parent market together with all children markets
    mapping(bytes32 => uint) public spentPerParent;

    // stores active tickets per user
    mapping(address => AddressSetLib.AddressSet) internal activeTicketsPerUser;

    // stores resolved tickets per user
    mapping(address => AddressSetLib.AddressSet) internal resolvedTicketsPerUser;

    // stores tickets per game
    mapping(bytes32 => AddressSetLib.AddressSet) internal ticketsPerGame;

    /* ========== CONSTRUCTOR ========== */

    /// @notice initialize the storage in the proxy contract with the parameters
    /// @param _owner owner for using the onlyOwner functions
    /// @param _defaultCollateral the address of default token used for payment
    /// @param _manager the address of manager
    /// @param _riskManager the address of risk manager
    /// @param _referrals the address of referrals
    /// @param _stakingThales the address of staking thales
    /// @param _safeBox the address of safe box
    function initialize(
        address _owner,
        IERC20 _defaultCollateral,
        ISportsAMMV2Manager _manager,
        ISportsAMMV2RiskManager _riskManager,
        ISportsAMMV2ResultManager _resultManager,
        IReferrals _referrals,
        IStakingThales _stakingThales,
        address _safeBox
    ) public initializer {
        setOwner(_owner);
        initNonReentrant();
        defaultCollateral = _defaultCollateral;
        manager = _manager;
        riskManager = _riskManager;
        resultManager = _resultManager;
        referrals = _referrals;
        stakingThales = _stakingThales;
        safeBox = _safeBox;
    }

    /* ========== EXTERNAL READ FUNCTIONS ========== */

    /// @notice gets trade quote
    /// @param _tradeData trade data with all market info needed for ticket
    /// @param _buyInAmount ticket buy-in amount
    /// @param _collateral different collateral used for payment
    /// @return collateralQuote buy-in amount in different collateral
    /// @return buyInAmountAfterFees ticket buy-in amount without fees
    /// @return payout expected payout
    /// @return totalQuote total ticket quote
    /// @return finalQuotes final quotes per market
    /// @return amountsToBuy amounts per market
    function tradeQuote(
        ISportsAMMV2.TradeData[] calldata _tradeData,
        uint _buyInAmount,
        address _collateral
    )
        external
        view
        returns (
            uint collateralQuote,
            uint buyInAmountAfterFees,
            uint payout,
            uint totalQuote,
            uint[] memory finalQuotes,
            uint[] memory amountsToBuy
        )
    {
        (buyInAmountAfterFees, payout, totalQuote, finalQuotes, amountsToBuy, ) = _tradeQuote(_tradeData, _buyInAmount);

        collateralQuote = _collateral == address(0)
            ? _buyInAmount
            : multiCollateralOnOffRamp.getMinimumNeeded(_collateral, _buyInAmount);
    }

    /// @notice is provided ticket active
    /// @param _ticket ticket address
    /// @return isActiveTicket true/false
    function isActiveTicket(address _ticket) external view returns (bool) {
        return knownTickets.contains(_ticket);
    }

    /// @notice gets batch of active tickets
    /// @param _index start index
    /// @param _pageSize batch size
    /// @return activeTickets
    function getActiveTickets(uint _index, uint _pageSize) external view returns (address[] memory) {
        return knownTickets.getPage(_index, _pageSize);
    }

    /// @notice gets number of active tickets
    /// @return numOfActiveTickets
    function numOfActiveTickets() external view returns (uint) {
        return knownTickets.elements.length;
    }

    /// @notice gets batch of active tickets per user
    /// @param _index start index
    /// @param _pageSize batch size
    /// @param _user to get active tickets for
    /// @return activeTickets
    function getActiveTicketsPerUser(uint _index, uint _pageSize, address _user) external view returns (address[] memory) {
        return activeTicketsPerUser[_user].getPage(_index, _pageSize);
    }

    /// @notice gets number of active tickets per user
    /// @param _user to get number of active tickets for
    /// @return numOfActiveTickets
    function numOfActiveTicketsPerUser(address _user) external view returns (uint) {
        return activeTicketsPerUser[_user].elements.length;
    }

    /// @notice gets batch of resolved tickets per user
    /// @param _index start index
    /// @param _pageSize batch size
    /// @param _user to get resolved tickets for
    /// @return resolvedTickets
    function getResolvedTicketsPerUser(uint _index, uint _pageSize, address _user) external view returns (address[] memory) {
        return resolvedTicketsPerUser[_user].getPage(_index, _pageSize);
    }

    /// @notice gets number of resolved tickets per user
    /// @param _user to get number of resolved tickets for
    /// @return numOfResolvedTickets
    function numOfResolvedTicketsPerUser(address _user) external view returns (uint) {
        return resolvedTicketsPerUser[_user].elements.length;
    }

    /// @notice gets batch of tickets per game
    /// @param _index start index
    /// @param _pageSize batch size
    /// @param _gameId to get tickets for
    /// @return resolvedTickets
    function getTicketsPerGame(uint _index, uint _pageSize, bytes32 _gameId) external view returns (address[] memory) {
        return ticketsPerGame[_gameId].getPage(_index, _pageSize);
    }

    /// @notice gets number of tickets per game
    /// @param _gameId to get number of tickets for
    /// @return numOfTickets
    function numOfTicketsPerGame(bytes32 _gameId) external view returns (uint) {
        return ticketsPerGame[_gameId].elements.length;
    }

    /* ========== EXTERNAL WRITE FUNCTIONS ========== */

    /// @notice make a trade and create a ticket
    /// @param _tradeData trade data with all market info needed for ticket
    /// @param _buyInAmount ticket buy-in amount
    /// @param _expectedPayout expected payout got from quote method
    /// @param _additionalSlippage slippage tolerance
    /// @param _differentRecipient different recipent of the ticket
    /// @param _referrer referrer to get referral fee
    /// @param _collateral different collateral used for payment
    /// @param _isEth pay with ETH
    function trade(
        ISportsAMMV2.TradeData[] calldata _tradeData,
        uint _buyInAmount,
        uint _expectedPayout,
        uint _additionalSlippage,
        address _differentRecipient,
        address _referrer,
        address _collateral,
        bool _isEth
    ) external payable nonReentrant notPaused {
        if (_referrer != address(0)) {
            referrals.setReferrer(_referrer, msg.sender);
        }

        if (_differentRecipient == address(0)) {
            _differentRecipient = msg.sender;
        }

        if (_collateral != address(0)) {
            _handleDifferentCollateral(_buyInAmount, _collateral, _isEth);
        }

        _trade(
            _tradeData,
            _buyInAmount,
            _expectedPayout,
            _additionalSlippage,
            _differentRecipient,
            _collateral == address(0)
        );
    }

    /// @notice exercise specific ticket
    /// @param _ticket ticket address
    function exerciseTicket(address _ticket) external nonReentrant notPaused onlyKnownTickets(_ticket) {
        _exerciseTicket(_ticket);
    }

    /// @notice additional logic for ticket resolve (called only from ticket contact)
    /// @param _ticketOwner ticket owner
    /// @param _hasUserWon is winning ticket
    /// @param _cancelled is ticket cancelled (needed for referral and safe box fee)
    /// @param _buyInAmount ticket buy-in amount (needed for referral and safe box fee)
    /// @param _ticketCreator ticket creator (needed for referral and safe box fee)
    function resolveTicket(
        address _ticketOwner,
        bool _hasUserWon,
        bool _cancelled,
        uint _buyInAmount,
        address _ticketCreator
    ) external notPaused onlyKnownTickets(msg.sender) {
        if (!_cancelled) {
            _handleReferrerAndSB(_buyInAmount, _ticketCreator);
        }
        knownTickets.remove(msg.sender);
        if (activeTicketsPerUser[_ticketOwner].contains(msg.sender)) {
            activeTicketsPerUser[_ticketOwner].remove(msg.sender);
        }
        resolvedTicketsPerUser[_ticketOwner].add(msg.sender);
        emit TicketResolved(msg.sender, _ticketOwner, _hasUserWon);
    }

    /// @notice pause/unapause provided tickets
    /// @param _tickets array of tickets to be paused/unpaused
    /// @param _paused pause/unpause
    function setPausedTickets(address[] calldata _tickets, bool _paused) external onlyOwner {
        for (uint i = 0; i < _tickets.length; i++) {
            Ticket(_tickets[i]).setPaused(_paused);
        }
    }

    /// @notice expire provided tickets
    /// @param _tickets array of tickets to be expired
    function expireTickets(address[] calldata _tickets) external onlyOwner {
        for (uint i = 0; i < _tickets.length; i++) {
            if (Ticket(_tickets[i]).phase() == Ticket.Phase.Expiry) {
                Ticket(_tickets[i]).expire(payable(safeBox));
            }
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _tradeQuote(
        ISportsAMMV2.TradeData[] memory _tradeData,
        uint _buyInAmount
    )
        internal
        view
        returns (
            uint buyInAmountAfterFees,
            uint payout,
            uint totalQuote,
            uint[] memory finalQuotes,
            uint[] memory amountsToBuy,
            uint payoutWithFees
        )
    {
        uint numOfMarkets = _tradeData.length;
        finalQuotes = new uint[](numOfMarkets);
        amountsToBuy = new uint[](numOfMarkets);
        buyInAmountAfterFees = ((ONE - safeBoxFee) * _buyInAmount) / ONE;

        for (uint i = 0; i < numOfMarkets; i++) {
            ISportsAMMV2.TradeData memory tradeDataItem = _tradeData[i];

            _verifyMerkleTree(tradeDataItem);

            if (tradeDataItem.odds.length > tradeDataItem.position) {
                finalQuotes[i] = tradeDataItem.odds[tradeDataItem.position];
            }
            if (finalQuotes[i] == 0) {
                totalQuote = 0;
                break;
            }
            amountsToBuy[i] = (ONE * buyInAmountAfterFees) / finalQuotes[i];
            totalQuote = totalQuote == 0 ? finalQuotes[i] : (totalQuote * finalQuotes[i]) / ONE;
        }
        if (totalQuote != 0) {
            if (totalQuote < maxSupportedOdds) {
                totalQuote = maxSupportedOdds;
            }
            payout = (buyInAmountAfterFees * ONE) / totalQuote;
            payoutWithFees = payout + _buyInAmount - buyInAmountAfterFees;
        }

        // check if any market breaches cap
        for (uint i = 0; i < _tradeData.length; i++) {
            ISportsAMMV2.TradeData memory tradeDataItem = _tradeData[i];
            uint riskPerMarket = amountsToBuy[i] - buyInAmountAfterFees;
            if (
                riskPerMarketAndPosition[tradeDataItem.gameId][tradeDataItem.sportId][tradeDataItem.typeId][
                    tradeDataItem.playerId
                ][tradeDataItem.line][tradeDataItem.position] +
                    riskPerMarket >
                riskManager.calculateCapToBeUsed(
                    tradeDataItem.gameId,
                    tradeDataItem.sportId,
                    tradeDataItem.typeId,
                    tradeDataItem.playerId,
                    tradeDataItem.line,
                    tradeDataItem.maturity
                ) ||
                !riskManager.isTotalSpendingLessThanTotalRisk(
                    spentPerParent[tradeDataItem.gameId] + riskPerMarket,
                    tradeDataItem.gameId,
                    tradeDataItem.sportId,
                    tradeDataItem.typeId,
                    tradeDataItem.playerId,
                    tradeDataItem.line,
                    tradeDataItem.maturity
                )
            ) {
                finalQuotes[i] = 0;
                totalQuote = 0;
            }
        }
    }

    function _handleDifferentCollateral(
        uint _buyInAmount,
        address _collateral,
        bool _isEth
    ) internal nonReentrant notPaused {
        require(multicollateralEnabled, "Multi collateral not enabled");
        uint collateralQuote = multiCollateralOnOffRamp.getMinimumNeeded(_collateral, _buyInAmount);

        uint exactReceived;

        if (_isEth) {
            require(_collateral == multiCollateralOnOffRamp.WETH9(), "Wrong collateral sent");
            require(msg.value >= collateralQuote, "Not enough ETH sent");
            exactReceived = multiCollateralOnOffRamp.onrampWithEth{value: msg.value}(msg.value);
        } else {
            IERC20(_collateral).safeTransferFrom(msg.sender, address(this), collateralQuote);
            IERC20(_collateral).approve(address(multiCollateralOnOffRamp), collateralQuote);
            exactReceived = multiCollateralOnOffRamp.onramp(_collateral, collateralQuote);
        }

        require(exactReceived >= _buyInAmount, "Not enough default payment token received");

        //send the surplus to SB
        if (exactReceived > _buyInAmount) {
            defaultCollateral.safeTransfer(safeBox, exactReceived - _buyInAmount);
        }
    }

    function _trade(
        ISportsAMMV2.TradeData[] memory _tradeData,
        uint _buyInAmount,
        uint _expectedPayout,
        uint _additionalSlippage,
        address _differentRecipient,
        bool _sendDefaultCollateral
    ) internal {
        uint payout;
        uint totalQuote;
        uint payoutWithFees;
        uint[] memory amountsToBuy = new uint[](_tradeData.length);
        uint buyInAmountAfterFees;
        (buyInAmountAfterFees, payout, totalQuote, , amountsToBuy, payoutWithFees) = _tradeQuote(_tradeData, _buyInAmount);

        _checkLimits(_buyInAmount, totalQuote, payout, _expectedPayout, _additionalSlippage);
        _checkRisk(_tradeData, amountsToBuy, buyInAmountAfterFees);

        if (_sendDefaultCollateral) {
            defaultCollateral.safeTransferFrom(msg.sender, address(this), _buyInAmount);
        }

        // clone a ticket
        Ticket.MarketData[] memory markets = _getTicketMarkets(_tradeData);
        Ticket ticket = Ticket(Clones.clone(ticketMastercopy));

        ticket.initialize(
            markets,
            _buyInAmount,
            buyInAmountAfterFees,
            totalQuote,
            address(this),
            _differentRecipient,
            msg.sender,
            (block.timestamp + expiryDuration)
        );
        _saveTicketData(_tradeData, address(ticket), _differentRecipient);

        if (address(stakingThales) != address(0)) {
            stakingThales.updateVolume(_differentRecipient, _buyInAmount);
        }

        liquidityPool.commitTrade(address(ticket), payout - buyInAmountAfterFees);
        defaultCollateral.safeTransfer(address(ticket), payoutWithFees);

        emit NewTicket(markets, address(ticket), buyInAmountAfterFees, payout);
        emit TicketCreated(address(ticket), _differentRecipient, _buyInAmount, buyInAmountAfterFees, payout, totalQuote);
    }

    function _saveTicketData(ISportsAMMV2.TradeData[] memory _tradeData, address ticket, address user) internal {
        knownTickets.add(ticket);
        activeTicketsPerUser[user].add(ticket);

        for (uint i = 0; i < _tradeData.length; i++) {
            ticketsPerGame[_tradeData[i].gameId].add(ticket);
        }
    }

    function _getTicketMarkets(
        ISportsAMMV2.TradeData[] memory _tradeData
    ) internal pure returns (Ticket.MarketData[] memory markets) {
        markets = new Ticket.MarketData[](_tradeData.length);

        for (uint i = 0; i < _tradeData.length; i++) {
            ISportsAMMV2.TradeData memory tradeDataItem = _tradeData[i];

            markets[i] = Ticket.MarketData(
                tradeDataItem.gameId,
                tradeDataItem.sportId,
                tradeDataItem.typeId,
                tradeDataItem.maturity,
                tradeDataItem.status,
                tradeDataItem.line,
                tradeDataItem.playerId,
                tradeDataItem.position,
                tradeDataItem.odds[tradeDataItem.position],
                tradeDataItem.combinedPositions[tradeDataItem.position]
            );
        }
    }

    function _checkLimits(
        uint _buyInAmount,
        uint _totalQuote,
        uint _payout,
        uint _expectedPayout,
        uint _additionalSlippage
    ) internal view {
        // apply all checks
        require(_buyInAmount >= minBuyInAmount, "Low buy-in amount");
        require(_totalQuote >= maxSupportedOdds, "Exceeded max supported odds");
        require((_payout - _buyInAmount) <= maxSupportedAmount, "Exceeded max supported amount");
        require(((ONE * _expectedPayout) / _payout) <= (ONE + _additionalSlippage), "Slippage too high");
    }

    function _checkRisk(
        ISportsAMMV2.TradeData[] memory _tradeData,
        uint[] memory _amountsToBuy,
        uint _buyInAmountAfterFees
    ) internal {
        for (uint i = 0; i < _tradeData.length; i++) {
            require(_isMarketInAMMTrading(_tradeData[i]), "Not trading");
            require(_tradeData[i].odds.length > _tradeData[i].position, "Invalid position");

            uint riskPerMarket = _amountsToBuy[i] - _buyInAmountAfterFees;

            riskPerMarketAndPosition[_tradeData[i].gameId][_tradeData[i].sportId][_tradeData[i].typeId][
                _tradeData[i].playerId
            ][_tradeData[i].line][_tradeData[i].position] += riskPerMarket;
            spentPerParent[_tradeData[i].gameId] += riskPerMarket;

            require(
                riskPerMarketAndPosition[_tradeData[i].gameId][_tradeData[i].sportId][_tradeData[i].typeId][
                    _tradeData[i].playerId
                ][_tradeData[i].line][_tradeData[i].position] <
                    riskManager.calculateCapToBeUsed(
                        _tradeData[i].gameId,
                        _tradeData[i].sportId,
                        _tradeData[i].typeId,
                        _tradeData[i].playerId,
                        _tradeData[i].line,
                        _tradeData[i].maturity
                    ),
                "Risk per individual market and position exceeded"
            );
            require(
                riskManager.isTotalSpendingLessThanTotalRisk(
                    spentPerParent[_tradeData[i].gameId],
                    _tradeData[i].gameId,
                    _tradeData[i].sportId,
                    _tradeData[i].typeId,
                    _tradeData[i].playerId,
                    _tradeData[i].line,
                    _tradeData[i].maturity
                ),
                "Risk is to high"
            );
        }
    }

    function _isMarketInAMMTrading(ISportsAMMV2.TradeData memory tradeData) internal view returns (bool isTrading) {
        bool isResolved = resultManager.isMarketResolved(
            tradeData.gameId,
            tradeData.typeId,
            tradeData.playerId,
            tradeData.line,
            tradeData.combinedPositions[tradeData.position]
        );
        if (tradeData.status == 0 && !isResolved) {
            if (tradeData.maturity >= block.timestamp) {
                isTrading = (tradeData.maturity - block.timestamp) > minimalTimeLeftToMaturity;
            }
        }
    }

    function _handleReferrerAndSB(uint _buyInAmount, address _tickerCreator) internal returns (uint safeBoxAmount) {
        uint referrerShare;
        address referrer = referrals.sportReferrals(_tickerCreator);
        if (referrer != address(0)) {
            uint referrerFeeByTier = referrals.getReferrerFee(referrer);
            if (referrerFeeByTier > 0) {
                referrerShare = (_buyInAmount * referrerFeeByTier) / ONE;
                defaultCollateral.safeTransfer(referrer, referrerShare);
                emit ReferrerPaid(referrer, _tickerCreator, referrerShare, _buyInAmount);
            }
        }
        safeBoxAmount = _getSafeBoxAmount(_buyInAmount, _tickerCreator);
        defaultCollateral.safeTransfer(safeBox, safeBoxAmount - referrerShare);
        emit SafeBoxFeePaid(safeBoxFee, safeBoxAmount);
    }

    function _getSafeBoxAmount(uint _buyInAmount, address _toCheck) internal view returns (uint safeBoxAmount) {
        uint sbFee = _getSafeBoxFeePerAddress(_toCheck);
        safeBoxAmount = (_buyInAmount * sbFee) / ONE;
    }

    function _getSafeBoxFeePerAddress(address _toCheck) internal view returns (uint toReturn) {
        return safeBoxFeePerAddress[_toCheck] > 0 ? safeBoxFeePerAddress[_toCheck] : safeBoxFee;
    }

    function _verifyMerkleTree(ISportsAMMV2.TradeData memory tradeDataItem) internal view {
        // Compute the merkle leaf from trade data
        bytes memory encodePackedOutput = abi.encodePacked(
            tradeDataItem.gameId,
            uint(tradeDataItem.sportId),
            uint(tradeDataItem.typeId),
            tradeDataItem.maturity,
            uint(tradeDataItem.status),
            int(tradeDataItem.line),
            uint(tradeDataItem.playerId),
            tradeDataItem.odds
        );

        for (uint i; i < tradeDataItem.combinedPositions.length; i++) {
            for (uint j; j < tradeDataItem.combinedPositions[i].length; j++) {
                encodePackedOutput = abi.encodePacked(
                    encodePackedOutput,
                    uint(tradeDataItem.combinedPositions[i][j].typeId),
                    uint(tradeDataItem.combinedPositions[i][j].position),
                    int(tradeDataItem.combinedPositions[i][j].line)
                );
            }
        }

        bytes32 leaf = keccak256(encodePackedOutput);
        // verify the proof is valid
        require(
            MerkleProof.verify(tradeDataItem.merkleProof, rootPerGame[tradeDataItem.gameId], leaf),
            "Proof is not valid"
        );
    }

    function _exerciseTicket(address _ticket) internal {
        Ticket ticket = Ticket(_ticket);
        ticket.exercise();
        uint amount = defaultCollateral.balanceOf(address(this));
        if (amount > 0) {
            liquidityPool.transferToPool(_ticket, amount);
        }
    }

    /* ========== SETTERS ========== */

    /// @notice set roots of merkle tree
    /// @param _games game IDs
    /// @param _roots new roots
    function setRootsPerGames(bytes32[] memory _games, bytes32[] memory _roots) public onlyOwner {
        require(_games.length == _roots.length, "Invalid length");
        for (uint i; i < _games.length; i++) {
            rootPerGame[_games[i]] = _roots[i];
            emit GameRootUpdated(_games[i], _roots[i]);
        }
    }

    /// @notice sets different amounts
    /// @param _safeBoxFee safe box fee paid on each trade
    /// @param _minBuyInAmount minimum ticket buy-in amount
    /// @param _maxTicketSize maximum ticket size
    /// @param _maxSupportedAmount maximum supported payout amount
    /// @param _maxSupportedOdds  maximum supported ticket odds
    function setAmounts(
        uint _safeBoxFee,
        uint _minBuyInAmount,
        uint _maxTicketSize,
        uint _maxSupportedAmount,
        uint _maxSupportedOdds
    ) external onlyOwner {
        safeBoxFee = _safeBoxFee;
        minBuyInAmount = _minBuyInAmount;
        maxTicketSize = _maxTicketSize;
        maxSupportedAmount = _maxSupportedAmount;
        maxSupportedOdds = _maxSupportedOdds;
        emit AmountsUpdated(_safeBoxFee, _minBuyInAmount, _maxTicketSize, _maxSupportedAmount, _maxSupportedOdds);
    }

    /// @notice sets main addresses
    /// @param _defaultCollateral the default token used for payment
    /// @param _manager manager address
    /// @param _riskManager risk manager address
    /// @param _referrals referrals address
    /// @param _stakingThales staking thales address
    /// @param _safeBox safeBox address
    function setAddresses(
        IERC20 _defaultCollateral,
        address _manager,
        address _riskManager,
        address _resultManager,
        address _referrals,
        address _stakingThales,
        address _safeBox
    ) external onlyOwner {
        defaultCollateral = _defaultCollateral;
        manager = ISportsAMMV2Manager(_manager);
        riskManager = ISportsAMMV2RiskManager(_riskManager);
        resultManager = ISportsAMMV2ResultManager(_resultManager);
        referrals = IReferrals(_referrals);
        stakingThales = IStakingThales(_stakingThales);
        safeBox = _safeBox;

        emit AddressesUpdated(
            _defaultCollateral,
            _manager,
            _riskManager,
            _resultManager,
            _referrals,
            _stakingThales,
            _safeBox
        );
    }

    /// @notice sets different times/periods
    /// @param _minimalTimeLeftToMaturity  the period of time in seconds before a game is matured and begins to be restricted for AMM trading
    /// @param _expiryDuration the period of time in seconds after mauturity when ticket expires
    function setTimes(uint _minimalTimeLeftToMaturity, uint _expiryDuration) external onlyOwner {
        minimalTimeLeftToMaturity = _minimalTimeLeftToMaturity;
        expiryDuration = _expiryDuration;
        emit TimesUpdated(_minimalTimeLeftToMaturity, _expiryDuration);
    }

    /// @notice sets new Ticket Mastercopy address
    /// @param _ticketMastercopy new Ticket Mastercopy address
    function setTicketMastercopy(address _ticketMastercopy) external onlyOwner {
        ticketMastercopy = _ticketMastercopy;
        emit TicketMastercopyUpdated(_ticketMastercopy);
    }

    /// @notice sets new LP address
    /// @param _liquidityPool new LP address
    function setLiquidityPool(address _liquidityPool) external onlyOwner {
        if (address(liquidityPool) != address(0)) {
            defaultCollateral.approve(address(liquidityPool), 0);
        }
        liquidityPool = ISportsAMMV2LiquidityPool(_liquidityPool);
        defaultCollateral.approve(_liquidityPool, MAX_APPROVAL);
        emit SetLiquidityPool(_liquidityPool);
    }

    /// @notice sets multi-collateral on/off ramp contract and enable/disable
    /// @param _onOffRamper new multi-collateral on/off ramp address
    /// @param _enabled enable/disable multi-collateral on/off ramp
    function setMultiCollateralOnOffRamp(address _onOffRamper, bool _enabled) external onlyOwner {
        if (address(multiCollateralOnOffRamp) != address(0)) {
            defaultCollateral.approve(address(multiCollateralOnOffRamp), 0);
        }
        multiCollateralOnOffRamp = IMultiCollateralOnOffRamp(_onOffRamper);
        multicollateralEnabled = _enabled;
        if (_enabled) {
            defaultCollateral.approve(_onOffRamper, MAX_APPROVAL);
        }
        emit SetMultiCollateralOnOffRamp(_onOffRamper, _enabled);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyKnownTickets(address _ticket) {
        require(knownTickets.contains(_ticket), "Unknown ticket");
        _;
    }

    /* ========== EVENTS ========== */

    event NewTicket(Ticket.MarketData[] markets, address ticket, uint buyInAmountAfterFees, uint payout);
    event TicketCreated(
        address ticket,
        address differentRecipient,
        uint buyInAmount,
        uint buyInAmountAfterFees,
        uint payout,
        uint totalQuote
    );

    event TicketResolved(address ticket, address ticketOwner, bool isUserTheWinner);
    event ReferrerPaid(address refferer, address trader, uint amount, uint volume);
    event SafeBoxFeePaid(uint safeBoxFee, uint safeBoxAmount);

    event GameRootUpdated(bytes32 game, bytes32 root);
    event AmountsUpdated(
        uint safeBoxFee,
        uint minBuyInAmount,
        uint maxTicketSize,
        uint maxSupportedAmount,
        uint maxSupportedOdds
    );
    event AddressesUpdated(
        IERC20 defaultCollateral,
        address manager,
        address riskManager,
        address resultManager,
        address referrals,
        address stakingThales,
        address safeBox
    );
    event TimesUpdated(uint minimalTimeLeftToMaturity, uint expiryDuration);
    event TicketMastercopyUpdated(address ticketMastercopy);
    event SetLiquidityPool(address liquidityPool);
    event SetMultiCollateralOnOffRamp(address onOffRamper, bool enabled);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// internal
import "../utils/OwnedWithInit.sol";
import "../interfaces/ISportsAMMV2.sol";

contract Ticket is OwnedWithInit {
    uint private constant ONE = 1e18;

    enum Phase {
        Trading,
        Maturity,
        Expiry
    }

    struct MarketData {
        bytes32 gameId;
        uint16 sportId;
        uint16 typeId;
        uint maturity;
        uint8 status;
        int24 line;
        uint16 playerId;
        uint8 position;
        uint odd;
        ISportsAMMV2.CombinedPosition[] combinedPositions;
    }

    ISportsAMMV2 public sportsAMM;
    address public ticketOwner;
    address public ticketCreator;

    uint public buyInAmount;
    uint public buyInAmountAfterFees;
    uint public totalQuote;
    uint public numOfMarkets;
    uint public expiry;
    uint public createdAt;

    bool public resolved;
    bool public paused;
    bool public initialized;
    bool public cancelled;

    mapping(uint => MarketData) public markets;

    /* ========== CONSTRUCTOR ========== */

    /// @notice initialize the ticket contract
    /// @param _markets data with all market info needed for ticket
    /// @param _buyInAmount ticket buy-in amount
    /// @param _buyInAmountAfterFees ticket buy-in amount without fees
    /// @param _totalQuote total ticket quote
    /// @param _sportsAMM address of Sports AMM contact
    /// @param _ticketOwner owner of the ticket
    /// @param _ticketCreator creator of the ticket
    /// @param _expiry ticket expiry timestamp
    function initialize(
        MarketData[] calldata _markets,
        uint _buyInAmount,
        uint _buyInAmountAfterFees,
        uint _totalQuote,
        address _sportsAMM,
        address _ticketOwner,
        address _ticketCreator,
        uint _expiry
    ) external {
        require(!initialized, "Ticket already initialized");
        initialized = true;
        initOwner(msg.sender);
        sportsAMM = ISportsAMMV2(_sportsAMM);
        numOfMarkets = _markets.length;
        for (uint i = 0; i < numOfMarkets; i++) {
            markets[i] = _markets[i];
        }
        buyInAmount = _buyInAmount;
        buyInAmountAfterFees = _buyInAmountAfterFees;
        totalQuote = _totalQuote;
        ticketOwner = _ticketOwner;
        ticketCreator = _ticketCreator;
        expiry = _expiry;
        createdAt = block.timestamp;
    }

    /* ========== EXTERNAL READ FUNCTIONS ========== */

    /// @notice checks if the user lost the ticket
    /// @return isTicketLost true/false
    function isTicketLost() public view returns (bool) {
        for (uint i = 0; i < numOfMarkets; i++) {
            bool isMarketResolved = sportsAMM.resultManager().isMarketResolved(
                markets[i].gameId,
                markets[i].typeId,
                markets[i].playerId,
                markets[i].line,
                markets[i].combinedPositions
            );
            bool isWinningMarketPosition = sportsAMM.resultManager().isWinningMarketPosition(
                markets[i].gameId,
                markets[i].typeId,
                markets[i].playerId,
                markets[i].line,
                markets[i].position,
                markets[i].combinedPositions
            );
            if (isMarketResolved && !isWinningMarketPosition) {
                return true;
            }
        }
        return false;
    }

    /// @notice checks are all markets of the ticket resolved
    /// @return areAllMarketsResolved true/false
    function areAllMarketsResolved() public view returns (bool) {
        for (uint i = 0; i < numOfMarkets; i++) {
            if (
                !sportsAMM.resultManager().isMarketResolved(
                    markets[i].gameId,
                    markets[i].typeId,
                    markets[i].playerId,
                    markets[i].line,
                    markets[i].combinedPositions
                )
            ) {
                return false;
            }
        }
        return true;
    }

    /// @notice checks if the user won the ticket
    /// @return hasUserWon true/false
    function isUserTheWinner() external view returns (bool hasUserWon) {
        if (areAllMarketsResolved()) {
            hasUserWon = !isTicketLost();
        }
    }

    /// @notice checks if the ticket ready to be exercised
    /// @return isExercisable true/false
    function isTicketExercisable() public view returns (bool isExercisable) {
        isExercisable = !resolved && (areAllMarketsResolved() || isTicketLost());
    }

    /// @notice gets current phase of the ticket
    /// @return phase ticket phase
    function phase() public view returns (Phase) {
        return resolved ? ((expiry < block.timestamp) ? Phase.Expiry : Phase.Maturity) : Phase.Trading;
    }

    /// @notice gets combined positions of the game
    /// @return combinedPositions game combined positions
    function getCombinedPositions(
        uint _marketIndex
    ) public view returns (ISportsAMMV2.CombinedPosition[] memory combinedPositions) {
        return markets[_marketIndex].combinedPositions;
    }

    /* ========== EXTERNAL WRITE FUNCTIONS ========== */

    /// @notice exercise ticket
    function exercise() external onlyAMM {
        require(!paused, "Market paused");
        bool isExercisable = isTicketExercisable();
        require(isExercisable, "Ticket not exercisable yet");

        uint payoutWithFees = sportsAMM.defaultCollateral().balanceOf(address(this));
        uint payout = payoutWithFees - (buyInAmount - buyInAmountAfterFees);
        bool isCancelled = false;

        if (isTicketLost()) {
            if (payoutWithFees > 0) {
                sportsAMM.defaultCollateral().transfer(address(sportsAMM), payoutWithFees);
            }
        } else {
            uint finalPayout = payout;
            isCancelled = true;
            for (uint i = 0; i < numOfMarkets; i++) {
                bool isCancelledMarketPosition = sportsAMM.resultManager().isCancelledMarketPosition(
                    markets[i].gameId,
                    markets[i].typeId,
                    markets[i].playerId,
                    markets[i].line,
                    markets[i].position,
                    markets[i].combinedPositions
                );
                if (isCancelledMarketPosition) {
                    finalPayout = (finalPayout * markets[i].odd) / ONE;
                } else {
                    isCancelled = false;
                }
            }
            sportsAMM.defaultCollateral().transfer(address(ticketOwner), isCancelled ? buyInAmount : finalPayout);

            uint balance = sportsAMM.defaultCollateral().balanceOf(address(this));
            if (balance != 0) {
                sportsAMM.defaultCollateral().transfer(
                    address(sportsAMM),
                    sportsAMM.defaultCollateral().balanceOf(address(this))
                );
            }
        }

        _resolve(!isTicketLost(), isCancelled);
    }

    /// @notice expire ticket
    function expire(address payable beneficiary) external onlyAMM {
        require(phase() == Phase.Expiry, "Ticket expired");
        require(!resolved, "Can't expire resolved parlay.");
        emit Expired(beneficiary);
        _selfDestruct(beneficiary);
    }

    /// @notice withdraw collateral from the ticket
    function withdrawCollateral(address recipient) external onlyAMM {
        sportsAMM.defaultCollateral().transfer(recipient, sportsAMM.defaultCollateral().balanceOf(address(this)));
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _resolve(bool _hasUserWon, bool _cancelled) internal {
        resolved = true;
        cancelled = _cancelled;
        sportsAMM.resolveTicket(ticketOwner, _hasUserWon, _cancelled, buyInAmount, ticketCreator);
        emit Resolved(_hasUserWon, _cancelled);
    }

    function _selfDestruct(address payable beneficiary) internal {
        uint balance = sportsAMM.defaultCollateral().balanceOf(address(this));
        if (balance != 0) {
            sportsAMM.defaultCollateral().transfer(beneficiary, balance);
        }
    }

    /* ========== SETTERS ========== */

    function setPaused(bool _paused) external onlyAMM {
        require(paused != _paused, "State not changed");
        paused = _paused;
        emit PauseUpdated(_paused);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAMM() {
        require(msg.sender == address(sportsAMM), "Only the AMM may perform these methods");
        _;
    }

    /* ========== EVENTS ========== */

    event Resolved(bool isUserTheWinner, bool cancelled);
    event Expired(address beneficiary);
    event PauseUpdated(bool paused);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AddressSetLib {
    struct AddressSet {
        address[] elements;
        mapping(address => uint) indices;
    }

    function contains(AddressSet storage set, address candidate) internal view returns (bool) {
        if (set.elements.length == 0) {
            return false;
        }
        uint index = set.indices[candidate];
        return index != 0 || set.elements[0] == candidate;
    }

    function getPage(AddressSet storage set, uint index, uint pageSize) internal view returns (address[] memory) {
        // NOTE: This implementation should be converted to slice operators if the compiler is updated to v0.6.0+
        uint endIndex = index + pageSize; // The check below that endIndex <= index handles overflow.

        // If the page extends past the end of the list, truncate it.
        if (endIndex > set.elements.length) {
            endIndex = set.elements.length;
        }
        if (endIndex <= index) {
            return new address[](0);
        }

        uint n = endIndex - index; // We already checked for negative overflow.
        address[] memory page = new address[](n);
        for (uint i; i < n; i++) {
            page[i] = set.elements[i + index];
        }
        return page;
    }

    function add(AddressSet storage set, address element) internal {
        // Adding to a set is an idempotent operation.
        if (!contains(set, element)) {
            set.indices[element] = set.elements.length;
            set.elements.push(element);
        }
    }

    function remove(AddressSet storage set, address element) internal {
        require(contains(set, element), "Element not in set.");
        // Replace the removed element with the last element of the list.
        uint index = set.indices[element];
        uint lastIndex = set.elements.length - 1; // We required that element is in the list, so it is not empty.
        if (index != lastIndex) {
            // No need to shift the last element if it is the one we want to delete.
            address shiftedElement = set.elements[lastIndex];
            set.elements[index] = shiftedElement;
            set.indices[shiftedElement] = index;
        }
        set.elements.pop();
        delete set.indices[element];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract OwnedWithInit {
    address public owner;
    address public nominatedOwner;

    constructor() {}

    function initOwner(address _owner) internal {
        require(owner == address(0), "Init can only be called when owner is 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Clone of syntetix contract without constructor
contract ProxyOwned {
    address public owner;
    address public nominatedOwner;
    bool private _initialized;
    bool private _transferredAtInit;

    function setOwner(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        require(!_initialized, "Already initialized, use nominateNewOwner");
        _initialized = true;
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    function transferOwnershipAtInit(address proxyAddress) external onlyOwner {
        require(proxyAddress != address(0), "Invalid address");
        require(!_transferredAtInit, "Already transferred");
        owner = proxyAddress;
        _transferredAtInit = true;
        emit OwnerChanged(owner, proxyAddress);
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Inheritance
import "./ProxyOwned.sol";

// Clone of syntetix contract without constructor
contract ProxyPausable is ProxyOwned {
    uint public lastPauseTime;
    bool public paused;

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = block.timestamp;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused() {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ProxyReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;
    bool private _initialized;

    function initNonReentrant() public {
        require(!_initialized, "Already initialized");
        _initialized = true;
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}