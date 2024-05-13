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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.20;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev An uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IMarketDescriptor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Configurable Interface
/// @notice This interface defines the functions for manage USD stablecoins and market configurations
interface IConfigurable {
    struct MarketConfig {
        MarketBaseConfig baseConfig;
        MarketFeeRateConfig feeRateConfig;
        MarketPriceConfig priceConfig;
    }

    struct MarketBaseConfig {
        // ==================== LP Position Configuration ====================
        /// @notice The minimum entry margin required for per LP position, for example, 10_000_000 means the minimum
        /// entry margin is 10 USD
        uint64 minMarginPerLiquidityPosition;
        /// @notice The maximum leverage for per LP position, for example, 100 means the maximum leverage is 100 times
        uint32 maxLeveragePerLiquidityPosition;
        /// @notice The liquidation fee rate for per LP position,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 liquidationFeeRatePerLiquidityPosition;
        // ==================== Trader Position Configuration ==================
        /// @notice The minimum entry margin required for per trader position, for example, 10_000_000 means
        /// the minimum entry margin is 10 USD
        uint64 minMarginPerPosition;
        /// @notice The maximum leverage for per trader position, for example, 100 means the maximum leverage
        /// is 100 times
        uint32 maxLeveragePerPosition;
        /// @notice The liquidation fee rate for per trader position,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 liquidationFeeRatePerPosition;
        /// @notice The maximum available liquidity used to calculate the maximum size
        /// of the trader's position
        uint128 maxPositionLiquidity;
        /// @notice The maximum value of all positions relative to `maxPositionLiquidity`,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        /// @dev The maximum position value rate is used to calculate the maximum size of
        /// the trader's position, the formula is
        /// `maxSize = maxPositionValueRate * min(liquidity, maxPositionLiquidity) / maxIndexPrice`
        uint32 maxPositionValueRate;
        /// @notice The maximum size of per position relative to `maxSize`,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        /// @dev The maximum size per position rate is used to calculate the maximum size of
        /// the trader's position, the formula is
        /// `maxSizePerPosition = maxSizeRatePerPosition
        ///                       * maxPositionValueRate * min(liquidity, maxPositionLiquidity) / maxIndexPrice`
        uint32 maxSizeRatePerPosition;
        // ==================== Other Configuration ==========================
        /// @notice The liquidation execution fee for LP and trader positions
        uint64 liquidationExecutionFee;
    }

    struct MarketFeeRateConfig {
        /// @notice The protocol funding fee rate as a percentage of funding fee,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 protocolFundingFeeRate;
        /// @notice A coefficient used to adjust how funding fees are paid to the market,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 fundingCoeff;
        /// @notice A coefficient used to adjust how funding fees are distributed between long and short positions,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 protocolFundingCoeff;
        /// @notice The interest rate used to calculate the funding rate,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 interestRate;
        /// @notice The funding buffer, denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 fundingBuffer;
        /// @notice The liquidity funding fee rate, denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 liquidityFundingFeeRate;
        /// @notice The maximum funding rate, denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 maxFundingRate;
    }

    struct VertexConfig {
        /// @notice The balance rate of the vertex, denominated in a bip (i.e. 1e-8)
        uint32 balanceRate;
        /// @notice The premium rate of the vertex, denominated in a bip (i.e. 1e-8)
        uint32 premiumRate;
    }

    struct MarketPriceConfig {
        /// @notice The maximum available liquidity used to calculate the premium rate
        /// when trader increase or decrease positions
        uint128 maxPriceImpactLiquidity;
        /// @notice The index used to store the net position of the liquidation
        uint8 liquidationVertexIndex;
        /// @notice The dynamic depth mode used to determine the formula for calculating the trade price
        uint8 dynamicDepthMode;
        /// @notice The dynamic depth level used to calculate the trade price,
        /// denominated in ten thousandths of a bip (i.e. 1e-8)
        uint32 dynamicDepthLevel;
        VertexConfig[10] vertices;
    }

    /// @notice Emitted when a USD stablecoin is enabled
    /// @param usd The ERC20 token representing the USD stablecoin used in markets
    event USDEnabled(IERC20 indexed usd);

    /// @notice Emitted when a market is enabled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param baseCfg The new market base configuration
    /// @param feeRateCfg The new market fee rate configuration
    /// @param priceCfg The new market price configuration
    event MarketConfigEnabled(
        IMarketDescriptor indexed market,
        MarketBaseConfig baseCfg,
        MarketFeeRateConfig feeRateCfg,
        MarketPriceConfig priceCfg
    );

    /// @notice Emitted when a market configuration is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param newCfg The new market base configuration
    event MarketBaseConfigChanged(IMarketDescriptor indexed market, MarketBaseConfig newCfg);

    /// @notice Emitted when a market fee rate configuration is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param newCfg The new market fee rate configuration
    event MarketFeeRateConfigChanged(IMarketDescriptor indexed market, MarketFeeRateConfig newCfg);

    /// @notice Emitted when a market price configuration is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param newCfg The new market price configuration
    event MarketPriceConfigChanged(IMarketDescriptor indexed market, MarketPriceConfig newCfg);

    /// @notice Market is not enabled
    error MarketNotEnabled(IMarketDescriptor market);
    /// @notice Market is already enabled
    error MarketAlreadyEnabled(IMarketDescriptor market);
    /// @notice Invalid maximum leverage for LP positions
    error InvalidMaxLeveragePerLiquidityPosition(uint32 maxLeveragePerLiquidityPosition);
    /// @notice Invalid liquidation fee rate for LP positions
    error InvalidLiquidationFeeRatePerLiquidityPosition(uint32 invalidLiquidationFeeRatePerLiquidityPosition);
    /// @notice Invalid maximum leverage for trader positions
    error InvalidMaxLeveragePerPosition(uint32 maxLeveragePerPosition);
    /// @notice Invalid liquidation fee rate for trader positions
    error InvalidLiquidationFeeRatePerPosition(uint32 liquidationFeeRatePerPosition);
    /// @notice Invalid maximum position value
    error InvalidMaxPositionLiquidity(uint128 maxPositionLiquidity);
    /// @notice Invalid maximum position value rate
    error InvalidMaxPositionValueRate(uint32 maxPositionValueRate);
    /// @notice Invalid maximum size per rate for per psoition
    error InvalidMaxSizeRatePerPosition(uint32 maxSizeRatePerPosition);
    /// @notice Invalid protocol funding fee rate
    error InvalidProtocolFundingFeeRate(uint32 protocolFundingFeeRate);
    /// @notice Invalid funding coefficient
    error InvalidFundingCoeff(uint32 fundingCoeff);
    /// @notice Invalid protocol funding coefficient
    error InvalidProtocolFundingCoeff(uint32 protocolFundingCoeff);
    /// @notice Invalid interest rate
    error InvalidInterestRate(uint32 interestRate);
    /// @notice Invalid funding buffer
    error InvalidFundingBuffer(uint32 fundingBuffer);
    /// @notice Invalid liquidity funding fee rate
    error InvalidLiquidityFundingFeeRate(uint32 liquidityFundingFeeRate);
    /// @notice Invalid maximum funding rate
    error InvalidMaxFundingRate(uint32 maxFundingRate);
    /// @notice Invalid maximum price impact liquidity
    error InvalidMaxPriceImpactLiquidity(uint128 maxPriceImpactLiquidity);
    /// @notice Invalid vertices length
    /// @dev The length of vertices must be equal to the `VERTEX_NUM`
    error InvalidVerticesLength(uint256 length, uint256 requiredLength);
    /// @notice Invalid liquidation vertex index
    /// @dev The liquidation vertex index must be less than the length of vertices
    error InvalidLiquidationVertexIndex(uint8 liquidationVertexIndex);
    /// @notice Invalid vertex
    /// @param index The index of the vertex
    error InvalidVertex(uint8 index);
    /// @notice Invalid dynamic depth level
    error InvalidDynamicDepthLevel(uint32 dynamicDepthLevel);

    /// @notice Get the USD stablecoin used in markets
    /// @return The ERC20 token representing the USD stablecoin used in markets
    function USD() external view returns (IERC20);

    /// @notice Checks if a market is enabled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @return True if the market is enabled, false otherwise
    function isEnabledMarket(IMarketDescriptor market) external view returns (bool);

    /// @notice Get market configuration
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function marketBaseConfigs(IMarketDescriptor market) external view returns (MarketBaseConfig memory);

    /// @notice Get market fee rate configuration
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function marketFeeRateConfigs(IMarketDescriptor market) external view returns (MarketFeeRateConfig memory);

    /// @notice Get market price configuration
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function marketPriceConfigs(IMarketDescriptor market) external view returns (MarketPriceConfig memory);

    /// @notice Get market price vertex configuration
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param index The index of the vertex
    function marketPriceVertexConfigs(
        IMarketDescriptor market,
        uint8 index
    ) external view returns (VertexConfig memory);

    /// @notice Enable a market
    /// @dev The call will fail if caller is not the governor or the market is already enabled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param cfg The market configuration
    function enableMarket(IMarketDescriptor market, MarketConfig calldata cfg) external;

    /// @notice Update a market configuration
    /// @dev The call will fail if caller is not the governor or the market is not enabled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param newCfg The new market base configuration
    function updateMarketBaseConfig(IMarketDescriptor market, MarketBaseConfig calldata newCfg) external;

    /// @notice Update a market fee rate configuration
    /// @dev The call will fail if caller is not the governor or the market is not enabled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param newCfg The new market fee rate configuration
    function updateMarketFeeRateConfig(IMarketDescriptor market, MarketFeeRateConfig calldata newCfg) external;

    /// @notice Update a market price configuration
    /// @dev The call will fail if caller is not the governor or the market is not enabled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param newCfg The new market price configuration
    function updateMarketPriceConfig(IMarketDescriptor market, MarketPriceConfig calldata newCfg) external;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Side} from "../../types/Side.sol";

interface IMarketErrors {
    /// @notice Liquidity is not enough to open a liquidity position
    error InvalidLiquidityToOpen();
    /// @notice Invalid caller
    error InvalidCaller(address requiredCaller);
    /// @notice Insufficient size to decrease
    error InsufficientSizeToDecrease(uint128 size, uint128 requiredSize);
    /// @notice Insufficient margin
    error InsufficientMargin();
    /// @notice Position not found
    error PositionNotFound(address requiredAccount, Side requiredSide);
    /// @notice Size exceeds max size per position
    error SizeExceedsMaxSizePerPosition(uint128 requiredSize, uint128 maxSizePerPosition);
    /// @notice Size exceeds max size
    error SizeExceedsMaxSize(uint128 requiredSize, uint128 maxSize);
    /// @notice Liquidity position not found
    error LiquidityPositionNotFound(address requiredAccount);
    /// @notice Insufficient liquidity to decrease
    error InsufficientLiquidityToDecrease(uint256 liquidity, uint128 requiredLiquidity);
    /// @notice Last liquidity position cannot be closed
    error LastLiquidityPositionCannotBeClosed();
    /// @notice Caller is not the liquidator
    error CallerNotLiquidator();
    /// @notice Insufficient balance
    error InsufficientBalance(uint256 balance, uint256 requiredAmount);
    /// @notice Leverage is too high
    error LeverageTooHigh(uint256 margin, uint128 liquidity, uint32 maxLeverage);
    /// @notice Insufficient global liquidity
    error InsufficientGlobalLiquidity();
    /// @notice Risk rate is too high
    error RiskRateTooHigh(int256 margin, uint256 maintenanceMargin);
    /// @notice Risk rate is too low
    error RiskRateTooLow(int256 margin, uint256 maintenanceMargin);
    /// @notice Position margin rate is too low
    error MarginRateTooLow(int256 margin, int256 unrealizedPnL, uint256 maintenanceMargin);
    /// @notice Position margin rate is too high
    error MarginRateTooHigh(int256 margin, int256 unrealizedPnL, uint256 maintenanceMargin);
    /// @notice Emitted when premium rate overflows, should stop calculation
    error MaxPremiumRateExceeded();
    /// @notice Emitted when size delta is zero
    error ZeroSizeDelta();
    /// @notice The liquidation fund is experiencing losses
    error LiquidationFundLoss();
    /// @notice Insufficient liquidation fund
    error InsufficientLiquidationFund(uint128 requiredRiskBufferFund);
    /// @notice Emitted when trade price is invalid
    error InvalidTradePrice(int256 tradePriceX96TimesSizeTotal);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IMarketDescriptor.sol";
import {Side} from "../../types/Side.sol";

/// @notice Interface for managing liquidity positions
/// @dev The market liquidity position is the core component of the protocol, which stores the information of
/// all LP's positions.
interface IMarketLiquidityPosition {
    struct GlobalLiquidityPosition {
        /// @notice The size of the net position held by all LPs
        uint128 netSize;
        /// @notice The size of the net position held by all LPs in the liquidation buffer
        uint128 liquidationBufferNetSize;
        /// @notice The Previous Settlement Point Price, as a Q64.96
        uint160 previousSPPriceX96;
        /// @notice The side of the position (Long or Short)
        Side side;
        /// @notice The total liquidity of all LPs
        uint128 liquidity;
        /// @notice The accumulated unrealized Profit and Loss (PnL) growth per liquidity unit, as a Q192.64.
        /// The value is updated when the following actions are performed:
        ///     1. Settlement Point is reached
        ///     2. Funding fee is added
        ///     3. Liquidation loss is added
        int256 unrealizedPnLGrowthX64;
        uint256[50] __gap;
    }

    struct LiquidityPosition {
        /// @notice The margin of the position
        uint128 margin;
        /// @notice The liquidity (value) of the position
        uint128 liquidity;
        /// @notice The snapshot of `GlobalLiquidityPosition.realizedProfitGrowthX64`
        /// at the time of the position was opened.
        int256 entryUnrealizedPnLGrowthX64;
        uint256[50] __gap;
    }

    /// @notice Emitted when the global liquidity position net position changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param sideAfter The adjusted side of the net position
    /// @param netSizeAfter The adjusted net position size
    /// @param liquidationBufferNetSizeAfter The adjusted net position size in the liquidation buffer
    event GlobalLiquidityPositionNetPositionChanged(
        IMarketDescriptor indexed market,
        Side sideAfter,
        uint128 netSizeAfter,
        uint128 liquidationBufferNetSizeAfter
    );

    /// @notice Emitted when the position margin/liquidity (value) is increased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param marginDelta The increased margin
    /// @param marginAfter The adjusted margin
    /// @param liquidityAfter The adjusted liquidity
    /// @param realizedPnLDelta The realized PnL of the position
    event LiquidityPositionIncreased(
        IMarketDescriptor indexed market,
        address indexed account,
        uint128 marginDelta,
        uint128 marginAfter,
        uint128 liquidityAfter,
        int256 realizedPnLDelta
    );

    /// @notice Emitted when the position margin/liquidity (value) is decreased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param marginDelta The decreased margin
    /// @param marginAfter The adjusted margin
    /// @param liquidityAfter The adjusted liquidity
    /// @param realizedPnLDelta The realized PnL of the position
    /// @param receiver The address that receives the margin
    event LiquidityPositionDecreased(
        IMarketDescriptor indexed market,
        address indexed account,
        uint128 marginDelta,
        uint128 marginAfter,
        uint128 liquidityAfter,
        int256 realizedPnLDelta,
        address receiver
    );

    /// @notice Emitted when a position is liquidated
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param liquidator The address that executes the liquidation of the position
    /// @param liquidationLoss The loss of the liquidated position.
    /// If it is a negative number, it means that the remaining LP bears this part of the loss,
    /// otherwise it means that the `Liquidation Fund` gets this part of the liquidation fee.
    /// @param unrealizedPnLGrowthAfterX64 The adjusted `GlobalLiquidityPosition.unrealizedPnLGrowthX64`, as a Q192.64
    /// @param feeReceiver The address that receives the liquidation execution fee
    event LiquidityPositionLiquidated(
        IMarketDescriptor indexed market,
        address indexed account,
        address indexed liquidator,
        int256 liquidationLoss,
        int256 unrealizedPnLGrowthAfterX64,
        address feeReceiver
    );

    /// @notice Emitted when the previous Settlement Point Price is initialized
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param previousSPPriceX96 The adjusted `GlobalLiquidityPosition.previousSPPriceX96`, as a Q64.96
    event PreviousSPPriceInitialized(IMarketDescriptor indexed market, uint160 previousSPPriceX96);

    /// @notice Emitted when the Settlement Point is reached
    /// @dev Settlement Point is triggered by the following 6 actions:
    ///     1. increaseLiquidityPosition
    ///     2. decreaseLiquidityPosition
    ///     3. liquidateLiquidityPosition
    ///     4. increasePosition
    ///     5. decreasePosition
    ///     6. liquidatePosition
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param unrealizedPnLGrowthAfterX64 The adjusted `GlobalLiquidityPosition.unrealizedPnLGrowthX64`, as a Q192.64
    /// @param previousSPPriceAfterX96 The adjusted `GlobalLiquidityPosition.previousSPPriceX96`, as a Q64.96
    event SettlementPointReached(
        IMarketDescriptor indexed market,
        int256 unrealizedPnLGrowthAfterX64,
        uint160 previousSPPriceAfterX96
    );

    /// @notice Emitted when the global liquidity position is increased by funding fee
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param unrealizedPnLGrowthAfterX64 The adjusted `GlobalLiquidityPosition.unrealizedPnLGrowthX64`, as a Q192.64
    event GlobalLiquidityPositionPnLGrowthIncreasedByFundingFee(
        IMarketDescriptor indexed market,
        int256 unrealizedPnLGrowthAfterX64
    );

    /// @notice Get the global liquidity position of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function globalLiquidityPositions(IMarketDescriptor market) external view returns (GlobalLiquidityPosition memory);

    /// @notice Get the information of a liquidity position
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    function liquidityPositions(
        IMarketDescriptor market,
        address account
    ) external view returns (LiquidityPosition memory);

    /// @notice Increase the margin/liquidity (value) of a position
    /// @dev The call will fail if the caller is not the `IRouter`
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param marginDelta The increase in margin, which can be 0
    /// @param liquidityDelta The increase in liquidity, which can be 0
    /// @return marginAfter The margin after increasing the position
    function increaseLiquidityPosition(
        IMarketDescriptor market,
        address account,
        uint128 marginDelta,
        uint128 liquidityDelta
    ) external returns (uint128 marginAfter);

    /// @notice Decrease the margin/liquidity (value) of a position
    /// @dev The call will fail if the caller is not the `IRouter` or the position does not exist
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param marginDelta The decrease in margin, which can be 0
    /// @param liquidityDelta The decrease in liquidity, which can be 0
    /// @param receiver The address to receive the margin at the time of closing
    /// @return marginAfter The margin after decreasing the position
    function decreaseLiquidityPosition(
        IMarketDescriptor market,
        address account,
        uint128 marginDelta,
        uint128 liquidityDelta,
        address receiver
    ) external returns (uint128 marginAfter);

    /// @notice Liquidate a liquidity position
    /// @dev The call will fail if the caller is not the `IRouter` or the position does not exist
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param feeReceiver The address to receive the liquidation execution fee
    function liquidateLiquidityPosition(IMarketDescriptor market, address account, address feeReceiver) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IConfigurable.sol";
import "./IMarketErrors.sol";
import "./IMarketPosition.sol";
import "./IMarketLiquidityPosition.sol";
import "../../oracle/interfaces/IPriceFeed.sol";

interface IMarketManager is IMarketErrors, IMarketPosition, IMarketLiquidityPosition, IConfigurable {
    struct PriceVertex {
        /// @notice The available size when the price curve moves to this vertex
        uint128 size;
        /// @notice The premium rate when the price curve moves to this vertex, as a Q32.96
        uint128 premiumRateX96;
    }

    struct PriceState {
        /// @notice The premium rate during the last position adjustment by the trader, as a Q32.96
        uint128 premiumRateX96;
        /// @notice The index used to track the pending update of the price vertex
        uint8 pendingVertexIndex;
        /// @notice The index used to track the current used price vertex
        uint8 currentVertexIndex;
        /// @notice The basis index price, as a Q64.96
        uint160 basisIndexPriceX96;
        /// @notice The price vertices used to determine the price curve
        PriceVertex[10] priceVertices;
        /// @notice The net sizes of the liquidation buffer
        uint128[10] liquidationBufferNetSizes;
        uint256[50] __gap;
    }

    struct GlobalLiquidationFund {
        /// @notice The liquidation fund, primarily used to compensate for the difference between the
        /// liquidation price and the index price when a trader's position is liquidated. It consists of
        /// the following parts:
        ///     1. Increased by the liquidation fee when the trader's is liquidated
        ///     2. Increased by the liquidation fee when the LP's position is liquidated
        ///     3. Increased by the liquidity added to the liquidation fund
        ///     4. Decreased by the liquidity removed from the liquidation fund
        ///     5. Decreased by the funding fee compensated when the trader's position is liquidated
        ///     6. Decreased by the loss compensated when the LP's position is liquidated
        ///     7. Decreased by the difference between the liquidation price and the index price when
        ///      the trader's position is liquidated
        ///     8. Decreased by the governance when the liquidation fund is pofitable
        int256 liquidationFund;
        /// @notice The total liquidity of the liquidation fund
        uint256 liquidity;
        uint256[50] __gap;
    }

    struct State {
        /// @notice The value is used to track the price curve
        PriceState priceState;
        /// @notice The value is used to track the USD balance of the market
        uint128 usdBalance;
        /// @notice The value is used to track the remaining protocol fee of the market
        uint128 protocolFee;
        /// @notice Mapping of referral token to referral fee
        mapping(uint256 referralToken => uint256 feeAmount) referralFees;
        // ==================== Liquidity Position Stats ====================
        /// @notice The value is used to track the global liquidity position
        GlobalLiquidityPosition globalLiquidityPosition;
        /// @notice Mapping of account to liquidity position
        mapping(address account => LiquidityPosition) liquidityPositions;
        // ==================== Position Stats ==============================
        /// @notice The value is used to track the global position
        GlobalPosition globalPosition;
        /// @notice Mapping of account to position
        mapping(address account => mapping(Side => Position)) positions;
        // ==================== Liquidation Fund Position Stats =============
        /// @notice The value is used to track the global liquidation fund
        GlobalLiquidationFund globalLiquidationFund;
        /// @notice Mapping of account to liquidation fund position
        mapping(address account => uint256 liquidity) liquidationFundPositions;
        uint256[50] __gap;
    }

    /// @notice Emitted when the price vertex is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param index The index of the price vertex
    /// @param sizeAfter The available size when the price curve moves to this vertex
    /// @param premiumRateAfterX96 The premium rate when the price curve moves to this vertex, as a Q32.96
    event PriceVertexChanged(
        IMarketDescriptor indexed market,
        uint8 index,
        uint128 sizeAfter,
        uint128 premiumRateAfterX96
    );

    /// @notice Emitted when the protocol fee is increased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param amount The increased protocol fee
    event ProtocolFeeIncreased(IMarketDescriptor indexed market, uint128 amount);

    /// @notice Emitted when the protocol fee is collected
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param amount The collected protocol fee
    event ProtocolFeeCollected(IMarketDescriptor indexed market, uint128 amount);

    /// @notice Emitted when the price feed is changed
    /// @param priceFeedBefore The address of the price feed before changed
    /// @param priceFeedAfter The address of the price feed after changed
    event PriceFeedChanged(IPriceFeed indexed priceFeedBefore, IPriceFeed indexed priceFeedAfter);

    /// @notice Emitted when the premium rate is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param premiumRateAfterX96 The premium rate after changed, as a Q32.96
    event PremiumRateChanged(IMarketDescriptor indexed market, uint128 premiumRateAfterX96);

    /// @notice Emitted when liquidation buffer net size is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param index The index of the liquidation buffer net size
    /// @param netSizeAfter The net size of the liquidation buffer after changed
    event LiquidationBufferNetSizeChanged(IMarketDescriptor indexed market, uint8 index, uint128 netSizeAfter);

    /// @notice Emitted when the basis index price is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param basisIndexPriceAfterX96 The basis index price after changed, as a Q64.96
    event BasisIndexPriceChanged(IMarketDescriptor indexed market, uint160 basisIndexPriceAfterX96);

    /// @notice Emitted when the liquidation fund is used by `Gov`
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param receiver The address that receives the liquidation fund
    /// @param liquidationFundDelta The amount of liquidation fund used
    event GlobalLiquidationFundGovUsed(
        IMarketDescriptor indexed market,
        address indexed receiver,
        uint128 liquidationFundDelta
    );

    /// @notice Emitted when the liquidity of the liquidation fund is increased by liquidation
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param liquidationFee The amount of the liquidation fee that is added to the liquidation fund.
    /// It consists of following parts:
    ///     1. The liquidation fee paid by the position
    ///     2. The funding fee compensated when liquidating, covered by the liquidation fund (if any)
    ///     3. The difference between the liquidation price and the trade price when liquidating,
    ///     covered by the liquidation fund (if any)
    /// @param liquidationFundAfter The amount of the liquidation fund after the increase
    event GlobalLiquidationFundIncreasedByLiquidation(
        IMarketDescriptor indexed market,
        int256 liquidationFee,
        int256 liquidationFundAfter
    );

    /// @notice Emitted when the liquidity of the liquidation fund is increased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param liquidityAfter The total liquidity of the position after the increase
    event LiquidationFundPositionIncreased(
        IMarketDescriptor indexed market,
        address indexed account,
        uint256 liquidityAfter
    );

    /// @notice Emitted when the liquidity of the liquidation fund is decreased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param liquidityAfter The total liquidity of the position after the decrease
    /// @param receiver The address that receives the liquidity when it is decreased
    event LiquidationFundPositionDecreased(
        IMarketDescriptor indexed market,
        address indexed account,
        uint256 liquidityAfter,
        address receiver
    );

    /// @notice Change the price feed
    /// @param priceFeed The address of the new price feed
    function setPriceFeed(IPriceFeed priceFeed) external;

    /// @notice Get the price state of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function priceStates(IMarketDescriptor market) external view returns (PriceState memory);

    /// @notice Get the USD balance of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function usdBalances(IMarketDescriptor market) external view returns (uint256);

    /// @notice Get the protocol fee of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function protocolFees(IMarketDescriptor market) external view returns (uint128);

    /// @notice Change the price vertex of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param startExclusive The start index of the price vertex to be changed, exclusive
    /// @param endInclusive The end index of the price vertex to be changed, inclusive
    function changePriceVertex(IMarketDescriptor market, uint8 startExclusive, uint8 endInclusive) external;

    /// @notice Settle the funding fee of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function settleFundingFee(IMarketDescriptor market) external;

    /// @notice Collect the protocol fee of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function collectProtocolFee(IMarketDescriptor market) external;

    /// @notice Get the global liquidation fund of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function globalLiquidationFunds(IMarketDescriptor market) external view returns (GlobalLiquidationFund memory);

    /// @notice Get the liquidity of the liquidation fund
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    function liquidationFundPositions(
        IMarketDescriptor market,
        address account
    ) external view returns (uint256 liquidity);

    /// @notice `Gov` uses the liquidation fund
    /// @dev The call will fail if the caller is not the `Gov` or the liquidation fund is insufficient
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param receiver The address to receive the liquidation fund
    /// @param liquidationFundDelta The amount of liquidation fund to be used
    function govUseLiquidationFund(IMarketDescriptor market, address receiver, uint128 liquidationFundDelta) external;

    /// @notice Increase the liquidity of a liquidation fund position
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param liquidityDelta The increase in liquidity
    function increaseLiquidationFundPosition(
        IMarketDescriptor market,
        address account,
        uint128 liquidityDelta
    ) external;

    /// @notice Decrease the liquidity of a liquidation fund position
    /// @dev The call will fail if the position liquidity is insufficient or the liquidation fund is losing
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param liquidityDelta The decrease in liquidity
    /// @param receiver The address to receive the liquidity when it is decreased
    function decreaseLiquidationFundPosition(
        IMarketDescriptor market,
        address account,
        uint128 liquidityDelta,
        address receiver
    ) external;

    /// @notice Get the market price of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param side The side of the position adjustment, 1 for opening long or closing short positions,
    /// 2 for opening short or closing long positions
    /// @return marketPriceX96 The market price, as a Q64.96
    function marketPriceX96s(IMarketDescriptor market, Side side) external view returns (uint160 marketPriceX96);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IMarketDescriptor.sol";
import {Side} from "../../types/Side.sol";

/// @notice Interface for managing market positions.
/// @dev The market position is the core component of the protocol, which stores the information of
/// all trader's positions and the funding rate.
interface IMarketPosition {
    struct GlobalPosition {
        /// @notice The sum of long position sizes
        uint128 longSize;
        /// @notice The sum of short position sizes
        uint128 shortSize;
        /// @notice The maximum available size of all positions
        uint128 maxSize;
        /// @notice The maximum available size of per position
        uint128 maxSizePerPosition;
        /// @notice The funding rate growth per unit of long position sizes, as a Q96.96
        int192 longFundingRateGrowthX96;
        /// @notice The funding rate growth per unit of short position sizes, as a Q96.96
        int192 shortFundingRateGrowthX96;
        /// @notice The last time the funding fee is settled
        uint64 lastFundingFeeSettleTime;
        uint256[50] __gap;
    }

    struct Position {
        /// @notice The margin of the position
        uint128 margin;
        /// @notice The size of the position
        uint128 size;
        /// @notice The entry price of the position, as a Q64.96
        uint160 entryPriceX96;
        /// @notice The snapshot of the funding rate growth at the time the position was opened.
        /// For long positions it is `GlobalPosition.longFundingRateGrowthX96`,
        /// and for short positions it is `GlobalPosition.shortFundingRateGrowthX96`
        int192 entryFundingRateGrowthX96;
        uint256[50] __gap;
    }
    /// @notice Emitted when the funding fee is settled
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param longFundingRateGrowthAfterX96 The adjusted `GlobalPosition.longFundingRateGrowthX96`, as a Q96.96
    /// @param shortFundingRateGrowthAfterX96 The adjusted `GlobalPosition.shortFundingRateGrowthX96`, as a Q96.96
    event FundingFeeSettled(
        IMarketDescriptor indexed market,
        int192 longFundingRateGrowthAfterX96,
        int192 shortFundingRateGrowthAfterX96
    );

    /// @notice Emitted when the max available size is changed
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param maxSizeAfter The adjusted `maxSize`
    /// @param maxSizePerPositionAfter The adjusted `maxSizePerPosition`
    event GlobalPositionSizeChanged(
        IMarketDescriptor indexed market,
        uint128 maxSizeAfter,
        uint128 maxSizePerPositionAfter
    );

    /// @notice Emitted when the position margin/liquidity (value) is increased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The increased margin
    /// @param marginAfter The adjusted margin
    /// @param sizeAfter The adjusted position size
    /// @param tradePriceX96 The trade price at which the position is adjusted.
    /// If only adding margin, it returns 0, as a Q64.96
    /// @param entryPriceAfterX96 The adjusted entry price of the position, as a Q64.96
    /// @param fundingFee The funding fee, a positive value means the position receives funding fee,
    /// while a negative value means the position positive pays funding fee
    event PositionIncreased(
        IMarketDescriptor indexed market,
        address indexed account,
        Side side,
        uint128 marginDelta,
        uint128 marginAfter,
        uint128 sizeAfter,
        uint160 tradePriceX96,
        uint160 entryPriceAfterX96,
        int256 fundingFee
    );

    /// @notice Emitted when the position margin/liquidity (value) is decreased
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The decreased margin
    /// @param marginAfter The adjusted margin
    /// @param sizeAfter The adjusted position size
    /// @param tradePriceX96 The trade price at which the position is adjusted.
    /// If only reducing margin, it returns 0, as a Q64.96
    /// @param realizedPnLDelta The realized PnL
    /// @param fundingFee The funding fee, a positive value means the position receives a funding fee,
    /// while a negative value means the position pays funding fee
    /// @param receiver The address that receives the margin
    event PositionDecreased(
        IMarketDescriptor indexed market,
        address indexed account,
        Side side,
        uint128 marginDelta,
        uint128 marginAfter,
        uint128 sizeAfter,
        uint160 tradePriceX96,
        int256 realizedPnLDelta,
        int256 fundingFee,
        address receiver
    );

    /// @notice Emitted when a position is liquidated
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param liquidator The address that executes the liquidation of the position
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param indexPriceX96 The index price when liquidating the position, as a Q64.96
    /// @param tradePriceX96 The trade price at which the position is liquidated, as a Q64.96
    /// @param liquidationPriceX96 The liquidation price of the position, as a Q64.96
    /// @param fundingFee The funding fee, a positive value means the position receives a funding fee,
    /// while a negative value means the position pays funding fee. If it's negative,
    /// it represents the actual funding fee paid during liquidation
    /// @param liquidationFee The liquidation fee paid by the position
    /// @param liquidationExecutionFee The liquidation execution fee paid by the position
    /// @param feeReceiver The address that receives the liquidation execution fee
    event PositionLiquidated(
        IMarketDescriptor indexed market,
        address indexed liquidator,
        address indexed account,
        Side side,
        uint160 indexPriceX96,
        uint160 tradePriceX96,
        uint160 liquidationPriceX96,
        int256 fundingFee,
        uint128 liquidationFee,
        uint64 liquidationExecutionFee,
        address feeReceiver
    );

    /// @notice Get the global position of the given market
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    function globalPositions(IMarketDescriptor market) external view returns (GlobalPosition memory);

    /// @notice Get the information of a position
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    function positions(IMarketDescriptor market, address account, Side side) external view returns (Position memory);

    /// @notice Increase the margin/liquidity (value) of a position
    /// @dev The call will fail if the caller is not the `IRouter`
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The increase in margin, which can be 0
    /// @param sizeDelta The increase in size, which can be 0
    /// @return tradePriceX96 The trade price at which the position is adjusted.
    /// If only adding margin, it returns 0, as a Q64.96
    function increasePosition(
        IMarketDescriptor market,
        address account,
        Side side,
        uint128 marginDelta,
        uint128 sizeDelta
    ) external returns (uint160 tradePriceX96);

    /// @notice Decrease the margin/liquidity (value) of a position
    /// @dev The call will fail if the caller is not the `IRouter` or the position does not exist
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The decrease in margin, which can be 0
    /// @param sizeDelta The decrease in size, which can be 0
    /// @param receiver The address to receive the margin
    /// @return tradePriceX96 The trade price at which the position is adjusted.
    /// If only reducing margin, it returns 0, as a Q64.96
    function decreasePosition(
        IMarketDescriptor market,
        address account,
        Side side,
        uint128 marginDelta,
        uint128 sizeDelta,
        address receiver
    ) external returns (uint160 tradePriceX96);

    /// @notice Liquidate a position
    /// @dev The call will fail if the caller is not the `IRouter` or the position does not exist
    /// @param market The descriptor used to describe the metadata of the market, such as symbol, name, decimals
    /// @param account The owner of the position
    /// @param side The side of the position (Long or Short)
    /// @param feeReceiver The address that receives the liquidation execution fee
    function liquidatePosition(IMarketDescriptor market, address account, Side side, address feeReceiver) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract GovernableUpgradeable is Initializable {
    /// @custom:storage-location erc7201:EquationDAO.storage.GovernableUpgradeable
    struct GovStorage {
        address gov;
        address pendingGov;
    }

    // keccak256(abi.encode(uint256(keccak256("EquationDAO.storage.GovernableUpgradeable")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant GOVERNABLE_UPGRADEABLE_STORAGE =
        0x7c382d3f962d99164ba990f004477147f4c3dae6d40d59c27227920aa3da5300;

    event ChangeGovStarted(address indexed previousGov, address indexed newGov);
    event GovChanged(address indexed previousGov, address indexed newGov);

    error Forbidden();

    modifier onlyGov() {
        _onlyGov();
        _;
    }

    function __Governable_init() internal onlyInitializing {
        __Governable_init_unchained();
    }

    function __Governable_init_unchained() internal onlyInitializing {
        _changeGov(msg.sender);
    }

    function gov() public view virtual returns (address) {
        return _governableStorage().gov;
    }

    function pendingGov() public view virtual returns (address) {
        return _governableStorage().pendingGov;
    }

    function changeGov(address _newGov) public virtual onlyGov {
        GovStorage storage $ = _governableStorage();
        $.pendingGov = _newGov;
        emit ChangeGovStarted($.gov, _newGov);
    }

    function acceptGov() public virtual {
        GovStorage storage $ = _governableStorage();
        if (msg.sender != $.pendingGov) revert Forbidden();

        delete $.pendingGov;
        _changeGov(msg.sender);
    }

    function _changeGov(address _newGov) internal virtual {
        GovStorage storage $ = _governableStorage();
        address previousGov = $.gov;
        $.gov = _newGov;
        emit GovChanged(previousGov, _newGov);
    }

    function _onlyGov() internal view {
        if (msg.sender != _governableStorage().gov) revert Forbidden();
    }

    function _governableStorage() private pure returns (GovStorage storage $) {
        // prettier-ignore
        assembly { $.slot := GOVERNABLE_UPGRADEABLE_STORAGE }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Math as _math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @title Math library
/// @dev Derived from OpenZeppelin's Math library. To avoid conflicts with OpenZeppelin's Math,
/// it has been renamed to `M` here. Import it using the following statement:
///      import {M as Math} from "path/to/Math.sol";
library M {
    enum Rounding {
        Up,
        Down
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Calculate `a / b` with rounding up
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // Guarantee the same behavior as in a regular Solidity division
        if (b == 0) return a / b;

        // prettier-ignore
        unchecked { return a == 0 ? 0 : (a - 1) / b + 1; }
    }

    /// @notice Calculate `x * y / denominator` with rounding down
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256) {
        return _math.mulDiv(x, y, denominator);
    }

    /// @notice Calculate `x * y / denominator` with rounding up
    function mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256) {
        return _math.mulDiv(x, y, denominator, _math.Rounding.Ceil);
    }

    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        return _math.mulDiv(x, y, denominator, rounding == Rounding.Up ? _math.Rounding.Ceil : _math.Rounding.Floor);
    }

    /// @notice Calculate `x * y / denominator` with rounding down and up
    /// @return result Result with rounding down
    /// @return resultUp Result with rounding up
    function mulDiv2(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result, uint256 resultUp) {
        result = _math.mulDiv(x, y, denominator);
        resultUp = result;
        if (mulmod(x, y, denominator) > 0) resultUp += 1;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.23;

import "../plugins/PositionRouterUpgradeable.sol";

contract ExecutorAssistant {
    struct IndexPerOperation {
        /// @dev The start index of the operation
        uint128 index;
        /// @dev The next index of the operation
        uint128 indexNext;
        /// @dev The end index of the operation.
        /// If the index == indexNext, indexEnd is invalid.
        uint128 indexEnd;
    }

    PositionRouterUpgradeable public immutable positionRouter;

    constructor(PositionRouterUpgradeable _positionRouter) {
        positionRouter = _positionRouter;
    }

    /// @dev Calculate the next market that `Multicall` needs to update the price, and the required indexEnd
    /// @param _max The maximum index that execute in one call
    /// @return markets The market in which to update the price, address(0) means no operation
    /// @return indexPerOperations The index of the per operation
    function calculateNextMulticall(
        uint128 _max
    ) external view returns (IMarketDescriptor[] memory markets, IndexPerOperation[4] memory indexPerOperations) {
        markets = new IMarketDescriptor[](4 * _max);
        uint256 marketIndex;

        // scope for increase liquidity position
        {
            IndexPerOperation memory indexPerOperation = indexPerOperations[0];
            (indexPerOperation.index, indexPerOperation.indexNext) = (
                positionRouter.increaseLiquidityPositionIndex(),
                positionRouter.increaseLiquidityPositionIndexNext()
            );
            if (indexPerOperation.index != indexPerOperation.indexNext) {
                indexPerOperation.indexEnd = uint128(
                    Math.min(indexPerOperation.index + _max, indexPerOperation.indexNext)
                );
                uint128 index = indexPerOperation.index;
                while (index < indexPerOperation.indexEnd) {
                    (address account, IMarketDescriptor market, , , , , , ) = positionRouter
                        .increaseLiquidityPositionRequests(index);
                    if (account != address(0)) markets[marketIndex++] = market;

                    // prettier-ignore
                    unchecked { index++; }
                }
            }
        }

        // scope for decrease liquidity position
        {
            IndexPerOperation memory indexPerOperation = indexPerOperations[1];
            (indexPerOperation.index, indexPerOperation.indexNext) = (
                positionRouter.decreaseLiquidityPositionIndex(),
                positionRouter.decreaseLiquidityPositionIndexNext()
            );
            if (indexPerOperation.index != indexPerOperation.indexNext) {
                indexPerOperation.indexEnd = uint128(
                    Math.min(indexPerOperation.index + _max, indexPerOperation.indexNext)
                );
                uint128 index = indexPerOperation.index;
                while (index < indexPerOperation.indexEnd) {
                    (address account, IMarketDescriptor market, , , , , , , ) = positionRouter
                        .decreaseLiquidityPositionRequests(index);
                    if (account != address(0)) markets[marketIndex++] = market;

                    // prettier-ignore
                    unchecked { index++; }
                }
            }
        }

        // scope for increase position
        {
            IndexPerOperation memory indexPerOperation = indexPerOperations[2];
            (indexPerOperation.index, indexPerOperation.indexNext) = (
                positionRouter.increasePositionIndex(),
                positionRouter.increasePositionIndexNext()
            );
            if (indexPerOperation.index != indexPerOperation.indexNext) {
                indexPerOperation.indexEnd = uint128(
                    Math.min(indexPerOperation.index + _max, indexPerOperation.indexNext)
                );
                uint128 index = indexPerOperation.index;
                while (index < indexPerOperation.indexEnd) {
                    (address account, IMarketDescriptor market, , , , , , , ) = positionRouter.increasePositionRequests(
                        index
                    );
                    if (account != address(0)) markets[marketIndex++] = market;

                    // prettier-ignore
                    unchecked { index++; }
                }
            }
        }

        // scope for decrease position
        {
            IndexPerOperation memory indexPerOperation = indexPerOperations[3];
            (indexPerOperation.index, indexPerOperation.indexNext) = (
                positionRouter.decreasePositionIndex(),
                positionRouter.decreasePositionIndexNext()
            );
            if (indexPerOperation.index != indexPerOperation.indexNext) {
                indexPerOperation.indexEnd = uint128(
                    Math.min(indexPerOperation.index + _max, indexPerOperation.indexNext)
                );
                uint128 index = indexPerOperation.index;
                while (index < indexPerOperation.indexEnd) {
                    (address account, IMarketDescriptor market, , , , , , , , ) = positionRouter
                        .decreasePositionRequests(index);
                    if (account != address(0)) markets[marketIndex++] = market;

                    // prettier-ignore
                    unchecked { index++; }
                }
            }
        }
        uint256 dropNum = markets.length - marketIndex;
        // prettier-ignore
        assembly { mstore(markets, sub(mload(markets), dropNum)) }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IChainLinkAggregator {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IChainLinkAggregator.sol";
import "../../core/interfaces/IMarketDescriptor.sol";

interface IPriceFeed {
    struct MarketConfig {
        /// @notice ChainLink contract address for corresponding market
        IChainLinkAggregator refPriceFeed;
        /// @notice Expected update interval of chain link price feed
        uint32 refHeartbeatDuration;
        /// @notice Maximum cumulative change ratio difference between prices and ChainLink price
        /// within a period of time.
        uint64 maxCumulativeDeltaDiff;
    }

    struct PriceDataItem {
        uint32 prevRound;
        uint160 prevRefPriceX96;
        uint64 cumulativeRefPriceDelta;
        uint160 prevPriceX96;
        uint64 cumulativePriceDelta;
    }

    struct PricePack {
        /// @notice The timestamp when updater uploads the price
        uint64 updateTimestamp;
        /// @notice Calculated maximum price, as a Q64.96
        uint160 maxPriceX96;
        /// @notice Calculated minimum price, as a Q64.96
        uint160 minPriceX96;
        /// @notice The block timestamp when price is committed
        uint64 updateBlockTimestamp;
    }

    struct MarketPrice {
        IMarketDescriptor market;
        uint160 priceX96;
    }

    /// @notice Emitted when market price updated
    /// @param market Market address
    /// @param priceX96 The price passed in by updater, as a Q64.96
    /// @param maxPriceX96 Calculated maximum price, as a Q64.96
    /// @param minPriceX96 Calculated minimum price, as a Q64.96
    event PriceUpdated(IMarketDescriptor indexed market, uint160 priceX96, uint160 minPriceX96, uint160 maxPriceX96);

    /// @notice Emitted when maxCumulativeDeltaDiff exceeded
    /// @param market Market address
    /// @param priceX96 The price passed in by updater, as a Q64.96
    /// @param refPriceX96 The price provided by ChainLink, as a Q64.96
    /// @param cumulativeDelta The cumulative value of the price change ratio
    /// @param cumulativeRefDelta The cumulative value of the ChainLink price change ratio
    event MaxCumulativeDeltaDiffExceeded(
        IMarketDescriptor indexed market,
        uint160 priceX96,
        uint160 refPriceX96,
        uint64 cumulativeDelta,
        uint64 cumulativeRefDelta
    );

    /// @notice Price not be initialized
    error NotInitialized();

    /// @notice Reference price feed not set
    error ReferencePriceFeedNotSet();

    /// @notice Invalid reference price
    /// @param referencePrice Reference price
    error InvalidReferencePrice(int256 referencePrice);

    /// @notice Reference price timeout
    /// @param elapsed The time elapsed since the last price update.
    error ReferencePriceTimeout(uint256 elapsed);

    /// @notice Stable market price timeout
    /// @param elapsed The time elapsed since the last price update.
    error StableMarketPriceTimeout(uint256 elapsed);

    /// @notice Invalid stable market price
    /// @param stableMarketPrice Stable market price
    error InvalidStableMarketPrice(int256 stableMarketPrice);

    /// @notice Invalid update timestamp
    /// @param timestamp Update timestamp
    error InvalidUpdateTimestamp(uint64 timestamp);
    /// @notice L2 sequencer is down
    error SequencerDown();
    /// @notice Grace period is not over
    /// @param sequencerUptime Sequencer uptime
    error GracePeriodNotOver(uint256 sequencerUptime);

    struct Slot {
        // Maximum deviation ratio between price and ChainLink price.
        uint32 maxDeviationRatio;
        // Period for calculating cumulative deviation ratio.
        uint32 cumulativeRoundDuration;
        // The number of additional rounds for ChainLink prices to participate in price update calculation.
        uint32 refPriceExtraSample;
        // The timeout for price update transactions.
        uint32 updateTxTimeout;
    }

    /// @notice Get the address of stable market price feed
    /// @return priceFeed The address of stable market price feed
    function stableMarketPriceFeed() external view returns (IChainLinkAggregator priceFeed);

    /// @notice Get the expected update interval of stable market price
    /// @return duration The expected update interval of stable market price
    function stableMarketPriceFeedHeartBeatDuration() external view returns (uint32 duration);

    /// @notice The 0th storage slot in the price feed stores many values, which helps reduce gas
    /// costs when interacting with the price feed.
    function slot() external view returns (Slot memory);

    /// @notice Get market configuration for updating price
    /// @param market The market address to query the configuration
    /// @return marketConfig The packed market config data
    function marketConfig(IMarketDescriptor market) external view returns (MarketConfig memory marketConfig);

    /// @notice `ReferencePriceFeedNotSet` will be ignored when `ignoreReferencePriceFeedError` is true
    function ignoreReferencePriceFeedError() external view returns (bool);

    /// @notice Get latest price data for corresponding market.
    /// @param market The market address to query the price data
    /// @return packedData The packed price data
    function latestPrice(IMarketDescriptor market) external view returns (PricePack memory packedData);

    /// @notice Update prices
    /// @dev Updater calls this method to update prices for multiple markets. The contract calculation requires
    /// higher precision prices, so the passed-in prices need to be adjusted.
    ///
    /// ## Example
    ///
    /// The price of ETH is $2000, and ETH has 18 decimals, so the price of one unit of ETH is $`2000 / (10 ^ 18)`.
    ///
    /// The price of USD is $1, and USD has 6 decimals, so the price of one unit of USD is $`1 / (10 ^ 6)`.
    ///
    /// Then the price of ETH/USD pair is 2000 / (10 ^ 18) * (10 ^ 6)
    ///
    /// Finally convert the price to Q64.96, ETH/USD priceX96 = 2000 / (10 ^ 18) * (10 ^ 6) * (2 ^ 96)
    /// @param marketPrices Array of market addresses and prices to update for
    /// @param timestamp The timestamp of price update
    function setPriceX96s(MarketPrice[] calldata marketPrices, uint64 timestamp) external;

    /// @notice calculate min and max price if passed a specific price value
    /// @param marketPrices Array of market addresses and prices to update for
    function calculatePriceX96s(
        MarketPrice[] calldata marketPrices
    ) external view returns (uint160[] memory minPriceX96s, uint160[] memory maxPriceX96s);

    /// @notice Get minimum market price
    /// @param market The market address to query the price
    /// @return priceX96 Minimum market price
    function getMinPriceX96(IMarketDescriptor market) external view returns (uint160 priceX96);

    /// @notice Get maximum market price
    /// @param market The market address to query the price
    /// @return priceX96 Maximum market price
    function getMaxPriceX96(IMarketDescriptor market) external view returns (uint160 priceX96);

    /// @notice Set updater status active or not
    /// @param account Updater address
    /// @param active Status of updater permission to set
    function setUpdater(address account, bool active) external;

    /// @notice Check if is updater
    /// @param account The address to query the status
    /// @return active Status of updater
    function isUpdater(address account) external returns (bool active);

    /// @notice Set ChainLink contract address for corresponding market.
    /// @param market The market address to set
    /// @param priceFeed ChainLink contract address
    function setRefPriceFeed(IMarketDescriptor market, IChainLinkAggregator priceFeed) external;

    /// @notice Set SequencerUptimeFeed contract address.
    /// @param sequencerUptimeFeed SequencerUptimeFeed contract address
    function setSequencerUptimeFeed(IChainLinkAggregator sequencerUptimeFeed) external;

    /// @notice Get SequencerUptimeFeed contract address.
    /// @return sequencerUptimeFeed SequencerUptimeFeed contract address
    function sequencerUptimeFeed() external returns (IChainLinkAggregator sequencerUptimeFeed);

    /// @notice Set the expected update interval for the ChainLink oracle price of the corresponding market.
    /// If ChainLink does not update the price within this period, it is considered that ChainLink has broken down.
    /// @param market The market address to set
    /// @param duration Expected update interval
    function setRefHeartbeatDuration(IMarketDescriptor market, uint32 duration) external;

    /// @notice Set maximum deviation ratio between price and ChainLink price.
    /// If exceeded, the updated price will refer to ChainLink price.
    /// @param maxDeviationRatio Maximum deviation ratio
    function setMaxDeviationRatio(uint32 maxDeviationRatio) external;

    /// @notice Set period for calculating cumulative deviation ratio.
    /// @param cumulativeRoundDuration Period in seconds to set.
    function setCumulativeRoundDuration(uint32 cumulativeRoundDuration) external;

    /// @notice Set the maximum acceptable cumulative change ratio difference between prices and ChainLink prices
    /// within a period of time. If exceeded, the updated price will refer to ChainLink price.
    /// @param market The market address to set
    /// @param maxCumulativeDeltaDiff Maximum cumulative change ratio difference
    function setMaxCumulativeDeltaDiffs(IMarketDescriptor market, uint64 maxCumulativeDeltaDiff) external;

    /// @notice Set number of additional rounds for ChainLink prices to participate in price update calculation.
    /// @param refPriceExtraSample The number of additional sampling rounds.
    function setRefPriceExtraSample(uint32 refPriceExtraSample) external;

    /// @notice Set the timeout for price update transactions.
    /// @param updateTxTimeout The timeout for price update transactions
    function setUpdateTxTimeout(uint32 updateTxTimeout) external;

    /// @notice Set ChainLink contract address and heart beat duration config for stable market.
    /// @param stableMarketPriceFeed The stable market address to set
    /// @param stableMarketPriceFeedHeartBeatDuration The expected update interval of stable market price
    function setStableMarketPriceFeed(
        IChainLinkAggregator stableMarketPriceFeed,
        uint32 stableMarketPriceFeedHeartBeatDuration
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.23;

/// @title Plugin Manager Interface
/// @notice The interface defines the functions to manage plugins
interface IPluginManager {
    /// @notice Emitted when a new plugin is registered
    /// @param plugin The registered plugin
    event PluginRegistered(address indexed plugin);

    /// @notice Emitted when a registered plugin is unregister
    /// @param plugin The unregister plugin
    event PluginUnregistered(address indexed plugin);

    /// @notice Emitted when a plugin is approved
    /// @param account The account that approved the plugin
    /// @param plugin The approved plugin
    event PluginApproved(address indexed account, address indexed plugin);

    /// @notice Emitted when a plugin is revoked
    /// @param account The account that revoked the plugin
    /// @param plugin The revoked plugin
    event PluginRevoked(address indexed account, address indexed plugin);

    /// @notice Emitted when a new liquidator is registered
    /// @param liquidator The registered liquidator
    event LiquidatorRegistered(address indexed liquidator);

    /// @notice Emitted when a registered liquidator is unregistered
    /// @param liquidator The unregistered liquidator
    event LiquidatorUnregistered(address indexed liquidator);

    /// @notice Plugin is already registered
    error PluginAlreadyRegistered(address plugin);
    /// @notice Plugin is not registered
    error PluginNotRegistered(address plugin);
    /// @notice Plugin is already approved
    error PluginAlreadyApproved(address sender, address plugin);
    /// @notice Plugin is not approved
    error PluginNotApproved(address sender, address plugin);
    /// @notice Liquidator is already registered
    error LiquidatorAlreadyRegistered(address liquidator);
    /// @notice Liquidator is not registered
    error LiquidatorNotRegistered(address liquidator);

    /// @notice Register a new plugin
    /// @dev The call will fail if the caller is not the governor or the plugin is already registered
    /// @param plugin The plugin to register
    function registerPlugin(address plugin) external;

    /// @notice Unregister a registered plugin
    /// @dev The call will fail if the caller is not the governor or the plugin is not registered
    /// @param plugin The plugin to unregister
    function unregisterPlugin(address plugin) external;

    /// @notice Checks if a plugin is registered
    /// @param plugin The plugin to check
    /// @return True if the plugin is registered, false otherwise
    function registeredPlugins(address plugin) external view returns (bool);

    /// @notice Approve a plugin
    /// @dev The call will fail if the plugin is not registered or already approved
    /// @param plugin The plugin to approve
    function approvePlugin(address plugin) external;

    /// @notice Revoke approval for a plugin
    /// @dev The call will fail if the plugin is not approved
    /// @param plugin The plugin to revoke
    function revokePlugin(address plugin) external;

    /// @notice Checks if a plugin is approved for an account
    /// @param account The account to check
    /// @param plugin The plugin to check
    /// @return True if the plugin is approved for the account, false otherwise
    function isPluginApproved(address account, address plugin) external view returns (bool);

    /// @notice Register a new liquidator
    /// @dev The call will fail if the caller if not the governor or the liquidator is already registered
    /// @param liquidator The liquidator to register
    function registerLiquidator(address liquidator) external;

    /// @notice Unregister a registered liquidator
    /// @dev The call will fail if the caller if not the governor or the liquidator is not registered
    /// @param liquidator The liquidator to unregister
    function unregisterLiquidator(address liquidator) external;

    /// @notice Checks if a liquidator is registered
    /// @param liquidator The liquidator to check
    /// @return True if the liquidator is registered, false otherwise
    function isRegisteredLiquidator(address liquidator) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Side} from "../../types/Side.sol";
import "../../core/interfaces/IMarketDescriptor.sol";

interface IPositionRouter {
    enum RequestType {
        IncreaseLiquidityPosition,
        DecreaseLiquidityPosition,
        IncreasePosition,
        DecreasePosition
    }

    struct IncreaseLiquidityPositionRequest {
        address account;
        IMarketDescriptor market;
        uint128 marginDelta;
        uint128 liquidityDelta;
        uint128 acceptableMinMargin;
        uint256 executionFee;
        uint96 blockNumber;
        uint64 blockTime;
    }

    struct DecreaseLiquidityPositionRequest {
        address account;
        IMarketDescriptor market;
        uint128 marginDelta;
        uint128 liquidityDelta;
        uint128 acceptableMinMargin;
        uint256 executionFee;
        uint96 blockNumber;
        uint64 blockTime;
        address receiver;
    }

    struct IncreasePositionRequest {
        address account;
        IMarketDescriptor market;
        Side side;
        uint128 marginDelta;
        uint128 sizeDelta;
        uint160 acceptableTradePriceX96;
        uint256 executionFee;
        uint96 blockNumber;
        uint64 blockTime;
    }

    struct DecreasePositionRequest {
        address account;
        IMarketDescriptor market;
        Side side;
        uint128 marginDelta;
        uint128 sizeDelta;
        uint160 acceptableTradePriceX96;
        uint256 executionFee;
        uint96 blockNumber;
        uint64 blockTime;
        address receiver;
    }

    struct ClosePositionParameter {
        IMarketDescriptor market;
        Side side;
    }

    /// @notice Emitted when min execution fee updated
    /// @param minExecutionFee New min execution fee after the update
    event MinExecutionFeeUpdated(uint256 minExecutionFee);

    /// @notice Emitted when position executor updated
    /// @param account Account to update
    /// @param active Whether active after the update
    event PositionExecutorUpdated(address indexed account, bool active);

    /// @notice Emitted when delay parameter updated
    /// @param minBlockDelayExecutor The new min block delay for executor to execute requests
    /// @param minTimeDelayPublic The new min time delay for public to execute requests
    /// @param maxTimeDelay The new max time delay until request expires
    event DelayValuesUpdated(uint32 minBlockDelayExecutor, uint32 minTimeDelayPublic, uint32 maxTimeDelay);

    /// @notice Emitted when increase liquidity position request created
    /// @param account Owner of the request
    /// @param market The market in which to increase liquidity position
    /// @param marginDelta The increase in liquidity position margin
    /// @param liquidityDelta The increase in liquidity position liquidity
    /// @param acceptableMinMargin The min acceptable margin of the request
    /// @param executionFee Amount of fee for the executor to carry out the request
    /// @param index Index of the request
    event IncreaseLiquidityPositionCreated(
        address indexed account,
        IMarketDescriptor indexed market,
        uint128 marginDelta,
        uint256 liquidityDelta,
        uint256 acceptableMinMargin,
        uint256 executionFee,
        uint128 indexed index
    );

    /// @notice Emitted when increase liquidity position request cancelled
    /// @param index Index of the cancelled request
    /// @param executionFeeReceiver Receiver of the request execution fee
    event IncreaseLiquidityPositionCancelled(uint128 indexed index, address payable executionFeeReceiver);

    /// @notice Emitted when increase liquidity position request executed
    /// @param index Index of the order to execute
    /// @param executionFeeReceiver Receiver of the order execution fee
    event IncreaseLiquidityPositionExecuted(uint128 indexed index, address payable executionFeeReceiver);

    /// @notice Emitted when decrease liquidity position request created
    /// @param account Owner of the request
    /// @param market The market in which to decrease liquidity position
    /// @param marginDelta The decrease in liquidity position margin
    /// @param liquidityDelta The decrease in liquidity position liquidity
    /// @param acceptableMinMargin The min acceptable margin of the request
    /// @param receiver Address of the margin receiver
    /// @param executionFee  Amount of fee for the executor to carry out the request
    /// @param index Index of the request
    event DecreaseLiquidityPositionCreated(
        address indexed account,
        IMarketDescriptor indexed market,
        uint128 marginDelta,
        uint256 liquidityDelta,
        uint256 acceptableMinMargin,
        address receiver,
        uint256 executionFee,
        uint128 indexed index
    );

    /// @notice Emitted when decrease liquidity position request cancelled
    /// @param index Index of cancelled request
    /// @param executionFeeReceiver Receiver of the request execution fee
    event DecreaseLiquidityPositionCancelled(uint128 indexed index, address payable executionFeeReceiver);

    /// @notice Emitted when decrease liquidity position request executed
    /// @param index Index of the executed request
    /// @param executionFeeReceiver Receiver of the request execution fee
    event DecreaseLiquidityPositionExecuted(uint128 indexed index, address payable executionFeeReceiver);

    /// @notice Emitted when open or increase an existing position size request created
    /// @param account Owner of the request
    /// @param market The market in which to increase position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The increase in position margin
    /// @param sizeDelta The increase in position size
    /// @param acceptableTradePriceX96 The worst trade price of the request
    /// @param executionFee Amount of fee for the executor to carry out the request
    /// @param index Index of the request
    event IncreasePositionCreated(
        address indexed account,
        IMarketDescriptor indexed market,
        Side side,
        uint128 marginDelta,
        uint128 sizeDelta,
        uint160 acceptableTradePriceX96,
        uint256 executionFee,
        uint128 indexed index
    );

    /// @notice Emitted when increase position request cancelled
    /// @param index Index of the cancelled request
    /// @param executionFeeReceiver Receiver of the cancelled request execution fee
    event IncreasePositionCancelled(uint128 indexed index, address payable executionFeeReceiver);

    /// @notice Emitted when increase position request executed
    /// @param index Index of the executed request
    /// @param executionFeeReceiver Receiver of the executed request execution fee
    event IncreasePositionExecuted(uint128 indexed index, address payable executionFeeReceiver);

    /// @notice Emitted when close or decrease existing position size request created
    /// @param account Owner of the request
    /// @param market The market in which to decrease position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The decrease in position margin
    /// @param sizeDelta The decrease in position size
    /// @param acceptableTradePriceX96 The worst trade price of the request
    /// @param executionFee Amount of fee for the executor to carry out the order
    /// @param index Index of the request
    /// @param receiver Address of the margin receiver
    event DecreasePositionCreated(
        address indexed account,
        IMarketDescriptor indexed market,
        Side side,
        uint128 marginDelta,
        uint128 sizeDelta,
        uint160 acceptableTradePriceX96,
        address receiver,
        uint256 executionFee,
        uint128 indexed index
    );

    /// @notice Emitted when decrease position request cancelled
    /// @param index Index of the cancelled decrease position request
    /// @param executionFeeReceiver Receiver of the request execution fee
    event DecreasePositionCancelled(uint128 indexed index, address payable executionFeeReceiver);

    /// @notice Emitted when decrease position request executed
    /// @param index Index of the executed decrease position request
    /// @param executionFeeReceiver Receiver of the request execution fee
    event DecreasePositionExecuted(uint128 indexed index, address payable executionFeeReceiver);

    /// @notice Emitted when requests execution reverted
    /// @param reqType Request type
    /// @param index Index of the failed request
    /// @param shortenedReason The error selector for the failure
    event ExecuteFailed(RequestType indexed reqType, uint128 indexed index, bytes4 shortenedReason);

    /// @notice Execution fee is insufficient
    /// @param available The available execution fee amount
    /// @param required The required minimum execution fee amount
    error InsufficientExecutionFee(uint256 available, uint256 required);

    /// @notice Execution fee is invalid
    /// @param available The available execution fee amount
    /// @param required The required execution fee amount
    error InvalidExecutionFee(uint256 available, uint256 required);

    /// @notice Position not found
    /// @param market The market in which to close position
    /// @param account The account of the position
    /// @param side The side of the position
    error PositionNotFound(IMarketDescriptor market, address account, Side side);

    /// @notice Liquidity position not found
    /// @param market The market in which to close liquidity position
    /// @param account The account of the liquidity position
    error LiquidityNotFound(IMarketDescriptor market, address account);

    /// @notice Request expired
    /// @param expiredAt When the request is expired
    error Expired(uint256 expiredAt);

    /// @notice Too early to execute request
    /// @param earliest The earliest time to execute the request
    error TooEarly(uint256 earliest);

    /// @notice Trade price exceeds limit
    error InvalidTradePrice(uint160 tradePriceX96, uint160 acceptableTradePriceX96);

    /// @notice Margin is less than acceptable min margin
    error InvalidMargin(uint128 margin, uint128 acceptableMinMargin);

    /// @notice Update position executor
    /// @param account Account to update
    /// @param active Updated status
    function updatePositionExecutor(address account, bool active) external;

    /// @notice Update delay parameters
    /// @param minBlockDelayExecutor New min block delay for executor to execute requests
    /// @param minTimeDelayPublic New min time delay for public to execute requests
    /// @param maxTimeDelay New max time delay until request expires
    function updateDelayValues(uint32 minBlockDelayExecutor, uint32 minTimeDelayPublic, uint32 maxTimeDelay) external;

    /// @notice Update minimum execution fee
    /// @param minExecutionFee New min execution fee
    function updateMinExecutionFee(uint256 minExecutionFee) external;

    /// @notice Update the gas limit for executing requests
    /// @param executionGasLimit New execution gas limit
    function updateExecutionGasLimit(uint160 executionGasLimit) external;

    /// @notice Create increase liquidity position request
    /// @param market The market in which to increase liquidity position
    /// @param marginDelta Margin delta of the liquidity position
    /// @param liquidityDelta Liquidity delta of the liquidity position
    /// @param acceptableMinMargin The min acceptable margin of the request
    /// @return index Index of the request
    function createIncreaseLiquidityPosition(
        IMarketDescriptor market,
        uint128 marginDelta,
        uint128 liquidityDelta,
        uint128 acceptableMinMargin
    ) external payable returns (uint128 index);

    /// @notice Cancel increase liquidity position request
    /// @param index Index of the request to cancel
    /// @param executionFeeReceiver Receiver of request execution fee
    /// @return cancelled True if the cancellation succeeds or request not exists
    function cancelIncreaseLiquidityPosition(
        uint128 index,
        address payable executionFeeReceiver
    ) external returns (bool cancelled);

    /// @notice Execute increase liquidity position request
    /// @param index Index of request to execute
    /// @param executionFeeReceiver Receiver of the request execution fee
    /// @return executed True if the execution succeeds or request not exists
    function executeIncreaseLiquidityPosition(
        uint128 index,
        address payable executionFeeReceiver
    ) external returns (bool executed);

    /// @notice Execute multiple liquidity position requests
    /// @param endIndex The maximum request index to execute, excluded
    /// @param executionFeeReceiver Receiver of the request execution fees
    function executeIncreaseLiquidityPositions(uint128 endIndex, address payable executionFeeReceiver) external;

    /// @notice Create decrease liquidity position request
    /// @param market The market in which to decrease liquidity position
    /// @param marginDelta The decrease in liquidity position margin
    /// @param liquidityDelta The decrease in liquidity position liquidity
    /// @param acceptableMinMargin The min acceptable margin of the request
    /// @param receiver Address of the margin receiver
    /// @return index The request index
    function createDecreaseLiquidityPosition(
        IMarketDescriptor market,
        uint128 marginDelta,
        uint128 liquidityDelta,
        uint128 acceptableMinMargin,
        address receiver
    ) external payable returns (uint128 index);

    /// @notice Create multiple close liquidity position requests in a single call
    /// @param markets Markets to close liquidity position
    /// @param receiver Margin recipient address
    /// @return indices The request indices
    function createCloseLiquidityPositionsBatch(
        IMarketDescriptor[] calldata markets,
        address receiver
    ) external payable returns (uint128[] memory indices);

    /// @notice Cancel decrease liquidity position request
    /// @param index Index of the request to cancel
    /// @param executionFeeReceiver Receiver of the request execution fee
    /// @return cancelled True if the cancellation succeeds or request not exists
    function cancelDecreaseLiquidityPosition(
        uint128 index,
        address payable executionFeeReceiver
    ) external returns (bool cancelled);

    /// @notice Execute decrease liquidity position request
    /// @param index Index of the request to execute
    /// @param executionFeeReceiver Receiver of the request execution fee
    /// @return executed True if the execution succeeds or request not exists
    function executeDecreaseLiquidityPosition(
        uint128 index,
        address payable executionFeeReceiver
    ) external returns (bool executed);

    /// @notice Execute multiple decrease liquidity position requests
    /// @param endIndex The maximum request index to execute, excluded
    /// @param executionFeeReceiver Receiver of the request execution fee
    function executeDecreaseLiquidityPositions(uint128 endIndex, address payable executionFeeReceiver) external;

    /// @notice Execute increase liquidation fund position request
    /// @param market The market in which to increase liquidation fund position
    /// @param liquidityDelta The increase in liquidity
    function executeIncreaseLiquidationFundPosition(IMarketDescriptor market, uint128 liquidityDelta) external;

    /// @notice Execute decrease liquidation fund position request
    /// @param market The market in which to decrease liquidation fund position
    /// @param liquidityDelta The decrease in liquidity
    /// @param receiver Address of the margin receiver
    function executeDecreaseLiquidationFundPosition(
        IMarketDescriptor market,
        uint128 liquidityDelta,
        address receiver
    ) external;

    /// @notice Create open or increase the size of existing position request
    /// @param market The market in which to increase position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The increase in position margin
    /// @param sizeDelta The increase in position size
    /// @param acceptableTradePriceX96 The worst trade price of the request, as a Q64.96
    /// @return index Index of the request
    function createIncreasePosition(
        IMarketDescriptor market,
        Side side,
        uint128 marginDelta,
        uint128 sizeDelta,
        uint160 acceptableTradePriceX96
    ) external payable returns (uint128 index);

    /// @notice Cancel increase position request
    /// @param index Index of the request to cancel
    /// @param executionFeeReceiver Receiver of the request execution fee
    /// @return cancelled True if the cancellation succeeds or request not exists
    function cancelIncreasePosition(
        uint128 index,
        address payable executionFeeReceiver
    ) external returns (bool cancelled);

    /// @notice Execute increase position request
    /// @param index Index of the request to execute
    /// @param executionFeeReceiver Receiver of the request execution fee
    /// @return executed True if the execution succeeds or request not exists
    function executeIncreasePosition(
        uint128 index,
        address payable executionFeeReceiver
    ) external returns (bool executed);

    /// @notice Execute multiple increase position requests
    /// @param endIndex The maximum request index to execute, excluded
    /// @param executionFeeReceiver Receiver of the request execution fee
    function executeIncreasePositions(uint128 endIndex, address payable executionFeeReceiver) external;

    /// @notice Create decrease position request
    /// @param market The market in which to decrease position
    /// @param side The side of the position (Long or Short)
    /// @param marginDelta The decrease in position margin
    /// @param sizeDelta The decrease in position size
    /// @param acceptableTradePriceX96 The worst trade price of the request, as a Q64.96
    /// @param receiver Margin recipient address
    /// @return index The request index
    function createDecreasePosition(
        IMarketDescriptor market,
        Side side,
        uint128 marginDelta,
        uint128 sizeDelta,
        uint160 acceptableTradePriceX96,
        address receiver
    ) external payable returns (uint128 index);

    /// @notice Create multiple close position requests in a single call
    /// @param parameters Parameters of the close position requests
    /// @param receiver Margin recipient address
    /// @return indices The request indices
    function createClosePositionsBatch(
        ClosePositionParameter[] calldata parameters,
        address receiver
    ) external payable returns (uint128[] memory indices);

    /// @notice Cancel decrease position request
    /// @param index Index of the request to cancel
    /// @param executionFeeReceiver Receiver of the request execution fee
    /// @return cancelled True if the cancellation succeeds or request not exists
    function cancelDecreasePosition(
        uint128 index,
        address payable executionFeeReceiver
    ) external returns (bool cancelled);

    /// @notice Execute decrease position request
    /// @param index Index of the request to execute
    /// @param executionFeeReceiver Receiver of the request execution fee
    /// @return executed True if the execution succeeds or request not exists
    function executeDecreasePosition(
        uint128 index,
        address payable executionFeeReceiver
    ) external returns (bool executed);

    /// @notice Execute multiple decrease position requests
    /// @param endIndex The maximum request index to execute, excluded
    /// @param executionFeeReceiver Receiver of the request execution fee
    function executeDecreasePositions(uint128 endIndex, address payable executionFeeReceiver) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.23;

import "../governance/GovernableUpgradeable.sol";
import "./interfaces/IPluginManager.sol";

abstract contract PluginManagerUpgradeable is IPluginManager, GovernableUpgradeable {
    /// @custom:storage-location erc7201:EquationDAO.storage.PluginManagerUpgradeable
    struct PluginManagerStorage {
        mapping(address plugin => bool) registeredPlugins;
        mapping(address liquidator => bool) registeredLiquidators;
        mapping(address account => mapping(address plugin => bool)) pluginApprovals;
    }

    // keccak256(abi.encode(uint256(keccak256("EquationDAO.storage.PluginManagerUpgradeable")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant PLUGIN_MANAGER_UPGRADEABLE_STORAGE =
        0xf9fe859717463c72f74c7189bf68eb7b4a998dbbeaec3a6b76288d359ba09700;

    function __PluginManager_init() internal onlyInitializing {
        GovernableUpgradeable.__Governable_init();
    }

    /// @inheritdoc IPluginManager
    function registerPlugin(address _plugin) external override onlyGov {
        PluginManagerStorage storage $ = _pluginManagerStorage();
        if ($.registeredPlugins[_plugin]) revert PluginAlreadyRegistered(_plugin);

        $.registeredPlugins[_plugin] = true;

        emit PluginRegistered(_plugin);
    }

    /// @inheritdoc IPluginManager
    function unregisterPlugin(address _plugin) external override onlyGov {
        PluginManagerStorage storage $ = _pluginManagerStorage();
        if (!$.registeredPlugins[_plugin]) revert PluginNotRegistered(_plugin);

        delete $.registeredPlugins[_plugin];
        emit PluginUnregistered(_plugin);
    }

    /// @inheritdoc IPluginManager
    function registeredPlugins(address _plugin) public view override returns (bool) {
        return _pluginManagerStorage().registeredPlugins[_plugin];
    }

    /// @inheritdoc IPluginManager
    function approvePlugin(address _plugin) external override {
        PluginManagerStorage storage $ = _pluginManagerStorage();
        if ($.pluginApprovals[msg.sender][_plugin]) revert PluginAlreadyApproved(msg.sender, _plugin);

        if (!$.registeredPlugins[_plugin]) revert PluginNotRegistered(_plugin);

        $.pluginApprovals[msg.sender][_plugin] = true;
        emit PluginApproved(msg.sender, _plugin);
    }

    /// @inheritdoc IPluginManager
    function revokePlugin(address _plugin) external {
        PluginManagerStorage storage $ = _pluginManagerStorage();
        if (!$.pluginApprovals[msg.sender][_plugin]) revert PluginNotApproved(msg.sender, _plugin);

        delete $.pluginApprovals[msg.sender][_plugin];
        emit PluginRevoked(msg.sender, _plugin);
    }

    /// @inheritdoc IPluginManager
    function isPluginApproved(address _account, address _plugin) public view override returns (bool) {
        return _pluginManagerStorage().pluginApprovals[_account][_plugin];
    }

    /// @inheritdoc IPluginManager
    function registerLiquidator(address _liquidator) external override onlyGov {
        PluginManagerStorage storage $ = _pluginManagerStorage();
        if ($.registeredLiquidators[_liquidator]) revert LiquidatorAlreadyRegistered(_liquidator);

        $.registeredLiquidators[_liquidator] = true;

        emit LiquidatorRegistered(_liquidator);
    }

    /// @inheritdoc IPluginManager
    function unregisterLiquidator(address _liquidator) external override onlyGov {
        PluginManagerStorage storage $ = _pluginManagerStorage();
        if (!$.registeredLiquidators[_liquidator]) revert LiquidatorNotRegistered(_liquidator);

        delete $.registeredLiquidators[_liquidator];
        emit LiquidatorUnregistered(_liquidator);
    }

    /// @inheritdoc IPluginManager
    function isRegisteredLiquidator(address _liquidator) public view override returns (bool) {
        return _pluginManagerStorage().registeredLiquidators[_liquidator];
    }

    function _pluginManagerStorage() private pure returns (PluginManagerStorage storage $) {
        // prettier-ignore
        assembly { $.slot := PLUGIN_MANAGER_UPGRADEABLE_STORAGE }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.23;

import "./RouterUpgradeable.sol";
import "./interfaces/IPositionRouter.sol";
import {M as Math} from "../libraries/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract PositionRouterUpgradeable is IPositionRouter, GovernableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeCast for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    IERC20 public usd;
    RouterUpgradeable public router;
    IMarketManager public marketManager;

    uint256 public minExecutionFee;

    // pack into a single slot to save gas
    uint32 public minBlockDelayExecutor;
    uint32 public minTimeDelayPublic;
    uint32 public maxTimeDelay;
    uint160 public executionGasLimit;

    mapping(address => bool) public positionExecutors;

    // LP stats
    mapping(uint128 => IncreaseLiquidityPositionRequest) public increaseLiquidityPositionRequests;
    uint128 public increaseLiquidityPositionIndex;
    uint128 public increaseLiquidityPositionIndexNext;

    mapping(uint128 => DecreaseLiquidityPositionRequest) public decreaseLiquidityPositionRequests;
    uint128 public decreaseLiquidityPositionIndex;
    uint128 public decreaseLiquidityPositionIndexNext;

    // Trader stats
    mapping(uint128 => IncreasePositionRequest) public increasePositionRequests;
    uint128 public increasePositionIndex;
    uint128 public increasePositionIndexNext;

    mapping(uint128 => DecreasePositionRequest) public decreasePositionRequests;
    uint128 public decreasePositionIndex;
    uint128 public decreasePositionIndexNext;

    modifier onlyPositionExecutor() {
        if (!positionExecutors[msg.sender]) revert Forbidden();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IERC20 _usd,
        RouterUpgradeable _router,
        IMarketManager _marketManager,
        uint256 _minExecutionFee
    ) public initializer {
        GovernableUpgradeable.__Governable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        (usd, router, marketManager, minExecutionFee) = (_usd, _router, _marketManager, _minExecutionFee);
        (minTimeDelayPublic, maxTimeDelay, executionGasLimit) = (3 minutes, 30 minutes, 1_000_000 wei);
        emit MinExecutionFeeUpdated(_minExecutionFee);
    }

    /// @inheritdoc IPositionRouter
    function updatePositionExecutor(address _account, bool _active) external override onlyGov {
        positionExecutors[_account] = _active;
        emit PositionExecutorUpdated(_account, _active);
    }

    /// @inheritdoc IPositionRouter
    function updateDelayValues(
        uint32 _minBlockDelayExecutor,
        uint32 _minTimeDelayPublic,
        uint32 _maxTimeDelay
    ) external override onlyGov {
        minBlockDelayExecutor = _minBlockDelayExecutor;
        minTimeDelayPublic = _minTimeDelayPublic;
        maxTimeDelay = _maxTimeDelay;
        emit DelayValuesUpdated(_minBlockDelayExecutor, _minTimeDelayPublic, _maxTimeDelay);
    }

    /// @inheritdoc IPositionRouter
    function updateMinExecutionFee(uint256 _minExecutionFee) external override onlyGov {
        minExecutionFee = _minExecutionFee;
        emit MinExecutionFeeUpdated(_minExecutionFee);
    }

    /// @inheritdoc IPositionRouter
    function updateExecutionGasLimit(uint160 _executionGasLimit) external override onlyGov {
        executionGasLimit = _executionGasLimit;
    }

    /// @inheritdoc IPositionRouter
    function createIncreaseLiquidityPosition(
        IMarketDescriptor _market,
        uint128 _marginDelta,
        uint128 _liquidityDelta,
        uint128 _acceptableMinMargin
    ) external payable override nonReentrant returns (uint128 index) {
        if (msg.value < minExecutionFee) revert InsufficientExecutionFee(msg.value, minExecutionFee);

        if (_marginDelta > 0) router.pluginTransfer(usd, msg.sender, address(this), _marginDelta);

        index = increaseLiquidityPositionIndexNext++;
        increaseLiquidityPositionRequests[index] = IncreaseLiquidityPositionRequest({
            account: msg.sender,
            market: _market,
            marginDelta: _marginDelta,
            liquidityDelta: _liquidityDelta,
            acceptableMinMargin: _acceptableMinMargin,
            executionFee: msg.value,
            blockNumber: block.number.toUint96(),
            blockTime: block.timestamp.toUint64()
        });

        emit IncreaseLiquidityPositionCreated(
            msg.sender,
            _market,
            _marginDelta,
            _liquidityDelta,
            _acceptableMinMargin,
            msg.value,
            index
        );
    }

    /// @inheritdoc IPositionRouter
    function cancelIncreaseLiquidityPosition(
        uint128 _index,
        address payable _executionFeeReceiver
    ) external override nonReentrant returns (bool) {
        IncreaseLiquidityPositionRequest memory request = increaseLiquidityPositionRequests[_index];
        if (request.account == address(0)) return true;

        bool shouldCancel = _shouldCancel(request.blockNumber, request.blockTime, request.account);
        if (!shouldCancel) return false;

        if (request.marginDelta > 0) usd.safeTransfer(request.account, request.marginDelta);

        _transferOutETH(request.executionFee, _executionFeeReceiver);

        delete increaseLiquidityPositionRequests[_index];

        emit IncreaseLiquidityPositionCancelled(_index, _executionFeeReceiver);

        return true;
    }

    /// @inheritdoc IPositionRouter
    function executeIncreaseLiquidityPosition(
        uint128 _index,
        address payable _executionFeeReceiver
    ) external override nonReentrant returns (bool) {
        IncreaseLiquidityPositionRequest memory request = increaseLiquidityPositionRequests[_index];
        if (request.account == address(0)) return true;

        bool shouldExecute = _shouldExecute(request.blockNumber, request.blockTime, request.account);
        if (!shouldExecute) return false;

        if (request.marginDelta > 0) usd.safeTransfer(address(marketManager), request.marginDelta);

        // Note that the gas specified here is just an upper limit,
        // when the gas left is lower than this value, code can still be executed
        uint128 marginAfter = router.pluginIncreaseLiquidityPosition{gas: executionGasLimit}(
            request.market,
            request.account,
            request.marginDelta,
            request.liquidityDelta
        );

        _validateMargin(marginAfter, request.acceptableMinMargin);

        _transferOutETH(request.executionFee, _executionFeeReceiver);

        delete increaseLiquidityPositionRequests[_index];

        emit IncreaseLiquidityPositionExecuted(_index, _executionFeeReceiver);
        return true;
    }

    /// @inheritdoc IPositionRouter
    function executeIncreaseLiquidityPositions(
        uint128 _endIndex,
        address payable _executionFeeReceiver
    ) external override onlyPositionExecutor {
        uint128 index = increaseLiquidityPositionIndex;
        _endIndex = uint128(Math.min(_endIndex, increaseLiquidityPositionIndexNext));

        while (index < _endIndex) {
            try this.executeIncreaseLiquidityPosition(index, _executionFeeReceiver) returns (bool _executed) {
                if (!_executed) break;
            } catch (bytes memory reason) {
                bytes4 errorTypeSelector = _decodeShortenedReason(reason);
                emit ExecuteFailed(RequestType.IncreaseLiquidityPosition, index, errorTypeSelector);

                try this.cancelIncreaseLiquidityPosition(index, _executionFeeReceiver) returns (bool _cancelled) {
                    if (!_cancelled) break;
                } catch {}
            }
            // prettier-ignore
            unchecked { ++index; }
        }

        increaseLiquidityPositionIndex = index;
    }

    /// @inheritdoc IPositionRouter
    function createDecreaseLiquidityPosition(
        IMarketDescriptor _market,
        uint128 _marginDelta,
        uint128 _liquidityDelta,
        uint128 _acceptableMinMargin,
        address _receiver
    ) external payable override nonReentrant returns (uint128 index) {
        if (msg.value < minExecutionFee) revert InsufficientExecutionFee(msg.value, minExecutionFee);

        index = _createDecreaseLiquidityPosition(
            _market,
            _marginDelta,
            _liquidityDelta,
            _acceptableMinMargin,
            _receiver,
            msg.value
        );
    }

    /// @inheritdoc IPositionRouter
    function createCloseLiquidityPositionsBatch(
        IMarketDescriptor[] calldata markets,
        address receiver
    ) external payable override nonReentrant returns (uint128[] memory indices) {
        uint256 len = markets.length;
        if (len == 0) return new uint128[](0);

        unchecked {
            uint256 executionFeePerRequest = msg.value / len;
            if (executionFeePerRequest < minExecutionFee)
                revert InsufficientExecutionFee(executionFeePerRequest, minExecutionFee);

            if (executionFeePerRequest * len != msg.value)
                revert InvalidExecutionFee(msg.value, executionFeePerRequest * len);

            indices = new uint128[](markets.length);
            for (uint256 i; i < len; ++i) {
                IMarketDescriptor market = markets[i];
                IMarketManager.LiquidityPosition memory position = marketManager.liquidityPositions(market, msg.sender);
                if (position.liquidity == 0) revert LiquidityNotFound(market, msg.sender);

                indices[i] = _createDecreaseLiquidityPosition(
                    market,
                    0,
                    position.liquidity,
                    0,
                    receiver,
                    executionFeePerRequest
                );
            }
        }
    }

    /// @inheritdoc IPositionRouter
    function cancelDecreaseLiquidityPosition(
        uint128 _index,
        address payable _executionFeeReceiver
    ) external override nonReentrant returns (bool) {
        DecreaseLiquidityPositionRequest memory request = decreaseLiquidityPositionRequests[_index];
        if (request.account == address(0)) return true;

        bool shouldCancel = _shouldCancel(request.blockNumber, request.blockTime, request.account);
        if (!shouldCancel) return false;

        _transferOutETH(request.executionFee, _executionFeeReceiver);

        delete decreaseLiquidityPositionRequests[_index];

        emit DecreaseLiquidityPositionCancelled(_index, _executionFeeReceiver);

        return true;
    }

    /// @inheritdoc IPositionRouter
    function executeDecreaseLiquidityPosition(
        uint128 _index,
        address payable _executionFeeReceiver
    ) external override nonReentrant returns (bool) {
        DecreaseLiquidityPositionRequest memory request = decreaseLiquidityPositionRequests[_index];
        if (request.account == address(0)) return true;

        bool shouldExecute = _shouldExecute(request.blockNumber, request.blockTime, request.account);
        if (!shouldExecute) return false;

        uint128 marginAfter = router.pluginDecreaseLiquidityPosition{gas: executionGasLimit}(
            request.market,
            request.account,
            request.marginDelta,
            request.liquidityDelta,
            request.receiver
        );

        _validateMargin(marginAfter, request.acceptableMinMargin);

        _transferOutETH(request.executionFee, _executionFeeReceiver);

        delete decreaseLiquidityPositionRequests[_index];

        emit DecreaseLiquidityPositionExecuted(_index, _executionFeeReceiver);
        return true;
    }

    /// @inheritdoc IPositionRouter
    function executeDecreaseLiquidityPositions(
        uint128 _endIndex,
        address payable _executionFeeReceiver
    ) external override onlyPositionExecutor {
        uint128 index = decreaseLiquidityPositionIndex;
        _endIndex = uint128(Math.min(_endIndex, decreaseLiquidityPositionIndexNext));

        while (index < _endIndex) {
            try this.executeDecreaseLiquidityPosition(index, _executionFeeReceiver) returns (bool _executed) {
                if (!_executed) break;
            } catch (bytes memory reason) {
                bytes4 errorTypeSelector = _decodeShortenedReason(reason);
                emit ExecuteFailed(RequestType.DecreaseLiquidityPosition, index, errorTypeSelector);

                try this.cancelDecreaseLiquidityPosition(index, _executionFeeReceiver) returns (bool _cancelled) {
                    if (!_cancelled) break;
                } catch {}
            }
            // prettier-ignore
            unchecked { ++index; }
        }

        decreaseLiquidityPositionIndex = index;
    }

    /// @inheritdoc IPositionRouter
    function executeIncreaseLiquidationFundPosition(
        IMarketDescriptor _market,
        uint128 _liquidityDelta
    ) external override {
        router.pluginTransfer(usd, msg.sender, address(marketManager), _liquidityDelta);

        router.pluginIncreaseLiquidationFundPosition(_market, msg.sender, _liquidityDelta);
    }

    /// @inheritdoc IPositionRouter
    function executeDecreaseLiquidationFundPosition(
        IMarketDescriptor _market,
        uint128 _liquidityDelta,
        address _receiver
    ) external override {
        router.pluginDecreaseLiquidationFundPosition(_market, msg.sender, _liquidityDelta, _receiver);
    }

    /// @inheritdoc IPositionRouter
    function createIncreasePosition(
        IMarketDescriptor _market,
        Side _side,
        uint128 _marginDelta,
        uint128 _sizeDelta,
        uint160 _acceptableTradePriceX96
    ) external payable override nonReentrant returns (uint128 index) {
        _side.requireValid();
        if (msg.value < minExecutionFee) revert InsufficientExecutionFee(msg.value, minExecutionFee);

        if (_marginDelta > 0) router.pluginTransfer(usd, msg.sender, address(this), _marginDelta);

        index = increasePositionIndexNext++;
        increasePositionRequests[index] = IncreasePositionRequest({
            account: msg.sender,
            market: _market,
            side: _side,
            marginDelta: _marginDelta,
            sizeDelta: _sizeDelta,
            acceptableTradePriceX96: _acceptableTradePriceX96,
            executionFee: msg.value,
            blockNumber: block.number.toUint96(),
            blockTime: block.timestamp.toUint64()
        });

        emit IncreasePositionCreated(
            msg.sender,
            _market,
            _side,
            _marginDelta,
            _sizeDelta,
            _acceptableTradePriceX96,
            msg.value,
            index
        );
    }

    /// @inheritdoc IPositionRouter
    function cancelIncreasePosition(
        uint128 _index,
        address payable _executionFeeReceiver
    ) external override nonReentrant returns (bool) {
        IncreasePositionRequest memory request = increasePositionRequests[_index];
        if (request.account == address(0)) return true;

        bool shouldCancel = _shouldCancel(request.blockNumber, request.blockTime, request.account);
        if (!shouldCancel) return false;

        if (request.marginDelta > 0) usd.safeTransfer(request.account, request.marginDelta);

        _transferOutETH(request.executionFee, _executionFeeReceiver);

        delete increasePositionRequests[_index];

        emit IncreasePositionCancelled(_index, _executionFeeReceiver);

        return true;
    }

    /// @inheritdoc IPositionRouter
    function executeIncreasePosition(
        uint128 _index,
        address payable _executionFeeReceiver
    ) external override nonReentrant returns (bool) {
        IncreasePositionRequest memory request = increasePositionRequests[_index];
        if (request.account == address(0)) return true;

        bool shouldExecute = _shouldExecute(request.blockNumber, request.blockTime, request.account);
        if (!shouldExecute) return false;

        if (request.marginDelta > 0) usd.safeTransfer(address(marketManager), request.marginDelta);

        uint160 tradePriceX96 = router.pluginIncreasePosition{gas: executionGasLimit}(
            request.market,
            request.account,
            request.side,
            request.marginDelta,
            request.sizeDelta
        );

        if (request.acceptableTradePriceX96 != 0)
            _validateTradePriceX96(request.side, tradePriceX96, request.acceptableTradePriceX96);

        _transferOutETH(request.executionFee, _executionFeeReceiver);

        delete increasePositionRequests[_index];

        emit IncreasePositionExecuted(_index, _executionFeeReceiver);
        return true;
    }

    /// @inheritdoc IPositionRouter
    function executeIncreasePositions(
        uint128 _endIndex,
        address payable _executionFeeReceiver
    ) external override onlyPositionExecutor {
        uint128 index = increasePositionIndex;
        _endIndex = uint128(Math.min(_endIndex, increasePositionIndexNext));

        while (index < _endIndex) {
            try this.executeIncreasePosition(index, _executionFeeReceiver) returns (bool _executed) {
                if (!_executed) break;
            } catch (bytes memory reason) {
                bytes4 errorTypeSelector = _decodeShortenedReason(reason);
                emit ExecuteFailed(RequestType.IncreasePosition, index, errorTypeSelector);

                try this.cancelIncreasePosition(index, _executionFeeReceiver) returns (bool _cancelled) {
                    if (!_cancelled) break;
                } catch {}
            }
            // prettier-ignore
            unchecked { ++index; }
        }

        increasePositionIndex = index;
    }

    /// @inheritdoc IPositionRouter
    function createDecreasePosition(
        IMarketDescriptor _market,
        Side _side,
        uint128 _marginDelta,
        uint128 _sizeDelta,
        uint160 _acceptableTradePriceX96,
        address _receiver
    ) external payable override nonReentrant returns (uint128 index) {
        _side.requireValid();
        if (msg.value < minExecutionFee) revert InsufficientExecutionFee(msg.value, minExecutionFee);

        index = _createDecreasePosition(
            _market,
            _side,
            _marginDelta,
            _sizeDelta,
            _acceptableTradePriceX96,
            _receiver,
            msg.value
        );
    }

    /// @inheritdoc IPositionRouter
    function createClosePositionsBatch(
        ClosePositionParameter[] calldata parameters,
        address receiver
    ) external payable override nonReentrant returns (uint128[] memory indices) {
        uint256 len = parameters.length;
        if (len == 0) return new uint128[](0);

        unchecked {
            uint256 executionFeePerRequest = msg.value / len;
            if (executionFeePerRequest < minExecutionFee)
                revert InsufficientExecutionFee(executionFeePerRequest, minExecutionFee);

            if (executionFeePerRequest * len != msg.value)
                revert InvalidExecutionFee(msg.value, executionFeePerRequest * len);

            indices = new uint128[](parameters.length);
            for (uint256 i; i < len; ++i) {
                ClosePositionParameter memory parameter = parameters[i];
                IMarketManager.Position memory position = marketManager.positions(
                    parameter.market,
                    msg.sender,
                    parameter.side
                );
                if (position.size == 0) revert PositionNotFound(parameter.market, msg.sender, parameter.side);

                indices[i] = _createDecreasePosition(
                    parameter.market,
                    parameter.side,
                    0,
                    position.size,
                    0,
                    receiver,
                    executionFeePerRequest
                );
            }
        }
    }

    /// @inheritdoc IPositionRouter
    function cancelDecreasePosition(
        uint128 _index,
        address payable _executionFeeReceiver
    ) external override nonReentrant returns (bool) {
        DecreasePositionRequest memory request = decreasePositionRequests[_index];
        if (request.account == address(0)) return true;

        bool shouldCancel = _shouldCancel(request.blockNumber, request.blockTime, request.account);
        if (!shouldCancel) return false;

        _transferOutETH(request.executionFee, _executionFeeReceiver);

        delete decreasePositionRequests[_index];

        emit DecreasePositionCancelled(_index, _executionFeeReceiver);

        return true;
    }

    /// @inheritdoc IPositionRouter
    function executeDecreasePosition(
        uint128 _index,
        address payable _executionFeeReceiver
    ) external override nonReentrant returns (bool) {
        DecreasePositionRequest memory request = decreasePositionRequests[_index];
        if (request.account == address(0)) return true;

        bool shouldExecute = _shouldExecute(request.blockNumber, request.blockTime, request.account);
        if (!shouldExecute) return false;

        uint160 tradePriceX96 = router.pluginDecreasePosition{gas: executionGasLimit}(
            request.market,
            request.account,
            request.side,
            request.marginDelta,
            request.sizeDelta,
            request.receiver
        );

        if (request.acceptableTradePriceX96 != 0)
            _validateTradePriceX96(request.side.flip(), tradePriceX96, request.acceptableTradePriceX96);

        _transferOutETH(request.executionFee, _executionFeeReceiver);

        delete decreasePositionRequests[_index];

        emit DecreasePositionExecuted(_index, _executionFeeReceiver);
        return true;
    }

    /// @inheritdoc IPositionRouter
    function executeDecreasePositions(
        uint128 _endIndex,
        address payable _executionFeeReceiver
    ) external override onlyPositionExecutor {
        uint128 index = decreasePositionIndex;
        _endIndex = uint128(Math.min(_endIndex, decreasePositionIndexNext));

        while (index < _endIndex) {
            try this.executeDecreasePosition(index, _executionFeeReceiver) returns (bool _executed) {
                if (!_executed) break;
            } catch (bytes memory reason) {
                bytes4 errorTypeSelector = _decodeShortenedReason(reason);
                emit ExecuteFailed(RequestType.DecreasePosition, index, errorTypeSelector);

                try this.cancelDecreasePosition(index, _executionFeeReceiver) returns (bool _cancelled) {
                    if (!_cancelled) break;
                } catch {}
            }
            // prettier-ignore
            unchecked { ++index; }
        }

        decreasePositionIndex = index;
    }

    // validation
    function _shouldCancel(
        uint256 _positionBlockNumber,
        uint256 _positionBlockTime,
        address _account
    ) internal view returns (bool) {
        return _shouldExecuteOrCancel(_positionBlockNumber, _positionBlockTime, _account);
    }

    function _shouldExecute(
        uint256 _positionBlockNumber,
        uint256 _positionBlockTime,
        address _account
    ) internal view returns (bool) {
        if (_positionBlockTime + maxTimeDelay <= block.timestamp) revert Expired(_positionBlockTime + maxTimeDelay);

        return _shouldExecuteOrCancel(_positionBlockNumber, _positionBlockTime, _account);
    }

    function _shouldExecuteOrCancel(
        uint256 _positionBlockNumber,
        uint256 _positionBlockTime,
        address _account
    ) internal view returns (bool) {
        bool isExecutorCall = msg.sender == address(this) || positionExecutors[msg.sender];

        if (isExecutorCall) return _positionBlockNumber + minBlockDelayExecutor <= block.number;

        if (msg.sender != _account) revert Forbidden();

        if (_positionBlockTime + minTimeDelayPublic > block.timestamp)
            revert TooEarly(_positionBlockTime + minTimeDelayPublic);

        return true;
    }

    function _createDecreaseLiquidityPosition(
        IMarketDescriptor _market,
        uint128 _marginDelta,
        uint128 _liquidityDelta,
        uint128 _acceptableMinMargin,
        address _receiver,
        uint256 _executionFee
    ) private returns (uint128 index) {
        index = decreaseLiquidityPositionIndexNext++;
        decreaseLiquidityPositionRequests[index] = DecreaseLiquidityPositionRequest({
            account: msg.sender,
            market: _market,
            marginDelta: _marginDelta,
            liquidityDelta: _liquidityDelta,
            acceptableMinMargin: _acceptableMinMargin,
            executionFee: _executionFee,
            blockNumber: block.number.toUint96(),
            blockTime: block.timestamp.toUint64(),
            receiver: _receiver
        });

        emit DecreaseLiquidityPositionCreated(
            msg.sender,
            _market,
            _marginDelta,
            _liquidityDelta,
            _acceptableMinMargin,
            _receiver,
            _executionFee,
            index
        );
    }

    function _createDecreasePosition(
        IMarketDescriptor _market,
        Side _side,
        uint128 _marginDelta,
        uint128 _sizeDelta,
        uint160 _acceptableTradePriceX96,
        address _receiver,
        uint256 _executionFee
    ) private returns (uint128 index) {
        index = decreasePositionIndexNext++;
        decreasePositionRequests[index] = DecreasePositionRequest({
            account: msg.sender,
            market: _market,
            side: _side,
            marginDelta: _marginDelta,
            sizeDelta: _sizeDelta,
            acceptableTradePriceX96: _acceptableTradePriceX96,
            executionFee: _executionFee,
            blockNumber: block.number.toUint96(),
            blockTime: block.timestamp.toUint64(),
            receiver: _receiver
        });

        emit DecreasePositionCreated(
            msg.sender,
            _market,
            _side,
            _marginDelta,
            _sizeDelta,
            _acceptableTradePriceX96,
            _receiver,
            _executionFee,
            index
        );
    }

    function _validateTradePriceX96(
        Side _side,
        uint160 _tradePriceX96,
        uint160 _acceptableTradePriceX96
    ) internal pure {
        // long makes price up, short makes price down
        if (
            (_side.isLong() && (_tradePriceX96 > _acceptableTradePriceX96)) ||
            (_side.isShort() && (_tradePriceX96 < _acceptableTradePriceX96))
        ) revert InvalidTradePrice(_tradePriceX96, _acceptableTradePriceX96);
    }

    function _validateMargin(uint128 margin, uint128 _acceptableMinMargin) internal pure {
        if (margin < _acceptableMinMargin) revert InvalidMargin(margin, _acceptableMinMargin);
    }

    function _decodeShortenedReason(bytes memory _reason) internal pure virtual returns (bytes4) {
        return bytes4(_reason);
    }

    function _transferOutETH(uint256 _amountOut, address payable _receiver) private {
        _receiver.sendValue(_amountOut);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.23;

import "./PluginManagerUpgradeable.sol";
import "../core/interfaces/IMarketManager.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract RouterUpgradeable is PluginManagerUpgradeable {
    using SafeERC20 for IERC20;

    /// @custom:storage-location erc7201:EquationDAO.storage.RouterUpgradeable
    struct RouterStorage {
        IMarketManager marketManager;
    }

    // keccak256(abi.encode(uint256(keccak256("EquationDAO.storage.RouterUpgradeable")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant ROUTER_UPGRADEABLE_STORAGE =
        0x38258f3e6818c21474db0903a5c2a7a1a4d0bce55a1869ca0718c5c0b39e3100;

    /// @notice Caller is not a plugin or not approved
    error CallerUnauthorized();
    /// @notice Owner mismatch
    error OwnerMismatch(address owner, address expectedOwner);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(IMarketManager _marketManager) public initializer {
        PluginManagerUpgradeable.__PluginManager_init();
        _routerStorage().marketManager = _marketManager;
    }

    /// @notice Transfers `_amount` of `_token` from `_from` to `_to`
    /// @param _token The address of the ERC20 token
    /// @param _from The address to transfer the tokens from
    /// @param _to The address to transfer the tokens to
    /// @param _amount The amount of tokens to transfer
    function pluginTransfer(IERC20 _token, address _from, address _to, uint256 _amount) external {
        _onlyPluginApproved(_from);
        SafeERC20.safeTransferFrom(_token, _from, _to, _amount);
    }

    /// @notice Transfers an NFT token from `_from` to `_to`
    /// @param _token The address of the ERC721 token to transfer
    /// @param _from The address to transfer the NFT from
    /// @param _to The address to transfer the NFT to
    /// @param _tokenId The ID of the NFT token to transfer
    function pluginTransferNFT(IERC721 _token, address _from, address _to, uint256 _tokenId) external {
        _onlyPluginApproved(_from);
        _token.safeTransferFrom(_from, _to, _tokenId);
    }

    /// @notice Settle the funding fee of the given market
    /// @param _market The market in which to settle funding fee
    function pluginSettleFundingFee(IMarketDescriptor _market) external {
        _onlyPlugin();
        _routerStorage().marketManager.settleFundingFee(_market);
    }

    /// @notice Increase a liquidity position
    /// @param _market The market in which to increase liquidity position
    /// @param _account The owner of the position
    /// @param _marginDelta The margin of the position
    /// @param _liquidityDelta The liquidity (value) of the position
    /// @param marginAfter The margin after increasing the position
    function pluginIncreaseLiquidityPosition(
        IMarketDescriptor _market,
        address _account,
        uint128 _marginDelta,
        uint128 _liquidityDelta
    ) external returns (uint128 marginAfter) {
        _onlyPluginApproved(_account);
        return
            _routerStorage().marketManager.increaseLiquidityPosition(_market, _account, _marginDelta, _liquidityDelta);
    }

    /// @notice Decrease a liquidity position
    /// @param _market The market in which to decrease liquidity position
    /// @param _account The owner of the liquidation position
    /// @param _marginDelta The increase in margin, which can be 0
    /// @param _liquidityDelta The decrease in liquidity, which can be 0
    /// @param _receiver The address to receive the margin at the time of closing
    /// @param marginAfter The margin after decreasing the position
    function pluginDecreaseLiquidityPosition(
        IMarketDescriptor _market,
        address _account,
        uint128 _marginDelta,
        uint128 _liquidityDelta,
        address _receiver
    ) external returns (uint128 marginAfter) {
        _onlyPluginApproved(_account);
        return
            _routerStorage().marketManager.decreaseLiquidityPosition(
                _market,
                _account,
                _marginDelta,
                _liquidityDelta,
                _receiver
            );
    }

    /// @notice Liquidate a liquidity position
    /// @param _market The market in which to liquidate liquidity position
    /// @param _account The owner of the liquidation position
    /// @param _feeReceiver The address to receive the fee
    function pluginLiquidateLiquidityPosition(
        IMarketDescriptor _market,
        address _account,
        address _feeReceiver
    ) external {
        _onlyLiquidator();
        _routerStorage().marketManager.liquidateLiquidityPosition(_market, _account, _feeReceiver);
    }

    /// @notice Increase a liquidation fund position
    /// @param _market The market in which to increase liquidation fund position
    /// @param _account The owner of the liquidation fund position
    /// @param _liquidityDelta The liquidity (value) of the liquidation fund position
    function pluginIncreaseLiquidationFundPosition(
        IMarketDescriptor _market,
        address _account,
        uint128 _liquidityDelta
    ) external {
        _onlyPluginApproved(_account);
        return _routerStorage().marketManager.increaseLiquidationFundPosition(_market, _account, _liquidityDelta);
    }

    /// @notice Decrease the liquidity (value) of a liquidation fund position
    /// @param _market The market in which to decrease liquidation fund position
    /// @param _account The owner of the liquidation fund position
    /// @param _liquidityDelta The decrease in liquidity
    /// @param _receiver The address to receive the liquidity
    function pluginDecreaseLiquidationFundPosition(
        IMarketDescriptor _market,
        address _account,
        uint128 _liquidityDelta,
        address _receiver
    ) external {
        _onlyPluginApproved(_account);
        return
            _routerStorage().marketManager.decreaseLiquidationFundPosition(
                _market,
                _account,
                _liquidityDelta,
                _receiver
            );
    }

    /// @notice Increase the margin/liquidity (value) of a position
    /// @param _market The market in which to increase position
    /// @param _account The owner of the position
    /// @param _side The side of the position (Long or Short)
    /// @param _marginDelta The increase in margin, which can be 0
    /// @param _sizeDelta The increase in size, which can be 0
    /// @return tradePriceX96 The trade price at which the position is adjusted.
    /// If only adding margin, it returns 0, as a Q64.96
    function pluginIncreasePosition(
        IMarketDescriptor _market,
        address _account,
        Side _side,
        uint128 _marginDelta,
        uint128 _sizeDelta
    ) external returns (uint160 tradePriceX96) {
        _onlyPluginApproved(_account);
        return _routerStorage().marketManager.increasePosition(_market, _account, _side, _marginDelta, _sizeDelta);
    }

    /// @notice Decrease the margin/liquidity (value) of a position
    /// @param _market The market in which to decrease position
    /// @param _account The owner of the position
    /// @param _side The side of the position (Long or Short)
    /// @param _marginDelta The decrease in margin, which can be 0
    /// @param _sizeDelta The decrease in size, which can be 0
    /// @param _receiver The address to receive the margin
    /// @return tradePriceX96 The trade price at which the position is adjusted.
    /// If only reducing margin, it returns 0, as a Q64.96
    function pluginDecreasePosition(
        IMarketDescriptor _market,
        address _account,
        Side _side,
        uint128 _marginDelta,
        uint128 _sizeDelta,
        address _receiver
    ) external returns (uint160 tradePriceX96) {
        _onlyPluginApproved(_account);
        return
            _routerStorage().marketManager.decreasePosition(
                _market,
                _account,
                _side,
                _marginDelta,
                _sizeDelta,
                _receiver
            );
    }

    /// @notice Liquidate a position
    /// @param _market The market in which to close position
    /// @param _account The owner of the position
    /// @param _side The side of the position (Long or Short)
    /// @param _feeReceiver The address to receive the fee
    function pluginLiquidatePosition(
        IMarketDescriptor _market,
        address _account,
        Side _side,
        address _feeReceiver
    ) external {
        _onlyLiquidator();
        _routerStorage().marketManager.liquidatePosition(_market, _account, _side, _feeReceiver);
    }

    /// @notice Close a position by the liquidator
    /// @param _market The market in which to close position
    /// @param _account The owner of the position
    /// @param _side The side of the position (Long or Short)
    /// @param _sizeDelta The decrease in size
    /// @param _receiver The address to receive the margin
    function pluginClosePositionByLiquidator(
        IMarketDescriptor _market,
        address _account,
        Side _side,
        uint128 _sizeDelta,
        address _receiver
    ) external {
        _onlyLiquidator();
        _routerStorage().marketManager.decreasePosition(_market, _account, _side, 0, _sizeDelta, _receiver);
    }

    function _onlyPlugin() internal view {
        if (!registeredPlugins(msg.sender)) revert CallerUnauthorized();
    }

    function _onlyPluginApproved(address _account) internal view {
        if (!isPluginApproved(_account, msg.sender)) revert CallerUnauthorized();
    }

    function _onlyLiquidator() internal view {
        if (!isRegisteredLiquidator(msg.sender)) revert CallerUnauthorized();
    }

    function _routerStorage() private pure returns (RouterStorage storage $) {
        // prettier-ignore
        assembly { $.slot := ROUTER_UPGRADEABLE_STORAGE }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

Side constant LONG = Side.wrap(1);
Side constant SHORT = Side.wrap(2);

type Side is uint8;

error InvalidSide(Side side);

using {requireValid, isLong, isShort, flip, eq as ==} for Side global;

function requireValid(Side self) pure {
    if (!isLong(self) && !isShort(self)) revert InvalidSide(self);
}

function isLong(Side self) pure returns (bool) {
    return Side.unwrap(self) == Side.unwrap(LONG);
}

function isShort(Side self) pure returns (bool) {
    return Side.unwrap(self) == Side.unwrap(SHORT);
}

function eq(Side self, Side other) pure returns (bool) {
    return Side.unwrap(self) == Side.unwrap(other);
}

function flip(Side self) pure returns (Side) {
    return isLong(self) ? SHORT : LONG;
}