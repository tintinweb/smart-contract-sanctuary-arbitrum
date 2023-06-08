// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused)
        external
        pure
        returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );

    error InvalidBlockNumber(uint256 requested, uint256 current);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
        if (_initialized < type(uint8).max) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

abstract contract Adminable {
    event AdminUpdated(address indexed user, address indexed newAdmin);

    address public admin;

    modifier onlyAdmin() virtual {
        require(msg.sender == admin, "UNAUTHORIZED");

        _;
    }

    function setAdmin(address newAdmin) public virtual onlyAdmin {
        _setAdmin(newAdmin);
    }

    function _setAdmin(address newAdmin) internal {
        require(newAdmin != address(0), "Can not set admin to zero address");
        admin = newAdmin;

        emit AdminUpdated(msg.sender, newAdmin);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

library DuetMath {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
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
            uint256 prod0;
            // Least significant 256 bits of the product
            uint256 prod1;
            // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                require(denominator > 0);
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
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = denominator**3;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse;
            // inverse mod 2^8
            inverse *= 2 - denominator * inverse;
            // inverse mod 2^16
            inverse *= 2 - denominator * inverse;
            // inverse mod 2^32
            inverse *= 2 - denominator * inverse;
            // inverse mod 2^64
            inverse *= 2 - denominator * inverse;
            // inverse mod 2^128
            inverse *= 2 - denominator * inverse;
            // inverse mod 2^256

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
        Rounding direction
    ) public pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (direction == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IPool } from "./interfaces/IPool.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20MetadataUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { IDeriLens } from "./interfaces/IDeriLens.sol";
import { Adminable } from "@private/shared/libs/Adminable.sol";
import { DuetMath } from "@private/shared/libs/DuetMath.sol";

import { IBoosterOracle } from "./interfaces/IBoosterOracle.sol";
import { ArbSys } from "@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";
import { IVault } from "./interfaces/IVault.sol";

contract DuetProStaking is ReentrancyGuardUpgradeable, Adminable {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    uint256 public constant PRECISION = 1e12;
    uint256 public constant LIQUIDITY_DECIMALS = 18;
    uint256 public constant PRICE_DECIMALS = 8;
    uint256 public constant MIN_BOOSTER_TOKENS = 10 ** 18;
    uint256 public constant MIN_LIQUIDITY_OPS = 10 ** 18;

    IPool public pool;
    IDeriLens public deriLens;
    IBoosterOracle public boosterOracle;
    IERC20MetadataUpgradeable public usdLikeUnderlying;
    uint256 public totalShares;
    uint256 public totalBoostedShares;
    uint256 public lastNormalLiquidity;
    uint256 public lastBoostedLiquidity;
    uint256 public totalStakedBoosterValue;
    uint256 public totalStakedBoosterAmount;

    uint256 public lastActionTime;
    uint256 public lastActionBlock;

    // user => token => amount
    mapping(address => mapping(address => uint256)) public userStakedBooster;

    // token => isSupported
    mapping(address => bool) public supportedBoosterTokens;

    // user => UserInfo
    mapping(address => UserInfo) public userInfos;

    struct UserInfo {
        uint256 shares;
        uint256 boostedShares;
        uint256 stakedBoosterValue;
        uint256 stakedBoosterAmount;
        uint256 lastActionTime;
        uint256 lastActionBlock;
        uint256 accAddedLiquidity;
        uint256 accRemovedLiquidity;
    }

    event AddSupportedBoosterToken(address indexed user, address token);
    event RemoveSupportedBoosterToken(address indexed user, address token);

    constructor() {
        // 30097 is the chain id of hardhat in hardhat.config.ts
        if (block.chainid != 30097) {
            _disableInitializers();
        }
    }

    function initialize(
        IPool pool_,
        IDeriLens deriLens_,
        IERC20MetadataUpgradeable usdLikeUnderlying_,
        IBoosterOracle boosterOracle_,
        address admin_
    ) external initializer {
        require(address(pool_) != address(0), "DuetProStaking: pool cannot be zero address");
        require(address(deriLens_) != address(0), "DuetProStaking: deriLens cannot be zero address");
        require(address(usdLikeUnderlying_) != address(0), "DuetProStaking: usdLikeUnderlying_ cannot be zero address");
        require(address(boosterOracle_) != address(0), "DuetProStaking: boosterOracle cannot be zero address");
        require(admin_ != address(0), "DuetProStaking: admin cannot be zero address");
        require(
            usdLikeUnderlying_.decimals() <= 18,
            "DuetProStaking: usdLikeUnderlying_ decimals must be less than 18"
        );

        boosterOracle = boosterOracle_;
        __ReentrancyGuard_init();
        pool = pool_;
        usdLikeUnderlying = usdLikeUnderlying_;
        deriLens = deriLens_;
        _setAdmin(admin_);
    }

    function setBoosterOracle(IBoosterOracle boosterOracle_) external onlyAdmin {
        boosterOracle = boosterOracle_;
    }

    function addSupportedBooster(IERC20MetadataUpgradeable booster_) external onlyAdmin {
        supportedBoosterTokens[address(booster_)] = true;
        emit AddSupportedBoosterToken(msg.sender, address(booster_));
    }

    function removeSupportedBooster(IERC20MetadataUpgradeable booster_) external onlyAdmin {
        delete supportedBoosterTokens[address(booster_)];
        emit RemoveSupportedBoosterToken(msg.sender, address(booster_));
    }

    function stakeBooster(IERC20MetadataUpgradeable booster_, uint256 amount_) external nonReentrant {
        require(supportedBoosterTokens[address(booster_)], "DuetProStaking: unsupported booster");

        uint256 normalizedAmount = normalizeDecimals(amount_, booster_.decimals(), LIQUIDITY_DECIMALS);
        require(
            normalizedAmount >= MIN_BOOSTER_TOKENS,
            "DuetProStaking: amount must be greater than MIN_BOOSTER_TOKENS"
        );
        address user = msg.sender;
        UserInfo storage userInfo = userInfos[user];
        _updatePool();

        booster_.safeTransferFrom(user, address(this), amount_);
        userStakedBooster[user][address(booster_)] += normalizedAmount;
        userInfo.stakedBoosterAmount += normalizedAmount;
        totalStakedBoosterAmount += normalizedAmount;

        uint256 boosterValue = _getBoosterValue(booster_, normalizedAmount);
        userInfo.stakedBoosterValue += boosterValue;
        totalStakedBoosterValue += boosterValue;

        _touchUser(user);
        _updateUserBoostedShares(user);
    }

    function unstakeBooster(IERC20MetadataUpgradeable booster_, uint256 amount_) external nonReentrant {
        address user = msg.sender;
        require(userStakedBooster[user][address(booster_)] >= amount_, "DuetProStaking: insufficient staked booster");
        UserInfo storage userInfo = userInfos[user];
        _updatePool();

        userStakedBooster[user][address(booster_)] -= amount_;
        userInfo.stakedBoosterAmount -= amount_;
        totalStakedBoosterAmount -= amount_;

        uint256 boosterValue = _getBoosterValue(booster_, amount_);
        if (userInfo.stakedBoosterValue <= boosterValue) {
            userInfo.stakedBoosterValue = 0;
        } else {
            userInfo.stakedBoosterValue -= boosterValue;
        }
        if (totalStakedBoosterValue <= boosterValue) {
            totalStakedBoosterValue = 0;
        } else {
            totalStakedBoosterValue -= boosterValue;
        }

        booster_.safeTransfer(user, amount_);
        _touchUser(user);
        _updateUserBoostedShares(user);
    }

    function addLiquidity(uint256 underlyingAmount_, IPool.PythData calldata pythData) external payable nonReentrant {
        uint256 amount = normalizeDecimals(underlyingAmount_, usdLikeUnderlying.decimals(), LIQUIDITY_DECIMALS);
        require(amount >= MIN_LIQUIDITY_OPS, "DuetProStaking: amount must be greater than MIN_LIQUIDITY_OPS");
        _updatePool();
        address user = msg.sender;
        usdLikeUnderlying.safeTransferFrom(user, address(this), underlyingAmount_);
        usdLikeUnderlying.approve(address(pool), underlyingAmount_);
        pool.addLiquidity{ value: msg.value }(address(usdLikeUnderlying), underlyingAmount_, pythData);
        UserInfo storage userInfo = userInfos[user];
        uint256 totalNormalShares = totalShares - totalBoostedShares;

        uint256 addNormalShares = totalNormalShares > 0
            ? DuetMath.mulDiv(totalNormalShares, amount, lastNormalLiquidity)
            : amount;
        // Add to normal liquidity first, calc boosted shares post liquidity added, see _updateUserBoostedShares
        lastNormalLiquidity += amount;
        totalShares += addNormalShares;
        userInfo.shares += addNormalShares;
        _touchUser(user);
        userInfo.accAddedLiquidity += amount;
        _updateUserBoostedShares(user);
    }

    function removeLiquidity(
        uint256 amount_,
        IPool.PythData calldata pythData
    )
        external
        payable
        nonReentrant
        returns (
            uint256 userNormalLiquidity,
            uint256 userBoostedLiquidity,
            uint256 normalSharesToRemove,
            uint256 userNormalShares,
            uint256 normalLiquidityToRemove
        )
    {
        uint256 amount = normalizeDecimals(amount_, usdLikeUnderlying.decimals(), LIQUIDITY_DECIMALS);
        _updatePool();
        address user = msg.sender;
        UserInfo storage userInfo = userInfos[user];
        (userNormalLiquidity, userBoostedLiquidity) = sharesToLiquidity(userInfo.shares, userInfo.boostedShares);
        uint256 userTotalLiquidity = userNormalLiquidity + userBoostedLiquidity;
        if (amount >= userTotalLiquidity || userTotalLiquidity <= MIN_LIQUIDITY_OPS) {
            amount = userTotalLiquidity;
        }
        userNormalShares = userInfo.shares - userInfo.boostedShares;
        uint256 boostedSharesToRemove;
        uint256 boostedLiquidityToRemove;
        if (amount <= userNormalLiquidity) {
            normalSharesToRemove = DuetMath.mulDiv(userNormalShares, amount, userNormalLiquidity);
            normalLiquidityToRemove = amount;
        } else {
            normalSharesToRemove = userNormalShares;
            normalLiquidityToRemove = userNormalLiquidity;
            boostedLiquidityToRemove = amount - userNormalLiquidity;

            boostedSharesToRemove = DuetMath.mulDiv(
                userInfo.boostedShares,
                boostedLiquidityToRemove,
                userBoostedLiquidity
            );
        }
        userInfo.shares -= (normalSharesToRemove + boostedSharesToRemove);
        totalShares -= (normalSharesToRemove + boostedSharesToRemove);
        lastNormalLiquidity -= normalLiquidityToRemove;

        userInfo.boostedShares -= boostedSharesToRemove;
        totalBoostedShares -= boostedSharesToRemove;
        lastBoostedLiquidity -= boostedLiquidityToRemove;

        _touchUser(user);
        userInfo.accRemovedLiquidity += amount;
        uint256 usdLikeAmount = normalizeDecimals(amount, LIQUIDITY_DECIMALS, usdLikeUnderlying.decimals());
        pool.removeLiquidity{ value: msg.value }(address(usdLikeUnderlying), usdLikeAmount, pythData);
        usdLikeUnderlying.safeTransfer(user, usdLikeAmount);
    }

    function sharesToLiquidity(
        uint256 shares_,
        uint256 boostedShares_
    ) public view returns (uint256 normalLiquidity, uint256 boostedLiquidity) {
        (uint256 totalNormalLiquidity, uint256 totalBoostedLiquidity) = calcPool();
        uint256 normalShares = shares_ - boostedShares_;
        uint256 totalNormalShares = totalShares - totalBoostedShares;

        return (
            normalShares > 0 ? DuetMath.mulDiv(totalNormalLiquidity, normalShares, totalNormalShares) : 0,
            boostedShares_ > 0 ? DuetMath.mulDiv(totalBoostedLiquidity, boostedShares_, totalBoostedShares) : 0
        );
    }

    function amountToShares(uint256 amount_) external view returns (uint256) {
        (uint256 normalLiquidity, uint256 boostedLiquidity) = calcPool();
        return totalShares > 0 ? (amount_ * totalShares) / (normalLiquidity + boostedLiquidity) : amount_;
    }

    function getUserInfo(
        address user_
    ) external view returns (UserInfo memory info, uint256 normalLiquidity, uint256 boostedLiquidity) {
        (normalLiquidity, boostedLiquidity) = sharesToLiquidity(
            userInfos[user_].shares,
            userInfos[user_].boostedShares
        );
        return (userInfos[user_], normalLiquidity, boostedLiquidity);
    }

    function calcPool() public view returns (uint256 normalLiquidity, uint256 boostedLiquidity) {
        if (lastActionBlock == blockNumber()) {
            return (lastNormalLiquidity, lastBoostedLiquidity);
        }
        if (totalShares == 0) {
            return (0, 0);
        }
        IDeriLens.LpInfo memory lpInfo = getRemoteInfo();

        int256 intBalanceB0 = lpInfo.amountB0;
        if (lpInfo.vaultLiquidity > 0 && lpInfo.markets.length > 0) {
            require(
                lpInfo.markets[0].underlying == address(usdLikeUnderlying),
                "DuetProStaking: calc pool error, market underlying mismatch"
            );
            intBalanceB0 += int256(lpInfo.markets[0].vTokenBalance);
        }
        require(intBalanceB0 > 0, "DuetProStaking: calc pool error, negative balanceB0");
        uint256 balanceB0 = uint256(intBalanceB0);

        if (balanceB0 == 0) {
            return (0, 0);
        }
        int256 liquidityDelta = int256(balanceB0) - int256(lastNormalLiquidity + lastBoostedLiquidity);

        if (liquidityDelta == 0) {
            return (lastNormalLiquidity, lastBoostedLiquidity);
        }

        uint256 uintLiquidityDelta = uint256(liquidityDelta > 0 ? liquidityDelta : 0 - liquidityDelta);
        if (liquidityDelta < 0) {
            // no boost when pnl is negative
            uint256 boostedPnl = DuetMath.mulDiv(
                uintLiquidityDelta,
                lastBoostedLiquidity,
                lastNormalLiquidity + lastBoostedLiquidity
            );
            uint256 normalPnl = uintLiquidityDelta - boostedPnl;
            // To simplify subsequent calculations, negative numbers are not allowed in liquidity.
            // As an extreme case, when it occurs, the development team intervenes to handle it.
            // @see forceAddLiquidity
            require(lastNormalLiquidity >= normalPnl, "DuetProStaking: calc pool error, negative normal pnl");
            require(lastBoostedLiquidity >= boostedPnl, "DuetProStaking: calc pool error, negative boosted pnl");
            return (lastNormalLiquidity - normalPnl, lastBoostedLiquidity - boostedPnl);
        }

        uint256 boostedPnl = DuetMath.mulDiv(
            uintLiquidityDelta,
            // boostedShares can boost 2x
            lastBoostedLiquidity * 2,
            lastBoostedLiquidity * 2 + lastNormalLiquidity
        );
        uint256 normalPnl = uintLiquidityDelta - boostedPnl;
        return (lastNormalLiquidity + normalPnl, lastBoostedLiquidity + boostedPnl);
    }

    function _updatePool() internal {
        (lastNormalLiquidity, lastBoostedLiquidity) = calcPool();
        lastActionTime = block.timestamp;
        lastActionBlock = blockNumber();
    }

    function getRemoteInfo() public view returns (IDeriLens.LpInfo memory lpInfo) {
        return deriLens.getLpInfo(address(pool), address(this));
    }

    function _boosterValue(IERC20MetadataUpgradeable booster_, uint256 amount_) internal view returns (uint256) {
        uint256 boosterPrice = boosterOracle.getPrice(address(booster_));
        uint256 boosterDecimals = booster_.decimals();
        require(boosterPrice > 0, "DuetProStaking: booster price is zero");
        return uint256(normalizeDecimals(boosterPrice * amount_, boosterDecimals, LIQUIDITY_DECIMALS));
    }

    function forceAddLiquidity(uint256 amount_, IPool.PythData calldata pythData) external payable {
        usdLikeUnderlying.safeTransferFrom(msg.sender, address(this), amount_);
        usdLikeUnderlying.approve(address(pool), amount_);
        pool.addLiquidity{ value: msg.value }(address(usdLikeUnderlying), amount_, pythData);
    }

    function normalizeDecimals(
        uint256 value_,
        uint256 sourceDecimals_,
        uint256 targetDecimals_
    ) public pure returns (uint256) {
        if (targetDecimals_ == sourceDecimals_) {
            return value_;
        }
        if (targetDecimals_ > sourceDecimals_) {
            return value_ * 10 ** (targetDecimals_ - sourceDecimals_);
        }
        return value_ / 10 ** (sourceDecimals_ - targetDecimals_);
    }

    /**
     * @dev Returns the amount of shares that the user has in the pool.
     * @param booster_ The address of the booster token.
     * @param normalizedAmount_ Amount with liquidity decimals.
     */
    function _getBoosterValue(
        IERC20MetadataUpgradeable booster_,
        uint256 normalizedAmount_
    ) internal view returns (uint256 boosterValue) {
        uint256 boosterPrice = boosterOracle.getPrice(address(booster_));
        return
            normalizeDecimals(
                (boosterPrice * normalizedAmount_) / (10 ** LIQUIDITY_DECIMALS),
                PRICE_DECIMALS,
                LIQUIDITY_DECIMALS
            );
    }

    function _touchUser(address user_) internal {
        userInfos[user_].lastActionBlock = blockNumber();
        userInfos[user_].lastActionTime = block.timestamp;
    }

    /**
     * @dev update user boosted share after user's booster stake or unstake and liquidity change to make sure
     *       the user's boosted share is correct.
     * @param user_ The address of the user.
     */
    function _updateUserBoostedShares(address user_) internal {
        UserInfo storage userInfo = userInfos[user_];
        require(lastActionBlock == blockNumber(), "DuetProStaking: update pool first");
        require(userInfo.lastActionBlock == blockNumber(), "DuetProStaking: update user shares first");
        if (userInfo.shares == 0) {
            userInfo.boostedShares = 0;
            return;
        }
        uint256 userNormalShares = userInfo.shares - userInfo.boostedShares;
        (uint256 userNormalLiquidity, uint256 userBoostedLiquidity) = sharesToLiquidity(
            userInfo.shares,
            userInfo.boostedShares
        );
        if (userBoostedLiquidity == userInfo.stakedBoosterValue) {
            return;
        }
        if (userBoostedLiquidity > userInfo.stakedBoosterValue) {
            uint256 exceededBoostedLiquidity = userBoostedLiquidity - userInfo.stakedBoosterValue;
            uint256 exceededBoostedShares = DuetMath.mulDiv(
                userInfo.boostedShares,
                exceededBoostedLiquidity,
                userBoostedLiquidity
            );
            uint256 exchangedNormalShares = DuetMath.mulDiv(
                totalShares - totalBoostedShares,
                exceededBoostedLiquidity,
                lastNormalLiquidity
            );

            userInfo.boostedShares -= exceededBoostedShares;
            totalBoostedShares -= exceededBoostedShares;

            userInfo.shares -= exceededBoostedShares;
            userInfo.shares += exchangedNormalShares;

            totalShares -= exceededBoostedShares;
            totalShares += exchangedNormalShares;

            lastBoostedLiquidity -= exceededBoostedLiquidity;
            lastNormalLiquidity += exceededBoostedLiquidity;

            return;
        }
        if (userNormalLiquidity == 0) {
            return;
        }

        uint256 missingBoostedLiquidity = userInfo.stakedBoosterValue - userBoostedLiquidity;
        missingBoostedLiquidity = missingBoostedLiquidity >= userNormalLiquidity
            ? userNormalLiquidity
            : missingBoostedLiquidity;

        uint256 missingBoostedShares = totalBoostedShares > 0
            ? DuetMath.mulDiv(totalBoostedShares, missingBoostedLiquidity, lastBoostedLiquidity)
            : missingBoostedLiquidity;
        if (missingBoostedShares == 0) {
            return;
        }

        uint256 exchangedNormalShares = userNormalShares > 0 && missingBoostedShares > 0
            ? DuetMath.mulDiv(userNormalShares, missingBoostedLiquidity, userNormalLiquidity)
            : 0;

        userInfo.boostedShares += missingBoostedShares;
        userInfo.shares -= exchangedNormalShares;
        userInfo.shares += missingBoostedShares;

        totalBoostedShares += missingBoostedShares;
        totalShares -= exchangedNormalShares;
        totalShares += missingBoostedShares;

        lastBoostedLiquidity += missingBoostedLiquidity;
        lastNormalLiquidity -= missingBoostedLiquidity;
    }

    function chainId() public view returns (uint256) {
        return block.chainid;
    }

    function blockNumber() public view returns (uint256) {
        // 42170 421611 421613
        if (
            // arbitrum one
            block.chainid == 42161 ||
            // arbitrum xDai
            block.chainid == 200 ||
            // arbitrum nova
            block.chainid == 42170 ||
            // arbitrum rinkeby
            block.chainid == 421611 ||
            // arbitrum Goerli
            block.chainid == 421613
        ) {
            return ArbSys(address(100)).arbBlockNumber();
        }
        return block.number;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBoosterOracle {
    // Must 8 dec, same as chainlink decimals.
    function getPrice(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IDeriLens {
    struct PriceAndVolatility {
        string symbol;
        int256 indexPrice;
        int256 volatility;
    }

    struct PoolInfo {
        address pool;
        address implementation;
        address protocolFeeCollector;
        address tokenB0;
        address tokenWETH;
        address vTokenB0;
        address vTokenETH;
        address lToken;
        address pToken;
        address oracleManager;
        address swapper;
        address symbolManager;
        uint256 reserveRatioB0;
        int256 minRatioB0;
        int256 poolInitialMarginMultiplier;
        int256 protocolFeeCollectRatio;
        int256 minLiquidationReward;
        int256 maxLiquidationReward;
        int256 liquidationRewardCutRatio;
        int256 liquidity;
        int256 lpsPnl;
        int256 cumulativePnlPerLiquidity;
        int256 protocolFeeAccrued;
        address symbolManagerImplementation;
        int256 initialMarginRequired;
    }

    struct MarketInfo {
        address underlying;
        address vToken;
        string underlyingSymbol;
        string vTokenSymbol;
        uint256 underlyingPrice;
        uint256 exchangeRate;
        uint256 vTokenBalance;
    }

    struct SymbolInfo {
        string category;
        string symbol;
        address symbolAddress;
        address implementation;
        address manager;
        address oracleManager;
        bytes32 symbolId;
        int256 feeRatio;
        int256 alpha;
        int256 fundingPeriod;
        int256 minTradeVolume;
        int256 minInitialMarginRatio;
        int256 initialMarginRatio;
        int256 maintenanceMarginRatio;
        int256 pricePercentThreshold;
        uint256 timeThreshold;
        bool isCloseOnly;
        bytes32 priceId;
        bytes32 volatilityId;
        int256 feeRatioITM;
        int256 feeRatioOTM;
        int256 strikePrice;
        bool isCall;
        int256 netVolume;
        int256 netCost;
        int256 indexPrice;
        uint256 fundingTimestamp;
        int256 cumulativeFundingPerVolume;
        int256 tradersPnl;
        int256 initialMarginRequired;
        uint256 nPositionHolders;
        int256 curIndexPrice;
        int256 curVolatility;
        int256 curCumulativeFundingPerVolume;
        int256 K;
        int256 markPrice;
        int256 funding;
        int256 timeValue;
        int256 delta;
        int256 u;
    }

    struct LpInfo {
        address account;
        uint256 lTokenId;
        address vault;
        int256 amountB0;
        int256 liquidity;
        int256 cumulativePnlPerLiquidity;
        uint256 vaultLiquidity;
        MarketInfo[] markets;
    }

    struct TdInfo {
        address account;
        uint256 pTokenId;
        address vault;
        int256 amountB0;
        uint256 vaultLiquidity;
        MarketInfo[] markets;
        PositionInfo[] positions;
    }

    struct PositionInfo {
        address symbolAddress;
        string symbol;
        int256 volume;
        int256 cost;
        int256 cumulativeFundingPerVolume;
    }

    function everlastingOptionPricingLens() external view returns (address);

    function getInfo(
        address pool_,
        address account_,
        PriceAndVolatility[] memory pvs
    )
        external
        view
        returns (
            PoolInfo memory poolInfo,
            MarketInfo[] memory marketsInfo,
            SymbolInfo[] memory symbolsInfo,
            LpInfo memory lpInfo,
            TdInfo memory tdInfo
        );

    function getLpInfo(address pool_, address account_) external view returns (LpInfo memory info);

    function getMarketsInfo(address pool_) external view returns (MarketInfo[] memory infos);

    function getPoolInfo(address pool_) external view returns (PoolInfo memory info);

    function getSymbolsInfo(
        address pool_,
        PriceAndVolatility[] memory pvs
    ) external view returns (SymbolInfo[] memory infos);

    function getTdInfo(address pool_, address account_) external view returns (TdInfo memory info);

    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface INameVersion {
    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPool {
    function implementation() external view returns (address);

    function protocolFeeCollector() external view returns (address);

    function liquidity() external view returns (int256);

    function lpsPnl() external view returns (int256);

    function cumulativePnlPerLiquidity() external view returns (int256);

    function protocolFeeAccrued() external view returns (int256);

    function setImplementation(address newImplementation) external;

    function addMarket(address market) external;

    function approveSwapper(address underlying) external;

    function collectProtocolFee() external;

    function claimVenusLp(address account) external;

    function claimVenusTrader(address account) external;

    struct OracleSignature {
        bytes32 oracleSymbolId;
        uint256 timestamp;
        uint256 value;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct PythData {
        bytes[] vaas;
        bytes32[] ids;
    }

    function addLiquidity(address underlying, uint256 amount, PythData calldata pythData) external payable;

    function removeLiquidity(address underlying, uint256 amount, PythData calldata pythData) external payable;

    function addMargin(address underlying, uint256 amount, PythData calldata pythData) external payable;

    function removeMargin(address underlying, uint256 amount, PythData calldata pythData) external;

    function trade(string memory symbolName, int256 tradeVolume, int256 priceLimit) external;

    function liquidate(uint256 pTokenId, PythData calldata pythData) external;

    struct LpInfo {
        address vault;
        int256 amountB0;
        int256 liquidity;
        int256 cumulativePnlPerLiquidity;
    }

    function lpInfos(uint256) external view returns (LpInfo memory);

    function marketB0() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./INameVersion.sol";

interface IVault is INameVersion {
    function pool() external view returns (address);

    function weth() external view returns (address);

    function aavePool() external view returns (address);

    function aaveOracle() external view returns (address);

    function aaveRewardsController() external view returns (address);

    function vaultLiquidityMultiplier() external view returns (uint256);

    function getVaultLiquidity() external view returns (uint256);

    function getHypotheticalVaultLiquidityChange(address asset, uint256 removeAmount) external view returns (uint256);

    function getAssetsIn() external view returns (address[] memory);

    function getAssetBalance(address market) external view returns (uint256);

    function mint() external payable;

    function mint(address asset, uint256 amount) external;

    function redeem(address asset, uint256 amount) external returns (uint256 withdrawnAmount);

    function transfer(address asset, address to, uint256 amount) external;

    function transferAll(address asset, address to) external returns (uint256);

    function claimStakedAave(address[] memory markets, address reward, address to) external;
}