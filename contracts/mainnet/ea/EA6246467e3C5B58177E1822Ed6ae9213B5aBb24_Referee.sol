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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.20;

import {EnumerableSet} from "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code repetition as possible, we write it in
    // terms of a generic Map type with bytes32 keys and values. The Map implementation uses private functions,
    // and user-facing implementations such as `UintToAddressMap` are just wrappers around the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit in bytes32.

    /**
     * @dev Query for a nonexistent map key.
     */
    error EnumerableMapNonexistentKey(bytes32 key);

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 key => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(Bytes32ToBytes32Map storage map, bytes32 key, bytes32 value) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        if (value == 0 && !contains(map, key)) {
            revert EnumerableMapNonexistentKey(key);
        }
        return value;
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(Bytes32ToBytes32Map storage map) internal view returns (bytes32[] memory) {
        return map._keys.values();
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToUintMap storage map, uint256 key, uint256 value) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(UintToUintMap storage map) internal view returns (uint256[] memory) {
        bytes32[] memory store = keys(map._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(UintToAddressMap storage map) internal view returns (uint256[] memory) {
        bytes32[] memory store = keys(map._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(AddressToUintMap storage map, address key, uint256 value) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(AddressToUintMap storage map) internal view returns (address[] memory) {
        bytes32[] memory store = keys(map._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(Bytes32ToUintMap storage map, bytes32 key, uint256 value) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(Bytes32ToUintMap storage map) internal view returns (bytes32[] memory) {
        bytes32[] memory store = keys(map._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {
    EnumerableMap
} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {RewardPayout} from "./RewardPayout.sol";
import {Proxied} from "./vendor/proxy/Proxied.sol";
import {IDelegateRegistry} from "./interfaces/IDelegateRegistry.sol";
import {INodeKey} from "./interfaces/INodeKey.sol";

contract Referee is RewardPayout, Initializable, Proxied {
    using EnumerableMap for EnumerableMap.Bytes32ToBytes32Map;

    struct BatchInfo {
        uint256 l1NodeConfirmedTimestamp;
        bytes32 finalL2StateRoot;
    }

    event LogSetRewardPerSecond(uint256 _rewardPerSecond);
    event LogSetOracle(address _oracle);

    error AlreadyAttested();
    error AlreadyFinalized();
    error InvalidBatchNumber();
    error NotNodeKeyOperator();
    error OnlyOracle();

    uint256 public immutable ATTEST_PERIOD;
    IDelegateRegistry public immutable DELEGATE_REGISTRY;
    INodeKey public immutable NODE_KEY;

    uint256 public currentBatchNumber;
    uint256 public rewardPerSecond;
    address public oracle;

    // batchNumber => nodeKeyId(bytes32) => l2StateRoot
    mapping(uint256 => EnumerableMap.Bytes32ToBytes32Map)
        internal _attestations;
    // batchNumber => timestamp
    mapping(uint256 => BatchInfo) public batchInfo;
    // nodeKeyId => reward
    mapping(uint256 => uint256) public rewardOfNodeKey;

    modifier onlyOracle() {
        if (msg.sender != oracle) {
            revert OnlyOracle();
        }
        _;
    }

    constructor(
        uint256 _attestPeriod,
        IDelegateRegistry _delegateRegistry,
        INodeKey _nodeKey,
        address _rewardToken
    ) RewardPayout(_rewardToken) {
        ATTEST_PERIOD = _attestPeriod;
        DELEGATE_REGISTRY = _delegateRegistry;
        NODE_KEY = _nodeKey;
    }

    function initialize(
        uint256 _currentBatchNumber,
        uint256 _rewardPerSecond,
        address _oracle
    ) external initializer {
        currentBatchNumber = _currentBatchNumber;
        rewardPerSecond = _rewardPerSecond;
        oracle = _oracle;
    }

    function setRewardPerSecond(
        uint256 _rewardPerSecond
    ) external onlyProxyAdmin {
        rewardPerSecond = _rewardPerSecond;

        emit LogSetRewardPerSecond(_rewardPerSecond);
    }

    function setOracle(address _oracle) external onlyProxyAdmin {
        oracle = _oracle;

        emit LogSetOracle(_oracle);
    }

    function setCurrentBatchNumber(
        uint256 _currentBatchNumber
    ) external onlyProxyAdmin {
        currentBatchNumber = _currentBatchNumber;
    }

    function _isNodeKeyOperator(
        uint256 _nodeKeyId
    ) internal view returns (bool) {
        address ownerOfNodeKey = NODE_KEY.ownerOf(_nodeKeyId);

        return
            msg.sender == ownerOfNodeKey ||
            DELEGATE_REGISTRY.checkDelegateForERC721(
                msg.sender,
                ownerOfNodeKey,
                address(NODE_KEY),
                _nodeKeyId,
                ""
            );
    }

    function attest(
        uint256 _batchNumber,
        bytes32 _l2StateRoot,
        uint256 _nodeKeyId
    ) external {
        _attest(_batchNumber, _l2StateRoot, _nodeKeyId);
    }

    function batchAttest(
        uint256 _batchNumber,
        bytes32 _l2StateRoot,
        uint256[] memory _nodeKeyIds
    ) external {
        for (uint256 i; i < _nodeKeyIds.length; i++) {
            _attest(_batchNumber, _l2StateRoot, _nodeKeyIds[i]);
        }
    }

    // Todo: limit nr of attestors for each batch
    function _attest(
        uint256 _batchNumber,
        bytes32 _l2StateRoot,
        uint256 _nodeKeyId
    ) internal {
        bytes32 nodeKeyIdBytes = bytes32(_nodeKeyId);

        if (!_isNodeKeyOperator(_nodeKeyId)) {
            revert NotNodeKeyOperator();
        }
        if (_batchNumber < currentBatchNumber) {
            revert InvalidBatchNumber();
        }
        if (_attestations[_batchNumber].contains(nodeKeyIdBytes)) {
            revert AlreadyAttested();
        }

        _attestations[_batchNumber].set(nodeKeyIdBytes, _l2StateRoot);
    }

    /**
     * Scenario 1: Oracle downtime
     * Attestations are waiting to be finalized,
     * Rewards = Math.min(block.timestamp - l1NodeConfirmed, MAX_REWARD_TIME_PERIOD)
     *
     * Scenario 2: Oracle finalizing early
     *
     */

    function finalize(
        uint256 _batchNumber,
        uint256 _l1NodeConfirmedTimestamp,
        bytes32 _finalL2StateRoot
    ) external onlyOracle {
        if (_batchNumber == 0 || _batchNumber != currentBatchNumber) {
            revert InvalidBatchNumber();
        }

        EnumerableMap.Bytes32ToBytes32Map storage map = _attestations[
            _batchNumber
        ];
        uint256 length = map.length();

        uint256 nrOfSuccessfulNodeKeys;

        for (uint256 i; i < length; i++) {
            (, bytes32 l2StateRoot) = map.at(i);

            if (l2StateRoot == _finalL2StateRoot) {
                nrOfSuccessfulNodeKeys += 1;
            }
        }

        if (nrOfSuccessfulNodeKeys > 0) {
            uint256 rewardTimeWindow = Math.min(
                block.timestamp - _l1NodeConfirmedTimestamp,
                ATTEST_PERIOD
            );

            uint256 rewardPerNodeKey = (rewardTimeWindow * rewardPerSecond) /
                nrOfSuccessfulNodeKeys;

            for (uint256 x; x < length; x++) {
                (bytes32 nodeKeyIdBytes, bytes32 l2StateRoot) = map.at(x);

                if (l2StateRoot == _finalL2StateRoot) {
                    rewardOfNodeKey[
                        uint256(nodeKeyIdBytes)
                    ] += rewardPerNodeKey;
                }
            }
        }

        batchInfo[_batchNumber] = BatchInfo({
            l1NodeConfirmedTimestamp: _l1NodeConfirmedTimestamp,
            finalL2StateRoot: _finalL2StateRoot
        });
        currentBatchNumber += 1;
    }

    function claimReward(uint256 _nodeKeyId) external {
        _claimReward(_nodeKeyId);
    }

    function batchClaimReward(uint256[] memory _nodeKeyIds) external {
        for (uint256 i; i < _nodeKeyIds.length; i++) {
            _claimReward(_nodeKeyIds[i]);
        }
    }

    function _claimReward(uint256 _nodeKeyId) internal {
        address nodeKeyOwner = NODE_KEY.ownerOf(_nodeKeyId);

        uint256 reward = rewardOfNodeKey[_nodeKeyId];
        rewardOfNodeKey[_nodeKeyId] = 0;
        _payReward(nodeKeyOwner, reward);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {
    SafeERC20,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract RewardPayout {
    error ETHTransferFailed();

    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable REWARD_TOKEN;

    constructor(address _rewardToken) {
        REWARD_TOKEN = _rewardToken;
    }

    function _payReward(address _to, uint256 _amount) internal {
        if (REWARD_TOKEN == ETH) {
            (bool success, ) = _to.call{value: _amount}("");
            if (!success) {
                revert ETHTransferFailed();
            }
        } else {
            SafeERC20.safeTransfer(IERC20(REWARD_TOKEN), _to, _amount);
        }
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.13;

/**
 * @title IDelegateRegistry
 * @custom:version 2.0
 * @custom:author foobar (0xfoobar)
 * @notice A standalone immutable registry storing delegated permissions from one address to another
 */
interface IDelegateRegistry {
    /// @notice Delegation type, NONE is used when a delegation does not exist or is revoked
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        ERC721,
        ERC20,
        ERC1155
    }

    /// @notice Struct for returning delegations
    struct Delegation {
        DelegationType type_;
        address to;
        address from;
        bytes32 rights;
        address contract_;
        uint256 tokenId;
        uint256 amount;
    }

    /// @notice Emitted when an address delegates or revokes rights for their entire wallet
    event DelegateAll(
        address indexed from,
        address indexed to,
        bytes32 rights,
        bool enable
    );

    /// @notice Emitted when an address delegates or revokes rights for a contract address
    event DelegateContract(
        address indexed from,
        address indexed to,
        address indexed contract_,
        bytes32 rights,
        bool enable
    );

    /// @notice Emitted when an address delegates or revokes rights for an ERC721 tokenId
    event DelegateERC721(
        address indexed from,
        address indexed to,
        address indexed contract_,
        uint256 tokenId,
        bytes32 rights,
        bool enable
    );

    /// @notice Emitted when an address delegates or revokes rights for an amount of ERC20 tokens
    event DelegateERC20(
        address indexed from,
        address indexed to,
        address indexed contract_,
        bytes32 rights,
        uint256 amount
    );

    /// @notice Emitted when an address delegates or revokes rights for an amount of an ERC1155 tokenId
    event DelegateERC1155(
        address indexed from,
        address indexed to,
        address indexed contract_,
        uint256 tokenId,
        bytes32 rights,
        uint256 amount
    );

    /// @notice Thrown if multicall calldata is malformed
    error MulticallFailed();

    /**
     * -----------  WRITE -----------
     */

    /**
     * @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
     * @param data The encoded function data for each of the calls to make to this contract
     * @return results The results from each of the calls passed in via data
     */
    function multicall(
        bytes[] calldata data
    ) external payable returns (bytes[] memory results);

    /**
     * @notice Allow the delegate to act on behalf of `msg.sender` for all contracts
     * @param to The address to act as delegate
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param enable Whether to enable or disable this delegation, true delegates and false revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateAll(
        address to,
        bytes32 rights,
        bool enable
    ) external payable returns (bytes32 delegationHash);

    /**
     * @notice Allow the delegate to act on behalf of `msg.sender` for a specific contract
     * @param to The address to act as delegate
     * @param contract_ The contract whose rights are being delegated
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param enable Whether to enable or disable this delegation, true delegates and false revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateContract(
        address to,
        address contract_,
        bytes32 rights,
        bool enable
    ) external payable returns (bytes32 delegationHash);

    /**
     * @notice Allow the delegate to act on behalf of `msg.sender` for a specific ERC721 token
     * @param to The address to act as delegate
     * @param contract_ The contract whose rights are being delegated
     * @param tokenId The token id to delegate
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param enable Whether to enable or disable this delegation, true delegates and false revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateERC721(
        address to,
        address contract_,
        uint256 tokenId,
        bytes32 rights,
        bool enable
    ) external payable returns (bytes32 delegationHash);

    /**
     * @notice Allow the delegate to act on behalf of `msg.sender` for a specific amount of ERC20 tokens
     * @dev The actual amount is not encoded in the hash, just the existence of a amount (since it is an upper bound)
     * @param to The address to act as delegate
     * @param contract_ The address for the fungible token contract
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param amount The amount to delegate, > 0 delegates and 0 revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateERC20(
        address to,
        address contract_,
        bytes32 rights,
        uint256 amount
    ) external payable returns (bytes32 delegationHash);

    /**
     * @notice Allow the delegate to act on behalf of `msg.sender` for a specific amount of ERC1155 tokens
     * @dev The actual amount is not encoded in the hash, just the existence of a amount (since it is an upper bound)
     * @param to The address to act as delegate
     * @param contract_ The address of the contract that holds the token
     * @param tokenId The token id to delegate
     * @param rights Specific subdelegation rights granted to the delegate, pass an empty bytestring to encompass all rights
     * @param amount The amount of that token id to delegate, > 0 delegates and 0 revokes
     * @return delegationHash The unique identifier of the delegation
     */
    function delegateERC1155(
        address to,
        address contract_,
        uint256 tokenId,
        bytes32 rights,
        uint256 amount
    ) external payable returns (bytes32 delegationHash);

    /**
     * ----------- CHECKS -----------
     */

    /**
     * @notice Check if `to` is a delegate of `from` for the entire wallet
     * @param to The potential delegate address
     * @param from The potential address who delegated rights
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return valid Whether delegate is granted to act on the from's behalf
     */
    function checkDelegateForAll(
        address to,
        address from,
        bytes32 rights
    ) external view returns (bool);

    /**
     * @notice Check if `to` is a delegate of `from` for the specified `contract_` or the entire wallet
     * @param to The delegated address to check
     * @param contract_ The specific contract address being checked
     * @param from The cold wallet who issued the delegation
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return valid Whether delegate is granted to act on from's behalf for entire wallet or that specific contract
     */
    function checkDelegateForContract(
        address to,
        address from,
        address contract_,
        bytes32 rights
    ) external view returns (bool);

    /**
     * @notice Check if `to` is a delegate of `from` for the specific `contract` and `tokenId`, the entire `contract_`, or the entire wallet
     * @param to The delegated address to check
     * @param contract_ The specific contract address being checked
     * @param tokenId The token id for the token to delegating
     * @param from The wallet that issued the delegation
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return valid Whether delegate is granted to act on from's behalf for entire wallet, that contract, or that specific tokenId
     */
    function checkDelegateForERC721(
        address to,
        address from,
        address contract_,
        uint256 tokenId,
        bytes32 rights
    ) external view returns (bool);

    /**
     * @notice Returns the amount of ERC20 tokens the delegate is granted rights to act on the behalf of
     * @param to The delegated address to check
     * @param contract_ The address of the token contract
     * @param from The cold wallet who issued the delegation
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return balance The delegated balance, which will be 0 if the delegation does not exist
     */
    function checkDelegateForERC20(
        address to,
        address from,
        address contract_,
        bytes32 rights
    ) external view returns (uint256);

    /**
     * @notice Returns the amount of a ERC1155 tokens the delegate is granted rights to act on the behalf of
     * @param to The delegated address to check
     * @param contract_ The address of the token contract
     * @param tokenId The token id to check the delegated amount of
     * @param from The cold wallet who issued the delegation
     * @param rights Specific rights to check for, pass the zero value to ignore subdelegations and check full delegations only
     * @return balance The delegated balance, which will be 0 if the delegation does not exist
     */
    function checkDelegateForERC1155(
        address to,
        address from,
        address contract_,
        uint256 tokenId,
        bytes32 rights
    ) external view returns (uint256);

    /**
     * ----------- ENUMERATIONS -----------
     */

    /**
     * @notice Returns all enabled delegations a given delegate has received
     * @param to The address to retrieve delegations for
     * @return delegations Array of Delegation structs
     */
    function getIncomingDelegations(
        address to
    ) external view returns (Delegation[] memory delegations);

    /**
     * @notice Returns all enabled delegations an address has given out
     * @param from The address to retrieve delegations for
     * @return delegations Array of Delegation structs
     */
    function getOutgoingDelegations(
        address from
    ) external view returns (Delegation[] memory delegations);

    /**
     * @notice Returns all hashes associated with enabled delegations an address has received
     * @param to The address to retrieve incoming delegation hashes for
     * @return delegationHashes Array of delegation hashes
     */
    function getIncomingDelegationHashes(
        address to
    ) external view returns (bytes32[] memory delegationHashes);

    /**
     * @notice Returns all hashes associated with enabled delegations an address has given out
     * @param from The address to retrieve outgoing delegation hashes for
     * @return delegationHashes Array of delegation hashes
     */
    function getOutgoingDelegationHashes(
        address from
    ) external view returns (bytes32[] memory delegationHashes);

    /**
     * @notice Returns the delegations for a given array of delegation hashes
     * @param delegationHashes is an array of hashes that correspond to delegations
     * @return delegations Array of Delegation structs, return empty structs for nonexistent or revoked delegations
     */
    function getDelegationsFromHashes(
        bytes32[] calldata delegationHashes
    ) external view returns (Delegation[] memory delegations);

    /**
     * ----------- STORAGE ACCESS -----------
     */

    /**
     * @notice Allows external contracts to read arbitrary storage slots
     */
    function readSlot(bytes32 location) external view returns (bytes32);

    /**
     * @notice Allows external contracts to read an arbitrary array of storage slots
     */
    function readSlots(
        bytes32[] calldata locations
    ) external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INodeKey is IERC721 {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address ownerAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            ownerAddress := sload(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)
        }
    }
}