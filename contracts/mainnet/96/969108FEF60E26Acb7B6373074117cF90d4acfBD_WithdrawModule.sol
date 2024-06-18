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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    /// @custom:storage-location erc7201:openzeppelin.storage.ReentrancyGuard
    struct ReentrancyGuardStorage {
        uint256 _status;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ReentrancyGuardStorageLocation = 0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    function _getReentrancyGuardStorage() private pure returns (ReentrancyGuardStorage storage $) {
        assembly {
            $.slot := ReentrancyGuardStorageLocation
        }
    }

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        $._status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if ($._status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        $._status = ENTERED;
    }

    function _nonReentrantAfter() private {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        $._status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        return $._status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` amount of tokens of type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the value of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers a `value` amount of tokens of type `id` from `from` to `to`.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155Received} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `value` amount.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155BatchReceived} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits either a {TransferSingle} or a {TransferBatch} event, depending on the length of the array arguments.
     *
     * Requirements:
     *
     * - `ids` and `values` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;

import {Math} from "./math/Math.sol";
import {SignedMath} from "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

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
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
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
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/MessageHashUtils.sol)

pragma solidity ^0.8.20;

import {Strings} from "../Strings.sol";

/**
 * @dev Signature message hash utilities for producing digests to be consumed by {ECDSA} recovery or signing.
 *
 * The library provides methods for generating a hash of a message that conforms to the
 * https://eips.ethereum.org/EIPS/eip-191[EIP 191] and https://eips.ethereum.org/EIPS/eip-712[EIP 712]
 * specifications.
 */
library MessageHashUtils {
    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x45` (`personal_sign` messages).
     *
     * The digest is calculated by prefixing a bytes32 `messageHash` with
     * `"\x19Ethereum Signed Message:\n32"` and hashing the result. It corresponds with the
     * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
     *
     * NOTE: The `messageHash` parameter is intended to be the result of hashing a raw message with
     * keccak256, although any bytes32 value can be safely used because the final digest will
     * be re-hashed.
     *
     * See {ECDSA-recover}.
     */
    function toEthSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32") // 32 is the bytes-length of messageHash
            mstore(0x1c, messageHash) // 0x1c (28) is the length of the prefix
            digest := keccak256(0x00, 0x3c) // 0x3c is the length of the prefix (0x1c) + messageHash (0x20)
        }
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x45` (`personal_sign` messages).
     *
     * The digest is calculated by prefixing an arbitrary `message` with
     * `"\x19Ethereum Signed Message:\n" + len(message)` and hashing the result. It corresponds with the
     * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
     *
     * See {ECDSA-recover}.
     */
    function toEthSignedMessageHash(bytes memory message) internal pure returns (bytes32) {
        return
            keccak256(bytes.concat("\x19Ethereum Signed Message:\n", bytes(Strings.toString(message.length)), message));
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x00` (data with intended validator).
     *
     * The digest is calculated by prefixing an arbitrary `data` with `"\x19\x00"` and the intended
     * `validator` address. Then hashing the result.
     *
     * See {ECDSA-recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(hex"19_00", validator, data));
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-712 typed data (EIP-191 version `0x01`).
     *
     * The digest is calculated from a `domainSeparator` and a `structHash`, by prefixing them with
     * `\x19\x01` and hashing the result. It corresponds to the hash signed by the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`] JSON-RPC method as part of EIP-712.
     *
     * See {ECDSA-recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, hex"19_01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            digest := keccak256(ptr, 0x42)
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._positions[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.19;

import {IWormhole} from "wormhole/interfaces/IWormhole.sol";
import {ICircleBridge} from "./circle/ICircleBridge.sol";
import {IMessageTransmitter} from "./circle/IMessageTransmitter.sol";

interface ICircleIntegration {
    struct TransferParameters {
        address token;
        uint256 amount;
        uint16 targetChain;
        bytes32 mintRecipient;
    }

    struct RedeemParameters {
        bytes encodedWormholeMessage;
        bytes circleBridgeMessage;
        bytes circleAttestation;
    }

    struct DepositWithPayload {
        bytes32 token;
        uint256 amount;
        uint32 sourceDomain;
        uint32 targetDomain;
        uint64 nonce;
        bytes32 fromAddress;
        bytes32 mintRecipient;
        bytes payload;
    }

    function transferTokensWithPayload(TransferParameters memory transferParams, uint32 batchId, bytes memory payload)
        external
        payable
        returns (uint64 messageSequence);

    function redeemTokensWithPayload(RedeemParameters memory params)
        external
        returns (DepositWithPayload memory depositWithPayload);

    function fetchLocalTokenAddress(uint32 sourceDomain, bytes32 sourceToken)
        external
        view
        returns (bytes32);

    function encodeDepositWithPayload(DepositWithPayload memory message) external pure returns (bytes memory);

    function decodeDepositWithPayload(bytes memory encoded) external pure returns (DepositWithPayload memory message);

    function isInitialized(address impl) external view returns (bool);

    function wormhole() external view returns (IWormhole);

    function chainId() external view returns (uint16);

    function wormholeFinality() external view returns (uint8);

    function circleBridge() external view returns (ICircleBridge);

    function circleTransmitter() external view returns (IMessageTransmitter);

    function getRegisteredEmitter(uint16 emitterChainId) external view returns (bytes32);

    function isAcceptedToken(address token) external view returns (bool);

    function getDomainFromChainId(uint16 chainId_) external view returns (uint32);

    function getChainIdFromDomain(uint32 domain) external view returns (uint16);

    function isMessageConsumed(bytes32 hash) external view returns (bool);

    function localDomain() external view returns (uint32);

    function verifyGovernanceMessage(bytes memory encodedMessage, uint8 action)
        external
        view
        returns (bytes32 messageHash, bytes memory payload);

    function evmChain() external view returns (uint256);

    // guardian governance only
    function updateWormholeFinality(bytes memory encodedMessage) external;

    function registerEmitterAndDomain(bytes memory encodedMessage) external;

    function upgradeContract(bytes memory encodedMessage) external;
}

// contracts/Messages.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface IWormhole {
    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;

        uint32 guardianSetIndex;
        Signature[] signatures;

        bytes32 hash;
    }

    struct ContractUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;

        address newContract;
    }

    struct GuardianSetUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;

        GuardianSet newGuardianSet;
        uint32 newGuardianSetIndex;
    }

    struct SetMessageFee {
        bytes32 module;
        uint8 action;
        uint16 chain;

        uint256 messageFee;
    }

    struct TransferFees {
        bytes32 module;
        uint8 action;
        uint16 chain;

        uint256 amount;
        bytes32 recipient;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;

        uint256 evmChainId;
        uint16 newChainId;
    }

    event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel);
    event ContractUpgraded(address indexed oldContract, address indexed newContract);
    event GuardianSetAdded(uint32 indexed index);

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function initialize() external;

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (VM memory vm, bool valid, string memory reason);

    function verifyVM(VM memory vm) external view returns (bool valid, string memory reason);

    function verifySignatures(bytes32 hash, Signature[] memory signatures, GuardianSet memory guardianSet) external pure returns (bool valid, string memory reason);

    function parseVM(bytes memory encodedVM) external pure returns (VM memory vm);

    function quorum(uint numGuardians) external pure returns (uint numSignaturesRequiredForQuorum);

    function getGuardianSet(uint32 index) external view returns (GuardianSet memory);

    function getCurrentGuardianSetIndex() external view returns (uint32);

    function getGuardianSetExpiry() external view returns (uint32);

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function chainId() external view returns (uint16);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256);

    function evmChainId() external view returns (uint256);

    function nextSequence(address emitter) external view returns (uint64);

    function parseContractUpgrade(bytes memory encodedUpgrade) external pure returns (ContractUpgrade memory cu);

    function parseGuardianSetUpgrade(bytes memory encodedUpgrade) external pure returns (GuardianSetUpgrade memory gsu);

    function parseSetMessageFee(bytes memory encodedSetMessageFee) external pure returns (SetMessageFee memory smf);

    function parseTransferFees(bytes memory encodedTransferFees) external pure returns (TransferFees memory tf);

    function parseRecoverChainId(bytes memory encodedRecoverChainId) external pure returns (RecoverChainId memory rci);

    function submitContractUpgrade(bytes memory _vm) external;

    function submitSetMessageFee(bytes memory _vm) external;

    function submitNewGuardianSet(bytes memory _vm) external;

    function submitTransferFees(bytes memory _vm) external;

    function submitRecoverChainId(bytes memory _vm) external;
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

import {IMessageTransmitter} from "./IMessageTransmitter.sol";
import {ITokenMinter} from "./ITokenMinter.sol";

interface ICircleBridge {
    /**
     * @notice Deposits and burns tokens from sender to be minted on destination domain.
     * Emits a `DepositForBurn` event.
     * @dev reverts if:
     * - given burnToken is not supported
     * - given destinationDomain has no CircleBridge registered
     * - transferFrom() reverts. For example, if sender's burnToken balance or approved allowance
     * to this contract is less than `amount`.
     * - burn() reverts. For example, if `amount` is 0.
     * - MessageTransmitter returns false or reverts.
     * @param _amount amount of tokens to burn
     * @param _destinationDomain destination domain (ETH = 0, AVAX = 1)
     * @param _mintRecipient address of mint recipient on destination domain
     * @param _burnToken address of contract to burn deposited tokens, on local domain
     * @return _nonce unique nonce reserved by message
     */
    function depositForBurn(uint256 _amount, uint32 _destinationDomain, bytes32 _mintRecipient, address _burnToken)
        external
        returns (uint64 _nonce);

    /**
     * @notice Deposits and burns tokens from sender to be minted on destination domain. The mint
     * on the destination domain must be called by `_destinationCaller`.
     * WARNING: if the `_destinationCaller` does not represent a valid address as bytes32, then it will not be possible
     * to broadcast the message on the destination domain. This is an advanced feature, and the standard
     * depositForBurn() should be preferred for use cases where a specific destination caller is not required.
     * Emits a `DepositForBurn` event.
     * @dev reverts if:
     * - given destinationCaller is zero address
     * - given burnToken is not supported
     * - given destinationDomain has no CircleBridge registered
     * - transferFrom() reverts. For example, if sender's burnToken balance or approved allowance
     * to this contract is less than `amount`.
     * - burn() reverts. For example, if `amount` is 0.
     * - MessageTransmitter returns false or reverts.
     * @param _amount amount of tokens to burn
     * @param _destinationDomain destination domain
     * @param _mintRecipient address of mint recipient on destination domain
     * @param _burnToken address of contract to burn deposited tokens, on local domain
     * @param _destinationCaller caller on the destination domain, as bytes32
     * @return _nonce unique nonce reserved by message
     */
    function depositForBurnWithCaller(
        uint256 _amount,
        uint32 _destinationDomain,
        bytes32 _mintRecipient,
        address _burnToken,
        bytes32 _destinationCaller
    ) external returns (uint64 _nonce);

    function owner() external view returns (address);

    function handleReceiveMessage(uint32 _remoteDomain, bytes32 _sender, bytes memory messageBody)
        external
        view
        returns (bool);

    function localMessageTransmitter() external view returns (IMessageTransmitter);

    function localMinter() external view returns (ITokenMinter);

    function remoteCircleBridges(uint32 domain) external view returns (bytes32);

    // owner only methods
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

interface IMessageTransmitter {
    event MessageSent(bytes message);

    /**
     * @notice Emitted when tokens are minted
     * @param _mintRecipient recipient address of minted tokens
     * @param _amount amount of minted tokens
     * @param _mintToken contract address of minted token
     */
    event MintAndWithdraw(address _mintRecipient, uint256 _amount, address _mintToken);

    /**
     * @notice Receive a message. Messages with a given nonce
     * can only be broadcast once for a (sourceDomain, destinationDomain)
     * pair. The message body of a valid message is passed to the
     * specified recipient for further processing.
     *
     * @dev Attestation format:
     * A valid attestation is the concatenated 65-byte signature(s) of exactly
     * `thresholdSignature` signatures, in increasing order of attester address.
     * ***If the attester addresses recovered from signatures are not in
     * increasing order, signature verification will fail.***
     * If incorrect number of signatures or duplicate signatures are supplied,
     * signature verification will fail.
     *
     * Message format:
     * Field Bytes Type Index
     * version 4 uint32 0
     * sourceDomain 4 uint32 4
     * destinationDomain 4 uint32 8
     * nonce 8 uint64 12
     * sender 32 bytes32 20
     * recipient 32 bytes32 52
     * messageBody dynamic bytes 84
     * @param _message Message bytes
     * @param _attestation Concatenated 65-byte signature(s) of `_message`, in increasing order
     * of the attester address recovered from signatures.
     * @return success bool, true if successful
     */
    function receiveMessage(bytes memory _message, bytes calldata _attestation) external returns (bool success);

    function attesterManager() external view returns (address);

    function availableNonces(uint32 domain) external view returns (uint64);

    function getNumEnabledAttesters() external view returns (uint256);

    function isEnabledAttester(address _attester) external view returns (bool);

    function localDomain() external view returns (uint32);

    function maxMessageBodySize() external view returns (uint256);

    function owner() external view returns (address);

    function paused() external view returns (bool);

    function pauser() external view returns (address);

    function rescuer() external view returns (address);

    function version() external view returns (uint32);

    // owner only methods
    function transferOwnership(address newOwner) external;

    function updateAttesterManager(address _newAttesterManager) external;

    // attester manager only methods
    function getEnabledAttester(uint256 _index) external view returns (address);

    function disableAttester(address _attester) external;

    function enableAttester(address _attester) external;

    function setSignatureThreshold(uint256 newSignatureThreshold) external;
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

/**
 * @title ITokenMinter
 * @notice interface for minter of tokens that are mintable, burnable, and interchangeable
 * across domains.
 */
interface ITokenMinter {
    function burnLimitsPerMessage(address token) external view returns (uint256);

    function remoteTokensToLocalTokens(bytes32 sourceIdHash) external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./SafeCast.sol";

/**
 * @title Utility library used to represent "decimals" (fixed point numbers) with integers, with two different levels of precision.
 *
 * They are represented by N * UNIT, where UNIT is the number of decimals of precision in the representation.
 *
 * Examples:
 * 1) Given UNIT = 100
 * then if A = 50, A represents the decimal 0.50
 * 2) Given UNIT = 1000000000000000000
 * then if A = 500000000000000000, A represents the decimal 0.500000000000000000
 *
 * Note: An accompanying naming convention of the postfix "D<Precision>" is helpful with this utility. I.e. if a variable "myValue" represents a low resolution decimal, it should be named "myValueD18", and if it was a high resolution decimal "myValueD27". While scaling, intermediate precision decimals like "myValue45" could arise. Non-decimals should have no postfix, i.e. just "myValue".
 *
 * Important: Multiplication and division operations are currently not supported for high precision decimals. Using these operations on them will yield incorrect results and fail silently.
 */
library DecimalMath {
    using SafeCastU256 for uint256;
    using SafeCastI256 for int256;

    // solhint-disable numcast/safe-cast

    // Numbers representing 1.0 (low precision).
    uint256 public constant UNIT = 1e18;
    int256 public constant UNIT_INT = int256(UNIT);
    uint128 public constant UNIT_UINT128 = uint128(UNIT);
    int128 public constant UNIT_INT128 = int128(UNIT_INT);

    // Numbers representing 1.0 (high precision).
    uint256 public constant UNIT_PRECISE = 1e27;
    int256 public constant UNIT_PRECISE_INT = int256(UNIT_PRECISE);
    int128 public constant UNIT_PRECISE_INT128 = int128(UNIT_PRECISE_INT);

    // Precision scaling, (used to scale down/up from one precision to the other).
    uint256 public constant PRECISION_FACTOR = 9; // 27 - 18 = 9 :)

    // solhint-enable numcast/safe-cast

    // -----------------
    // uint256
    // -----------------

    /**
     * @dev Multiplies two low precision decimals.
     *
     * Since the two numbers are assumed to be fixed point numbers,
     * (x * UNIT) * (y * UNIT) = x * y * UNIT ^ 2,
     * the result is divided by UNIT to remove double scaling.
     */
    function mulDecimal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return (x * y) / UNIT;
    }

    /**
     * @dev Divides two low precision decimals.
     *
     * Since the two numbers are assumed to be fixed point numbers,
     * (x * UNIT) / (y * UNIT) = x / y (Decimal representation is lost),
     * x is first scaled up to end up with a decimal representation.
     */
    function divDecimal(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return (x * UNIT) / y;
    }

    /**
     * @dev Scales up a value.
     *
     * E.g. if value is not a decimal, a scale up by 18 makes it a low precision decimal.
     * If value is a low precision decimal, a scale up by 9 makes it a high precision decimal.
     */
    function upscale(uint256 x, uint256 factor) internal pure returns (uint256) {
        return x * 10 ** factor;
    }

    /**
     * @dev Scales down a value.
     *
     * E.g. if value is a high precision decimal, a scale down by 9 makes it a low precision decimal.
     * If value is a low precision decimal, a scale down by 9 makes it a regular integer.
     *
     * Scaling down a regular integer would not make sense.
     */
    function downscale(uint256 x, uint256 factor) internal pure returns (uint256) {
        return x / 10 ** factor;
    }

    // -----------------
    // uint128
    // -----------------

    // Note: Overloading doesn't seem to work for similar types, i.e. int256 and int128, uint256 and uint128, etc, so explicitly naming the functions differently here.

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimalUint128(uint128 x, uint128 y) internal pure returns (uint128) {
        return (x * y) / UNIT_UINT128;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimalUint128(uint128 x, uint128 y) internal pure returns (uint128) {
        return (x * UNIT_UINT128) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscaleUint128(uint128 x, uint256 factor) internal pure returns (uint128) {
        return x * (10 ** factor).to128();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscaleUint128(uint128 x, uint256 factor) internal pure returns (uint128) {
        return x / (10 ** factor).to128();
    }

    // -----------------
    // int256
    // -----------------

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimal(int256 x, int256 y) internal pure returns (int256) {
        return (x * y) / UNIT_INT;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimal(int256 x, int256 y) internal pure returns (int256) {
        return (x * UNIT_INT) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscale(int256 x, uint256 factor) internal pure returns (int256) {
        return x * (10 ** factor).toInt();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscale(int256 x, uint256 factor) internal pure returns (int256) {
        return x / (10 ** factor).toInt();
    }

    // -----------------
    // int128
    // -----------------

    /**
     * @dev See mulDecimal for uint256.
     */
    function mulDecimalInt128(int128 x, int128 y) internal pure returns (int128) {
        return (x * y) / UNIT_INT128;
    }

    /**
     * @dev See divDecimal for uint256.
     */
    function divDecimalInt128(int128 x, int128 y) internal pure returns (int128) {
        return (x * UNIT_INT128) / y;
    }

    /**
     * @dev See upscale for uint256.
     */
    function upscaleInt128(int128 x, uint256 factor) internal pure returns (int128) {
        return x * ((10 ** factor).toInt()).to128();
    }

    /**
     * @dev See downscale for uint256.
     */
    function downscaleInt128(int128 x, uint256 factor) internal pure returns (int128) {
        return x / ((10 ** factor).toInt().to128());
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * Utilities that convert numeric types avoiding silent overflows.
 */
import "./SafeCast/SafeCastU32.sol";
import "./SafeCast/SafeCastI32.sol";
import "./SafeCast/SafeCastI24.sol";
import "./SafeCast/SafeCastU56.sol";
import "./SafeCast/SafeCastI56.sol";
import "./SafeCast/SafeCastU64.sol";
import "./SafeCast/SafeCastI64.sol";
import "./SafeCast/SafeCastI128.sol";
import "./SafeCast/SafeCastI256.sol";
import "./SafeCast/SafeCastU128.sol";
import "./SafeCast/SafeCastU160.sol";
import "./SafeCast/SafeCastU256.sol";
import "./SafeCast/SafeCastAddress.sol";
import "./SafeCast/SafeCastBytes32.sol";

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastAddress {
    function toBytes32(address x) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(x)));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastBytes32 {
    function toAddress(bytes32 x) internal pure returns (address) {
        return address(uint160(uint256(x)));
    }

    function toUint(bytes32 x) internal pure returns (uint) {
        return uint(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI128 {
    error OverflowInt128ToUint128();
    error OverflowInt128ToInt32();

    function toUint(int128 x) internal pure returns (uint128) {
        // ----------------<==============o==============>-----------------
        // ----------------xxxxxxxxxxxxxxxo===============>----------------
        if (x < 0) {
            revert OverflowInt128ToUint128();
        }

        return uint128(x);
    }

    function to256(int128 x) internal pure returns (int256) {
        return int256(x);
    }

    function to32(int128 x) internal pure returns (int32) {
        // ----------------<==============o==============>-----------------
        // ----------------xxxxxxxxxxxx<==o==>xxxxxxxxxxxx-----------------
        if (x < int256(type(int32).min) || x > int256(type(int32).max)) {
            revert OverflowInt128ToInt32();
        }

        return int32(x);
    }

    function zero() internal pure returns (int128) {
        return int128(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI24 {
    function to256(int24 x) internal pure returns (int256) {
        return int256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI256 {
    error OverflowInt256ToUint256();
    error OverflowInt256ToInt128();
    error OverflowInt256ToInt24();

    function to128(int256 x) internal pure returns (int128) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxx<==============o==============>xxxxxxxxxxxxx----
        if (x < int256(type(int128).min) || x > int256(type(int128).max)) {
            revert OverflowInt256ToInt128();
        }

        return int128(x);
    }

    function to24(int256 x) internal pure returns (int24) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxx<======o=======>xxxxxxxxxxxxxxxxxxxx----
        if (x < int256(type(int24).min) || x > int256(type(int24).max)) {
            revert OverflowInt256ToInt24();
        }

        return int24(x);
    }

    function toUint(int256 x) internal pure returns (uint256) {
        // ----<==========================o===========================>----
        // ----xxxxxxxxxxxxxxxxxxxxxxxxxxxo===============================>
        if (x < 0) {
            revert OverflowInt256ToUint256();
        }

        return uint256(x);
    }

    function zero() internal pure returns (int256) {
        return int256(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI32 {
    error OverflowInt32ToUint32();

    function toUint(int32 x) internal pure returns (uint32) {
        // ----------------------<========o========>----------------------
        // ----------------------xxxxxxxxxo=========>----------------------
        if (x < 0) {
            revert OverflowInt32ToUint32();
        }

        return uint32(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI56 {
    error OverflowInt56ToInt24();

    function to24(int56 x) internal pure returns (int24) {
        // ----------------------<========o========>-----------------------
        // ----------------------xxx<=====o=====>xxx-----------------------
        if (x < int256(type(int24).min) || x > int256(type(int24).max)) {
            revert OverflowInt56ToInt24();
        }

        return int24(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastI64 {
    error OverflowInt64ToUint64();

    function toUint(int64 x) internal pure returns (uint64) {
        // ----------------------<========o========>----------------------
        // ----------------------xxxxxxxxxo=========>----------------------
        if (x < 0) {
            revert OverflowInt64ToUint64();
        }

        return uint64(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU128 {
    error OverflowUint128ToInt128();

    function to256(uint128 x) internal pure returns (uint256) {
        return uint256(x);
    }

    function toInt(uint128 x) internal pure returns (int128) {
        // -------------------------------o===============>----------------
        // ----------------<==============o==============>x----------------
        if (x > uint128(type(int128).max)) {
            revert OverflowUint128ToInt128();
        }

        return int128(x);
    }

    function toBytes32(uint128 x) internal pure returns (bytes32) {
        return bytes32(uint256(x));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU160 {
    function to256(uint160 x) internal pure returns (uint256) {
        return uint256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU256 {
    error OverflowUint256ToUint128();
    error OverflowUint256ToInt256();
    error OverflowUint256ToUint64();
    error OverflowUint256ToUint32();
    error OverflowUint256ToUint160();

    function to128(uint256 x) internal pure returns (uint128) {
        // -------------------------------o===============================>
        // -------------------------------o===============>xxxxxxxxxxxxxxxx
        if (x > type(uint128).max) {
            revert OverflowUint256ToUint128();
        }

        return uint128(x);
    }

    function to64(uint256 x) internal pure returns (uint64) {
        // -------------------------------o===============================>
        // -------------------------------o======>xxxxxxxxxxxxxxxxxxxxxxxxx
        if (x > type(uint64).max) {
            revert OverflowUint256ToUint64();
        }

        return uint64(x);
    }

    function to32(uint256 x) internal pure returns (uint32) {
        // -------------------------------o===============================>
        // -------------------------------o===>xxxxxxxxxxxxxxxxxxxxxxxxxxxx
        if (x > type(uint32).max) {
            revert OverflowUint256ToUint32();
        }

        return uint32(x);
    }

    function to160(uint256 x) internal pure returns (uint160) {
        // -------------------------------o===============================>
        // -------------------------------o==================>xxxxxxxxxxxxx
        if (x > type(uint160).max) {
            revert OverflowUint256ToUint160();
        }

        return uint160(x);
    }

    function toBytes32(uint256 x) internal pure returns (bytes32) {
        return bytes32(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        // -------------------------------o===============================>
        // ----<==========================o===========================>xxxx
        if (x > uint256(type(int256).max)) {
            revert OverflowUint256ToInt256();
        }

        return int256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU32 {
    error OverflowUint32ToInt32();

    function toInt(uint32 x) internal pure returns (int32) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint32(type(int32).max)) {
            revert OverflowUint32ToInt32();
        }

        return int32(x);
    }

    function to256(uint32 x) internal pure returns (uint256) {
        return uint256(x);
    }

    function to56(uint32 x) internal pure returns (uint56) {
        return uint56(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU56 {
    error OverflowUint56ToInt56();

    function toInt(uint56 x) internal pure returns (int56) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint56(type(int56).max)) {
            revert OverflowUint56ToInt56();
        }

        return int56(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title See SafeCast.sol.
 */
library SafeCastU64 {
    error OverflowUint64ToInt64();

    function toInt(uint64 x) internal pure returns (int64) {
        // -------------------------------o=========>----------------------
        // ----------------------<========o========>x----------------------
        if (x > uint64(type(int64).max)) {
            revert OverflowUint64ToInt64();
        }

        return int64(x);
    }

    function to256(uint64 x) internal pure returns (uint256) {
        return uint256(x);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import {SafeCastI256, SafeCastI128, SafeCastU256} from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

library MathUtil {
    using SafeCastI256 for int256;
    using SafeCastI128 for int128;
    using SafeCastU256 for uint256;

    function abs(int256 x) internal pure returns (uint256) {
        return x >= 0 ? x.toUint() : (-x).toUint();
    }

    function abs128(int128 x) internal pure returns (uint128) {
        return x >= 0 ? x.toUint() : (-x).toUint();
    }

    function max(int256 x, int256 y) internal pure returns (int256) {
        return x < y ? y : x;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? y : x;
    }

    function min(int256 x, int256 y) internal pure returns (int256) {
        return x < y ? x : y;
    }

    function min128(int128 x, int128 y) internal pure returns (int128) {
        return x < y ? x : y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    function min128(uint128 x, uint128 y) internal pure returns (uint128) {
        return x < y ? x : y;
    }

    function sameSide(int256 a, int256 b) internal pure returns (bool) {
        return (a == 0) || (b == 0) || (a > 0) == (b > 0);
    }

    function isSameSideReducing(int128 a, int128 b) internal pure returns (bool) {
        return sameSide(a, b) && abs(b) < abs(a);
    }

    function ceilDivide(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) return 0;
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title Initializable module
 */
library Initializable {
    // ------- Storage -------
    struct InitializableStorageData {
        bool initialized;
    }

    error AlreadyInitialized();
    error NotInitialized();

    /**
     * @dev Returns the account stored at the specified account id.
     */
    function getStorage() internal pure returns (InitializableStorageData storage data) {
        bytes32 slot = keccak256(abi.encode("io.infinex.InitializableStorage"));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data.slot := slot
        }
    }

    // ------- Implementation -------
    function initialize() internal {
        InitializableStorageData storage data = getStorage();

        // Note: We don't use onlyUninitialized here to save gas by preventing a double call to load().
        if (data.initialized) revert AlreadyInitialized();

        data.initialized = true;
    }

    modifier onlyInitialized() {
        if (!getStorage().initialized) revert NotInitialized();
        _;
    }

    modifier onlyUninitialized() {
        if (getStorage().initialized) revert AlreadyInitialized();
        _;
    }
}

//       c=<
//        |
//        |   ////\    1@2
//    @@  |  /___\**   @@@2			@@@@@@@@@@@@@@@@@@@@@@
//   @@@  |  |~L~ |*   @@@@@@		@@@  @@@@@        @@@@    @@@ @@@@    @@@  @@@@@@@@ @@@@ @@@@    @@@ @@@@@@@@@ @@@@   @@@@
//  @@@@@ |   \=_/8    @@@@1@@		@@@  @@@@@  @@@@  @@@@    @@@ @@@@@   @@@ @@@@@@@@@ @@@@ @@@@@  @@@@ @@@@@@@@@  @@@@ @@@@
// @@@@@@| _ /| |\__ @@@@@@@@2		@@@  @@@@@  @@@@  @@@@    @@@ @@@@@@@ @@@ @@@@      @@@@ @@@@@@ @@@@ @@@         @@@@@@@
// 1@@@@@@|\  \___/)   @@1@@@@@2	~~~  ~~~~~  @@@@  ~~@@    ~~~ ~~~~~~~~~~~ ~~~~      ~~~~ ~~~~~~~~~~~ ~@@          @@@@@
// 2@@@@@ |  \ \ / |     @@@@@@2	@@@  @@@@@  @@@@  @@@@    @@@ @@@@@@@@@@@ @@@@@@@@@ @@@@ @@@@@@@@@@@ @@@@@@@@@    @@@@@
// 2@@@@  |_  >   <|__    @@1@12	@@@  @@@@@  @@@@  @@@@    @@@ @@@@ @@@@@@ @@@@      @@@@ @@@@ @@@@@@ @@@         @@@@@@@
// @@@@  / _|  / \/    \   @@1@		@@@   @@@   @@@@  @@@@    @@@ @@@@  @@@@@ @@@@      @@@@ @@@@  @@@@@ @@@@@@@@@  @@@@ @@@@
//  @@ /  |^\/   |      |   @@1		@@@         @@@@  @@@@    @@@ @@@@    @@@ @@@@      @@@@ @@@    @@@@ @@@@@@@@@ @@@@   @@@@
//   /     / ---- \ \\\=    @@		@@@@@@@@@@@@@@@@@@@@@@
//   \___/ --------  ~~    @@@
//     @@  | |   | |  --   @@
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IWithdrawModule } from "src/interfaces/accounts/IWithdrawModule.sol";

import { SecurityModifiers } from "src/accounts/utils/SecurityModifiers.sol";
import { WithdrawUtil } from "src/accounts/utils/WithdrawUtil.sol";
import { Withdrawal } from "src/accounts/storage/Withdrawal.sol";
import { Recovery } from "src/accounts/storage/Recovery.sol";

import { Error } from "src/libraries/Error.sol";

contract WithdrawModule is IWithdrawModule, ReentrancyGuardUpgradeable, SecurityModifiers {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if the provided withdrawal address is allowlisted.
     * @param _withdrawalAddress The withdrawal address to check.
     * @return A boolean indicating if the withdrawal address is allowlisted.
     */
    function isAllowlistedWithdrawalAddress(address _withdrawalAddress) external view override returns (bool) {
        return Withdrawal._isAllowlistedWithdrawalAddress(_withdrawalAddress);
    }

    /**
     * @notice Returns the timestamp when the withdrawal address will be valid from
     * @param _withdrawalAddress The withdrawal address to check.
     * @return The timestamp when the withdrawal address was added to the allowlist.
     */
    function allowlistedWithdrawalAddressValidFrom(address _withdrawalAddress) external view returns (uint256) {
        return Withdrawal._allowlistedWithdrawalAddressValidFrom(_withdrawalAddress);
    }

    /**
     * @notice Retrieves the allowlist delay value.
     * @dev This function returns the value of the allowlist delay, which determines the time period
     * required for an address to be added to the allowlist before it can withdraw funds to it.
     * @return The allowlist delay value.
     */
    function getAllowlistDelay() external view returns (uint256) {
        return Withdrawal._getAllowlistDelay();
    }

    /*///////////////////////////////////////////////////////////////
                            MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the status of an allowlisted withdrawal address, this is only valid after the configured delay.
     * @dev Requires the sender to be the sudo key.
     * @param _allowlistedWithdrawalAddress The allowlisted withdrawal address
     * @param _status The status to set the allowlisted withdrawal address
     */
    function setAllowlistedWithdrawalAddress(address _allowlistedWithdrawalAddress, bool _status) external requiresSudoKeySender {
        if (_allowlistedWithdrawalAddress == address(0)) revert Error.NullAddress();
        Withdrawal._setAllowlistedWithdrawalAddress(_allowlistedWithdrawalAddress, _status);
    }

    /**
     * @notice Withdraws to an allowlisted address on this chain.
     * @param _withdrawalAddress The address to withdraw to.
     * @param _token The address of the token to withdraw.
     * @param _amount The amount to withdraw in 18 decimals, gets scaled to token decimals.
     * @dev Requires the sender to be the sudo key.
     */
    function withdrawERC20ToAllowlistedAddress(address _withdrawalAddress, address _token, uint256 _amount)
        external
        requiresSudoKeySender
        nonReentrant
    {
        _validateWithdrawalAddressAllowlisted(_withdrawalAddress);
        _withdrawERC20ToAddress(_withdrawalAddress, _token, _amount);
    }

    /**
     * @notice Withdraws an ERC721 token to an allowlisted address.
     * @param _withdrawalAddress The address to withdraw the token to.
     * @param _token The address of the ERC721 token to withdraw.
     * @param _tokenId The ID of the ERC721 token to withdraw.
     * @dev Requires the sender to be the sudo key.
     */
    function withdrawERC721ToAllowlistedAddress(address _withdrawalAddress, address _token, uint256 _tokenId)
        external
        requiresSudoKeySender
        nonReentrant
    {
        _validateWithdrawalAddressAllowlisted(_withdrawalAddress);
        _withdrawERC721ToAddress(_withdrawalAddress, _token, _tokenId);
    }

    /**
     * @notice Withdraws Ether to an address.
     * @param _withdrawalAddress The address to withdraw the token to.
     * @param _amount The amount of the token to withdraw.
     * @dev Requires the sender to be the sudo key.
     */
    function withdrawEtherToAllowlistedAddress(address _withdrawalAddress, uint256 _amount)
        external
        requiresSudoKeySender
        nonReentrant
    {
        _validateWithdrawalAddressAllowlisted(_withdrawalAddress);
        _withdrawEtherToAddress(_withdrawalAddress, _amount);
    }

    /**
     * @notice Withdraws specified amount of ERC1155 tokens to an allowlisted address.
     * @param _withdrawalAddress The address that the token will be withdrawn to.
     * @param _token The address of the ERC1155 token to withdraw.
     * @param _tokenId The ID of the ERC1155 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     * @param _data Data to send with the transfer.
     * @dev Requires the sender to be the sudo key.
     */
    function withdrawERC1155ToAllowlistedAddress(
        address _withdrawalAddress,
        address _token,
        uint256 _tokenId,
        uint256 _amount,
        bytes calldata _data
    ) external requiresSudoKeySender nonReentrant {
        _validateWithdrawalAddressAllowlisted(_withdrawalAddress);
        _withdrawERC1155ToAddress(_withdrawalAddress, _token, _tokenId, _amount, _data);
    }

    /**
     * @notice Withdraws specified batch of ERC1155 tokens to an allowlisted address.
     * @param _withdrawalAddress The address that the token will be withdrawn to.
     * @param _token The address of the ERC1155 token to withdraw.
     * @param _tokenIds The IDs of the ERC1155 tokens to withdraw.
     * @param _amounts The amounts of tokens to withdraw.
     * @param _data Data to send with the transfer.
     * @dev Requires the sender to be the sudo key.
     */
    function withdrawERC1155BatchToAllowlistedAddress(
        address _withdrawalAddress,
        address _token,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external requiresSudoKeySender nonReentrant {
        _validateWithdrawalAddressAllowlisted(_withdrawalAddress);
        _withdrawERC1155BatchToAddress(_withdrawalAddress, _token, _tokenIds, _amounts, _data);
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    function _validateWithdrawalAddressAllowlisted(address _withdrawalAddress) internal view {
        if (
            !Withdrawal._isAllowlistedWithdrawalAddress(_withdrawalAddress)
                && _withdrawalAddress != Recovery._getFundsRecoveryAddress()
        ) revert Error.InvalidWithdrawalAddress(_withdrawalAddress);
    }

    /**
     * @notice Withdraws Ether to an address.
     * @param _withdrawalAddress The address to withdraw Ether to.
     * @param _amount The amount of Ether to withdraw.
     */
    function _withdrawEtherToAddress(address _withdrawalAddress, uint256 _amount) internal {
        if (_withdrawalAddress == address(0)) revert Error.NullAddress();
        if (_amount == 0) revert Error.ZeroValue();
        WithdrawUtil._withdrawEther(_withdrawalAddress, _amount);
    }

    /**
     * @notice Withdraws to an address.
     * @param _withdrawalAddress The address to withdraw to.
     * @param _token The address of the token.
     * @param _amount The amount to withdraw in 18 decimals, gets scaled to decimals of the token..
     */
    function _withdrawERC20ToAddress(address _withdrawalAddress, address _token, uint256 _amount) internal {
        if (_amount == 0) revert Error.ZeroValue();
        if (_withdrawalAddress == address(0)) revert Error.NullAddress();
        if (_token == address(0)) revert Error.NullAddress();
        WithdrawUtil._withdrawERC20(_token, _withdrawalAddress, _amount);
    }

    /**
     * @notice Withdraws an ERC721 token to an address.
     * @param _withdrawalAddress The address that the token will be withdrawn to.
     * @param _token The address of the ERC721 token to withdraw.
     * @param _tokenId The ID of the ERC721 token to withdraw.
     */
    function _withdrawERC721ToAddress(address _withdrawalAddress, address _token, uint256 _tokenId) internal {
        if (_withdrawalAddress == address(0)) revert Error.NullAddress();
        if (_token == address(0)) revert Error.NullAddress();
        WithdrawUtil._withdrawERC721(_withdrawalAddress, _token, _tokenId);
    }

    /**
     * @notice Withdraws an amount of ERC1155 tokens to a specified address.
     * @param _withdrawalAddress The address to which the tokens will be withdrawn.
     * @param _token The address of the ERC1155 token to withdraw.
     * @param _tokenId The ID of the ERC1155 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     * @param _data Data to send with the transfer.
     */
    function _withdrawERC1155ToAddress(
        address _withdrawalAddress,
        address _token,
        uint256 _tokenId,
        uint256 _amount,
        bytes calldata _data
    ) internal {
        WithdrawUtil._withdrawERC1155(_withdrawalAddress, _token, _tokenId, _amount, _data);
    }

    /**
     * @notice Withdraws batched ERC1155 tokens to a specified address.
     * @param _withdrawalAddress The address to which the tokens will be withdrawn.
     * @param _token The address of the ERC1155 token to withdraw.
     * @param _tokenIds The IDs of the ERC1155 token to withdrawn.
     * @param _amounts The amount of tokens to withdraw.
     * @param _data Data to send with the transfer.
     */
    function _withdrawERC1155BatchToAddress(
        address _withdrawalAddress,
        address _token,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) internal {
        WithdrawUtil._withdrawERC1155Batch(_withdrawalAddress, _token, _tokenIds, _amounts, _data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { IInfinexProtocolConfigBeacon } from "src/interfaces/beacons/IInfinexProtocolConfigBeacon.sol";

/**
 * @title Account storage struct
 */
library Account {
    struct InitializableStorage {
        uint64 _initialized;
        bool _initializing;
    }

    struct Data {
        address infinexProtocolConfigBeacon; // Address of the Infinex Protocol Config Beacon
        uint256 referralTokenId; // ID of the referral token
        bool upgrading; // Flag to indicate if the account is upgrading
    }

    /*///////////////////////////////////////////////////////////////
                    			EVENTS / ERRORS
    ///////////////////////////////////////////////////////////////*/

    event Initialized(uint64 version);

    error InvalidInitialization();

    /*///////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the account stored at the specified account id.
     */
    function getStorage() internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("io.infinex.AccountStorage"));
        assembly {
            data.slot := s
        }
    }

    /**
     * @notice Get the Infinex Protocol Config
     * @return The Infinex Protocol Config Beacon
     */
    function _infinexProtocolConfig() internal view returns (IInfinexProtocolConfigBeacon) {
        Data storage data = getStorage();
        return IInfinexProtocolConfigBeacon(data.infinexProtocolConfigBeacon);
    }

    /**
     * @notice Get the referral token ID
     * @return The referral token ID
     */
    function _referralTokenId() internal view returns (uint256) {
        Data storage data = getStorage();
        return data.referralTokenId;
    }

    /**
     * @notice Get the upgrading flag
     * @return The upgrading flag
     */
    function _upgrading() internal view returns (bool) {
        Data storage data = getStorage();
        return data.upgrading;
    }

    /*///////////////////////////////////////////////////////////////
                                MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the initialized version of the contract.
     * @param _version The initialized version as a uint64 value.
     */
    function _setInitializedVersion(uint64 _version) internal {
        InitializableStorage storage initializableStorage;
        // storage slot comes from OZ proxy/utils/Initializable.sol
        bytes32 INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00; //#gitleaks:allow
        assembly {
            initializableStorage.slot := INITIALIZABLE_STORAGE
        }
        initializableStorage._initialized = _version;

        emit Initialized(_version);
    }

    /**
     * @notice Set the upgrading flag for the account.
     * @param _isUpgrading The value to set for the upgrading flag.
     */
    function _setUpgrading(bool _isUpgrading) internal {
        Data storage data = getStorage();
        data.upgrading = _isUpgrading;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title Bridging related storage struct and functions
 */
library Bridge {
    struct Data {
        // Parameters for interacting with USDC and the Circle Bridge
        address circleBridge;
        address circleMinter;
        address USDC;
        address wormholeCircleBridge;
        uint32 defaultDestinationCCTPDomain;
        uint16 defaultDestinationWormholeChainId;
    }

    /**
     * @dev Returns the account stored at the specified account id.
     */
    function getStorage() internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("io.infinex.Bridge"));
        assembly {
            data.slot := s
        }
    }

    /**
     * @dev Returns the address of the USDC token.
     */
    function _USDC() internal view returns (address) {
        return getStorage().USDC;
    }

    /**
     * @dev Returns the address of the Circle Bridge contract.
     */
    // slither-disable-next-line dead-code
    function _circleBridge() internal view returns (address) {
        return getStorage().circleBridge;
    }

    /**
     * @dev Returns the address of the Circle Minter contract.
     * The minter contract stores the maximum amount of tokens that can be minted or burned.
     * The contract is responsible for minting and burning tokens as part of a bridging transaction.
     */
    // slither-disable-next-line dead-code
    function _circleMinter() internal view returns (address) {
        return getStorage().circleMinter;
    }

    /**
     * @dev Returns the address of the Wormhole Circle Bridge contract.
     */
    function _wormholeCircleBridge() internal view returns (address) {
        return getStorage().wormholeCircleBridge;
    }

    /**
     * @dev Returns the CCTP domain of the default destination chain.
     */
    // slither-disable-next-line dead-code
    function _defaultDestinationCCTPDomain() internal view returns (uint32) {
        return getStorage().defaultDestinationCCTPDomain;
    }

    /**
     * @dev Returns the Wormhole chain id of the default destination chain.
     */
    // slither-disable-next-line dead-code
    function _defaultDestinationWormholeChainId() internal view returns (uint16) {
        return getStorage().defaultDestinationWormholeChainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

library EIP712 {
    bytes32 private constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @custom:storage-location erc7201:openzeppelin.storage.EIP712
    struct EIP712Storage {
        /// @custom:oz-renamed-from _HASHED_NAME
        bytes32 _hashedName;
        /// @custom:oz-renamed-from _HASHED_VERSION
        bytes32 _hashedVersion;
        string _name;
        string _version;
    }

    function _getEIP712Storage() private pure returns (EIP712Storage storage data) {
        bytes32 s = keccak256(abi.encode("io.infinex.EIP712"));
        assembly {
            data.slot := s
        }
    }

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal {
        EIP712Storage storage $ = _getEIP712Storage();
        $._name = name;
        $._version = version;

        // Reset prior values in storage if upgrading
        $._hashedName = 0;
        $._hashedVersion = 0;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator();
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash(), block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return MessageHashUtils.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {IERC-5267}.
     */
    function eip712Domain()
        internal
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        EIP712Storage storage $ = _getEIP712Storage();
        // If the hashed name and version in storage are non-zero, the contract hasn't been properly initialized
        // and the EIP712 domain is not reliable, as it will be missing name and version.
        // solhint-disable-next-line gas-custom-errors
        require($._hashedName == 0 && $._hashedVersion == 0, "EIP712: Uninitialized");

        return (
            hex"0f", // 01111
            _EIP712Name(),
            _EIP712Version(),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }

    /**
     * @dev The name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712Name() internal view returns (string memory) {
        EIP712Storage storage $ = _getEIP712Storage();
        return $._name;
    }

    /**
     * @dev The version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712Version() internal view returns (string memory) {
        EIP712Storage storage $ = _getEIP712Storage();
        return $._version;
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: In previous versions this function was virtual. In this version you should override `_EIP712Name` instead.
     */
    function _EIP712NameHash() internal view returns (bytes32) {
        EIP712Storage storage $ = _getEIP712Storage();
        string memory name = _EIP712Name();
        if (bytes(name).length > 0) {
            return keccak256(bytes(name));
        } else {
            // If the name is empty, the contract may have been upgraded without initializing the new storage.
            // We return the name hash in storage if non-zero, otherwise we assume the name is empty by design.
            bytes32 hashedName = $._hashedName;
            if (hashedName != 0) {
                return hashedName;
            } else {
                return keccak256("");
            }
        }
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: In previous versions this function was virtual. In this version you should override `_EIP712Version` instead.
     */
    function _EIP712VersionHash() internal view returns (bytes32) {
        EIP712Storage storage $ = _getEIP712Storage();
        string memory version = _EIP712Version();
        if (bytes(version).length > 0) {
            return keccak256(bytes(version));
        } else {
            // If the version is empty, the contract may have been upgraded without initializing the new storage.
            // We return the version hash in storage if non-zero, otherwise we assume the version is empty by design.
            bytes32 hashedVersion = $._hashedVersion;
            if (hashedVersion != 0) {
                return hashedVersion;
            } else {
                return keccak256("");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title Recovery related storage struct and functions
 */
library Recovery {
    struct Data {
        address fundsRecoveryAddress;
    }

    /*///////////////////////////////////////////////////////////////
                    			EVENTS
    ///////////////////////////////////////////////////////////////*/

    event FundsRecoveryAddressSet(address fundsRecoveryAddress);

    /*
     * @dev Returns the data at the specified 
     */
    function getStorage() internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("io.infinex.Recovery"));
        assembly {
            data.slot := s
        }
    }

    /*///////////////////////////////////////////////////////////////
                                    VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice gets the funds recovery address.
     * @return the recovery address for the account.
     */
    function _getFundsRecoveryAddress() internal view returns (address) {
        Data storage data = getStorage();
        return data.fundsRecoveryAddress;
    }

    /*///////////////////////////////////////////////////////////////
                                MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows the setting of the funds recovery address.
     * @param _fundsRecoveryAddress is the address that is used for funds recovery.
     */
    function _setFundsRecoveryAddress(address _fundsRecoveryAddress) internal {
        Data storage data = getStorage();
        emit FundsRecoveryAddressSet(_fundsRecoveryAddress);
        data.fundsRecoveryAddress = _fundsRecoveryAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import { Error } from "src/libraries/Error.sol";

/**
 * @title Security keys storage and functions
 */
library SecurityKeys {
    using MessageHashUtils for bytes32;

    // slither-disable-next-line constable-states,unused-state
    bytes32 internal constant _SIGNATURE_REQUEST_TYPEHASH = keccak256(
        "Request(address _address,address _address2,uint256 _uint256,bytes32 _nonce,uint32 _uint32,bool _bool,bytes4 _selector)"
    );

    struct Data {
        mapping(bytes32 => bool) nonces; // Mapping of nonces
        mapping(address => bool) operationKeys;
        mapping(address => bool) recoveryKeys;
        mapping(address => bool) sudoKeys;
        uint16 sudoKeysCounter;
    }

    /*///////////////////////////////////////////////////////////////
                    			EVENTS / ERRORS
    ///////////////////////////////////////////////////////////////*/

    event NonceConsumed(bytes32 nonce);
    event OperationKeyStatusSet(address operationKey, bool isValid);
    event RecoveryKeyStatusSet(address recoveryKey, bool isValid);
    event SudoKeyStatusSet(address sudoKey, bool isValid);

    /**
     * @dev Returns the account stored at the specified account id.
     */
    function getStorage() internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("io.infinex.SecurityKeys"));
        assembly {
            data.slot := s
        }
    }

    /*///////////////////////////////////////////////////////////////
                                    VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if the provided operation key is valid
     * @param _operationKey The operation key to check
     * @return A boolean indicating if the operation key is valid
     */
    function _isValidOperationKey(address _operationKey) internal view returns (bool) {
        Data storage data = getStorage();
        return data.operationKeys[_operationKey];
    }

    /**
     * @notice Check if the provided recovery key is valid
     * @param _recoveryKey The recovery key to check
     * @return A boolean indicating if the recovery key is valid
     */
    function _isValidRecoveryKey(address _recoveryKey) internal view returns (bool) {
        Data storage data = getStorage();
        return data.recoveryKeys[_recoveryKey];
    }

    /**
     * @notice Check if the provided sudo key is valid
     * @param _sudoKey The sudo key to check
     * @return A boolean indicating if the sudo key is valid
     */
    function _isValidSudoKey(address _sudoKey) internal view returns (bool) {
        Data storage data = getStorage();
        return data.sudoKeys[_sudoKey];
    }

    /**
     * @notice Check if the provided nonce is valid
     * @param _nonce The nonce to check
     * @return A boolean indicating if the nonce is valid
     */
    function _isValidNonce(bytes32 _nonce) internal view returns (bool) {
        Data storage data = getStorage();
        return !data.nonces[_nonce];
    }

    /*///////////////////////////////////////////////////////////////
                                MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Set an operation key for the account
     * @param _operationKey The operation key address to be set
     * @param _isValid Whether the key is to be set as valid or invalid
     */
    function _setOperationKeyStatus(address _operationKey, bool _isValid) internal {
        Data storage data = getStorage();
        if (_operationKey == address(0)) revert Error.NullAddress();
        if (data.operationKeys[_operationKey]) {
            if (_isValid) revert Error.KeyAlreadyValid();
        } else {
            if (!_isValid) revert Error.KeyAlreadyInvalid();
        }
        emit OperationKeyStatusSet(_operationKey, _isValid);
        data.operationKeys[_operationKey] = _isValid;
    }

    /**
     * @notice Set a new recovery key for the account
     * @param _recoveryKey The recovery key address to be set
     * @param _isValid Whether the key is to be set as valid or invalid
     */
    function _setRecoveryKeyStatus(address _recoveryKey, bool _isValid) internal {
        Data storage data = getStorage();
        if (_recoveryKey == address(0)) revert Error.NullAddress();
        if (data.recoveryKeys[_recoveryKey]) {
            if (_isValid) revert Error.KeyAlreadyValid();
        } else {
            if (!_isValid) revert Error.KeyAlreadyInvalid();
        }
        emit RecoveryKeyStatusSet(_recoveryKey, _isValid);
        data.recoveryKeys[_recoveryKey] = _isValid;
    }

    /**
     * @notice Set a sudo key for the account
     * @param _sudoKey The sudo key address to be set
     * @param _isValid Whether the key is to be set as valid or invalid
     */
    function _setSudoKeyStatus(address _sudoKey, bool _isValid) internal {
        Data storage data = getStorage();
        if (_sudoKey == address(0)) revert Error.NullAddress();
        if (data.sudoKeys[_sudoKey]) {
            if (_isValid) revert Error.KeyAlreadyValid();
            if (data.sudoKeysCounter == 1) revert Error.CannotRemoveLastKey();
            --data.sudoKeysCounter;
        } else {
            if (!_isValid) revert Error.KeyAlreadyInvalid();
            ++data.sudoKeysCounter;
        }
        emit SudoKeyStatusSet(_sudoKey, _isValid);
        data.sudoKeys[_sudoKey] = _isValid;
    }

    /**
     * @notice Consumes a nonce, marking it as used
     * @param _nonce The nonce to consume
     * @dev Reverts if nonce has already been consumed.
     */
    function _consumeNonce(bytes32 _nonce) internal returns (bool) {
        Data storage data = getStorage();
        if (data.nonces[_nonce]) revert Error.InvalidNonce(_nonce);
        emit NonceConsumed(_nonce);
        data.nonces[_nonce] = true;
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { Error } from "src/libraries/Error.sol";

/**
 * @title Withdrawal related storage struct and functions
 */
library Withdrawal {
    struct Data {
        mapping(address => uint256) allowlistedWithdrawalAddressesValidFrom; // Mapping of allowlisted withdrawal addresses and the date they were added.
        uint256 allowlistDelay; // The delay before an address can be removed from the allowlist.
    }

    /*///////////////////////////////////////////////////////////////
                                    EVENTS
    ///////////////////////////////////////////////////////////////*/

    event AllowlistedWithdrawAddressSetWithDelay(address indexed withdrawalAddress, uint256 validFrom);
    event AllowlistedWithdrawAddressRemoved(address indexed withdrawalAddress);

    /**
     * @dev Returns the stored at the specified account id.
     */
    function getStorage() internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("io.infinex.Withdraw"));
        assembly {
            data.slot := s
        }
    }

    /*///////////////////////////////////////////////////////////////
                                    VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if the provided withdrawal address is allowlisted.
     * @param _withdrawalAddress The withdrawal address to check.
     * @return A boolean indicating if the withdrawal address is allowlisted.
     */
    function _isAllowlistedWithdrawalAddress(address _withdrawalAddress) internal view returns (bool) {
        Data storage data = getStorage();
        if (data.allowlistedWithdrawalAddressesValidFrom[_withdrawalAddress] == 0) {
            return false;
        }
        return data.allowlistedWithdrawalAddressesValidFrom[_withdrawalAddress] < block.timestamp;
    }

    /**
     * @notice Returns the timestamp when the withdrawal address will be valid from
     * @param _withdrawalAddress The withdrawal address to check.
     * @return validFrom The seconds since epoch when the address will be a valid allowlisted address.
     */
    function _allowlistedWithdrawalAddressValidFrom(address _withdrawalAddress) internal view returns (uint256 validFrom) {
        Data storage data = getStorage();
        return data.allowlistedWithdrawalAddressesValidFrom[_withdrawalAddress];
    }

    /**
     * @notice Retrieves the allowlist delay value from the storage.
     * @return The allowlist delay value as a uint64.
     */
    function _getAllowlistDelay() internal view returns (uint256) {
        Data storage data = getStorage();
        return data.allowlistDelay;
    }

    /*///////////////////////////////////////////////////////////////
                                MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the status of an allowlisted withdrawal address.
     * @param _allowlistedWithdrawalAddress The allowlisted withdrawal address.
     * @param _status The status to set the allowlisted withdrawal address.
     */
    function _setAllowlistedWithdrawalAddress(address _allowlistedWithdrawalAddress, bool _status) internal {
        Data storage data = getStorage();

        if (_status) {
            if (data.allowlistedWithdrawalAddressesValidFrom[_allowlistedWithdrawalAddress] > 0) {
                revert Error.AddressAlreadySet();
            }
            uint256 validFrom = block.timestamp + data.allowlistDelay;
            emit AllowlistedWithdrawAddressSetWithDelay(_allowlistedWithdrawalAddress, validFrom);
            data.allowlistedWithdrawalAddressesValidFrom[_allowlistedWithdrawalAddress] = validFrom;
        } else {
            emit AllowlistedWithdrawAddressRemoved(_allowlistedWithdrawalAddress);
            data.allowlistedWithdrawalAddressesValidFrom[_allowlistedWithdrawalAddress] = 0;
        }
    }

    /**
     * @notice Sets the delay for the allowlist.
     * @param _delay The delay in seconds for the allowlist.
     */
    function _setAllowlistDelay(uint64 _delay) internal {
        Data storage data = getStorage();
        data.allowlistDelay = _delay;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library AccountConstants {
    uint256 public constant MAX_WITHDRAWAL_FEE = 50;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract RequestTypes {
    struct Request {
        address _address;
        address _address2;
        uint256 _uint256;
        bytes32 _nonce;
        uint32 _uint32;
        bool _bool;
        bytes4 _selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import { RequestTypes } from "src/accounts/utils/RequestTypes.sol";

import { ERC2771Context } from "src/forwarder/ERC2771Context.sol";
import { Account } from "src/accounts/storage/Account.sol";
import { EIP712 } from "src/accounts/storage/EIP712.sol";
import { SecurityKeys } from "src/accounts/storage/SecurityKeys.sol";

import { Error } from "src/libraries/Error.sol";

contract SecurityModifiers {
    using MessageHashUtils for bytes32;

    /*///////////////////////////////////////////////////////////////
                    			EVENTS / ERRORS
    ///////////////////////////////////////////////////////////////*/

    event PayloadProcessed(RequestTypes.Request request, bytes signature);

    /*///////////////////////////////////////////////////////////////
                            SECURITY CHECK MODIFIERS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Modifier to check if the request requires an sudo key.
     * @param _request The request data.
     * @param _signature The sudo key signature to process the transaction.
     */
    modifier requiresSudoKey(RequestTypes.Request calldata _request, bytes calldata _signature) {
        if (_request._selector != msg.sig) {
            revert Error.InvalidRequest();
        }
        bytes32 messageHash = EIP712._hashTypedDataV4(keccak256(abi.encode(SecurityKeys._SIGNATURE_REQUEST_TYPEHASH, _request)));

        address sudoKey = ECDSA.recover(messageHash, _signature);
        if (!SecurityKeys._isValidSudoKey(sudoKey)) {
            revert Error.InvalidKeySignature(sudoKey);
        }

        SecurityKeys._consumeNonce(_request._nonce);
        emit PayloadProcessed(_request, _signature);

        _;
    }

    /**
     * @notice Modifier to check if the sender is an sudo key.
     */
    modifier requiresSudoKeySender() {
        if (!SecurityKeys._isValidSudoKey(ERC2771Context._msgSender())) {
            revert Error.InvalidKeySignature(ERC2771Context._msgSender());
        }

        _;
    }

    /**
     * @notice Modifier to check if the sender is a sudo or operation key.
     * If not, it reverts with an error message.
     * @dev Update isAuthorizedOperationsParty() in AccountUtilsModule when
     * this modifier is updated.
     */
    modifier requiresAuthorizedOperationsParty() {
        address sender = ERC2771Context._msgSender();
        if (!SecurityKeys._isValidSudoKey(sender) && !SecurityKeys._isValidOperationKey(sender)) {
            revert Error.InvalidKeySignature(sender);
        }
        _;
    }

    /**
     * @notice Modifier to check if the sender is an sudo key, a recovery key or a trusted recovery keeper.
     * If not, it reverts with an error message.
     * @dev Update isAuthorizedRecoveryParty() in AccountUtilsModule when
     * this modifier is updated.
     */
    modifier requiresAuthorizedRecoveryParty() {
        address sender = ERC2771Context._msgSender();
        if (
            !SecurityKeys._isValidSudoKey(sender) && !SecurityKeys._isValidRecoveryKey(sender)
                && !Account._infinexProtocolConfig().isTrustedRecoveryKeeper(sender)
        ) {
            revert Error.InvalidKeySignature(sender);
        }
        _;
    }

    /**
     * @notice Modifier to check if the sender is a trusted keeper for recovery.
     * If not, reverts with an error message.
     */
    modifier requiresTrustedRecoveryKeeper() {
        if (!Account._infinexProtocolConfig().isTrustedRecoveryKeeper(ERC2771Context._msgSender())) {
            revert Error.InvalidKeySignature(ERC2771Context._msgSender());
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import { MathUtil } from "@synthetixio/perps-market/contracts/utils/MathUtil.sol";

import { IInfinexProtocolConfigBeacon } from "src/interfaces/beacons/IInfinexProtocolConfigBeacon.sol";

import { Account } from "src/accounts/storage/Account.sol";
import { Bridge } from "src/accounts/storage/Bridge.sol";

import { BridgeIntegrations } from "src/integrations/BridgeIntegrations.sol";
import { DecimalScaling } from "src/libraries/DecimalScaling.sol";

import { AccountConstants } from "src/accounts/utils/AccountConstants.sol";

import { Error } from "src/libraries/Error.sol";

library WithdrawUtil {
    event WithdrawalFeeUSDCTaken(address token, uint256 amount);
    event WithdrawalToDomainStarted(
        address indexed token, address indexed addressTo, uint32 indexed destinationDomain, uint256 amount
    );
    event WithdrawalEtherExecuted(address indexed withdrawalAddress, uint256 amount);
    event WithdrawalERC20Executed(address indexed token, address indexed withdrawalAddress, uint256 amount);
    event WithdrawalERC721Executed(address indexed token, address indexed withdrawalAddress, uint256 tokenId);
    event WithdrawalERC1155Executed(
        address indexed token, address indexed withdrawalAddress, uint256 tokenId, uint256 amount, bytes data
    );
    event WithdrawalERC1155BatchExecuted(
        address indexed token, address indexed withdrawalAddress, uint256[] tokenIds, uint256[] amounts, bytes data
    );

    /*///////////////////////////////////////////////////////////////
                                            INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Withdraws ether to a specified address
     * @param _withdrawalAddress The address to which the ether will be withdrawn
     * @param _amount The amount of ether to be withdrawn
     */
    function _withdrawEther(address _withdrawalAddress, uint256 _amount) internal {
        _takeUSDCWithdrawalFee();
        emit WithdrawalEtherExecuted(_withdrawalAddress, _amount);
        (bool success,) = _withdrawalAddress.call{ value: _amount }("");
        if (!success) revert Error.ETHTransferFailed();
    }

    /**
     * @notice Withdraws USDC to a specified address on the specified chain via CCTP
     * @dev This function takes USDC's decimals 'amount' and scales to target token amount
     * @param _amount The amount of tokens to be withdrawn in USDC's decimals
     * @param _addressTo The destination chain address to which the funds will be withdrawn
     * @param _destinationDomain The CCTP domain id of the destination chain
     * @return amountAfterFee The amount after the withdrawal fee has been taken
     */
    function _withdrawUSDCToChain(uint256 _amount, address _addressTo, uint32 _destinationDomain)
        internal
        returns (uint256 amountAfterFee)
    {
        address USDC = Bridge._USDC();
        uint256 balance = IERC20(USDC).balanceOf(address(this));
        if (balance < _amount) revert Error.InsufficientBalance();

        /// @dev take the withdrawal fee, takes the amount in the target token decimals
        // The amount returned is scaled to the target token
        amountAfterFee = _amount - _takeUSDCWithdrawalFee();
        emit WithdrawalToDomainStarted(USDC, _addressTo, _destinationDomain, amountAfterFee);

        // Call the bridge with the necessary approvals
        BridgeIntegrations._CCTPBridgeUSDC(amountAfterFee, bytes32(uint256(uint160(_addressTo))), _destinationDomain);
    }

    /**
     * @notice Withdraws a specified amount of an ERC20 token to a destination address.
     * @param _token The address of the token to be withdrawn.
     * @param _withdrawalAddress The address to which the token will be withdrawn.
     * @param _amount The amount of tokens to be withdrawn in 18 decimals.
     */
    function _withdrawERC20(address _token, address _withdrawalAddress, uint256 _amount) internal {
        // amount is in 18 decimals, scale to token decimals
        uint256 scaledAmount = DecimalScaling.scaleTo(_amount, IERC20Metadata(_token).decimals());
        uint256 amountAfterFee = scaledAmount;
        // take the fee
        uint256 fee = _takeUSDCWithdrawalFee();
        // if withdrawing USDC, fee is taken from the withdraw amount
        if (_token == Bridge._USDC()) {
            amountAfterFee = scaledAmount - fee;
        }
        emit WithdrawalERC20Executed(_token, _withdrawalAddress, amountAfterFee);
        SafeERC20.safeTransfer(IERC20(_token), _withdrawalAddress, amountAfterFee);
    }

    /**
     * @notice Withdraws ERC721 tokens from the contract.
     * @param _withdrawalAddress The address that the token will be withdrawn to.
     * @param _token The address of the ERC721 token to withdraw.
     * @param _tokenId The ID of the ERC721 token to withdraw.
     */
    function _withdrawERC721(address _withdrawalAddress, address _token, uint256 _tokenId) internal {
        emit WithdrawalERC721Executed(_token, _withdrawalAddress, _tokenId);
        IERC721(_token).safeTransferFrom(address(this), _withdrawalAddress, _tokenId);
    }

    /**
     * @notice Takes the withdrawal fee from the withdrawal amount and transfers it to the Revenue Pool.
     * @return fee The amount of the withdrawal fee taken
     */
    function _takeUSDCWithdrawalFee() internal returns (uint256 fee) {
        IInfinexProtocolConfigBeacon infoBeacon = Account._infinexProtocolConfig();
        /// @dev get the withdrawal fee. User is protected by the hardcoded limit of $USDC 50.
        /// @dev fees are in usdc, regardless of the token withdrawn
        address USDC = Bridge._USDC();
        uint256 decimals = IERC20Metadata(USDC).decimals();
        uint256 balance = IERC20(USDC).balanceOf(address(this));
        fee = MathUtil.min(AccountConstants.MAX_WITHDRAWAL_FEE * (10 ** decimals), infoBeacon.withdrawalFeeUSDC());
        if (balance < fee) revert Error.InsufficientBalanceForFee(balance, fee);
        emit WithdrawalFeeUSDCTaken(USDC, fee);
        SafeERC20.safeTransfer(IERC20(USDC), infoBeacon.revenuePool(), fee);
    }

    /**
     * @notice Withdraws an amount of ERC1155 tokens to a specified address.
     * @param _withdrawalAddress The address to which the tokens will be withdrawn.
     * @param _token The address of the ERC1155 token to withdraw.
     * @param _tokenId The ID of the ERC1155 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     * @param _data Data to send with the transfer.
     */
    function _withdrawERC1155(address _withdrawalAddress, address _token, uint256 _tokenId, uint256 _amount, bytes calldata _data)
        internal
    {
        emit WithdrawalERC1155Executed(_token, _withdrawalAddress, _tokenId, _amount, _data);
        IERC1155(_token).safeTransferFrom(address(this), _withdrawalAddress, _tokenId, _amount, _data);
    }

    /**
     * @notice Withdraws batched ERC1155 tokens to a specified address.
     * @param _withdrawalAddress The address to which the tokens will be withdrawn.
     * @param _token The address of the ERC1155 token to withdraw.
     * @param _tokenIds The IDs of the ERC1155 token to withdrawn.
     * @param _amounts The amounts of tokens to withdraw.
     * @param _data Data to send with the transfer.
     */
    function _withdrawERC1155Batch(
        address _withdrawalAddress,
        address _token,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) internal {
        emit WithdrawalERC1155BatchExecuted(_token, _withdrawalAddress, _tokenIds, _amounts, _data);
        IERC1155(_token).safeBatchTransferFrom(address(this), _withdrawalAddress, _tokenIds, _amounts, _data);
    }
}

// SPDX-License-Identifier: MIT
// Originally sourced from OpenZeppelin Contracts (last updated v4.9.3) (metatx/ERC2771Context.sol)
pragma solidity ^0.8.21;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Initializable } from "src/Initializable.sol";

import { Error } from "src/libraries/Error.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
library ERC2771Context {
    event TrustedForwarderAdded(address forwarder);
    event TrustedForwarderRemoved(address forwarder);

    struct Data {
        EnumerableSet.AddressSet trustedForwarders;
    }

    function getStorage() internal pure returns (Data storage data) {
        bytes32 slot = keccak256(abi.encode("io.infinex.ERC2771Context"));
        assembly {
            data.slot := slot
        }
    }

    function initialize(address initialTrustedForwarder) internal {
        Initializable.initialize();

        EnumerableSet.add(getStorage().trustedForwarders, initialTrustedForwarder);
    }

    function isTrustedForwarder(address forwarder) internal view returns (bool) {
        return EnumerableSet.contains(getStorage().trustedForwarders, forwarder);
    }

    function trustedForwarder() internal view returns (address[] memory) {
        return EnumerableSet.values(getStorage().trustedForwarders);
    }

    function _addTrustedForwarder(address forwarder) internal returns (bool) {
        if (EnumerableSet.add(getStorage().trustedForwarders, forwarder)) {
            emit TrustedForwarderAdded(forwarder);
            return true;
        } else {
            revert Error.AlreadyExists();
        }
    }

    function _removeTrustedForwarder(address forwarder) internal returns (bool) {
        if (EnumerableSet.remove(getStorage().trustedForwarders, forwarder)) {
            emit TrustedForwarderRemoved(forwarder);
            return true;
        } else {
            revert Error.DoesNotExist();
        }
    }

    function _msgSender() internal view returns (address) {
        uint256 calldataLength = msg.data.length;
        uint256 contextSuffixLength = _contextSuffixLength();
        if (isTrustedForwarder(msg.sender) && calldataLength >= contextSuffixLength) {
            return address(bytes20(msg.data[calldataLength - contextSuffixLength:]));
        } else {
            return msg.sender;
        }
    }

    // slither-disable-start dead-code
    function _msgData() internal view returns (bytes calldata) {
        uint256 calldataLength = msg.data.length;
        uint256 contextSuffixLength = _contextSuffixLength();
        if (isTrustedForwarder(msg.sender) && calldataLength >= contextSuffixLength) {
            return msg.data[:calldataLength - contextSuffixLength];
        } else {
            return msg.data;
        }
    }

    /**
     * @dev ERC-2771 specifies the context as being a single address (20 bytes).
     */
    function _contextSuffixLength() internal pure returns (uint256) {
        return 20;
    }
    // slither-disable-end dead-code
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ICircleIntegration } from "wormhole-circle-integration/interfaces/ICircleIntegration.sol";

import { Bridge } from "src/accounts/storage/Bridge.sol";
import { Account } from "src/accounts/storage/Account.sol";

import { Error } from "src/libraries/Error.sol";

import { ITokenMessenger } from "src/interfaces/circle/ITokenMessenger.sol";
import { ITokenMinter } from "src/interfaces/circle/ITokenMinter.sol";

/**
 * @notice A library for bridging tokens via third parties such as Wormhole and Circle.
 */
library BridgeIntegrations {
    event TokenBridged(
        address indexed token, bytes32 indexed destinationAddress, uint32 indexed destinationDomain, address bridge, uint256 amount
    );

    event TokenBridgeMessageRedeemed(address indexed token, uint32 indexed sourceDomain, uint256 amount);

    /**
     * @notice Bridge USDC tokens to another chain using the Circle Bridge.
     * @param _amount The amount of USDC tokens to bridge.
     * @param _destinationAddress The address on the destination domain to receive the bridged tokens.
     * @param _destinationDomain The address of the destination domain.
     */
    function _CCTPBridgeUSDC(uint256 _amount, bytes32 _destinationAddress, uint32 _destinationDomain) internal {
        _checkExceedsMinBridgeAmount(_amount);
        address USDC = Bridge._USDC();
        address circleBridge = Bridge._circleBridge();
        // Call the bridge with the necessary approvals
        IERC20(USDC).approve(circleBridge, _amount);
        emit TokenBridged(USDC, _destinationAddress, _destinationDomain, circleBridge, _amount);
        ITokenMessenger(circleBridge).depositForBurn(
            _amount,
            _destinationDomain,
            // The circle bridge expects the mint recipient address as a bytes32
            _destinationAddress,
            USDC
        );
    }

    /**
     * @notice Bridge USDC tokens to another chain using the Wormhole facilitated Circle Bridge.
     * @param _amount The amount of USDC tokens to bridge.
     * @param _destinationAddress The address on the destination domain to receive the bridged tokens.
     * @param _destinationWormholeChainId The wormhole chain id of the destination chain.
     */
    function _wormholeBridgeUSDC(uint256 _amount, bytes32 _destinationAddress, uint16 _destinationWormholeChainId) internal {
        _checkExceedsMinBridgeAmount(_amount);
        if (!_validateWormholeChainId(_destinationWormholeChainId)) revert Error.InvalidWormholeChainId();
        address USDC = Bridge._USDC();
        address wormholeCircleBridge = Bridge._wormholeCircleBridge();
        ICircleIntegration.TransferParameters memory transferParameters = ICircleIntegration.TransferParameters({
            token: USDC,
            amount: _amount,
            targetChain: _destinationWormholeChainId,
            // The circle bridge expects the mint recipient address as a bytes32
            mintRecipient: _destinationAddress
        });

        // Call the bridge with the necessary approvals
        IERC20(USDC).approve(wormholeCircleBridge, _amount);
        emit TokenBridged(USDC, _destinationAddress, uint32(_destinationWormholeChainId), wormholeCircleBridge, _amount);
        ICircleIntegration(wormholeCircleBridge).transferTokensWithPayload(transferParameters, 0, abi.encode(msg.sender));
    }

    /**
     * @notice Process a Wormhole Bridge message to complete a bridging transaction.
     * @param _redeemParams The redeem parameters for the bridge message.
     */
    function _processWormholeBridgeMessage(ICircleIntegration.RedeemParameters calldata _redeemParams) internal {
        // Call the bridge with the payload
        ICircleIntegration circleIntegration = ICircleIntegration(Bridge._wormholeCircleBridge());

        ICircleIntegration.DepositWithPayload memory depositWithPayload = circleIntegration.redeemTokensWithPayload(_redeemParams);
        emit TokenBridgeMessageRedeemed(
            address(uint160(uint256(depositWithPayload.token))), depositWithPayload.sourceDomain, depositWithPayload.amount
        );
    }

    /**
     * @notice Validate the wormhole chain id.
     * @param _chainId The wormhole chain id.
     * @return isValid A boolean indicating if the chain id is valid or not.
     */
    function _validateWormholeChainId(uint16 _chainId) internal view returns (bool isValid) {
        if (ICircleIntegration(Bridge._wormholeCircleBridge()).getRegisteredEmitter(_chainId) == bytes32(0)) return false;
        return true;
    }

    /**
     * @notice Checks the amount given is greater than the minimum bridging amount.
     * @param _amount The amount to be checked against the minimum.
     */
    function _checkExceedsMinBridgeAmount(uint256 _amount) internal view {
        if (_amount < Account._infinexProtocolConfig().getMinimumUSDCBridgeAmount()) revert Error.InsufficientBridgeAmount();
    }

    /**
     * @notice Internal function to get the maximum amount that can be bridged.
     * @return the maximum bridging amount.
     */
    function _getBridgeMaxAmount() internal view returns (uint256) {
        return ITokenMinter(Bridge._circleMinter()).burnLimitsPerMessage(Bridge._USDC());
    }

    /**
     * @notice Internal function to calculate the amount of USDC tokens to bridge.
     * @dev This function retrieves the balance of USDC tokens held by the contract and performs checks on the amount.
     * @return amountToBridge The amount of USDC tokens to bridge in native decimals (6).
     * @return isTotalAmount A boolean indicating if the amount to bridge is the full balance of the account.
     */
    function _getUSDCBridgeableAmount(uint256 _amount) internal view returns (uint256 amountToBridge, bool isTotalAmount) {
        // Check that the amount is less than the maximum bridge amount, if not, just bridge the max
        uint256 maxBridgeAmount = _getBridgeMaxAmount();

        if (_amount > maxBridgeAmount) {
            amountToBridge = maxBridgeAmount;
            isTotalAmount = false;
        } else {
            amountToBridge = _amount;
            isTotalAmount = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title Capability for the withdrawal of ERC20 tokens, ERC721 tokens, and Ether.
 */
interface IWithdrawModule {
    /*///////////////////////////////////////////////////////////////
                                    VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if the provided withdrawal address is allowlisted for withdrawals
     * @param _withdrawalAddress The withdrawal address to check
     * @return A boolean indicating if the withdrawal address is allowlisted
     */
    function isAllowlistedWithdrawalAddress(address _withdrawalAddress) external view returns (bool);

    /**
     * @notice Returns the timestamp when the withdrawal address was added to the allowlist.
     * @param _withdrawalAddress The withdrawal address to check.
     * @return The timestamp when the withdrawal address was added to the allowlist.
     */
    function allowlistedWithdrawalAddressValidFrom(address _withdrawalAddress) external view returns (uint256);

    /**
     * @notice Retrieves the allowlist delay value.
     * @dev This function returns the value of the allowlist delay, which determines the time period
     * required for an address to be added to the allowlist before it can withdraw funds to it.
     * @return The allowlist delay value.
     */
    function getAllowlistDelay() external view returns (uint256);

    /*///////////////////////////////////////////////////////////////
                                MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the status of an allowlisted withdrawal address, this has a 48 hour delay.
     * @param _allowlistedWithdrawalAddress The allowlisted withdrawal address
     * @param _status The status to set the allowlisted withdrawal address
     */
    function setAllowlistedWithdrawalAddress(address _allowlistedWithdrawalAddress, bool _status) external;

    /**
     * @notice Withdraws to an allowlisted address on this chain
     * @param _withdrawalAddress The address to withdraw to
     * @param _token The address of the token to withdraw
     * @param _amount The amount to withdraw in 18 decimals, gets scaled accordingly.
     */
    function withdrawERC20ToAllowlistedAddress(address _withdrawalAddress, address _token, uint256 _amount) external;

    /**
     * @notice Withdraws ERC721 tokens from the contract to an allowlisted address.
     * @param _withdrawalAddress The address to withdraw the token to.
     * @param _token The address of the ERC721 token to withdraw.
     * @param _tokenId The ID of the ERC721 token to withdraw.
     */
    function withdrawERC721ToAllowlistedAddress(address _withdrawalAddress, address _token, uint256 _tokenId) external;

    /**
     * @notice Withdraws Ether from the contract to an allowlisted address.
     * @param _withdrawalAddress The address to withdraw Ether to.
     * @param _amount The amount of Ether to withdraw.
     */
    function withdrawEtherToAllowlistedAddress(address _withdrawalAddress, uint256 _amount) external;

    /**
     * @notice Withdraws specified amount of ERC1155 tokens to an allowlisted address.
     * @param _withdrawalAddress The address that the token will be withdrawn to.
     * @param _token The address of the ERC1155 token to withdraw.
     * @param _tokenId The ID of the ERC1155 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     * @param _data Data to send with the transfer.
     * @dev Requires the sender to be the sudo key.
     */
    function withdrawERC1155ToAllowlistedAddress(
        address _withdrawalAddress,
        address _token,
        uint256 _tokenId,
        uint256 _amount,
        bytes calldata _data
    ) external;

    /**
     * @notice Withdraws specified batch of ERC1155 tokens to an allowlisted address.
     * @param _withdrawalAddress The address that the token will be withdrawn to.
     * @param _token The address of the ERC1155 token to withdraw.
     * @param _tokenIds The IDs of the ERC1155 tokens to withdraw.
     * @param _amounts The amounts of tokens to withdraw.
     * @param _data Data to send with the transfer.
     * @dev Requires the sender to be the sudo key.
     */
    function withdrawERC1155BatchToAllowlistedAddress(
        address _withdrawalAddress,
        address _token,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title IInfinexProtocolConfigBeacon
 * @notice Interface for the Infinex Protocol Config Beacon contract.
 */
interface IInfinexProtocolConfigBeacon {
    /*///////////////////////////////////////////////////////////////
    	 										STRUCTS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Struct containing the constructor arguments for the InfinexProtocolConfigBeacon contract
     * @param trustedForwarder Address of the trusted forwarder contract
     * @param appRegistry Address of the app registry contract
     * @param latestAccountImplementation Address of the latest account implementation contract
     * @param initialProxyImplementation Address of the initial proxy implementation contract
     * @param revenuePool Address of the revenue pool contract
     * @param USDC Address of the USDC token contract
     * @param minimumUSDCBridgeAmount Minimum amount of USDC required to bridge
     * @param circleBridge Address of the Circle bridge contract
     * @param circleMinter Address of the Circle minter contract, used for checking the maximum bridge amount
     * @param wormholeCircleBridge Address of the Wormhole Circle bridge contract
     * @param defaultDestinationCCTPDomain the CCTP domain of the default destination chain.
     * @param defaultDestinationWormholeChainId the Wormhole chain id of the default destination chain.
     * @param solanaWalletSeed The salt used to generate the Solana account (fixed seed "wallet")
     * @param solanaFixedPDASeed The salt used to generate the PDA (Program Derived Address)
     * @param solanaWalletProgramAddress The Solana Wallet Program Address
     * @param solanaTokenMintAddress The Solana token mint address
     * @param solanaTokenProgramAddress The Solana token program address
     * @param solanaAssociatedTokenProgramAddress The Solana ATA program address
     */
    struct InfinexBeaconConstructorArgs {
        address trustedForwarder;
        address appRegistry;
        address latestAccountImplementation;
        address initialProxyImplementation;
        address revenuePool;
        address USDC;
        uint256 minimumUSDCBridgeAmount;
        address circleBridge;
        address circleMinter;
        address wormholeCircleBridge;
        uint32 defaultDestinationCCTPDomain;
        uint16 defaultDestinationWormholeChainId;
        uint16[] supportedWormholeChainIds;
        uint32 solanaCCTPDestinationDomain;
        bytes solanaWalletSeed;
        bytes solanaFixedPDASeed;
        bytes32 solanaWalletProgramAddress;
        bytes32 solanaTokenMintAddress;
        bytes32 solanaTokenProgramAddress;
        bytes32 solanaAssociatedTokenProgramAddress;
    }

    /**
     * @notice Struct containing both Circle and Wormhole bridge configuration
     * @param minimumUSDCBridgeAmount Minimum amount of USDC required to bridge
     * @param circleBridge Address of the Circle bridge contract
     * @param circleMinter Address of the Circle minter contract, used for checking the maximum bridge amount
     * @param wormholeCircleBridge Address of the Wormhole Circle bridge contract
     * @param defaultDestinationCCTPDomain the CCTP domain of the default destination chain.
     * @param defaultDestinationWormholeChainId the Wormhole chain id of the default destination chain.
     * @dev Chain id is the official chain id for evm chains and documented one for non evm chains.
     */
    struct BridgeConfiguration {
        uint256 minimumUSDCBridgeAmount;
        address circleBridge;
        address circleMinter;
        address wormholeCircleBridge;
        uint32 defaultDestinationCCTPDomain;
        uint16 defaultDestinationWormholeChainId;
    }

    /**
     * @notice The addresses for implementations referenced by the beacon
     * @param initialProxyImplementation The initial proxy implementation address used for account creation to ensure identical cross chain addresses
     * @param latestAccountImplementation The latest account implementation address, used for account upgrades and new accounts
     * @param latestInfinexProtocolConfigBeacon The latest Infinex Protocol config beacon address, used for pointing account updates to the latest beacon
     */
    struct ImplementationAddresses {
        address initialProxyImplementation;
        address latestAccountImplementation;
        address latestInfinexProtocolConfigBeacon;
    }

    /**
     * @notice Struct containing the Solana configuration needed to verify addresses
     * @param walletSeed The salt used to generate the Solana account (fixed seed "wallet")
     * @param fixedPDASeed The salt used to generate the PDA (Program Derived Address)
     * @param walletProgramAddress The Solana Wallet Program Address
     * @param tokenMintAddress The Solana token mint address
     * @param tokenProgramAddress The Solana token address
     * @param associatedTokenProgramAddress The Solana ATA program address
     */
    struct SolanaConfiguration {
        bytes walletSeed;
        bytes fixedPDASeed;
        bytes32 walletProgramAddress;
        bytes32 tokenMintAddress;
        bytes32 tokenProgramAddress;
        bytes32 associatedTokenProgramAddress;
    }

    /*///////////////////////////////////////////////////////////////
    	 										EVENTS
    ///////////////////////////////////////////////////////////////*/

    event LatestAccountImplementationSet(address latestAccountImplementation);
    event InitialProxyImplementationSet(address initialProxyImplementation);
    event AppRegistrySet(address appRegistry);
    event RevenuePoolSet(address revenuePool);
    event USDCAddressSet(address USDC);
    event CircleBridgeParamsSet(address circleBridge, address circleMinter, uint32 defaultDestinationCCTPDomain);
    event WormholeCircleBridgeParamsSet(address wormholeCircleBridge, uint16 defaultDestinationWormholeChainId);
    event LatestInfinexProtocolConfigBeaconSet(address latestInfinexProtocolConfigBeacon);
    event WithdrawalFeeUSDCSet(uint256 withdrawalFee);
    event FundsRecoveryStatusSet(bool status);
    event MinimumUSDCBridgeAmountSet(uint256 amount);
    event WormholeDestinationDomainSet(uint256 indexed chainId, uint16 destinationDomain);
    event CircleDestinationDomainSet(uint256 indexed chainId, uint32 destinationDomain);
    event TrustedRecoveryKeeperSet(address indexed trustedRecoveryKeeper, bool isTrusted);
    event SupportedWormholeChainIdSet(uint16 wormholeChainId, bool status);
    event SolanaCCTPDestinationDomainSet(uint32 solanaCCTPDestinationDomain);

    /*///////////////////////////////////////////////////////////////
    	 									VARIABLES
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the timestamp the beacon was deployed
     * @return The timestamp the beacon was deployed
     */
    function CREATED_AT() external view returns (uint256);

    /**
     * @notice Gets the trusted forwarder address
     * @return The address of the trusted forwarder
     */
    function TRUSTED_FORWARDER() external view returns (address);

    /**
     * @notice Gets the app registry address
     * @return The address of the app registry
     */
    function appRegistry() external view returns (address);

    /**
     * @notice A platform wide feature flag to enable or disable funds recovery, false by default
     * @return True if funds recovery is active
     */
    function fundsRecoveryActive() external view returns (bool);

    /**
     * @notice Gets the revenue pool address
     * @return The address of the revenue pool
     */
    function revenuePool() external view returns (address);

    /**
     * @notice Gets the USDC amount to charge as withdrawal fee
     * @return The withdrawal fee in USDC's decimals
     */
    function withdrawalFeeUSDC() external view returns (uint256);

    /**
     * @notice Retrieves the USDC address.
     * @return The address of the USDC token
     */
    function USDC() external view returns (address);

    /*///////////////////////////////////////////////////////////////
    	 								VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Retrieves supported wormhole chain ids.
     * @param _wormholeChainId the chain id to check
     * @return bool if the chain is supported or not.
     */
    function isSupportedWormholeChainId(uint16 _wormholeChainId) external view returns (bool);

    /**
     * @notice Retrieves the minimum USDC amount that can be bridged.
     * @return The minimum USDC bridge amount.
     */
    function getMinimumUSDCBridgeAmount() external view returns (uint256);

    /**
     * @notice Retrieves the Circle Bridge parameters.
     * @return circleBridge The address of the Circle Bridge contract.
     * @return circleMinter The address of the TokenMinter contract.
     * @return defaultDestinationCCTPDomain The CCTP domain of the default destination chain.
     */
    function getCircleBridgeParams()
        external
        view
        returns (address circleBridge, address circleMinter, uint32 defaultDestinationCCTPDomain);

    /**
     * @notice Retrieves the Circle Bridge address.
     * @return The address of the Circle Bridge contract.
     */
    function getCircleBridge() external view returns (address);

    /**
     * @notice Retrieves the Circle TokenMinter address.
     * @return The address of the Circle TokenMinter contract.
     */
    function getCircleMinter() external view returns (address);

    /**
     * @notice Retrieves the CCTP domain of the destination chain.
     * @return The CCTP domain of the default destination chain.
     */
    function getDefaultDestinationCCTPDomain() external view returns (uint32);

    /**
     * @notice Retrieves the parameters required for Wormhole bridging.
     * @return The address of the Wormhole Circle Bridge contract.
     * @return The default wormhole destination domain for the circle bridge contract.
     */
    function getWormholeCircleBridgeParams() external view returns (address, uint16);

    /**
     * @notice Retrieves the Wormhole Circle Bridge address.
     * @return The address of the Wormhole Circle Bridge contract.
     */
    function getWormholeCircleBridge() external view returns (address);

    /**
     * @notice Retrieves the Wormhole chain id for Base, or Ethereum Mainnet if deployed on Base.
     * @return The Wormhole chain id of the default destination chain.
     */
    function getDefaultDestinationWormholeChainId() external view returns (uint16);

    /**
     * @notice Retrieves the circle CCTP destination domain for solana.
     * @return The CCTP destination domain for solana.
     */
    function getSolanaCCTPDestinationDomain() external view returns (uint32);

    /**
     * @notice Gets the latest account implementation address.
     * @return The address of the latest account implementation.
     */
    function getLatestAccountImplementation() external view returns (address);

    /**
     * @notice Gets the initial proxy implementation address.
     * @return The address of the initial proxy implementation.
     */
    function getInitialProxyImplementation() external view returns (address);

    /**
     * @notice The latest Infinex Protocol config beacon address, used for pointing account updates to the latest beacon.
     * @return The address of the latest Infinex Protocol config beacon.
     */
    function getLatestInfinexProtocolConfigBeacon() external view returns (address);

    /**
     * @notice Checks if an address is a trusted recovery keeper.
     * @param _address The address to check.
     * @return True if the address is a trusted recovery keeper, false otherwise.
     */
    function isTrustedRecoveryKeeper(address _address) external view returns (bool);

    /**
     * @notice Returns the Solana configuration
     * @param walletSeed The salt used to generate the Solana account (fixed seed "wallet")
     * @param fixedPDASeed The salt used to generate the PDA (Program Derived Address)
     * @param walletProgramAddress The Solana Wallet Program Address
     * @param tokenMintAddress The Solana token mint address
     * @param tokenProgramAddress The Solana token program address
     * @param associatedTokenProgramAddress The Solana ATA program address
     */
    function getSolanaConfiguration()
        external
        view
        returns (
            bytes memory walletSeed,
            bytes memory fixedPDASeed,
            bytes32 walletProgramAddress,
            bytes32 tokenMintAddress,
            bytes32 tokenProgramAddress,
            bytes32 associatedTokenProgramAddress
        );

    /*///////////////////////////////////////////////////////////////
    	 							MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets or unsets a supported wormhole chain id.
     * @param _wormholeChainId the wormhole chain id to add or remove.
     * @param _status the status of the chain id.
     */
    function setSupportedWormholeChainId(uint16 _wormholeChainId, bool _status) external;

    /**
     * @notice Sets the solana CCTP destination domain
     * @param _solanaCCTPDestinationDomain the destination domain for circles CCTP USDC bridge.
     */
    function setSolanaCCTPDestinationDomain(uint32 _solanaCCTPDestinationDomain) external;

    /**
     * @notice Sets the address of the app registry contract.
     * @param _appRegistry The address of the app registry contract.
     */
    function setAppRegistry(address _appRegistry) external;

    /**
     * @notice Sets or unsets an address as a trusted recovery keeper.
     * @param _address The address to set or unset.
     * @param _isTrusted Boolean indicating whether to set or unset the address as a trusted recovery keeper.
     */
    function setTrustedRecoveryKeeper(address _address, bool _isTrusted) external;

    /**
     * @notice Sets the funds recovery flag to active.
     * @dev Initially only the owner can call this. After 90 days, it can be activated by anyone.
     */
    function setFundsRecoveryActive() external;

    /**
     * @notice Sets the revenue pool address.
     * @param _revenuePool The revenue pool address.
     */
    function setRevenuePool(address _revenuePool) external;

    /**
     * @notice Sets the USDC amount to charge as withdrawal fee.
     * @param _withdrawalFeeUSDC The withdrawal fee in USDC's decimals.
     */
    function setWithdrawalFeeUSDC(uint256 _withdrawalFeeUSDC) external;

    /**
     * @notice Sets the address of the USDC token contract.
     * @param _USDC The address of the USDC token contract.
     * @dev Only the contract owner can call this function.
     * @dev Throws an error if the provided address is the zero address.
     */
    function setUSDCAddress(address _USDC) external;

    /**
     * @notice Sets the minimum USDC amount that can be bridged, in 6 decimals.
     * @param _amount The minimum USDC bridge amount.
     */
    function setMinimumUSDCBridgeAmount(uint256 _amount) external;

    /**
     * @notice Sets the parameters for Circle bridging.
     * @param _circleBridge The address of the Circle Bridge contract.
     * @param _circleMinter The address of the Circle TokenMinter contract.
     * @param _defaultDestinationCCTPDomain The CCTP domain of the default destination chain.
     * @dev Circle Destination Domain can be 0 - Ethereum.
     */
    function setCircleBridgeParams(address _circleBridge, address _circleMinter, uint32 _defaultDestinationCCTPDomain) external;

    /**
     * @notice Sets the parameters for Wormhole bridging.
     * @param _wormholeCircleBridge The address of the Wormhole Circle Bridge contract.
     * @param _defaultDestinationWormholeChainId The wormhole domain of the default destination chain.
     */
    function setWormholeCircleBridgeParams(address _wormholeCircleBridge, uint16 _defaultDestinationWormholeChainId) external;

    /**
     * @notice Sets the initial proxy implementation address.
     * @param _initialProxyImplementation The initial proxy implementation address.
     * @dev Throws an error if the provided address is the zero address.
     */
    function setInitialProxyImplementation(address _initialProxyImplementation) external;

    /**
     * @notice Sets the latest account implementation address.
     * @param _latestAccountImplementation The latest account implementation address.
     * @dev Throws an error if the provided address is the zero address.
     */
    function setLatestAccountImplementation(address _latestAccountImplementation) external;

    /**
     * @notice Sets the latest Infinex Protocol Config Beacon.
     * @param _latestInfinexProtocolConfigBeacon The address of the Infinex Protocol Config Beacon.
     * @dev Throws an error if the provided address is the zero address.
     */
    function setLatestInfinexProtocolConfigBeacon(address _latestInfinexProtocolConfigBeacon) external;
}

/*
 * ADAPTED FROM: https://github.com/circlefin/evm-cctp-contracts/blob/1ddc5057e2a686194d481d04239387cf095ec760/src/TokenMessenger.sol
 * Copyright (c) 2022, Circle Internet Financial Limited.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface ITokenMessenger {
    // ============ Events ============
    /**
     * @notice Emitted when a DepositForBurn message is sent
     * @param nonce unique nonce reserved by message
     * @param burnToken address of token burnt on source domain
     * @param amount deposit amount
     * @param depositor address where deposit is transferred from
     * @param mintRecipient address receiving minted tokens on destination domain as bytes32
     * @param destinationDomain destination domain
     * @param destinationTokenMessenger address of TokenMessenger on destination domain as bytes32
     * @param destinationCaller authorized caller as bytes32 of receiveMessage() on destination domain, if not equal to bytes32(0).
     * If equal to bytes32(0), any address can call receiveMessage().
     */
    event DepositForBurn(
        uint64 indexed nonce,
        address indexed burnToken,
        uint256 amount,
        address indexed depositor,
        bytes32 mintRecipient,
        uint32 destinationDomain,
        bytes32 destinationTokenMessenger,
        bytes32 destinationCaller
    );

    /**
     * @notice Emitted when tokens are minted
     * @param mintRecipient recipient address of minted tokens
     * @param amount amount of minted tokens
     * @param mintToken contract address of minted token
     */
    event MintAndWithdraw(address indexed mintRecipient, uint256 amount, address indexed mintToken);

    // ============ External Functions  ============
    /**
     * @notice Deposits and burns tokens from sender to be minted on destination domain.
     * Emits a `DepositForBurn` event.
     * @dev reverts if:
     * - given burnToken is not supported
     * - given destinationDomain has no TokenMessenger registered
     * - transferFrom() reverts. For example, if sender's burnToken balance or approved allowance
     * to this contract is less than `amount`.
     * - burn() reverts. For example, if `amount` is 0.
     * - MessageTransmitter returns false or reverts.
     * @param amount amount of tokens to burn
     * @param destinationDomain destination domain
     * @param mintRecipient address of mint recipient on destination domain
     * @param burnToken address of contract to burn deposited tokens, on local domain
     * @return _nonce unique nonce reserved by message
     */
    function depositForBurn(uint256 amount, uint32 destinationDomain, bytes32 mintRecipient, address burnToken)
        external
        returns (uint64 _nonce);

    /**
     * @notice Handles an incoming message received by the local MessageTransmitter,
     * and takes the appropriate action. For a burn message, mints the
     * associated token to the requested recipient on the local domain.
     * @dev Validates the local sender is the local MessageTransmitter, and the
     * remote sender is a registered remote TokenMessenger for `remoteDomain`.
     * @param remoteDomain The domain where the message originated from.
     * @param sender The sender of the message (remote TokenMessenger).
     * @param messageBody The message body bytes.
     * @return success Bool, true if successful.
     */
    function handleReceiveMessage(uint32 remoteDomain, bytes32 sender, bytes calldata messageBody) external returns (bool);
}

// Adapted from the Circle interface https://github.com/circlefin/evm-cctp-contracts/blob/master/src/interfaces/ITokenMinter.sol

/*
 * Copyright (c) 2022, Circle Internet Financial Limited.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
pragma solidity ^0.8.21;

/**
 * @title ITokenMinter
 * @notice interface for minter of tokens that are mintable, burnable, and interchangeable
 * across domains.
 */
interface ITokenMinter {
    /**
     * @notice Get the maximum burn amount per message for a specific local token.
     * @notice this mapping is exposed in the TokenMinter contract, but is from https://github.com/circlefin/evm-cctp-contracts/blob/master/src/roles/TokenController.sol
     * @param token The local token address.
     * @return The maximum burn amount per message for the specified local token.
     */
    function burnLimitsPerMessage(address token) external view returns (uint256);

    /**
     * @notice Mints `amount` of local tokens corresponding to the
     * given (`sourceDomain`, `burnToken`) pair, to `to` address.
     * @dev reverts if the (`sourceDomain`, `burnToken`) pair does not
     * map to a nonzero local token address. This mapping can be queried using
     * getLocalToken().
     * @param sourceDomain Source domain where `burnToken` was burned.
     * @param burnToken Burned token address as bytes32.
     * @param to Address to receive minted tokens, corresponding to `burnToken`,
     * on this domain.
     * @param amount Amount of tokens to mint. Must be less than or equal
     * to the minterAllowance of this TokenMinter for given `_mintToken`.
     * @return mintToken token minted.
     */
    function mint(uint32 sourceDomain, bytes32 burnToken, address to, uint256 amount) external returns (address mintToken);

    /**
     * @notice Burn tokens owned by this ITokenMinter.
     * @param burnToken burnable token.
     * @param amount amount of tokens to burn. Must be less than or equal to this ITokenMinter's
     * account balance of the given `_burnToken`.
     */
    function burn(address burnToken, uint256 amount) external;

    /**
     * @notice Get the local token associated with the given remote domain and token.
     * @param remoteDomain Remote domain
     * @param remoteToken Remote token
     * @return local token address
     */
    function getLocalToken(uint32 remoteDomain, bytes32 remoteToken) external view returns (address);

    /**
     * @notice Set the token controller of this ITokenMinter. Token controller
     * is responsible for mapping local tokens to remote tokens, and managing
     * token-specific limits
     * @param newTokenController new token controller address
     */
    function setTokenController(address newTokenController) external;
}

//       c=<
//        |
//        |   ////\    1@2
//    @@  |  /___\**   @@@2			@@@@@@@@@@@@@@@@@@@@@@
//   @@@  |  |~L~ |*   @@@@@@		@@@  @@@@@        @@@@    @@@ @@@@    @@@  @@@@@@@@ @@@@ @@@@    @@@ @@@@@@@@@ @@@@   @@@@
//  @@@@@ |   \=_/8    @@@@1@@		@@@  @@@@@  @@@@  @@@@    @@@ @@@@@   @@@ @@@@@@@@@ @@@@ @@@@@  @@@@ @@@@@@@@@  @@@@ @@@@
// @@@@@@| _ /| |\__ @@@@@@@@2		@@@  @@@@@  @@@@  @@@@    @@@ @@@@@@@ @@@ @@@@      @@@@ @@@@@@ @@@@ @@@         @@@@@@@
// 1@@@@@@|\  \___/)   @@1@@@@@2	~~~  ~~~~~  @@@@  ~~@@    ~~~ ~~~~~~~~~~~ ~~~~      ~~~~ ~~~~~~~~~~~ ~@@          @@@@@
// 2@@@@@ |  \ \ / |     @@@@@@2	@@@  @@@@@  @@@@  @@@@    @@@ @@@@@@@@@@@ @@@@@@@@@ @@@@ @@@@@@@@@@@ @@@@@@@@@    @@@@@
// 2@@@@  |_  >   <|__    @@1@12	@@@  @@@@@  @@@@  @@@@    @@@ @@@@ @@@@@@ @@@@      @@@@ @@@@ @@@@@@ @@@         @@@@@@@
// @@@@  / _|  / \/    \   @@1@		@@@   @@@   @@@@  @@@@    @@@ @@@@  @@@@@ @@@@      @@@@ @@@@  @@@@@ @@@@@@@@@  @@@@ @@@@
//  @@ /  |^\/   |      |   @@1		@@@         @@@@  @@@@    @@@ @@@@    @@@ @@@@      @@@@ @@@    @@@@ @@@@@@@@@ @@@@   @@@@
//   /     / ---- \ \\\=    @@		@@@@@@@@@@@@@@@@@@@@@@
//   \___/ --------  ~~    @@@
//     @@  | |   | |  --   @@
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

// SPDX-License-Identifier: MIT
// adapted from https://github.com/Synthetixio/synthetix-v3/markets/spot-market/contracts/storage/Price.sol#L93
pragma solidity ^0.8.21;

import { DecimalMath } from "@synthetixio/core-contracts/contracts/utils/DecimalMath.sol";
import { SafeCastI256 } from "@synthetixio/core-contracts/contracts/utils/SafeCast.sol";

import { Error } from "src/libraries/Error.sol";

library DecimalScaling {
    using DecimalMath for uint256;
    using DecimalMath for int256;
    using SafeCastI256 for int256;

    /**
     * @dev Scales the amount to or from 18 decimal places depending on the input decimals.
     * If specified decimals are greater than 18, it divides the amount by 10 raised to the power of the difference.
     * If specified decimals are less than 18, it multiplies the amount by 10 raised to the power of the difference.
     * @param amount The amount to be scaled.
     * @param decimals The number of decimals of the amount.
     * @return scaledAmount The amount scaled to 18 decimal places.
     */
    function scale(int256 amount, uint256 decimals) internal pure returns (int256 scaledAmount) {
        return (decimals > 18 ? amount.downscale(decimals - 18) : amount.upscale(18 - decimals));
    }

    /**
     * @dev Scales the amount from 18 decimal places to the specified number of decimals.
     * If the specified decimals are greater than 18, it multiplies the amount by 10 raised to the power of the difference.
     * If the specified decimals are less than 18, it divides the amount by 10 raised to the power of the difference.
     * @param amount The amount to be scaled from 18 decimal places.
     * @param decimals The target number of decimals.
     * @return scaledAmount The amount scaled from 18 decimal places to the specified number of decimals.
     */
    function scaleTo(int256 amount, uint256 decimals) internal pure returns (int256 scaledAmount) {
        return (decimals > 18 ? amount.upscale(decimals - 18) : amount.downscale(18 - decimals));
    }

    /**
     * @dev Scales the amount to or from 18 decimal places depending on the input decimals.
     * If specified decimals are greater than 18, it divides the amount by 10 raised to the power of the difference.
     * If specified decimals are less than 18, it multiplies the amount by 10 raised to the power of the difference.
     * @param amount The amount to be scaled.
     * @param decimals The number of decimals of the amount.
     * @return scaledAmount The amount scaled to 18 decimal places.
     */
    function scale(uint256 amount, uint256 decimals) internal pure returns (uint256 scaledAmount) {
        return (decimals > 18 ? amount.downscale(decimals - 18) : amount.upscale(18 - decimals));
    }

    /**
     * @dev Scales the amount from 18 decimal places to the specified number of decimals.
     * If the specified decimals are greater than 18, it multiplies the amount by 10 raised to the power of the difference.
     * If the specified decimals are less than 18, it divides the amount by 10 raised to the power of the difference.
     * @param amount The amount to be scaled from 18 decimal places.
     * @param decimals The target number of decimals.
     * @return scaledAmount The amount scaled from 18 decimal places to the specified number of decimals.
     */
    function scaleTo(uint256 amount, uint256 decimals) internal pure returns (uint256 scaledAmount) {
        return (decimals > 18 ? amount.upscale(decimals - 18) : amount.downscale(18 - decimals));
    }

    /**
     * @notice Converts the given amount in 18 decimals to a decimal precision.
     * @param amount The amount to be converted.
     * @param decimals The number of decimals wanted for precision.
     * @return preciseAmount The amount converted to a decimal precision
     */
    // slither-disable-start divide-before-multiply
    function toPrecision(uint256 amount, uint256 decimals) internal pure returns (uint256 preciseAmount) {
        if (decimals > 18) {
            revert Error.DecimalsMoreThan18(decimals);
        }
        amount = amount / (10 ** (18 - decimals));
        return amount * (10 ** (18 - decimals));
    }
    // slither-disable-end divide-before-multiply
}

//       c=<
//        |
//        |   ////\    1@2
//    @@  |  /___\**   @@@2			@@@@@@@@@@@@@@@@@@@@@@
//   @@@  |  |~L~ |*   @@@@@@		@@@  @@@@@        @@@@    @@@ @@@@    @@@  @@@@@@@@ @@@@ @@@@    @@@ @@@@@@@@@ @@@@   @@@@
//  @@@@@ |   \=_/8    @@@@1@@		@@@  @@@@@  @@@@  @@@@    @@@ @@@@@   @@@ @@@@@@@@@ @@@@ @@@@@  @@@@ @@@@@@@@@  @@@@ @@@@
// @@@@@@| _ /| |\__ @@@@@@@@2		@@@  @@@@@  @@@@  @@@@    @@@ @@@@@@@ @@@ @@@@      @@@@ @@@@@@ @@@@ @@@         @@@@@@@
// 1@@@@@@|\  \___/)   @@1@@@@@2	~~~  ~~~~~  @@@@  ~~@@    ~~~ ~~~~~~~~~~~ ~~~~      ~~~~ ~~~~~~~~~~~ ~@@          @@@@@
// 2@@@@@ |  \ \ / |     @@@@@@2	@@@  @@@@@  @@@@  @@@@    @@@ @@@@@@@@@@@ @@@@@@@@@ @@@@ @@@@@@@@@@@ @@@@@@@@@    @@@@@
// 2@@@@  |_  >   <|__    @@1@12	@@@  @@@@@  @@@@  @@@@    @@@ @@@@ @@@@@@ @@@@      @@@@ @@@@ @@@@@@ @@@         @@@@@@@
// @@@@  / _|  / \/    \   @@1@		@@@   @@@   @@@@  @@@@    @@@ @@@@  @@@@@ @@@@      @@@@ @@@@  @@@@@ @@@@@@@@@  @@@@ @@@@
//  @@ /  |^\/   |      |   @@1		@@@         @@@@  @@@@    @@@ @@@@    @@@ @@@@      @@@@ @@@    @@@@ @@@@@@@@@ @@@@   @@@@
//   /     / ---- \ \\\=    @@		@@@@@@@@@@@@@@@@@@@@@@
//   \___/ --------  ~~    @@@
//     @@  | |   | |  --   @@
// ————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library Error {
    /*///////////////////////////////////////////////////////////////
                                            GENERIC
    ///////////////////////////////////////////////////////////////*/

    error AlreadyExists();

    error DoesNotExist();

    error Unauthorized();

    error InvalidLength();

    error NotOwner();

    error InvalidWormholeChainId();

    error InvalidCallerContext();

    /*///////////////////////////////////////////////////////////////
                                            ADDRESS
    ///////////////////////////////////////////////////////////////*/

    error ImplementationMismatch(address implementation, address latestImplementation);

    error InvalidWithdrawalAddress(address to);

    error NullAddress();

    error SameAddress();

    error InvalidSolanaAddress();

    error AddressAlreadySet();

    error InsufficientAllowlistDelay();

    /*///////////////////////////////////////////////////////////////
                                    AMOUNT / BALANCE
    ///////////////////////////////////////////////////////////////*/

    error InsufficientBalance();

    error InsufficientWithdrawalAmount(uint256 amount);

    error InsufficientBalanceForFee(uint256 balance, uint256 fee);

    error InvalidNonce(bytes32 nonce);

    error ZeroValue();

    error AmountDeltaZeroValue();

    error DecimalsMoreThan18(uint256 decimals);

    error InsufficientBridgeAmount();

    error BridgeMaxAmountExceeded();

    error ETHTransferFailed();

    error OutOfBounds();

    /*///////////////////////////////////////////////////////////////
                                            ACCOUNT
    ///////////////////////////////////////////////////////////////*/

    error CreateAccountDisabled();

    error InvalidKeysForSalt();

    error PredictAddressDisabled();

    error FundsRecoveryActivationDeadlinePending();

    error InvalidAppAccount();

    error InvalidAppBeacon();

    /*///////////////////////////////////////////////////////////////
                                        KEY MANAGEMENT
    ///////////////////////////////////////////////////////////////*/

    error InvalidRequest();

    error InvalidKeySignature(address from);

    error KeyAlreadyInvalid();

    error KeyAlreadyValid();

    error KeyNotFound();

    error CannotRemoveLastKey();

    /*///////////////////////////////////////////////////////////////
                                     GAS FEE REBATE
    ///////////////////////////////////////////////////////////////*/

    error InvalidDeductGasFunction(bytes4 sig);

    /*///////////////////////////////////////////////////////////////
                                FEATURE FLAGS
    ///////////////////////////////////////////////////////////////*/

    error FundsRecoveryNotActive();
}