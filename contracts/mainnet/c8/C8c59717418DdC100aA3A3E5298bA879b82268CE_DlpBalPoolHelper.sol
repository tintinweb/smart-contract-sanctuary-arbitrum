// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBasePool is IERC20 {
	function getSwapFeePercentage() external view returns (uint256);

	function setSwapFeePercentage(uint256 swapFeePercentage) external;

	function setAssetManagerPoolConfig(IERC20 token, IAssetManager.PoolConfig memory poolConfig) external;

	function setPaused(bool paused) external;

	function getVault() external view returns (IVault);

	function getPoolId() external view returns (bytes32);

	function getOwner() external view returns (address);
}

interface IWeightedPoolFactory {
	function create(
		string memory name,
		string memory symbol,
		IERC20[] memory tokens,
		uint256[] memory weights,
		address[] memory rateProviders,
		uint256 swapFeePercentage,
		address owner
	) external returns (address);
}

interface IWeightedPool is IBasePool {
	function getSwapEnabled() external view returns (bool);

	function getNormalizedWeights() external view returns (uint256[] memory);

	function getGradualWeightUpdateParams()
		external
		view
		returns (uint256 startTime, uint256 endTime, uint256[] memory endWeights);

	function setSwapEnabled(bool swapEnabled) external;

	function updateWeightsGradually(uint256 startTime, uint256 endTime, uint256[] memory endWeights) external;

	function withdrawCollectedManagementFees(address recipient) external;

	enum JoinKind {
		INIT,
		EXACT_TOKENS_IN_FOR_BPT_OUT,
		TOKEN_IN_FOR_EXACT_BPT_OUT
	}
	enum ExitKind {
		EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
		EXACT_BPT_IN_FOR_TOKENS_OUT,
		BPT_IN_FOR_EXACT_TOKENS_OUT
	}
}

interface IAssetManager {
	struct PoolConfig {
		uint64 targetPercentage;
		uint64 criticalPercentage;
		uint64 feePercentage;
	}

	function setPoolConfig(bytes32 poolId, PoolConfig calldata config) external;
}

interface IAsset {}

interface IVault {
	function hasApprovedRelayer(address user, address relayer) external view returns (bool);

	function setRelayerApproval(address sender, address relayer, bool approved) external;

	event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

	function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

	function manageUserBalance(UserBalanceOp[] memory ops) external payable;

	struct UserBalanceOp {
		UserBalanceOpKind kind;
		IAsset asset;
		uint256 amount;
		address sender;
		address payable recipient;
	}

	enum UserBalanceOpKind {
		DEPOSIT_INTERNAL,
		WITHDRAW_INTERNAL,
		TRANSFER_INTERNAL,
		TRANSFER_EXTERNAL
	}
	event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);
	event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

	enum PoolSpecialization {
		GENERAL,
		MINIMAL_SWAP_INFO,
		TWO_TOKEN
	}

	function registerPool(PoolSpecialization specialization) external returns (bytes32);

	event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

	function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

	function registerTokens(bytes32 poolId, IERC20[] memory tokens, address[] memory assetManagers) external;

	event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

	function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

	event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

	function getPoolTokenInfo(
		bytes32 poolId,
		IERC20 token
	) external view returns (uint256 cash, uint256 managed, uint256 lastChangeBlock, address assetManager);

	function getPoolTokens(
		bytes32 poolId
	) external view returns (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

	function joinPool(
		bytes32 poolId,
		address sender,
		address recipient,
		JoinPoolRequest memory request
	) external payable;

	struct JoinPoolRequest {
		IAsset[] assets;
		uint256[] maxAmountsIn;
		bytes userData;
		bool fromInternalBalance;
	}

	function exitPool(
		bytes32 poolId,
		address sender,
		address payable recipient,
		ExitPoolRequest memory request
	) external;

	struct ExitPoolRequest {
		IAsset[] assets;
		uint256[] minAmountsOut;
		bytes userData;
		bool toInternalBalance;
	}

	event PoolBalanceChanged(
		bytes32 indexed poolId,
		address indexed liquidityProvider,
		IERC20[] tokens,
		int256[] deltas,
		uint256[] protocolFeeAmounts
	);

	enum PoolBalanceChangeKind {
		JOIN,
		EXIT
	}

	enum SwapKind {
		GIVEN_IN,
		GIVEN_OUT
	}

	function swap(
		SingleSwap memory singleSwap,
		FundManagement memory funds,
		uint256 limit,
		uint256 deadline
	) external payable returns (uint256);

	struct SingleSwap {
		bytes32 poolId;
		SwapKind kind;
		IAsset assetIn;
		IAsset assetOut;
		uint256 amount;
		bytes userData;
	}

	function batchSwap(
		SwapKind kind,
		BatchSwapStep[] memory swaps,
		IAsset[] memory assets,
		FundManagement memory funds,
		int256[] memory limits,
		uint256 deadline
	) external payable returns (int256[] memory);

	struct BatchSwapStep {
		bytes32 poolId;
		uint256 assetInIndex;
		uint256 assetOutIndex;
		uint256 amount;
		bytes userData;
	}

	event Swap(
		bytes32 indexed poolId,
		IERC20 indexed tokenIn,
		IERC20 indexed tokenOut,
		uint256 amountIn,
		uint256 amountOut
	);
	struct FundManagement {
		address sender;
		bool fromInternalBalance;
		address payable recipient;
		bool toInternalBalance;
	}

	function queryBatchSwap(
		SwapKind kind,
		BatchSwapStep[] memory swaps,
		IAsset[] memory assets,
		FundManagement memory funds
	) external returns (int256[] memory assetDeltas);

	function managePoolBalance(PoolBalanceOp[] memory ops) external;

	struct PoolBalanceOp {
		PoolBalanceOpKind kind;
		bytes32 poolId;
		IERC20 token;
		uint256 amount;
	}

	enum PoolBalanceOpKind {
		WITHDRAW,
		DEPOSIT,
		UPDATE
	}
	event PoolBalanceManaged(
		bytes32 indexed poolId,
		address indexed assetManager,
		IERC20 indexed token,
		int256 cashDelta,
		int256 managedDelta
	);

	function setPaused(bool paused) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPoolHelper {
	function lpTokenAddr() external view returns (address);

	function zapWETH(uint256 amount) external returns (uint256);

	function zapTokens(uint256 _wethAmt, uint256 _rdntAmt) external returns (uint256);

	function quoteFromToken(uint256 tokenAmount) external view returns (uint256 optimalWETHAmount);

	function getLpPrice(uint rdntPriceInEth) external view returns (uint256 priceInEth);

	function getReserves() external view returns (uint256 rdnt, uint256 weth, uint256 lpTokenSupply);

	function getPrice() external view returns (uint256 priceInEth);
}

interface IBalancerPoolHelper is IPoolHelper {
	function initializePool(string calldata _tokenName, string calldata _tokenSymbol) external;
}

interface IUniswapPoolHelper is IPoolHelper {
	function initializePool() external;
}

interface ITestPoolHelper is IPoolHelper {
	function sell(uint256 _amount) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract BConst {
	uint public constant BONE = 10 ** 18;

	uint public constant MIN_BOUND_TOKENS = 2;
	uint public constant MAX_BOUND_TOKENS = 8;

	uint public constant MIN_FEE = BONE / 10 ** 6;
	uint public constant MAX_FEE = BONE / 10;
	uint public constant EXIT_FEE = 0;

	uint public constant MIN_WEIGHT = BONE;
	uint public constant MAX_WEIGHT = BONE * 50;
	uint public constant MAX_TOTAL_WEIGHT = BONE * 50;
	uint public constant MIN_BALANCE = BONE / 10 ** 12;

	uint public constant INIT_POOL_SUPPLY = BONE * 100;

	uint public constant MIN_BPOW_BASE = 1 wei;
	uint public constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
	uint public constant BPOW_PRECISION = BONE / 10 ** 10;

	uint public constant MAX_IN_RATIO = BONE / 2;
	uint public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./BConst.sol";

contract BNum is BConst {
	function btoi(uint a) internal pure returns (uint) {
		return a / BONE;
	}

	function bfloor(uint a) internal pure returns (uint) {
		return btoi(a) * BONE;
	}

	function badd(uint a, uint b) internal pure returns (uint) {
		uint c = a + b;
		require(c >= a, "ERR_ADD_OVERFLOW");
		return c;
	}

	function bsub(uint a, uint b) internal pure returns (uint) {
		(uint c, bool flag) = bsubSign(a, b);
		require(!flag, "ERR_SUB_UNDERFLOW");
		return c;
	}

	function bsubSign(uint a, uint b) internal pure returns (uint, bool) {
		if (a >= b) {
			return (a - b, false);
		} else {
			return (b - a, true);
		}
	}

	function bmul(uint a, uint b) internal pure returns (uint) {
		uint c0 = a * b;
		require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
		uint c1 = c0 + (BONE / 2);
		require(c1 >= c0, "ERR_MUL_OVERFLOW");
		uint c2 = c1 / BONE;
		return c2;
	}

	function bdiv(uint a, uint b) internal pure returns (uint) {
		require(b != 0, "ERR_DIV_ZERO");
		uint c0 = a * BONE;
		require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
		uint c1 = c0 + (b / 2);
		require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
		uint c2 = c1 / b;
		return c2;
	}

	// DSMath.wpow
	function bpowi(uint a, uint n) internal pure returns (uint) {
		uint z = n % 2 != 0 ? a : BONE;

		for (n /= 2; n != 0; n /= 2) {
			a = bmul(a, a);

			if (n % 2 != 0) {
				z = bmul(z, a);
			}
		}
		return z;
	}

	// Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
	// Use `bpowi` for `b^e` and `bpowK` for k iterations
	// of approximation of b^0.w
	function bpow(uint base, uint exp) internal pure returns (uint) {
		require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
		require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

		uint whole = bfloor(exp);
		uint remain = bsub(exp, whole);

		uint wholePow = bpowi(base, btoi(whole));

		if (remain == 0) {
			return wholePow;
		}

		uint partialResult = bpowApprox(base, remain, BPOW_PRECISION);
		return bmul(wholePow, partialResult);
	}

	function bpowApprox(uint base, uint exp, uint precision) internal pure returns (uint) {
		// term 0:
		uint a = exp;
		(uint x, bool xneg) = bsubSign(base, BONE);
		uint term = BONE;
		uint sum = term;
		bool negative = false;

		// term(k) = numer / denom
		//         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
		// each iteration, multiply previous term by (a-(k-1)) * x / k
		// continue until term is less than precision
		for (uint i = 1; term >= precision; i++) {
			uint bigK = i * BONE;
			(uint c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
			term = bmul(term, bmul(c, x));
			term = bdiv(term, bigK);
			if (term == 0) break;

			if (xneg) negative = !negative;
			if (cneg) negative = !negative;
			if (negative) {
				sum = bsub(sum, term);
			} else {
				sum = badd(sum, term);
			}
		}

		return sum;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./DustRefunder.sol";
import "./BNum.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../../interfaces/IWETH.sol";
import "../../interfaces/balancer/IWeightedPoolFactory.sol";
import "../../interfaces/radiant/IPoolHelper.sol";

/// @title Balance Pool Helper Contract
/// @author Radpie, completely forked from Radiant
contract DlpBalPoolHelper is IBalancerPoolHelper, Initializable, OwnableUpgradeable, BNum, DustRefunder {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	address public inTokenAddr;
	address public outTokenAddr;
	address public wethAddr;
	address public override lpTokenAddr;
	address public vaultAddr;
	bytes32 public poolId;
	IWeightedPoolFactory public poolFactory;
	address public mDLP;

	function __DlpBalPoolHelper_init(
		address _inTokenAddr,
		address _outTokenAddr,
		address _wethAddr,
		address _vault,
		IWeightedPoolFactory _poolFactory,
		address _lpTokenAddr,
		bytes32 _poolId,
		address _mDLP
	) external initializer {
		__Ownable_init();
		inTokenAddr = _inTokenAddr;
		outTokenAddr = _outTokenAddr;
		wethAddr = _wethAddr;
		vaultAddr = _vault;
		poolFactory = _poolFactory;
		lpTokenAddr = _lpTokenAddr;
		poolId = _poolId;
		mDLP = _mDLP;
	}

	function initializePool(string calldata _tokenName, string calldata _tokenSymbol) public {
		require(lpTokenAddr == address(0), "Already initialized");

		(address token0, address token1) = sortTokens(inTokenAddr, outTokenAddr);

		IERC20[] memory tokens = new IERC20[](2);
		tokens[0] = IERC20(token0);
		tokens[1] = IERC20(token1);

		address[] memory rateProviders = new address[](2);
		rateProviders[0] = 0x0000000000000000000000000000000000000000;
		rateProviders[1] = 0x0000000000000000000000000000000000000000;

		uint256 swapFeePercentage = 1000000000000000;

		uint256[] memory weights = new uint256[](2);

		if (token0 == outTokenAddr) {
			weights[0] = 800000000000000000;
			weights[1] = 200000000000000000;
		} else {
			weights[0] = 200000000000000000;
			weights[1] = 800000000000000000;
		}

		lpTokenAddr = poolFactory.create(
			_tokenName,
			_tokenSymbol,
			tokens,
			weights,
			rateProviders,
			swapFeePercentage,
			address(this)
		);

		poolId = IWeightedPool(lpTokenAddr).getPoolId();

		IERC20 outToken = IERC20(outTokenAddr);
		IERC20 inToken = IERC20(inTokenAddr);
		IERC20 lp = IERC20(lpTokenAddr);
		IERC20 weth = IERC20(wethAddr);

		outToken.safeApprove(vaultAddr, type(uint256).max);
		inToken.safeApprove(vaultAddr, type(uint256).max);
		weth.approve(vaultAddr, type(uint256).max);

		IAsset[] memory assets = new IAsset[](2);
		assets[0] = IAsset(token0);
		assets[1] = IAsset(token1);

		uint256 inTokenAmt = inToken.balanceOf(address(this));
		uint256 outTokenAmt = outToken.balanceOf(address(this));

		uint256[] memory maxAmountsIn = new uint256[](2);
		if (token0 == inTokenAddr) {
			maxAmountsIn[0] = inTokenAmt;
			maxAmountsIn[1] = outTokenAmt;
		} else {
			maxAmountsIn[0] = outTokenAmt;
			maxAmountsIn[1] = inTokenAmt;
		}

		IVault.JoinPoolRequest memory inRequest = IVault.JoinPoolRequest(
			assets,
			maxAmountsIn,
			abi.encode(0, maxAmountsIn),
			false
		);
		IVault(vaultAddr).joinPool(poolId, address(this), address(this), inRequest);
		uint256 liquidity = lp.balanceOf(address(this));
		lp.safeTransfer(msg.sender, liquidity);
	}

	/// @dev Return fair reserve amounts given spot reserves, weights, and fair prices.
	/// @param resA Reserve of the first asset
	/// @param resB Reserve of the second asset
	/// @param wA Weight of the first asset
	/// @param wB Weight of the second asset
	/// @param pxA Fair price of the first asset
	/// @param pxB Fair price of the second asset
	function computeFairReserves(
		uint256 resA,
		uint256 resB,
		uint256 wA,
		uint256 wB,
		uint256 pxA,
		uint256 pxB
	) internal pure returns (uint256 fairResA, uint256 fairResB) {
		// NOTE: wA + wB = 1 (normalize weights)
		// constant product = resA^wA * resB^wB
		// constraints:
		// - fairResA^wA * fairResB^wB = constant product
		// - fairResA * pxA / wA = fairResB * pxB / wB
		// Solving equations:
		// --> fairResA^wA * (fairResA * (pxA * wB) / (wA * pxB))^wB = constant product
		// --> fairResA / r1^wB = constant product
		// --> fairResA = resA^wA * resB^wB * r1^wB
		// --> fairResA = resA * (resB/resA)^wB * r1^wB = resA * (r1/r0)^wB
		uint256 r0 = bdiv(resA, resB);
		uint256 r1 = bdiv(bmul(wA, pxB), bmul(wB, pxA));
		// fairResA = resA * (r1 / r0) ^ wB
		// fairResB = resB * (r0 / r1) ^ wA
		if (r0 > r1) {
			uint256 ratio = bdiv(r1, r0);
			fairResA = bmul(resA, bpow(ratio, wB));
			fairResB = bdiv(resB, bpow(ratio, wA));
		} else {
			uint256 ratio = bdiv(r0, r1);
			fairResA = bdiv(resA, bpow(ratio, wB));
			fairResB = bmul(resB, bpow(ratio, wA));
		}
	}

	function getLpPrice(uint256 rdntPriceInEth) public view override returns (uint256 priceInEth) {
		IWeightedPool pool = IWeightedPool(lpTokenAddr);
		(address token0, ) = sortTokens(inTokenAddr, outTokenAddr);
		(uint256 rdntBalance, uint256 wethBalance, ) = getReserves();
		uint256[] memory weights = pool.getNormalizedWeights();

		uint256 rdntWeight;
		uint256 wethWeight;

		if (token0 == outTokenAddr) {
			rdntWeight = weights[0];
			wethWeight = weights[1];
		} else {
			rdntWeight = weights[1];
			wethWeight = weights[0];
		}

		// RDNT in eth, 8 decis
		uint256 pxA = rdntPriceInEth;
		// ETH in eth, 8 decis
		uint256 pxB = 100000000;

		(uint256 fairResA, uint256 fairResB) = computeFairReserves(
			rdntBalance,
			wethBalance,
			rdntWeight,
			wethWeight,
			pxA,
			pxB
		);
		// use fairReserveA and fairReserveB to compute LP token price
		// LP price = (fairResA * pxA + fairResB * pxB) / totalLPSupply
		priceInEth = fairResA.mul(pxA).add(fairResB.mul(pxB)).div(pool.totalSupply());
	}

	function getPrice() public view returns (uint256 priceInEth) {
		(IERC20[] memory tokens, uint256[] memory balances, ) = IVault(vaultAddr).getPoolTokens(poolId);
		uint256 rdntBalance = address(tokens[0]) == outTokenAddr ? balances[0] : balances[1];
		uint256 wethBalance = address(tokens[0]) == outTokenAddr ? balances[1] : balances[0];

		uint256 poolWeight = 4;

		return wethBalance.mul(1e8).div(rdntBalance.div(poolWeight));
	}

	function getReserves() public view override returns (uint256 rdnt, uint256 weth, uint256 lpTokenSupply) {
		IERC20 lpToken = IERC20(lpTokenAddr);

		(IERC20[] memory tokens, uint256[] memory balances, ) = IVault(vaultAddr).getPoolTokens(poolId);

		rdnt = address(tokens[0]) == outTokenAddr ? balances[0] : balances[1];
		weth = address(tokens[0]) == outTokenAddr ? balances[1] : balances[0];

		lpTokenSupply = lpToken.totalSupply().div(1e18);
	}

	function joinPool(uint256 _wethAmt, uint256 _rdntAmt) internal returns (uint256 liquidity) {
		(address token0, address token1) = sortTokens(outTokenAddr, inTokenAddr);
		IAsset[] memory assets = new IAsset[](2);
		assets[0] = IAsset(token0);
		assets[1] = IAsset(token1);

		uint256[] memory maxAmountsIn = new uint256[](2);
		if (token0 == inTokenAddr) {
			maxAmountsIn[0] = _wethAmt;
			maxAmountsIn[1] = _rdntAmt;
		} else {
			maxAmountsIn[0] = _rdntAmt;
			maxAmountsIn[1] = _wethAmt;
		}

		bytes memory userDataEncoded = abi.encode(IWeightedPool.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, maxAmountsIn, 0);
		IVault.JoinPoolRequest memory inRequest = IVault.JoinPoolRequest(assets, maxAmountsIn, userDataEncoded, false);
		IERC20(wethAddr).safeApprove(vaultAddr, _wethAmt);
		IERC20(outTokenAddr).safeApprove(vaultAddr, _rdntAmt);
		IVault(vaultAddr).joinPool(poolId, address(this), address(this), inRequest);

		IERC20 lp = IERC20(lpTokenAddr);
		liquidity = lp.balanceOf(address(this));
	}

	function zapWETH(uint256 amount) public override returns (uint256 liquidity) {
		require(msg.sender == mDLP, "!mDLP");
		IWETH(wethAddr).transferFrom(msg.sender, address(this), amount);
		liquidity = joinPool(amount, 0);
		IERC20 lp = IERC20(lpTokenAddr);
		lp.safeTransfer(msg.sender, liquidity);
		refundDust(outTokenAddr, wethAddr, msg.sender);
	}

	function zapTokens(uint256 _wethAmt, uint256 _rdntAmt) public override returns (uint256 liquidity) {
		require(msg.sender == mDLP, "!mDLP");
		IWETH(wethAddr).transferFrom(msg.sender, address(this), _wethAmt);
		IERC20(outTokenAddr).safeTransferFrom(msg.sender, address(this), _rdntAmt);

		liquidity = joinPool(_wethAmt, _rdntAmt);
		IERC20 lp = IERC20(lpTokenAddr);
		lp.safeTransfer(msg.sender, liquidity);

		refundDust(outTokenAddr, wethAddr, msg.sender);
	}

	function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
		require(tokenA != tokenB, "BalancerZap: IDENTICAL_ADDRESSES");
		(token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
		require(token0 != address(0), "BalancerZap: ZERO_ADDRESS");
	}

	function quoteFromToken(uint256 tokenAmount) public view override returns (uint256 optimalWETHAmount) {
		uint256 rdntPriceInEth = getPrice();
		uint256 p1 = rdntPriceInEth.mul(1e10);
		uint256 ethRequiredBeforeWeight = tokenAmount.mul(p1).div(1e18);
		optimalWETHAmount = ethRequiredBeforeWeight.div(4);
	}

	function swap(
		uint256 _amount,
		address _tokenInAddress,
		address _tokenOutAddress,
		address _lpAddr
	) internal returns (uint256 amountOut) {
		IAsset tokenInAddress = IAsset(_tokenInAddress);
		IAsset tokenOutAddress = IAsset(_tokenOutAddress);

		bytes32 _poolId = IWeightedPool(_lpAddr).getPoolId();

		bytes memory userDataEncoded = abi.encode(); //https://dev.balancer.fi/helpers/encoding
		IVault.SingleSwap memory singleSwapRequest = IVault.SingleSwap(
			_poolId,
			IVault.SwapKind.GIVEN_IN,
			tokenInAddress,
			tokenOutAddress,
			_amount,
			userDataEncoded
		);
		IVault.FundManagement memory fundManagementRequest = IVault.FundManagement(
			address(this),
			false,
			payable(address(this)),
			false
		);

		uint256 limit = 0;

		amountOut = IVault(vaultAddr).swap(
			singleSwapRequest,
			fundManagementRequest,
			limit,
			(block.timestamp + 3 minutes)
		);
	}

	function setmDLP(address _mDLP) external onlyOwner {
		mDLP = _mDLP;
	}

	function getSwapFeePercentage() public onlyOwner returns (uint256 fee) {
		IWeightedPool pool = IWeightedPool(lpTokenAddr);
		fee = pool.getSwapFeePercentage();
	}

	function setSwapFeePercentage(uint256 _fee) public onlyOwner {
		IWeightedPool pool = IWeightedPool(lpTokenAddr);
		pool.setSwapFeePercentage(_fee);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../interfaces/IWETH.sol";

contract DustRefunder {
	using SafeERC20 for IERC20;

	function refundDust(address _rdnt, address _weth, address _refundAddress) internal {
		IERC20 rdnt = IERC20(_rdnt);
		IWETH weth = IWETH(_weth);

		uint256 dustWETH = weth.balanceOf(address(this));
		if (dustWETH > 0) {
			weth.transfer(_refundAddress, dustWETH);
		}
		uint256 dustRdnt = rdnt.balanceOf(address(this));
		if (dustRdnt > 0) {
			rdnt.safeTransfer(_refundAddress, dustRdnt);
		}
	}
}