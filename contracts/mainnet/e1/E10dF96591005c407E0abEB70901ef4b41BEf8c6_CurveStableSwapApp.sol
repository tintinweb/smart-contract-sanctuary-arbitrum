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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Interface that must be implemented by smart contracts in order to receive
 * ERC-1155 token transfers.
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.20;

import {IERC165, ERC165} from "../../../utils/introspection/ERC165.sol";
import {IERC1155Receiver} from "../IERC1155Receiver.sol";

/**
 * @dev Simple implementation of `IERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 */
abstract contract ERC1155Holder is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.20;

import {IERC721Receiver} from "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or
 * {IERC721-setApprovalForAll}.
 */
abstract contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for address related errors.
 */
library AddressError {
    /**
     * @dev Thrown when a zero address was passed as a function parameter (0x0000000000000000000000000000000000000000).
     */
    error ZeroAddress();

    /**
     * @dev Thrown when an address representing a contract is expected, but no code is found at the address.
     * @param contr The address that was expected to be a contract.
     */
    error NotAContract(address contr);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for change related errors.
 */
library ChangeError {
    /**
     * @dev Thrown when a change is expected but none is detected.
     */
    error NoChange();
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Contract to be used as the implementation of a Universal Upgradeable Proxy Standard (UUPS) proxy.
 *
 * Important: A UUPS proxy requires its upgradeability functions to be in the implementation as opposed to the proxy. This means that if the proxy is upgraded to an implementation that does not support this interface, it will no longer be upgradeable.
 */
interface IUUPSImplementation {
    /**
     * @notice Thrown when an incoming implementation will not be able to receive future upgrades.
     */
    error ImplementationIsSterile(address implementation);

    /**
     * @notice Thrown intentionally when testing future upgradeability of an implementation.
     */
    error UpgradeSimulationFailed();

    /**
     * @notice Emitted when the implementation of the proxy has been upgraded.
     * @param self The address of the proxy whose implementation was upgraded.
     * @param implementation The address of the proxy's new implementation.
     */
    event Upgraded(address indexed self, address implementation);

    /**
     * @notice Allows the proxy to be upgraded to a new implementation.
     * @param newImplementation The address of the proxy's new implementation.
     * @dev Will revert if `newImplementation` is not upgradeable.
     * @dev The implementation of this function needs to be protected by some sort of access control such as `onlyOwner`.
     */
    function upgradeTo(address newImplementation) external;

    /**
     * @notice Function used to determine if a new implementation will be able to receive future upgrades in `upgradeTo`.
     * @param newImplementation The address of the new implementation being tested for future upgradeability.
     * @dev This function will always revert, but will revert with different error messages. The function `upgradeTo` uses this error to determine the future upgradeability of the implementation in question.
     */
    function simulateUpgradeTo(address newImplementation) external;

    /**
     * @notice Retrieves the current implementation of the proxy.
     * @return The address of the current implementation.
     */
    function getImplementation() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

contract ProxyStorage {
    bytes32 private constant _SLOT_PROXY_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.Proxy"));

    struct ProxyStore {
        address implementation;
        bool simulatingUpgrade;
    }

    function _proxyStore() internal pure returns (ProxyStore storage store) {
        bytes32 s = _SLOT_PROXY_STORAGE;
        assembly {
            store.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/IUUPSImplementation.sol";
import "../errors/AddressError.sol";
import "../errors/ChangeError.sol";
import "../utils/AddressUtil.sol";
import "./ProxyStorage.sol";

abstract contract UUPSImplementation is IUUPSImplementation, ProxyStorage {
    /**
     * @inheritdoc IUUPSImplementation
     */
    function simulateUpgradeTo(address newImplementation) public override {
        ProxyStore storage store = _proxyStore();

        store.simulatingUpgrade = true;

        address currentImplementation = store.implementation;
        store.implementation = newImplementation;

        (bool rollbackSuccessful, ) = newImplementation.delegatecall(
            abi.encodeCall(this.upgradeTo, (currentImplementation))
        );

        if (!rollbackSuccessful || _proxyStore().implementation != currentImplementation) {
            revert UpgradeSimulationFailed();
        }

        store.simulatingUpgrade = false;

        // solhint-disable-next-line reason-string
        revert();
    }

    /**
     * @inheritdoc IUUPSImplementation
     */
    function getImplementation() external view override returns (address) {
        return _proxyStore().implementation;
    }

    function _upgradeTo(address newImplementation) internal virtual {
        if (newImplementation == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (!AddressUtil.isContract(newImplementation)) {
            revert AddressError.NotAContract(newImplementation);
        }

        ProxyStore storage store = _proxyStore();

        if (newImplementation == store.implementation) {
            revert ChangeError.NoChange();
        }

        if (!store.simulatingUpgrade && _implementationIsSterile(newImplementation)) {
            revert ImplementationIsSterile(newImplementation);
        }

        store.implementation = newImplementation;

        emit Upgraded(address(this), newImplementation);
    }

    function _implementationIsSterile(
        address candidateImplementation
    ) internal virtual returns (bool) {
        (bool simulationReverted, bytes memory simulationResponse) = address(this).delegatecall(
            abi.encodeCall(this.simulateUpgradeTo, (candidateImplementation))
        );

        return
            !simulationReverted &&
            keccak256(abi.encodePacked(simulationResponse)) ==
            keccak256(abi.encodePacked(UpgradeSimulationFailed.selector));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library AddressUtil {
    function isContract(address account) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(account)
        }

        return size > 0;
    }
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

import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IUUPSImplementation } from "@synthetixio/core-contracts/contracts/interfaces/IUUPSImplementation.sol";
import { UUPSImplementation } from "@synthetixio/core-contracts/contracts/proxy/UUPSImplementation.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import { IAppAccountBase } from "src/interfaces/apps/base/IAppAccountBase.sol";
import { IAppBeaconBase } from "src/interfaces/apps/base/IAppBeaconBase.sol";

import { AppBase } from "src/apps/base/AppBase.sol";
import { AppSecurityModifiers } from "src/apps/base/AppSecurityModifiers.sol";

abstract contract AppAccountBase is
    IAppAccountBase,
    UUPSImplementation,
    AppSecurityModifiers,
    ERC165,
    ERC721Holder,
    ERC1155Holder,
    ReentrancyGuardUpgradeable
{
    /*///////////////////////////////////////////////////////////////
                                FALLBACK
    ///////////////////////////////////////////////////////////////*/

    receive() external payable { }

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    /*///////////////////////////////////////////////////////////////
                                INITIALIZER
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize the app account with the main account and the app beacon.
     * @param _mainAccount the address of the main account, this is the owner of the app.
     * @param _appBeacon the beacon for the app account.
     */
    function initialize(address _mainAccount, address _appBeacon) external virtual initializer {
        AppBase._setMainAccount(_mainAccount);
        if (!IERC165(_appBeacon).supportsInterface(type(IAppBeaconBase).interfaceId)) {
            revert InvalidAppBeacon();
        }
        AppBase._setAppBeacon(_appBeacon);
    }

    /*///////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, ERC1155Holder) returns (bool) {
        return interfaceId == type(IAppAccountBase).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns the app version number of the app account.
     * @return A uint64 representing the version of the app.
     * @dev NOTE: This number must be updated whenever a new version is deployed.
     * The number should always only be incremented by 1.
     */
    function appVersion() public pure virtual returns (uint64) {
        return 1;
    }

    /**
     * @notice Get the app's main account.
     * @return The main account associated with this app.
     */
    function getMainAccount() external view returns (address) {
        return AppBase._getMainAccount();
    }

    /**
     * @notice Get the app config beacon.
     * @return The app config beacon address.
     */
    function getAppBeacon() external view returns (address) {
        return AppBase._getAppBeacon();
    }

    /*///////////////////////////////////////////////////////////////
                            MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfer Ether to the main account from the app account.
     * @param _amount The amount of Ether to transfer.
     */
    function transferEtherToMainAccount(uint256 _amount) external nonReentrant requiresAuthorizedOperationsParty {
        _transferEtherToMainAccount(_amount);
    }

    /**
     * @notice Transfer ERC20 tokens to the main account from the app account.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount of tokens to transfer.
     */
    function transferERC20ToMainAccount(address _token, uint256 _amount) external nonReentrant requiresAuthorizedOperationsParty {
        _transferERC20ToMainAccount(_token, _amount);
    }

    /**
     * @notice Transfer ERC721 tokens to the main account from the app account.
     * @param _token The address of the ERC721 token.
     * @param _tokenId The token ID to transfer.
     */
    function transferERC721ToMainAccount(address _token, uint256 _tokenId) external nonReentrant requiresAuthorizedOperationsParty {
        _transferERC721ToMainAccount(_token, _tokenId);
    }

    /**
     * @notice Transfer ERC1155 tokens to the main account from the app account.
     * @param _token The address of the ERC1155 token.
     * @param _tokenId The token ID to transfer.
     * @param _amount The amount of tokens to transfer.
     * @param _data Additional data to pass in the transfer.
     */
    function transferERC1155ToMainAccount(address _token, uint256 _tokenId, uint256 _amount, bytes calldata _data)
        external
        nonReentrant
        requiresAuthorizedOperationsParty
    {
        _transferERC1155ToMainAccount(_token, _tokenId, _amount, _data);
    }

    /**
     * @notice Transfers batch ERC1155 tokens to the main account from the app account.
     * @param _token The address of the ERC1155 token.
     * @param _ids The IDs of the ERC1155 tokens.
     * @param _amounts The amounts of the ERC1155 tokens.
     * @param _data Data to send with the transfer.
     */
    function transferERC1155BatchToMainAccount(
        address _token,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external nonReentrant requiresAuthorizedOperationsParty {
        _transferERC1155BatchToMainAccount(_token, _ids, _amounts, _data);
    }

    /**
     * @notice Recovers all ether in the app account to the main account.
     * @dev Requires the sender to be an authorized recovery party.
     */
    function recoverEtherToMainAccount() external requiresAuthorizedRecoveryParty nonReentrant {
        emit EtherRecoveredToMainAccount(address(this).balance);
        _transferEtherToMainAccount(address(this).balance);
    }

    /**
     * @notice Recovers the full balance of an ERC20 token to the main account.
     * @param _token The address of the token to be recovered to the main account.
     * @dev Requires the sender to be an authorized recovery party.
     */
    function recoverERC20ToMainAccount(address _token) public nonReentrant requiresAuthorizedRecoveryParty {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        emit ERC20RecoveredToMainAccount(_token, balance);
        _transferERC20ToMainAccount(_token, balance);
    }

    /**
     * @notice Recovers a specified ERC721 token to the main account.
     * @param _token The ERC721 token address to recover.
     * @param _tokenId The ID of the ERC721 token to recover.
     * @dev Requires the sender to be an authorized recovery party.
     */
    function recoverERC721ToMainAccount(address _token, uint256 _tokenId) external requiresAuthorizedRecoveryParty nonReentrant {
        emit ERC721RecoveredToMainAccount(_token, _tokenId);
        _transferERC721ToMainAccount(_token, _tokenId);
    }

    /**
     * @notice Recovers a specified ERC1155 token to the main account.
     * @param _token The ERC1155 token address to recover.
     * @param _tokenId The id of the token to recover.
     * @param _data The data for the transaction.
     * @dev Requires the sender to be an authorized recovery party.
     */
    function recoverERC1155ToMainAccount(address _token, uint256 _tokenId, bytes calldata _data)
        external
        requiresAuthorizedRecoveryParty
        nonReentrant
    {
        uint256 balance = IERC1155(_token).balanceOf(address(this), _tokenId);
        emit ERC1155RecoveredToMainAccount(_token, _tokenId, balance, _data);
        _transferERC1155ToMainAccount(_token, _tokenId, balance, _data);
    }

    /**
     * @notice Recovers multiple ERC1155 tokens to the main account.
     * @param _token The address of the ERC1155 token.
     * @param _tokenIds The IDs of the ERC1155 tokens.
     * @param _amounts The values of the ERC1155 tokens.
     * @param _data Data to send with the transfer.
     * @dev Requires the sender to be an authorized recovery party.
     */
    function recoverERC1155BatchToMainAccount(
        address _token,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external requiresAuthorizedRecoveryParty nonReentrant {
        emit ERC1155BatchRecoveredToMainAccount(_token, _tokenIds, _amounts, _data);
        _transferERC1155BatchToMainAccount(_token, _tokenIds, _amounts, _data);
    }

    /**
     * @notice Upgrade to a new account implementation
     * @param _newImplementation The address of the new account implementation
     * @dev when this function is called, the UUPSImplementation contract will do
     * a simulation of the upgrade. If the simulation fails, the upgrade will not be performed.
     * So when simulatingUpgrade is true, we bypass the security logic as the way the simulation is
     * done would always revert.
     * @dev NOTE: DO NOT CALL THIS FUNCTION DIRECTLY. USE upgradeAppVersion INSTEAD.
     */
    function upgradeTo(address _newImplementation) public {
        /// @dev if we are in the middle of a simulation, then we use the default _upgradeTo function
        if (_proxyStore().simulatingUpgrade) {
            _upgradeTo(_newImplementation);
            return;
        }
        /// @dev if not in a simulation, then we perform the actual upgrade
        _upgradeToLatestImplementation(_newImplementation);
    }

    /**
     * @notice Upgrade the app account to the latest implementation and beacon.
     * @param _appBeacon The address of the new app beacon.
     * @param _latestAppImplementation The address of the latest app implementation.
     * @dev Requires the sender to be the main account.
     */
    function upgradeAppVersion(address _appBeacon, address _latestAppImplementation) external {
        if (_appBeacon != AppBase._getAppBeacon()) {
            _updateAppBeacon(_appBeacon);
        }
        if (_latestAppImplementation != IUUPSImplementation(address(this)).getImplementation()) {
            upgradeTo(_latestAppImplementation);
        }
    }

    /*///////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Upgrade the account implementation to the latest version
     * @dev Checks are done in the main account
     * @dev requires the sender to be the main account
     */
    function _upgradeToLatestImplementation(address _newImplementation) internal virtual requiresMainAccountSender {
        _upgradeTo(_newImplementation);
    }

    /**
     * @notice Updates the app beacon to the latest beacon as set in the current beacon.
     * @dev requires the sender to be the main account
     */
    function _updateAppBeacon(address _newAppBeacon) internal requiresMainAccountSender {
        AppBase._setAppBeacon(_newAppBeacon);
    }

    /**
     * @notice Transfer Ether to the main account from the app account.
     * @param _amount The amount of Ether to transfer.
     */
    function _transferEtherToMainAccount(uint256 _amount) internal {
        emit EtherTransferredToMainAccount(_amount);
        (bool success,) = payable(AppBase._getMainAccount()).call{ value: _amount }("");
        if (!success) revert ETHTransferFailed();
    }

    /**
     * @notice Transfer ERC20 tokens to the main account from the app account.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount of tokens to transfer.
     */
    function _transferERC20ToMainAccount(address _token, uint256 _amount) internal {
        emit ERC20TransferredToMainAccount(_token, _amount);
        SafeERC20.safeTransfer(IERC20(_token), AppBase._getMainAccount(), _amount);
    }

    /**
     * @notice Transfer ERC721 tokens to the main account from the app account.
     * @param _token The address of the ERC721 token.
     * @param _tokenId The token ID to transfer.
     */
    function _transferERC721ToMainAccount(address _token, uint256 _tokenId) internal {
        emit ERC721TransferredToMainAccount(_token, _tokenId);
        IERC721(_token).safeTransferFrom(address(this), AppBase._getMainAccount(), _tokenId);
    }

    /**
     * @notice Transfer ERC1155 tokens to the main account from the app account.
     * @param _token The address of the ERC1155 token.
     * @param _tokenId The token ID to transfer.
     * @param _amount The amount of tokens to transfer.
     * @param _data Additional data to pass in the transfer.
     */
    function _transferERC1155ToMainAccount(address _token, uint256 _tokenId, uint256 _amount, bytes calldata _data) internal {
        emit ERC1155TransferredToMainAccount(_token, _tokenId, _amount, _data);
        IERC1155(_token).safeTransferFrom(address(this), AppBase._getMainAccount(), _tokenId, _amount, _data);
    }

    /**
     * @notice Transfers multiple ERC1155 tokens to the main account from the app account.
     * @param _token The address of the ERC1155 token.
     * @param _tokenIds The IDs of the ERC1155 token.
     * @param _amounts The amounts of tokens to transfer.
     * @param _data Data to send with the transfer.
     */
    function _transferERC1155BatchToMainAccount(
        address _token,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) internal {
        emit ERC1155BatchTransferredToMainAccount(_token, _tokenIds, _amounts, _data);
        IERC1155(_token).safeBatchTransferFrom(address(this), AppBase._getMainAccount(), _tokenIds, _amounts, _data);
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

import { Error } from "src/libraries/Error.sol";

/**
 * @title AppBase storage struct
 */
library AppBase {
    struct Data {
        address mainAccount; // main account address
        address appBeacon; // Address of beacon for app configuration
    }

    /*///////////////////////////////////////////////////////////////
                    			EVENTS / ERRORS
    ///////////////////////////////////////////////////////////////*/

    event MainAccountSet(address mainAccount);
    event AppBeaconSet(address appBeacon);

    /**
     * @dev Returns the account stored at the specified account id.
     */
    function getStorage() internal pure returns (Data storage data) {
        bytes32 s = keccak256(abi.encode("io.infinex.AppBase"));
        assembly {
            data.slot := s
        }
    }

    /*///////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the Main Account.
     * @return The Main Account address.
     */
    function _getMainAccount() internal view returns (address) {
        Data storage data = getStorage();
        return data.mainAccount;
    }

    /**
     * @notice Get the App Beacon.
     * @return The App Beacon.
     */
    function _getAppBeacon() internal view returns (address) {
        Data storage data = getStorage();
        return data.appBeacon;
    }

    /*///////////////////////////////////////////////////////////////
                                MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the Main Account address.
     * @param _mainAccount The address to be set as Main Account.
     */
    function _setMainAccount(address _mainAccount) internal {
        Data storage data = getStorage();
        if (_mainAccount == address(0)) revert Error.NullAddress();
        emit MainAccountSet(_mainAccount);
        data.mainAccount = _mainAccount;
    }

    /**
     * @notice Set an app beacon for the account.
     * @param _appBeacon The app beacon associated with the account.
     */
    function _setAppBeacon(address _appBeacon) internal {
        Data storage data = getStorage();
        if (_appBeacon == address(0)) revert Error.NullAddress();
        emit AppBeaconSet(_appBeacon);
        data.appBeacon = _appBeacon;
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
// Originally sourced from OpenZeppelin Contracts (last updated v4.9.3) (metatx/ERC2771Context.sol)
pragma solidity ^0.8.21;

import { AppBase } from "src/apps/base/AppBase.sol";
import { IBaseModule } from "src/interfaces/accounts/IBaseModule.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
library AppERC2771Context {
    function _msgSender() internal view returns (address) {
        uint256 calldataLength = msg.data.length;
        uint256 contextSuffixLength = _contextSuffixLength();
        if (_isTrustedForwarder(msg.sender) && calldataLength >= contextSuffixLength) {
            return address(bytes20(msg.data[calldataLength - contextSuffixLength:]));
        } else {
            return msg.sender;
        }
    }

    // slither-disable-start dead-code
    function _msgData() internal view returns (bytes calldata) {
        uint256 calldataLength = msg.data.length;
        uint256 contextSuffixLength = _contextSuffixLength();
        if (_isTrustedForwarder(msg.sender) && calldataLength >= contextSuffixLength) {
            return msg.data[:calldataLength - contextSuffixLength];
        } else {
            return msg.data;
        }
    }

    /**
     * @notice Checks if a forwarder is trusted.
     * @param forwarder The address of the forwarder to check.
     * @return A boolean indicating whether the forwarder is trusted or not.
     */
    function _isTrustedForwarder(address forwarder) internal view returns (bool) {
        return IBaseModule(AppBase._getMainAccount()).isTrustedForwarder(forwarder);
    }

    /**
     * @dev ERC-2771 specifies the context as being a single address (20 bytes).
     */
    function _contextSuffixLength() internal pure returns (uint256) {
        return 20;
    }
    // slither-disable-end dead-code
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

import { AppERC2771Context } from "src/apps/base/AppERC2771Context.sol";
import { AppBase } from "src/apps/base/AppBase.sol";

import { IAccountUtilsModule } from "src/interfaces/accounts/IAccountUtilsModule.sol";

contract AppSecurityModifiers {
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    error InvalidKeySignature(address from);

    /*///////////////////////////////////////////////////////////////
                            SECURITY CHECK MODIFIERS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Modifier to check if the sender is the main account.
     */
    modifier requiresMainAccountSender() {
        if (msg.sender != AppBase._getMainAccount()) {
            revert InvalidKeySignature(msg.sender);
        }

        _;
    }

    /**
     * @notice Modifier to check if the sender is an sudo key.
     */
    modifier requiresSudoKeySender() {
        if (!_isValidSudoKey(AppERC2771Context._msgSender())) {
            revert InvalidKeySignature(AppERC2771Context._msgSender());
        }

        _;
    }

    /**
     * @notice Modifier to check if the sender is a sudo or operation key.
     * If not, it reverts with an error message.
     */
    modifier requiresAuthorizedOperationsParty() {
        if (!_isAuthorizedOperationsParty(AppERC2771Context._msgSender())) {
            revert InvalidKeySignature(AppERC2771Context._msgSender());
        }

        _;
    }

    /**
     * @notice Modifier to check if the sender is an sudo key, a recovery key or a trusted recovery keeper.
     * If not, it reverts with an error message.
     */
    modifier requiresAuthorizedRecoveryParty() {
        if (!_isAuthorizedRecoveryParty(AppERC2771Context._msgSender())) {
            revert InvalidKeySignature(AppERC2771Context._msgSender());
        }

        _;
    }

    /**
     * @notice Validate with the parent account if a key is a sudoKey.
     * @param _key The key to check.
     */
    function _isValidSudoKey(address _key) internal view returns (bool) {
        return IAccountUtilsModule(AppBase._getMainAccount()).isValidSudoKey(_key);
    }

    /**
     * @notice Validate with the parent account if a key is an authorized operations party.
     * @param _key The key to check.
     */
    function _isAuthorizedOperationsParty(address _key) internal view returns (bool) {
        return IAccountUtilsModule(AppBase._getMainAccount()).isAuthorizedOperationsParty(_key);
    }

    /**
     * @notice Validate with the parent account if a key is an authorized recovery party.
     * @param _key The key to check.
     */
    function _isAuthorizedRecoveryParty(address _key) internal view returns (bool) {
        return IAccountUtilsModule(AppBase._getMainAccount()).isAuthorizedRecoveryParty(_key);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library CurveAppError {
    /*///////////////////////////////////////////////////////////////
                                GENERIC
    ///////////////////////////////////////////////////////////////*/

    error TokenIndexMismatch();
    error InvalidPoolAddress(address poolAddress);
    error UnsupportedPool(address poolAddress);
    error InvalidToken();
    error ZeroAddress();
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
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AppAccountBase } from "src/apps/base/AppAccountBase.sol";
import { AppBase } from "src/apps/base/AppBase.sol";
import { CurveAppError } from "src/apps/curve/CurveAppError.sol";

import { ICurveStableSwapApp } from "src/interfaces/curve/ICurveStableSwapApp.sol";
import { ICurveStableSwapAppBeacon } from "src/interfaces/curve/ICurveStableSwapAppBeacon.sol";
import { ICurveStableSwapNG } from "src/interfaces/curve/ICurveStableSwapNG.sol";
import { ICurveStableSwapFactoryNG } from "src/interfaces/curve/ICurveStableSwapFactoryNG.sol";

contract CurveStableSwapApp is AppAccountBase, ICurveStableSwapApp {
    using SafeERC20 for IERC20;

    constructor() {
        _disableInitializers();
    }

    /*///////////////////////////////////////////////////////////////
                    			MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows the authorized operations party to exchange tokens on the stable swap pool.
     * @param _stableSwapPool The address of the stable swap pool.
     * @param _fromToken The address of the ERC20 token provided to exchange.
     * @param _toToken The address of the ERC20 token to receive from the exchange.
     * @param _fromAmount The amount of tokens to exchange.
     * @param _minToAmount The minimum amount of tokens to receive.
     */
    function exchange(address _stableSwapPool, address _fromToken, address _toToken, uint256 _fromAmount, uint256 _minToAmount)
        external
        nonReentrant
        requiresAuthorizedOperationsParty
    {
        _validatePoolAddress(_stableSwapPool);
        // convert token addresses to pool indices, reverts if pool and tokens aren't valid
        (int128 fromTokenIndex, int128 toTokenIndex,) = ICurveStableSwapFactoryNG(_getAppBeacon().curveStableswapFactoryNG())
            .get_coin_indices(_stableSwapPool, _fromToken, _toToken);
        IERC20(_fromToken).approve(_stableSwapPool, _fromAmount);
        uint256 receivedAmount = ICurveStableSwapNG(_stableSwapPool).exchange(fromTokenIndex, toTokenIndex, _fromAmount, _minToAmount);
        emit TokensExchanged(_stableSwapPool, _fromToken, _toToken, _fromAmount, receivedAmount);
    }

    /**
     * @notice Adds liquidity to the specified pool
     * @dev The arrays indices have to match the indices of the tokens in the pool.
     * @param _stableSwapPool The address of the pool to add liquidity to.
     * @param _tokens An array of token addresses to add as liquidity.
     * @param _amounts An array of token amounts to add as liquidity.
     * @param _minLPAmount The minimum amount of LP tokens to receive.
     */
    function addLiquidity(address _stableSwapPool, address[] calldata _tokens, uint256[] calldata _amounts, uint256 _minLPAmount)
        external
        nonReentrant
        requiresAuthorizedOperationsParty
    {
        _validatePoolAddress(_stableSwapPool);
        address[] memory coins = ICurveStableSwapFactoryNG(_getAppBeacon().curveStableswapFactoryNG()).get_coins(_stableSwapPool);
        // check and approve the pool to add the tokens as liquidity
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (coins[i] != _tokens[i]) revert CurveAppError.InvalidToken();
            IERC20(_tokens[i]).approve(_stableSwapPool, _amounts[i]);
        }

        // provide the liquidity
        uint256 lpAmount = ICurveStableSwapNG(_stableSwapPool).add_liquidity(_amounts, _minLPAmount);
        emit LiquidityAdded(_stableSwapPool, _amounts, lpAmount);
    }

    /**
     * @notice Removes liquidity for a single token from the Curve stable swap pool.
     * @param _stableSwapPool The address of the Curve stable swap pool.
     * @param _tokenIndex The index of the token to remove liquidity.
     * @param _lpAmount The amount of LP tokens to burn.
     * @param _minReceiveAmount The minimum amount of tokens to receive in return.
     * @return The amount of tokens received after removing liquidity.
     */
    function removeSingleTokenLiquidity(address _stableSwapPool, int128 _tokenIndex, uint256 _lpAmount, uint256 _minReceiveAmount)
        external
        nonReentrant
        requiresAuthorizedOperationsParty
        returns (uint256)
    {
        return _removeSingleTokenLiquidity(_stableSwapPool, _tokenIndex, _lpAmount, _minReceiveAmount);
    }

    /**
     * @notice Withdraw coins from a Curve stable swap pool in an imbalanced amount.
     * @param _stableSwapPool The address of the Curve stable swap pool.
     * @param _lpAmount The max amount of LP tokens to burn.
     * @param _amounts The amount of tokens to receive in return.
     */
    function removeLiquidityImbalance(address _stableSwapPool, uint256 _lpAmount, uint256[] calldata _amounts)
        external
        nonReentrant
        requiresAuthorizedOperationsParty
    {
        _removeLiquidityImbalance(_stableSwapPool, _lpAmount, _amounts);
    }

    /**
     * @notice Swaps ERC20 tokens to USDC at the current exchange amount and then recovers to mainAccount
     * @param _stableSwapPool The address of the stable swap pool.
     * @param _fromToken The address of the ERC20 token to recover.
     * @param _minToAmount The minimum amount of USDC to receive.
     * @dev This function must be called by an authorized recovery party.
     */
    function recoverERC20ToUSDC(address _stableSwapPool, address _fromToken, uint256 _minToAmount)
        external
        nonReentrant
        requiresAuthorizedRecoveryParty
    {
        _validatePoolAddress(_stableSwapPool);
        uint256 balance = IERC20(_fromToken).balanceOf(address(this));
        ICurveStableSwapAppBeacon appBeacon = _getAppBeacon();
        address USDC = appBeacon.USDC();
        // convert token addresses to pool indices, reverts if pool and tokens aren't valid
        (int128 fromTokenIndex, int128 toTokenIndex,) =
            ICurveStableSwapFactoryNG(_getAppBeacon().curveStableswapFactoryNG()).get_coin_indices(_stableSwapPool, _fromToken, USDC);
        IERC20(_fromToken).approve(_stableSwapPool, balance);
        // swap to USDC
        uint256 receivedAmount = ICurveStableSwapNG(_stableSwapPool).exchange(fromTokenIndex, toTokenIndex, balance, _minToAmount);
        emit TokensExchanged(_stableSwapPool, _fromToken, USDC, balance, receivedAmount);
        uint256 USDCRecoverBalance = IERC20(USDC).balanceOf(address(this));
        emit ERC20RecoveredToMainAccount(USDC, USDCRecoverBalance);
        _transferERC20ToMainAccount(USDC, USDCRecoverBalance);
    }

    /**
     * @notice Removes all Liquidity as USDC with specified slippage amount and then recovers to mainAccount
     * @param _LPToken The address of the pool to remove liquidity from.
     * @param _USDCIndex The address of the LP token and pool to recover from.
     * @param _minReceiveAmount The minimum amount of USDC to receive.
     * @dev This function must be called by an authorized recovery party.
     */
    function recoverUSDCFromLP(address _LPToken, int128 _USDCIndex, uint256 _minReceiveAmount)
        external
        nonReentrant
        requiresAuthorizedRecoveryParty
    {
        // pool address is validated by _removeSingleTokenLiquidity
        ICurveStableSwapAppBeacon appBeacon = _getAppBeacon();
        address USDC = appBeacon.USDC();

        if (ICurveStableSwapNG(_LPToken).coins(uint256(uint128(_USDCIndex))) != USDC) revert CurveAppError.TokenIndexMismatch();

        // recover funds
        uint256 lpBalance = IERC20(_LPToken).balanceOf(address(this));

        // the LP token is the pool address
        uint256 USDCRemoved = _removeSingleTokenLiquidity(_LPToken, _USDCIndex, lpBalance, _minReceiveAmount);

        emit ERC20RecoveredToMainAccount(USDC, USDCRemoved);
        _transferERC20ToMainAccount(USDC, IERC20(USDC).balanceOf(address(this)));
    }

    /**
     * @notice Removes a single token from an LP for the purpose of recovery
     * @param _LPToken The address of the LP token/pool to remove liquidity from.
     * @param _tokenIndex The index of the token to remove from the liquidity pool
     * @param _minToAmount The minimum amount of token to withdraw from the liquidity pool.
     * @dev This function must be called by an authorized recovery party.
     */
    function recoverERC20FromLP(address _LPToken, int128 _tokenIndex, uint256 _minToAmount)
        external
        nonReentrant
        requiresAuthorizedRecoveryParty
    {
        // pool address is validated by _removeSingleTokenLiquidity
        // remove token from pool
        uint256 lpBalance = IERC20(_LPToken).balanceOf(address(this));
        _removeSingleTokenLiquidity(_LPToken, _tokenIndex, lpBalance, _minToAmount);
    }

    /*///////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Removes liquidity for a single token from the Curve stable swap pool.
     * @param _stableSwapPool The address of the Curve stable swap pool.
     * @param _tokenIndex The index of the token to remove liquidity for.
     * @param _lpAmount The amount of LP tokens to burn.
     * @param _minReceiveAmount The minimum amount of tokens to receive in return.
     * @return amountRemoved The amount of tokens that were removed from the pool.
     */
    function _removeSingleTokenLiquidity(address _stableSwapPool, int128 _tokenIndex, uint256 _lpAmount, uint256 _minReceiveAmount)
        internal
        returns (uint256 amountRemoved)
    {
        _validatePoolAddress(_stableSwapPool);
        amountRemoved = ICurveStableSwapNG(_stableSwapPool).remove_liquidity_one_coin(_lpAmount, _tokenIndex, _minReceiveAmount);
        emit LiquidityRemovedSingleToken(_stableSwapPool, amountRemoved, _lpAmount);
    }

    /**
     * @notice Withdraw coins from a Curve stable swap pool in an imbalanced amount.
     * @param _stableSwapPool The address of the Curve stable swap pool.
     * @param _lpAmount The max amount of LP tokens to be burned for the token amounts to be removed
     * @param _amounts The amounts of tokens to be removed from the pool.
     */
    function _removeLiquidityImbalance(address _stableSwapPool, uint256 _lpAmount, uint256[] calldata _amounts) internal {
        _validatePoolAddress(_stableSwapPool);
        uint256 amountLPBurnt = ICurveStableSwapNG(_stableSwapPool).remove_liquidity_imbalance(_amounts, _lpAmount);
        emit LiquidityRemoved(_stableSwapPool, _amounts, amountLPBurnt);
    }

    function _validatePoolAddress(address _stableSwapPool) internal {
        ICurveStableSwapAppBeacon appBeacon = _getAppBeacon();
        if (!appBeacon.isSupportedPool(_stableSwapPool)) revert CurveAppError.UnsupportedPool(_stableSwapPool);
        if (ICurveStableSwapFactoryNG(appBeacon.curveStableswapFactoryNG()).get_implementation_address(_stableSwapPool) == address(0))
        {
            revert CurveAppError.InvalidPoolAddress(_stableSwapPool);
        }
    }

    /**
     * @dev Returns the beacon contract for the Curve StableSwap app.
     * @return The beacon contract for the Curve StableSwap app.
     */
    function _getAppBeacon() internal view returns (ICurveStableSwapAppBeacon) {
        return (ICurveStableSwapAppBeacon(AppBase._getAppBeacon()));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IAccountUtilsModule {
    event AccountInfinexProtocolBeaconImplementationUpgraded(address infinexProtocolConfigBeacon);

    event AccountSynthetixInformationBeaconUpgraded(address synthetixInformationBeacon);

    event AccountCircleBridgeParamsUpgraded(address circleBridge, address circleMinter, uint32 defaultDestinationCCTPDomain);

    event AccountWormholeCircleBridgeParamsUpgraded(address wormholeCircleBridge, uint16 defaultDestinationWormholeChainId);

    event AccountUSDCAddressUpgraded(address USDC);

    /*///////////////////////////////////////////////////////////////
                                    VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the Infinex Protocol Config
     * @return The Infinex Protocol Config Beacon
     */
    function infinexProtocolConfigBeacon() external view returns (address);

    /**
     * @notice Check if the provided operation key is valid
     * @param _operationKey The operation key to check
     * @return A boolean indicating if the key is valid
     */
    function isValidOperationKey(address _operationKey) external view returns (bool);

    /**
     * @notice Check if the provided sudo key is valid
     * @param _sudoKey The sudo key to check
     * @return A boolean indicating if the sudo key is valid
     */
    function isValidSudoKey(address _sudoKey) external view returns (bool);

    /**
     * @notice Check if the provided recovery key is valid
     * @param _recoveryKey The recovery key to check
     * @return A boolean indicating if the recovery key is valid
     */
    function isValidRecoveryKey(address _recoveryKey) external view returns (bool);

    /**
     * @notice Checks if the given address is an authorized operations party.
     * @param _key The address to check.
     * @return A boolean indicating whether the address is an authorized operations party.
     * @dev Update this function whenever the logic for requiresAuthorizedOperationsParty
     * from SecurityModifiers changes
     */
    function isAuthorizedOperationsParty(address _key) external view returns (bool);

    /**
     * @notice Checks if the given address is an authorized recovery party.
     * @param _key The address to check.
     * @return A boolean indicating whether the address is an authorized recovery party.
     * @dev Update this function whenever the logic for requiresAuthorizedRecoveryParty
     * from SecurityModifiers changes
     */
    function isAuthorizedRecoveryParty(address _key) external view returns (bool);

    /**
     * @notice Retrieves the Circle Bridge parameters.
     * @return The address of the circleBridge
     * @return The address of the minter.
     * @return The default circle bridge destination domain.
     */
    function getCircleBridgeParams() external view returns (address, address, uint32);

    /**
     * @notice Retrieves the wormhole circle bridge
     * @return The wormhole circle bridge address.
     */
    function getWormholeCircleBridge() external view returns (address);

    /**
     * @notice Retrieves the Wormhole Circle Bridge parameters.
     * @return The address of the wormholeCircleBridge
     * @return The address of the wormholeCircleBridge and the default defaultDestinationWormholeChainId
     */
    function getWormholeCircleBridgeParams() external view returns (address, uint16);

    /**
     * @notice Retrieves the USDC address.
     * @return The address of USDC
     */
    function getUSDCAddress() external view returns (address);

    /**
     * @notice Retrieves the maximum withdrawal fee.
     * @return The maximum withdrawal fee.
     */
    function getMaxWithdrawalFee() external pure returns (uint256);

    /*///////////////////////////////////////////////////////////////
                                MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Upgrade to a new beacon implementation and updates any new parameters along with it
     * @param _newInfinexProtocolConfigBeacon The address of the new beacon
     * @dev requires the sender to be the sudo key
     * @dev Requires passing the new beacon address which matches the latest to ensure that the upgrade both
     * is as the user intended, and is to the latest beacon implementation. Prevents the user from opting in to a
     * specific version and upgrading to a later version that may have been deployed between the opt-in and the upgrade
     */
    function upgradeProtocolBeaconParameters(address _newInfinexProtocolConfigBeacon) external;

    /**
     * @notice Updates the parameters for the Circle Bridge to the latest from the Infinex Protocol Config Beacon.
     * Update is opt in to prevent malicious automatic updates.
     * @dev requires the sender to be the sudo key
     */
    function updateCircleBridgeParams() external;

    /**
     * @notice Updates the parameters for the Wormhole Circle Bridge to the latest from the Infinex Protocol Config Beacon.
     * Update is opt in to prevent malicious automatic updates.
     * @dev requires the sender to be the sudo key
     */
    function updateWormholeCircleBridge() external;

    /**
     * @notice Updates the USDC address from the Infinex Protocol Config Beacon.
     * Update is opt in to prevent malicious automatic updates.
     * @dev requires the sender to be the sudo key
     */
    function updateUSDCAddress() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { RequestTypes } from "src/accounts/utils/RequestTypes.sol";

interface IBaseModule {
    /*///////////////////////////////////////////////////////////////
                    			EVENTS / ERRORS
    ///////////////////////////////////////////////////////////////*/

    event AccountImplementationUpgraded(address accountImplementation);
    event AccountMigratedFrom(uint64 previousVersion, uint64 currentVersion);

    /*///////////////////////////////////////////////////////////////
                                 		INITIALIZER
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize the account with the sudo key
     */
    function initialize(address _sudoKey) external;

    /**
     * @notice Reinitialize the account with the current version
     * @dev Only to be called by the upgradeTo function
     */
    function reinitialize(uint64 _previousVersion) external;

    /**
     * @notice Reinitialize the account with the current version
     * @dev Only to be called once to reinitialize accounts created with v1
     */
    function reinitializeLegacyAccount() external;

    /*///////////////////////////////////////////////////////////////
                                    VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the version number of the account.
     * @return A uint64 representing the version of the account.
     * @dev The version number is provided by the OZ Initializable library
     */
    function accountVersion() external view returns (uint64);

    /**
     * @notice Check if the provided nonce is valid
     * @param _nonce The nonce to check
     * @return A boolean indicating if the nonce is valid
     */
    function isValidNonce(bytes32 _nonce) external view returns (bool);

    /**
     * @notice Check if the provided forwarder is trusted
     * @param _forwarder The forwarder to check
     * @return A boolean indicating if the forwarder is trusted
     */
    function isTrustedForwarder(address _forwarder) external view returns (bool);

    /**
     * @notice Get all trusted forwarders
     * @return An array of addresses of all trusted forwarders
     */
    function trustedForwarders() external view returns (address[] memory);

    /*///////////////////////////////////////////////////////////////
                    			MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Enables or disables an operation key for the account
     * @param _operationKey The address of the operation key to be set
     * @param _isValid Whether the key is to be set as valid or invalid
     * @dev This function requires the sender to be the sudo key holder
     */
    function setOperationKeyStatus(address _operationKey, bool _isValid) external;

    /**
     * @notice Enables or disables a recovery key for the account
     * @param _recoveryKey The address of the recovery key to be set
     * @param _isValid Whether the key is to be set as valid or invalid
     * @dev This function requires the sender to be the sudo key holder
     */
    function setRecoveryKeyStatus(address _recoveryKey, bool _isValid) external;

    /**
     * @notice Enables or disables a sudo key for the account
     * @param _sudoKey The address of the sudo key to be set
     * @param _isValid Whether the key is to be set as valid or invalid
     * @dev This function requires the sender to be the sudo key holder
     */
    function setSudoKeyStatus(address _sudoKey, bool _isValid) external;

    /**
     * @notice Add a new trusted forwarder
     * @param _request The Request struct containing:
     *  RequestData {
     *  address _address; - The address of the new trusted forwarder.
     *	bytes32 _nonce; - The nonce of the signature
     *  }
     * @param _signature The required signature for executing the transaction
     * Required signature:
     * - sudo key
     */
    function addTrustedForwarder(RequestTypes.Request calldata _request, bytes calldata _signature) external;

    /**
     * @notice Remove a trusted forwarder
     * @param _request The Request struct containing:
     *  RequestData {
     *  address _address; - The address of the trusted forwarder to be removed.
     *	bytes32 _nonce; - The nonce of the signature
     *  }
     * @param _signature The required signature for executing the transaction
     * Required signature:
     * - sudo key
     */
    function removeTrustedForwarder(RequestTypes.Request calldata _request, bytes calldata _signature) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title IAppAccountBase
 * @notice Interface for the App Account Base
 */
interface IAppAccountBase {
    /*///////////////////////////////////////////////////////////////
    	 						EVENTS
    ///////////////////////////////////////////////////////////////*/

    event EtherTransferredToMainAccount(uint256 amount);
    event ERC20TransferredToMainAccount(address indexed token, uint256 amount);
    event ERC721TransferredToMainAccount(address indexed token, uint256 tokenId);
    event ERC1155TransferredToMainAccount(address indexed token, uint256 tokenId, uint256 amount, bytes data);
    event ERC1155BatchTransferredToMainAccount(address indexed token, uint256[] _ids, uint256[] _values, bytes _data);
    event EtherRecoveredToMainAccount(uint256 amount);
    event ERC20RecoveredToMainAccount(address indexed token, uint256 amount);
    event ERC721RecoveredToMainAccount(address indexed token, uint256 tokenId);
    event ERC1155RecoveredToMainAccount(address indexed token, uint256 tokenId, uint256 amount, bytes data);
    event ERC1155BatchRecoveredToMainAccount(address indexed token, uint256[] tokenIds, uint256[] amounts, bytes _data);

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    error InvalidAppBeacon();
    error ImplementationMismatch(address implementation, address latestImplementation);
    error ETHTransferFailed();

    /*///////////////////////////////////////////////////////////////
                                 		INITIALIZER
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize the app account with the main account and the app beacon.
     * @param _mainAccount the address of the main account, this is the owner of the app.
     * @param _appBeacon the beacon for the app account.
     */
    function initialize(address _mainAccount, address _appBeacon) external;

    /*///////////////////////////////////////////////////////////////
                    			VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the app version number of the app account.
     * @return A uint64 representing the version of the app.
     * @dev NOTE: This number must be updated whenever a new version is deployed.
     * The number should always only be incremented by 1.
     */
    function appVersion() external pure returns (uint64);

    /**
     * @notice Get the app's main account.
     * @return The main account associated with this app.
     */
    function getMainAccount() external view returns (address);

    /**
     * @notice Get the app config beacon.
     * @return The app config beacon address.
     */
    function getAppBeacon() external view returns (address);

    /*///////////////////////////////////////////////////////////////
                    			MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfer Ether to the main account from the app account.
     * @param _amount The amount of Ether to transfer.
     */
    function transferEtherToMainAccount(uint256 _amount) external;

    /**
     * @notice Transfer ERC20 tokens to the main account from the app account.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount of tokens to transfer.
     */
    function transferERC20ToMainAccount(address _token, uint256 _amount) external;

    /**
     * @notice Transfer ERC721 tokens to the main account from the app account.
     * @param _token The address of the ERC721 token.
     * @param _tokenId The ID of the ERC721 token.
     */
    function transferERC721ToMainAccount(address _token, uint256 _tokenId) external;

    /**
     * @notice Transfer ERC1155 tokens to the main account from the app account.
     * @param _token The address of the ERC1155 token.
     * @param _tokenId The ID of the ERC1155 token.
     * @param _amount The amount of tokens to transfer.
     * @param _data Data to send with the transfer.
     */
    function transferERC1155ToMainAccount(address _token, uint256 _tokenId, uint256 _amount, bytes calldata _data) external;

    /**
     * @notice Transfers batch ERC1155 tokens to the main account from the app account.
     * @param _token The address of the ERC1155 token.
     * @param _ids The IDs of the ERC1155 tokens.
     * @param _amounts The amounts of the ERC1155 tokens.
     * @param _data Data to send with the transfer.
     */
    function transferERC1155BatchToMainAccount(
        address _token,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external;

    /**
     * @notice Recovers all ether in the app account to the main account.
     * @dev Requires the sender to be an authorized recovery party.
     */
    function recoverEtherToMainAccount() external;

    /**
     * @notice Recovers the full balance of an ERC20 token to the main account.
     * @param _token The address of the token to be recovered to the main account.
     * @dev Requires the sender to be an authorized recovery party.
     */
    function recoverERC20ToMainAccount(address _token) external;

    /**
     * @notice Recovers a specified ERC721 token to the main account.
     * @param _token The ERC721 token address to recover.
     * @param _tokenId The ID of the ERC721 token to recover.
     * @dev Requires the sender to be an authorized recovery party.
     */
    function recoverERC721ToMainAccount(address _token, uint256 _tokenId) external;

    /**
     * @notice Recovers all the tokens of a specified ERC1155 token to the main account.
     * @param _token The ERC1155 token address to recover.
     * @param _tokenId The id of the token to recover.
     * @param _data The data for the transaction.
     * @dev Requires the sender to be an authorized recovery party.
     */
    function recoverERC1155ToMainAccount(address _token, uint256 _tokenId, bytes calldata _data) external;

    /**
     * @notice Recovers batch ERC1155 tokens to the main account.
     * @param _token The address of the ERC1155 token.
     * @param _ids The IDs of the ERC1155 tokens.
     * @param _values The values of the ERC1155 tokens.
     * @param _data Data to send with the transfer.
     */
    function recoverERC1155BatchToMainAccount(
        address _token,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
     * @notice Upgrade the app account to the latest implementation and beacon.
     * @param _appBeacon The address of the new app beacon.
     * @param _latestAppImplementation The address of the latest app implementation.
     * @dev Requires the sender to be the main account.
     */
    function upgradeAppVersion(address _appBeacon, address _latestAppImplementation) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title IAppBeaconBase
 * @notice Interface for the App Beacon Base
 */
interface IAppBeaconBase {
    /*///////////////////////////////////////////////////////////////
    	 						STRUCTS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Struct containing the config for the app beacon.
     * @param appName The name of the app.
     * @param latestAppImplementation The address of the latest app implementation.
     * @param latestAppBeacon The address of the latest app beacon.
     */
    struct AppBeaconConfig {
        string appName;
        address latestAppImplementation;
        address latestAppBeacon;
    }

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    error ZeroAddress();
    error InvalidAppAccountImplementation();
    error InvalidAppBeacon();

    /*///////////////////////////////////////////////////////////////
    	 						EVENTS
    ///////////////////////////////////////////////////////////////*/

    event LatestAppImplementationSet(address latestAppImplementation);
    event LatestAppBeaconSet(address latestAppBeacon);

    /*///////////////////////////////////////////////////////////////
                    			VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the name of the app associated to the beacon.
     * @return The name of the app beacon.
     */
    function getAppName() external view returns (string memory);

    /**
     * @notice Gets the latest app implementation.
     * @return The address of the latest app implementation.
     */
    function getLatestAppImplementation() external view returns (address);

    /**
     * @notice Gets the latest beacon address for the app.
     * @return The address of the latest app beacon.
     */
    function getLatestAppBeacon() external view returns (address);

    /*///////////////////////////////////////////////////////////////
                    		    MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the latest app implementation address.
     * @param _latestAppImplementation The address of the latest implementation for the app.
     */
    function setLatestAppImplementation(address _latestAppImplementation) external;

    /**
     * @notice Sets the latest app beacon address.
     * @param _latestAppBeacon The address of the latest app beacon associated with the app.
     */
    function setLatestAppBeacon(address _latestAppBeacon) external;
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

/**
 * @title ICurveStableSwapApp
 * @notice Interface for the curve stable swap app.
 */
interface ICurveStableSwapApp {
    /*///////////////////////////////////////////////////////////////
    	 					    EVENTS
    ///////////////////////////////////////////////////////////////*/

    event TokensExchanged(address indexed stableSwapPool, address fromToken, address toToken, uint256 fromAmount, uint256 toAmount);
    event LiquidityAdded(address indexed stableSwapPool, uint256[] amounts, uint256 lpAmount);
    event LiquidityRemoved(address indexed stableSwapPool, uint256[] amounts, uint256 lpAmount);
    event LiquidityRemovedSingleToken(address indexed stableSwapPool, uint256 amountRemoved, uint256 lpAmountBurnt);

    /*///////////////////////////////////////////////////////////////
                    			MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows the authorized operations party to exchange tokens on the stable swap pool.
     * @param _stableSwapPool The address of the stable swap pool.
     * @param _fromToken The address of the ERC20 token provided to exchange.
     * @param _toToken The address of the ERC20 token to receive from the exchange.
     * @param _fromAmount The amount of tokens to exchange.
     * @param _minToAmount The minimum amount of tokens to receive.
     */
    function exchange(address _stableSwapPool, address _fromToken, address _toToken, uint256 _fromAmount, uint256 _minToAmount)
        external;

    /**
     * @notice Adds liquidity to the specified pool
     * @dev The arrays indices have to match the indices of the tokens in the pool.
     * @param _stableSwapPool The address of the pool to add liquidity to.
     * @param _tokens An array of token addresses to add as liquidity.
     * @param _amounts An array of token amounts to add as liquidity.
     * @param _minLPAmount The minimum amount of LP tokens to receive.
     */
    function addLiquidity(address _stableSwapPool, address[] calldata _tokens, uint256[] calldata _amounts, uint256 _minLPAmount)
        external;

    /**
     * @notice Removes liquidity for a single token from the Curve stable swap pool.
     * @param _stableSwapPool The address of the Curve stable swap pool.
     * @param _tokenIndex The index of the token to remove liquidity.
     * @param _lpAmount The amount of LP tokens to burn.
     * @param _minReceiveAmount The minimum amount of tokens to receive in return.
     * @return The amount of tokens received after removing liquidity.
     */
    function removeSingleTokenLiquidity(address _stableSwapPool, int128 _tokenIndex, uint256 _lpAmount, uint256 _minReceiveAmount)
        external
        returns (uint256);

    /**
     * @notice Withdraw coins from a Curve stable swap pool in an imbalanced amount.
     * @param _stableSwapPool The address of the Curve stable swap pool.
     * @param _lpAmount The max amount of LP tokens to burn.
     * @param _amounts The amount of tokens to receive in return.
     */
    function removeLiquidityImbalance(address _stableSwapPool, uint256 _lpAmount, uint256[] calldata _amounts) external;

    /**
     * @notice Swaps ERC20 tokens to USDC at the current exchange amount and then recovers to mainAccount
     * @param _stableSwapPool The address of the stable swap pool.
     * @param _fromToken The address of the ERC20 token to recover.
     * @param _minToAmount The minimum amount of USDC to receive.
     * @dev This function must be called by an authorized recovery party.
     */
    function recoverERC20ToUSDC(address _stableSwapPool, address _fromToken, uint256 _minToAmount) external;

    /**
     * @notice Removes all Liquidity as USDC with specified slippage amount and then recovers to mainAccount
     * @param _LPToken The address of the pool to remove liquidity from.
     * @param _USDCIndex The address of the LP token and pool to recover from.
     * @param _minReceiveAmount The minimum amount of USDC to receive.
     * @dev This function must be called by an authorized recovery party.
     */
    function recoverUSDCFromLP(address _LPToken, int128 _USDCIndex, uint256 _minReceiveAmount) external;

    /**
     * @notice Removes a single token from an LP for the purpose of recovery
     * @param _LPToken The address of the LP token/pool to remove liquidity from.
     * @param _tokenIndex The index of the token to remove from the liquidity pool
     * @param _minToAmount The minimum amount of token to withdraw from the liquidity pool.
     * @dev This function must be called by an authorized recovery party.
     */
    function recoverERC20FromLP(address _LPToken, int128 _tokenIndex, uint256 _minToAmount) external;
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

/**
 * @title ICurveStableSwapAppBeacon
 * @notice Interface for the curve app beacon.
 */
interface ICurveStableSwapAppBeacon {
    /*///////////////////////////////////////////////////////////////
    	 				        STRUCTS
    ///////////////////////////////////////////////////////////////*/

    struct PoolData {
        address pool;
        int128 fromTokenIndex;
        int128 toTokenIndex;
        uint256 amountReceived;
        address[] tokens;
        uint256[] balances;
        uint256[] decimals;
        bool isUnderlying;
    }

    /*///////////////////////////////////////////////////////////////
    	 				    VIEW FUNCTIONS/VARIABLES
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the curve stable swap factory address.
     * @return The address of the curve stable swap factory.
     */
    function curveStableswapFactoryNG() external view returns (address);

    /**
     * @notice Gets the USDC address.
     * @return The address of the USDC token.
     */
    function USDC() external view returns (address);

    /**
     * @notice Checks if a pool has been vetted by the council and can be safely used by the app
     * @param _pool The address of the pool.
     * @return True if the pool is supported, false otherwise.
     */
    function isSupportedPool(address _pool) external view returns (bool);

    /**
     * @notice Get the pool data for the given tokens. Data will be empty if type is underyling
     * @param _fromToken The address of the token to swap from.
     * @param _toToken The address of the token to swap to.
     * @return poolData The pool data for the given tokens.
     */
    function getPoolDatafromTokens(address _fromToken, address _toToken, uint256 _fromAmount)
        external
        returns (PoolData memory poolData);

    /**
     * @notice A safety feature to limit the pools that can be used by the app to only vetted and suppported pools
     * @dev Only the contract owner can call this function.
     * @param _pool The address of the pool.
     * @param _supported The supported status of the pool.
     */
    function setIsSupportedPool(address _pool, bool _supported) external;
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

// from https://github.com/curvefi/stableswap-ng

/**
 * @title ICurveStableSwapFactoryNG
 * @notice Interface for the curve stable swap factory.
 */
interface ICurveStableSwapFactoryNG {
    /**
     * @notice Find an available pool for exchanging two coins
     * @param _from Address of coin to be sent
     * @param _to Address of coin to be received
     * @param i Index value. When multiple pools are available
     *        this value is used to return the n'th address.
     * @return Pool address
     */
    function find_pool_for_coins(address _from, address _to, uint256 i) external view returns (address);

    /**
     * @notice Find an available pool for exchanging two coins
     * @param _from Address of coin to be sent
     * @param _to Address of coin to be received
     * @return Pool address
     */
    function find_pool_for_coins(address _from, address _to) external view returns (address);

    /**
     * @notice Get the base pool for a given factory metapool
     * @param _pool Metapool address
     * @return Address of base pool
     */
    function get_base_pool(address _pool) external view returns (address);

    /**
     * @notice Get the number of coins in a pool
     * @param _pool Pool address
     * @return Number of coins
     */
    function get_n_coins(address _pool) external view returns (uint256);

    /**
     * @notice Get the coins within a pool
     * @param _pool Pool address
     * @return List of coin addresses
     */
    function get_coins(address _pool) external view returns (address[] memory);

    /**
     * @notice Get the underlying coins within a pool
     * @dev Reverts if a pool does not exist or is not a metapool
     * @param _pool Pool address
     * @return List of coin addresses
     */
    function get_underlying_coins(address _pool) external view returns (address[] memory);

    /**
     * @notice Get decimal places for each coin within a pool
     * @param _pool Pool address
     * @return uint256 list of decimals
     */
    function get_decimals(address _pool) external view returns (uint256[] memory);

    /**
     * @notice Get decimal places for each underlying coin within a pool
     * @param _pool Pool address
     * @return uint256 list of decimals
     */
    function get_underlying_decimals(address _pool) external view returns (uint256[] memory);

    /**
     * @notice Get rates for coins within a metapool
     * @param _pool Pool address
     * @return Rates for each coin, precision normalized to 10**18
     */
    function get_metapool_rates(address _pool) external view returns (uint256[] memory);

    /**
     * @notice Get balances for each coin within a pool
     * @dev For pools using lending, these are the wrapped coin balances
     * @param _pool Pool address
     * @return uint256 list of balances
     */
    function get_balances(address _pool) external view returns (uint256[] memory);

    /**
     * @notice Get balances for each underlying coin within a metapool
     * @param _pool Metapool address
     * @return uint256 list of underlying balances
     */
    function get_underlying_balances(address _pool) external view returns (uint256[] memory);

    /**
     * @notice Get the amplfication co-efficient for a pool
     * @param _pool Pool address
     * @return uint256 A
     */
    function get_A(address _pool) external view returns (uint256);

    /**
     * @notice Get the fees for a pool
     * @dev Fees are expressed as integers
     * @param _pool Pool address
     * @return Pool fee and admin fee as uint256 with 1e10 precision
     */
    function get_fees(address _pool) external view returns (uint256, uint256);

    /**
     * @notice Get the current admin balances (uncollected fees) for a pool
     * @param _pool Pool address
     * @return List of uint256 admin balances
     */
    function get_admin_balances(address _pool) external view returns (uint256[] memory);

    /**
     * @notice Convert coin addresses to indices for use with pool methods
     * @param _pool Pool address
     * @param _from Coin address to be used as `i` within a pool
     * @param _to Coin address to be used as `j` within a pool
     * @return int128 `i`, int128 `j`, boolean indicating if `i` and `j` are underlying coins
     */
    function get_coin_indices(address _pool, address _from, address _to) external view returns (int128, int128, bool);

    /**
     * @notice Get the address of the liquidity gauge contract for a factory pool
     * @dev Returns `empty(address)` if a gauge has not been deployed
     * @param _pool Pool address
     * @return Implementation contract address
     */
    function get_gauge(address _pool) external view returns (address);

    /**
     * @notice Get the address of the implementation contract used for a factory pool
     * @param _pool Pool address
     * @return Implementation contract address
     */
    function get_implementation_address(address _pool) external view returns (address);

    /**
     * @notice Verify `_pool` is a metapool
     * @param _pool Pool address
     * @return True if `_pool` is a metapool
     */
    function is_meta(address _pool) external view returns (bool);

    /**
     * @notice Query the asset type of `_pool`
     * @param _pool Pool Address
     * @return Dynarray of uint8 indicating the pool asset type
     *         Asset Types:
     *             0. Standard ERC20 token with no additional features
     *             1. Oracle - token with rate oracle (e.g. wrapped staked ETH)
     *             2. Rebasing - token with rebase (e.g. staked ETH)
     *             3. ERC4626 - e.g. sDAI
     */
    function get_pool_asset_types(address _pool) external view returns (uint8[] memory);

    /**
     * @notice Deploy a new plain pool
     * @param _name Name of the new plain pool
     * @param _symbol Symbol for the new plain pool - will be
     *                concatenated with factory symbol
     * @param _coins List of addresses of the coins being used in the pool.
     * @param _A Amplification co-efficient - a lower value here means
     *           less tolerance for imbalance within the pool's assets.
     *           Suggested values include:
     *            * Uncollateralized algorithmic stablecoins: 5-10
     *            * Non-redeemable, collateralized assets: 100
     *            * Redeemable assets: 200-400
     * @param _fee Trade fee, given as an integer with 1e10 precision. The
     *             maximum is 1% (100000000). 50% of the fee is distributed to veCRV holders.
     * @param _offpeg_fee_multiplier Off-peg fee multiplier
     * @param _ma_exp_time Averaging window of oracle. Set as time_in_seconds / ln(2)
     *                     Example: for 10 minute EMA, _ma_exp_time is 600 / ln(2) ~= 866
     * @param _implementation_idx Index of the implementation to use
     * @param _asset_types Asset types for pool, as an integer
     * @param _method_ids Array of first four bytes of the Keccak-256 hash of the function signatures
     *                    of the oracle addresses that gives rate oracles.
     *                    Calculated as: keccak(text=event_signature.replace(" ", ""))[:4]
     * @param _oracles Array of rate oracle addresses.
     * @return Address of the deployed pool
     */
    function deploy_plain_pool(
        string memory _name,
        string memory _symbol,
        address[] memory _coins,
        uint256 _A,
        uint256 _fee,
        uint256 _offpeg_fee_multiplier,
        uint256 _ma_exp_time,
        uint256 _implementation_idx,
        uint8[] memory _asset_types,
        bytes4[] memory _method_ids,
        address[] memory _oracles
    ) external returns (address);
    /**
     * @notice Deploy a new metapool
     * @param _base_pool Address of the base pool to use
     *                   within the metapool
     * @param _name Name of the new metapool
     * @param _symbol Symbol for the new metapool - will be
     *                concatenated with the base pool symbol
     * @param _coin Address of the coin being used in the metapool
     * @param _A Amplification co-efficient - a higher value here means
     *           less tolerance for imbalance within the pool's assets.
     *           Suggested values include:
     *            * Uncollateralized algorithmic stablecoins: 5-10
     *            * Non-redeemable, collateralized assets: 100
     *            * Redeemable assets: 200-400
     * @param _fee Trade fee, given as an integer with 1e10 precision. The
     *             the maximum is 1% (100000000).
     *             50% of the fee is distributed to veCRV holders.
     * @param _offpeg_fee_multiplier Off-peg fee multiplier
     * @param _ma_exp_time Averaging window of oracle. Set as time_in_seconds / ln(2)
     *                     Example: for 10 minute EMA, _ma_exp_time is 600 / ln(2) ~= 866
     * @param _implementation_idx Index of the implementation to use
     * @param _asset_type Asset type for token, as an integer
     * @param _method_id  First four bytes of the Keccak-256 hash of the function signatures
     *                    of the oracle addresses that gives rate oracles.
     *                    Calculated as: keccak(text=event_signature.replace(" ", ""))[:4]
     * @param _oracle Rate oracle address.
     * @return Address of the deployed pool
     */
    function deploy_metapool(
        address _base_pool,
        string memory _name,
        string memory _symbol,
        address _coin,
        uint256 _A,
        uint256 _fee,
        uint256 _offpeg_fee_multiplier,
        uint256 _ma_exp_time,
        uint256 _implementation_idx,
        uint8 _asset_type,
        bytes4 _method_id,
        address _oracle
    ) external returns (address);
    /**
     * @notice Deploy a liquidity gauge for a factory pool
     * @param _pool Factory pool address to deploy a gauge for
     * @return Address of the deployed gauge
     */
    function deploy_gauge(address _pool) external returns (address);

    /**
     * @notice Add a base pool to the registry, which may be used in factory metapools
     * @dev 1. Only callable by admin
     *      2. Rebasing tokens are not allowed in the base pool.
     *      3. Do not add base pool which contains native tokens (e.g. ETH).
     *      4. As much as possible: use standard ERC20 tokens.
     *      Should you choose to deviate from these recommendations, audits are advised.
     * @param _base_pool Pool address to add
     * @param _base_lp_token LP token of the base pool
     * @param _asset_types Asset type for pool, as an integer
     * @param _n_coins Number of coins in the pool
     */
    function add_base_pool(address _base_pool, address _base_lp_token, uint8[] memory _asset_types, uint256 _n_coins) external;

    /**
     * @notice Set implementation contracts for pools
     * @dev Only callable by admin
     * @param _implementation_index Implementation index where implementation is stored
     * @param _implementation Implementation address to use when deploying plain pools
     */
    function set_pool_implementations(uint256 _implementation_index, address _implementation) external;

    /**
     * @notice Set implementation contracts for metapools
     * @dev Only callable by admin
     * @param _implementation_index Implementation index where implementation is stored
     * @param _implementation Implementation address to use when deploying meta pools
     */
    function set_metapool_implementations(uint256 _implementation_index, address _implementation) external;

    /**
     * @notice Set implementation contracts for StableSwap Math
     * @dev Only callable by admin
     * @param _math_implementation Address of the math implementation contract
     */
    function set_math_implementation(address _math_implementation) external;

    /**
     * @notice Set implementation contracts for liquidity gauge
     * @dev Only callable by admin
     * @param _gauge_implementation Address of the gauge blueprint implementation contract
     */
    function set_gauge_implementation(address _gauge_implementation) external;

    /**
     * @notice Set implementation contracts for Views methods
     * @dev Only callable by admin
     * @param _views_implementation Implementation address of views contract
     */
    function set_views_implementation(address _views_implementation) external;
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

// from https://github.com/curvefi/stableswap-ng

/**
 * @title ICurveStableSwapNG
 * @notice Interface for the curve stable swap pool.
 */
interface ICurveStableSwapNG {
    /**
     * @notice Calculate the current input dx given output dy
     * @dev Index values can be found via the `coins` public getter method
     * @param i Index value for the coin to send
     * @param j Index value of the coin to receive
     * @param dy Amount of `j` being received after exchange
     * @param pool Address of the pool
     * @return Amount of `i` predicted
     */
    function get_dx(int128 i, int128 j, uint256 dy, address pool) external view returns (uint256);

    /**
     * @notice Calculate the current output dy given input dx
     * @dev Index values can be found via the `coins` public getter method
     * @param i Index value for the coin to send
     * @param j Index value of the coin to receive
     * @param dx Amount of `i` being exchanged
     * @return Amount of `j` predicted
     */
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);

    /**
     * @notice Calculate the amount received when withdrawing a single coin
     * @param _burn_amount Amount of LP tokens to burn in the withdrawal
     * @param i Index value of the coin to withdraw
     * @return Amount of coin received
     */
    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

    /**
     * @notice Returns the address of the token at the specified index.
     * @param i The index of the token.
     * @return The address of the token at the specified index.
     */
    function coins(uint256 i) external view returns (address);

    /**
     * @notice Returns the number of underlying coins in the pool.
     * @return The number of underlying coins in the pool.
     */
    function N_COINS() external view returns (uint256);

    /**
     * @notice Perform an exchange between two coins
     * @dev Index values can be found via the `coins` public getter method
     * @param i Index value for the coin to send
     * @param j Index value of the coin to receive
     * @param _dx Amount of `i` being exchanged
     * @param _min_dy Minimum amount of `j` to receive
     * @return Actual amount of `j` received
     */
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256);

    /**
     * @notice Deposit coins into the pool
     * @param _amounts List of amounts of coins to deposit
     * @param _min_mint_amount Minimum amount of LP tokens to mint from the deposit
     * @return Amount of LP tokens received by depositing
     */
    function add_liquidity(uint256[] memory _amounts, uint256 _min_mint_amount) external returns (uint256);

    /**
     * @notice Withdraw a single coin from the pool
     * @param _burn_amount Amount of LP tokens to burn in the withdrawal
     * @param i Index value of the coin to withdraw
     * @param _min_received Minimum amount of coin to receive
     * @return Amount of coin received
     */
    function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received) external returns (uint256);

    /**
     * @notice Withdraw coins from the pool in an imbalanced amount
     * @param _amounts List of amounts of underlying coins to withdraw
     * @param _max_burn_amount Maximum amount of LP token to burn in the withdrawal
     * @return Actual amount of the LP token burned in the withdrawal
     */
    function remove_liquidity_imbalance(uint256[] memory _amounts, uint256 _max_burn_amount) external returns (uint256);

    /**
     * @notice Withdraw coins from the pool
     * @dev Withdrawal amounts are based on current deposit ratios
     * @param _burn_amount Quantity of LP tokens to burn in the withdrawal
     * @param _min_amounts Minimum amounts of underlying coins to receive
     * @param _receiver Address that receives the withdrawn coins
     * @param _claim_admin_fees Whether to claim admin fees
     * @return List of amounts of coins that were withdrawn
     */
    function remove_liquidity(uint256 _burn_amount, uint256[] memory _min_amounts, address _receiver, bool _claim_admin_fees)
        external
        returns (uint256[] memory);
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