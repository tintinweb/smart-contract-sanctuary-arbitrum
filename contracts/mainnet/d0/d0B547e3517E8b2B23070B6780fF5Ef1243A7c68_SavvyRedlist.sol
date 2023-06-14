// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @notice An error used to indicate that an argument passed to a function is illegal or
///         inappropriate.
///
/// @param message The error message.
error IllegalArgumentWithReason(string message);

/// @notice An error used to indicate that a function has encountered an unrecoverable state.
///
/// @param message The error message.
error IllegalStateWithReason(string message);

/// @notice An error used to indicate that an operation is unsupported.
///
/// @param message The error message.
error UnsupportedOperationWithReason(string message);

/// @notice An error used to indicate that a message sender tried to execute a privileged function.
///
/// @param message The error message.
error UnauthorizedWithReason(string message);

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @notice An error used to indicate that an action could not be completed because either the `msg.sender` or
///         `msg.origin` is not authorized.
error Unauthorized();

/// @notice An error used to indicate that an action could not be completed because the contract either already existed
///         or entered an illegal condition which is not recoverable from.
error IllegalState();

/// @notice An error used to indicate that an action could not be completed because of an illegal argument was passed
///         to the function.
error IllegalArgument();

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  Mutex
/// @author Savvy DeFi
///
/// @notice Provides a mutual exclusion lock for implementing contracts.
abstract contract Mutex {
    /// @notice An error which is thrown when a lock is attempted to be claimed before it has been freed.
    error LockAlreadyClaimed();

    /// @notice The lock state. Non-zero values indicate the lock has been claimed.
    uint256 private _lockState;

    /// @dev A modifier which acquires the mutex.
    modifier lock() {
        _claimLock();

        _;

        _freeLock();
    }

    /// @dev Gets if the mutex is locked.
    ///
    /// @return if the mutex is locked.
    function _isLocked() internal view returns (bool) {
        return _lockState == 1;
    }

    /// @dev Claims the lock. If the lock is already claimed, then this will revert.
    function _claimLock() internal {
        // Check that the lock has not been claimed yet.
        require(_lockState == 0, "LockAlreadyClaimed");

        // Claim the lock.
        _lockState = 1;
    }

    /// @dev Frees the lock.
    function _freeLock() internal {
        _lockState = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../base/Errors.sol";
import "../libraries/Sets.sol";

/// @title  Allowlist
/// @author Savvy DeFi
interface IAllowlist {
    /// @dev Emitted when a contract is added to the allowlist.
    ///
    /// @param account The account that was added to the allowlist.
    event AccountAdded(address account);

    /// @dev Emitted when a contract is removed from the allowlist.
    ///
    /// @param account The account that was removed from the allowlist.
    event AccountRemoved(address account);

    /// @dev Emitted when the allowlist is deactivated.
    event AllowlistDisabled();

    /// @dev Returns the list of addresses that are allowlisted for the given contract address.
    ///
    /// @return addresses The addresses that are allowlisted to interact with the given contract.
    function getAddresses() external view returns (address[] memory addresses);

    /// @dev Returns the disabled status of a given allowlist.
    ///
    /// @return disabled A flag denoting if the given allowlist is disabled.
    function disabled() external view returns (bool);

    /// @dev Adds an contract to the allowlist.
    ///
    /// @param caller The address to add to the allowlist.
    function add(address caller) external;

    /// @dev Adds a contract to the allowlist.
    ///
    /// @param caller The address to remove from the allowlist.
    function remove(address caller) external;

    /// @dev Disables the allowlist of the target allowlisted contract.
    ///
    /// This can only occur once. Once the allowlist is disabled, then it cannot be reenabled.
    function disable() external;

    /// @dev Checks that the `msg.sender` is allowlisted when it is not an EOA.
    ///
    /// @param account The account to check.
    ///
    /// @return allowlisted A flag denoting if the given account is allowlisted.
    function isAllowed(address account) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface ISavvyRedlist {
    /// @notice Emitted when the allowlist contract is updated.
    ///
    /// @param allowlist_ The address of the allowlist contract.
    event AllowlistUpdated(address indexed allowlist_);

    /// @notice Emitted when the protocol token required flag is updated.
    ///
    /// @param protocolTokenRequired_ The protocol token required flag.
    event ProtocolTokenRequired(bool indexed protocolTokenRequired_);

    /// @notice Emitted when an NFT collection is added.
    ///
    /// @param nftCollection_ The address of the NFT collection.
    event NFTCollectionAdded(address indexed nftCollection_);

    /// @notice Emitted when an NFT collection is removed.
    ///
    /// @param nftCollection_ The address of the NFT collection.
    event NFTCollectionRemoved(address indexed nftCollection_);

    /// @notice Set the address of the allowlist contract.
    /// @notice Emits a {AllowlistUpdated} event.
    /// @dev `msg.sender` must be owner.
    /// @param allowlist_ The address of the allowlist contract.
    function setAllowlist(address allowlist_) external;

    /// @notice Set the protocol token required flag.
    /// @notice Emits a {ProtocolTokenRequired} event.
    /// @dev `msg.sender` must be owner.
    /// @param protocolTokenRequired_ The protocol token required flag.
    function setProtocolTokenRequired(bool protocolTokenRequired_) external;

    /// @notice Get all the NFT collection addresses.
    /// @return nftCollections_ The array of NFT collection addresses.
    function getNFTCollections() external view returns (address[] memory);

    /// @notice Check if an NFT collection is eligible for redlist.
    /// @param nftCollection_ The address of the NFT collection.
    /// @return isRedlistNFT_ True if the NFT collection is eligible for redlist.
    function isRedlistNFT(address nftCollection_) external view returns (bool);

    /// @notice Add an NFT collection to the eligible redlist.
    /// @notice Emits a {NFTCollectionAdded} event.
    /// @dev `msg.sender` must be owner.
    /// @param nftCollection_ The address of the NFT collection.
    function addNFTCollection(address nftCollection_) external;

    /// @notice Remove an NFT collection from the eligible redlist.
    /// @notice Emits a {NFTCollectionRemoved} event.
    /// @dev `msg.sender` must be owner.
    /// @param nftCollection_ The address of the NFT collection.
    function removeNFTCollection(address nftCollection_) external;

    /// @notice Check if an account is redlisted.
    /// @dev This function is not view because it updates the cache.
    /// @param account_ The address of the account.
    /// @param isProtocolTokenRequire_ The status that require protocol token or not.
    /// @param eligibleNFTRequire_ The status that require eligible NFT or not.
    /// @return isRedlisted_ True if the account is redlisted.
    function isRedlisted(
        address account_,
        bool eligibleNFTRequire_,
        bool isProtocolTokenRequire_
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title  ISavvyToken
/// @author Savvy DeFi
interface ISavvyToken is IERC20 {
    /// @notice Gets the total amount of minted tokens for an account.
    ///
    /// @param account The address of the account.
    ///
    /// @return The total minted.
    function hasMinted(address account) external view returns (uint256);

    /// @notice Lowers the number of tokens which the `msg.sender` has minted.
    ///
    /// This reverts if the `msg.sender` is not allowlisted.
    ///
    /// @param amount The amount to lower the minted amount by.
    function lowerHasMinted(uint256 amount) external;

    /// @notice Sets the mint allowance for a given account'
    ///
    /// This reverts if the `msg.sender` is not admin
    ///
    /// @param toSetCeiling The account whos allowance to update
    /// @param ceiling      The amount of tokens allowed to mint
    function setCeiling(address toSetCeiling, uint256 ceiling) external;

    /// @notice Updates the state of an address in the allowlist map
    ///
    /// This reverts if msg.sender is not admin
    ///
    /// @param toAllowlist the address whos state is being updated
    /// @param state the boolean state of the allowlist
    function setAllowlist(address toAllowlist, bool state) external;

    function mint(address recipient, uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface IVeERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./IVeERC20.sol";

/**
 * @dev Interface of the VeSvy
 */
interface IVeSvy is IVeERC20 {
    function isUser(address _addr) external view returns (bool);

    function stake(uint256 _amount) external;

    function claimable(address _addr) external view returns (uint256);

    function claim() external;

    function unstake(uint256 _amount) external;

    function getStakedSvy(address _addr) external view returns (uint256);

    function getVotes(address _account) external view returns (uint256);

    function getVeSVYEarnRatePerSec(
        address _addr
    ) external view returns (uint256);

    function getMaxVeSVYEarnable(address _addr) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../base/ErrorMessages.sol";

// a library for validating conditions.

library Checker {
    /// @dev Checks an expression and reverts with an {IllegalArgument} error if the expression is {false}.
    ///
    /// @param expression The expression to check.
    /// @param message The error message to display if the check fails.
    function checkArgument(
        bool expression,
        string memory message
    ) internal pure {
        require(expression, message);
    }

    /// @dev Checks an expression and reverts with an {IllegalState} error if the expression is {false}.
    ///
    /// @param expression The expression to check.
    /// @param message The error message to display if the check fails.
    function checkState(bool expression, string memory message) internal pure {
        require(expression, message);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  Sets
/// @author Savvy DeFi
library Sets {
    using Sets for AddressSet;

    /// @notice A data structure holding an array of values with an index mapping for O(1) lookup.
    struct AddressSet {
        address[] values;
        mapping(address => uint256) indexes;
    }

    /// @dev Add a value to a Set
    ///
    /// @param self  The Set.
    /// @param value The value to add.
    ///
    /// @return Whether the operation was successful (unsuccessful if the value is already contained in the Set)
    function add(
        AddressSet storage self,
        address value
    ) internal returns (bool) {
        if (self.contains(value)) {
            return false;
        }
        self.values.push(value);
        self.indexes[value] = self.values.length;
        return true;
    }

    /// @dev Remove a value from a Set
    ///
    /// @param self  The Set.
    /// @param value The value to remove.
    ///
    /// @return Whether the operation was successful (unsuccessful if the value was not contained in the Set)
    function remove(
        AddressSet storage self,
        address value
    ) internal returns (bool) {
        uint256 index = self.indexes[value];
        if (index == 0) {
            return false;
        }

        // Normalize the index since we know that the element is in the set.
        index--;

        uint256 lastIndex = self.values.length - 1;

        if (index != lastIndex) {
            address lastValue = self.values[lastIndex];
            self.values[index] = lastValue;
            self.indexes[lastValue] = index + 1;
        }

        self.values.pop();

        delete self.indexes[value];

        return true;
    }

    /// @dev Returns true if the value exists in the Set
    ///
    /// @param self  The Set.
    /// @param value The value to check.
    ///
    /// @return True if the value is contained in the Set, False if it is not.
    function contains(
        AddressSet storage self,
        address value
    ) internal view returns (bool) {
        return self.indexes[value] != 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "./base/Mutex.sol";
import "./libraries/Checker.sol";
import "./interfaces/IAllowlist.sol";
import "./interfaces/ISavvyRedlist.sol";
import "./interfaces/IVeSvy.sol";
import "./interfaces/ISavvyToken.sol";

/// @title  SavvyRedlist
/// @author Savvy DeFi
contract SavvyRedlist is ISavvyRedlist, Ownable2StepUpgradeable, Mutex {
    /// @notice SVY required flag
    /// @dev true/false = turn on/off
    bool public protocolTokenRequired;

    // @dev The address of the protocol token contract ($SVY).
    address public protocolToken;

    // @dev The address of the protocol token contract ($veSVY).
    address public veProtocolToken;

    // @dev The address of the allowlist contract.
    address public allowlist;

    // @dev Array of all NFT collections that are eligible for redlist
    address[] public nftCollections;

    // @dev Mapping of NFT collections to their index in the nftCollections array
    mapping(address => uint256) public nftCollectionsToIndex;

    // @dev Cache of the last NFT used for each account
    mapping(address => address) public lastNFTUsedCache;

    /// @dev Checks if 'msg.sender' is allowlisted.
    modifier onlyAllowlisted() {
        Checker.checkArgument(
            IAllowlist(allowlist).isAllowed(msg.sender),
            "only allowlisted addresses can call this function"
        );
        _;
    }

    constructor() {
        _disableInitializers();
    }

    /// @dev Add null entry to index 0 because mapping cannot differentiate between null & index 0
    ///
    /// @dev Include all savvyPositionManagers & in the allowlist
    function initialize(
        bool protocolTokenRequired_,
        address protocolToken_,
        address veProtocolToken_,
        address allowlist_,
        address[] calldata nftCollections_
    ) external initializer {
        Checker.checkArgument(
            address(protocolToken_) != address(0),
            "protocolToken_ must be a valid contract"
        );
        Checker.checkArgument(
            address(veProtocolToken_) != address(0),
            "veProtocolToken_ must be a valid contract"
        );
        Checker.checkArgument(
            address(allowlist_) != address(0),
            "allowlist_ must be a valid contract"
        );

        allowlist = allowlist_;
        protocolTokenRequired = protocolTokenRequired_;
        protocolToken = protocolToken_;
        veProtocolToken = veProtocolToken_;

        // Add null entry to index 0 because mapping cannot differentiate between null & index 0
        nftCollections.push(address(0));
        for (uint256 i = 0; i < nftCollections_.length; i++) {
            address nftCollection = nftCollections_[i];
            Checker.checkArgument(
                address(nftCollection) != address(0),
                "nftCollection must be a valid contract"
            );
            nftCollections.push(nftCollection);
            nftCollectionsToIndex[nftCollection] = nftCollections.length - 1;
        }
        __Ownable_init();
    }

    /// @inheritdoc ISavvyRedlist
    function setProtocolTokenRequired(
        bool protocolTokenRequired_
    ) external override onlyOwner {
        protocolTokenRequired = protocolTokenRequired_;
        emit ProtocolTokenRequired(protocolTokenRequired_);
    }

    /// @inheritdoc ISavvyRedlist
    function setAllowlist(address allowlist_) external override onlyOwner {
        allowlist = allowlist_;
        emit AllowlistUpdated(allowlist_);
    }

    /// @inheritdoc ISavvyRedlist
    function getNFTCollections()
        external
        view
        override
        returns (address[] memory)
    {
        return nftCollections;
    }

    /// @inheritdoc ISavvyRedlist
    function isRedlistNFT(
        address nftCollection_
    ) public view override returns (bool) {
        return nftCollectionsToIndex[nftCollection_] != 0;
    }

    /// @inheritdoc ISavvyRedlist
    function addNFTCollection(address nftCollection_) external onlyOwner lock {
        Checker.checkArgument(
            address(nftCollection_) != address(0),
            "nftCollection_ must be a valid contract"
        );
        Checker.checkArgument(
            !isRedlistNFT(nftCollection_),
            "NFT collection is already added to the redlist"
        );
        uint256 index = nftCollections.length;
        nftCollections.push(nftCollection_);
        nftCollectionsToIndex[nftCollection_] = index;

        emit NFTCollectionAdded(nftCollection_);
    }

    /// @inheritdoc ISavvyRedlist
    function removeNFTCollection(
        address nftCollection_
    ) external override onlyOwner lock {
        Checker.checkArgument(
            isRedlistNFT(nftCollection_),
            "nftCollection_ is already removed from the redlist"
        );
        uint256 index = nftCollectionsToIndex[nftCollection_];
        Checker.checkArgument(
            nftCollection_ == nftCollections[index],
            "NFT collection mapping and array state is corrupted"
        );
        delete nftCollections[index];
        nftCollectionsToIndex[nftCollection_] = 0;

        emit NFTCollectionRemoved(nftCollection_);
    }

    /// @inheritdoc ISavvyRedlist
    function isRedlisted(
        address account_,
        bool eligibleNFTRequire_,
        bool isProtocolTokenRequire_
    ) external override onlyAllowlisted returns (bool) {
        Checker.checkArgument(
            address(account_) != address(0),
            "account_ must be a valid contract"
        );
        if (isProtocolTokenRequire_ && !_hasRequiredProtocolTokens(account_)) {
            return false;
        }

        if (!eligibleNFTRequire_) return true;

        address nftCollection = address(lastNFTUsedCache[account_]);
        if (_isNFTOwner(account_, nftCollection)) {
            if (isRedlistNFT(nftCollection)) {
                return true;
            }
        } else {
            //clear outdated cache
            delete lastNFTUsedCache[account_];
        }
        for (uint256 i = 1; i < nftCollections.length; i++) {
            nftCollection = address(nftCollections[i]);
            if (
                _isNFTOwner(account_, nftCollection) &&
                isRedlistNFT(nftCollection)
            ) {
                lastNFTUsedCache[account_] = nftCollection;
                return true;
            }
        }
        return false;
    }

    /// @notice Check that 'account_' owns at least one NFT from 'nftCollection_'.
    /// @param account_ The address of the account.
    /// @param nftCollection_ The NFT collection to check.
    /// @return True if 'account_' owns at least one NFT from 'nftCollection_'.
    function _isNFTOwner(
        address account_,
        address nftCollection_
    ) internal view returns (bool) {
        if (nftCollection_ == address(0)) return false;
        return IERC721(nftCollection_).balanceOf(account_) > 0;
    }

    /// @notice Check that 'account_' has the required amount of SVY.
    /// @dev If the 'protocolTokenRequired' is disabled, return true.
    /// @dev If the 'account_' has SVY in their wallet or staked in veSVY, return true.
    /// @param account_ The address of the account.
    /// @return True if 'account_' has the required amount of protocol tokens.
    function _hasRequiredProtocolTokens(
        address account_
    ) internal view returns (bool) {
        if (!protocolTokenRequired) {
            return true;
        }
        uint256 protocolTokenInWallet = ISavvyToken(protocolToken).balanceOf(
            account_
        );
        uint256 protocolTokenStaked = IVeSvy(veProtocolToken).getStakedSvy(
            account_
        );
        if (protocolTokenInWallet > 0 || protocolTokenStaked > 0) {
            return true;
        }
        return false;
    }

    uint256[100] private __gap;
}