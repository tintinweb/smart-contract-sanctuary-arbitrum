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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

pragma solidity ^0.8.4;

import "contracts/libraries/721A/IERC721A.sol";

interface IMA is IERC721A {
    // blue 1/ green 0
    function characters(
        uint256 tokenId
    ) external view returns (uint256 quality, uint256 level, uint256 score);

    function tokensOfOwner(address addr_) external view returns (uint[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMSW is IERC721 {
    function cardInfoes(
        uint256
    ) external view returns (uint256, uint256, uint256, uint256, string memory);

    function cardIdMap(uint256) external view returns (uint256);

    function cardOwners(uint256) external view returns (address);

    function minters(address, uint256) external view returns (uint256);

    function superMinters(address) external view returns (bool);

    function myBaseURI() external view returns (string memory);

    function superMinter() external view returns (address);

    function WALLET() external view returns (address);

    function mint(address, uint, uint) external returns (bool);

    // main
    function upgrade(uint, uint) external returns (bool);
    //test
    // function upgrade(uint, uint) external;

    function tokenOfOwnerForAll(
        address addr_
    ) external view returns (uint[] memory, uint[] memory);

    function tokenURI(uint256) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed from,
        address indexed to
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DataTypes {
    struct UnionsInfo {
        // union owner
        address owner;
        // union level
        uint lv;
        // union id is nft token id
        uint unionId;
        // invitation union
        uint topUnions;
        // how many people in this union
        uint members;
        // sub union list
        uint[] subUnions;
        // claimed tax
        uint tax;
        // total tax
        uint taxDebt;
        // claimed getax
        uint geTax;
        // total getax
        uint geTaxDebt;
        // claimed dao bonus
        uint dao;
        // this value is increased when a union is upgraded
        uint daoToClaim;
        // debt
        uint daoDebt;
    }

    struct UserInfo {
        // the union to which this user belongs
        uint unionsId;
        // the user total power, accrual of all nft
        uint power;
        // this value is increased when a nft is deposited
        uint toClaim;
        // user claimed Token
        uint claimed;
        // debt of user, it should update after gobal debt
        uint debt;
        // Time of last interaction with the contract
        uint lastTime;
    }

    struct KunInfo {
        // nft owner
        address owner;
        // nft token id
        uint kunId;
        // the power of amplification
        uint kunPower;
        uint depositTime;
    }

    struct PoolInfo {
        // pool is alive
        bool status;
        uint dayOut;
        // TVL
        uint totalPower;
        // debt
        uint globalDebt;
        // user claimed total token
        uint totalClaimed;
        // this pool startTime
        uint startTime;
        // Time of last interaction with the pool
        uint lastRewardTime;
    }

    struct DaoDebt {
        // Date of last update of bonus data
        uint updateDays;
        // TVL
        uint totalDao;
        // debt
        uint debt;

        // mapping(uint => uint) debt;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMA} from "contracts/interface/IMA_1.sol";
import {IMSW} from "contracts/interface/IMSW_1.sol";
import {DataTypes} from "./libraries/types/DataTypes.sol";

contract NftMinning is OwnableUpgradeable, IERC721ReceiverUpgradeable {
    using AddressUpgradeable for address;
    address public WALLET;
    address public USDT;
    address public MSW;

    IMSW public unions;
    IMA public kun;

    uint[4] public tax;
    uint[3] public dao;
    uint public constant sytemUnions = 99999;
    uint private constant ACC = 1 ether;
    uint private constant powerAcc = 1012;
    uint private constant maxAcc = 2;

    uint public TVL;

    DataTypes.PoolInfo public pool;
    DataTypes.DaoDebt public daoDebt;
    mapping(uint => DataTypes.UnionsInfo) public unionsInfo;
    mapping(address => DataTypes.UserInfo) public userInfo;
    mapping(uint => DataTypes.KunInfo) public kunInfo;

    // unions => members,  user address list
    mapping(uint => address[]) internal unionsMembers;
    // user => kunId, how many nft-721A is deposited
    mapping(address => uint[]) internal kunIdList;
    // nft-721 base power
    mapping(uint => uint) public baseNftPower;
    // President
    mapping(address => uint) public unionOwner;

    // 1.1
    uint public daoX;
    mapping(uint => uint) public cardIdLv;

    // event
    event UploadUnion(
        address indexed user,
        uint indexed topUnionId,
        uint indexed unionId
    );

    event UnionLv(uint indexed uid, uint indexed lv);

    event UpgradeUnion(
        address indexed user,
        uint indexed uid,
        uint indexed toCardId
    );

    event JoinUnion(address indexed user, uint indexed unionsId);

    event Deposit(
        address indexed user,
        uint indexed tokenId,
        uint indexed inPower
    );
    event Claim(
        address indexed user,
        uint indexed unionId,
        uint indexed amount
    );
    event Withdraw(
        address indexed user,
        uint indexed tokenId,
        uint indexed dePower
    );

    event ClaimTax(
        address indexed user,
        uint indexed unionId,
        uint indexed amount
    );
    event ClaimGeTax(
        address indexed user,
        uint indexed unionId,
        uint indexed amount
    );
    event ClaimDao(
        address indexed user,
        uint indexed unionId,
        uint indexed amount
    );

    // init
    function init() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();

        pool.dayOut = 500000 ether;
        tax = [5, 20, 40, 60];
        dao = [5, 10, 15];
        daoX = 50;
        WALLET = msg.sender;
        USDT = 0x2E3C4B127DD7E9a63Ba001Dd924e5078D09b4a1F;
        MSW = 0x2E8b02719E4FF2E5C0e7a82A20dC1aBe19FcAF62;
        unions = IMSW(0x1bcbf20E1e5fF9cd61F3B81bd2A378a7747865CC);
        kun = IMA(0x64F1B3E0AB06B6C36d4685Eb218608Cc25E671A1);
        baseNftPower[1] = 500;
        baseNftPower[0] = 200;
        cardIdLv[10001] = 1;
        cardIdLv[10002] = 2;
        cardIdLv[10003] = 3;
        // setStatus(true);
    }

    modifier isStart() {
        require(pool.status, "not start!");
        _;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    // dev
    function setStatus(bool b) public onlyOwner {
        if (pool.startTime == 0) {
            pool.startTime = block.timestamp;
        }
        pool.status = b;
    }

    function setDaoDebt(uint uid_) public onlyOwner {
        (uint _debt, ) = updateDaoDebt();
        unionsInfo[uid_].daoDebt = _debt;
    }

    function setTax(uint[4] memory tax_) public onlyOwner {
        tax = tax_;
    }

    function setDao(uint[3] memory dao_) public onlyOwner {
        dao = dao_;
    }

    function setPooldayOut(uint dayOut_) public onlyOwner {
        updatePool();
        pool.dayOut = dayOut_;
    }

    function setUnions(address unions_) public onlyOwner {
        unions = IMSW(unions_);
    }

    function setCardIdLv(
        uint[] calldata cardId_,
        uint[] calldata lv_
    ) public onlyOwner {
        for (uint i; i < cardId_.length; i++) {
            cardIdLv[cardId_[i]] = lv_[i];
        }
    }

    function setDaoX(uint daoX_) public onlyOwner {
        daoX = daoX_;
    }

    function setKun(address kun_) public onlyOwner {
        kun = IMA(kun_);
    }

    function setToken(address usdt_, address msw_) public onlyOwner {
        USDT = usdt_;
        MSW = msw_;
    }

    function setWallet(address wallet_) public onlyOwner {
        WALLET = wallet_;
    }

    function setBaseNftPower(
        uint[] calldata cardId_,
        uint[] calldata power_
    ) public onlyOwner {
        for (uint i; i < cardId_.length; i++) {
            baseNftPower[cardId_[i]] = power_[i];
        }
    }

    function setTopUnions(uint topUnionId_, uint unionId_) public onlyOwner {
        require(
            unionsInfo[topUnionId_].topUnions != 0 &&
                unionsInfo[topUnionId_].owner != address(0) &&
                topUnionId_ != unionId_,
            "topUnion illegal!"
        );
        require(unionsInfo[unionId_].owner != address(0), "union not found!");
        unionsInfo[unionId_].topUnions = topUnionId_;
        unionsInfo[topUnionId_].subUnions.push(unionId_);
    }

    // Unions ---------------------------------------------------------------------------------------------
    function uploadUnion(
        uint topUnionId_,
        uint unionId_
    ) public returns (bool) {
        require(unionId_ != 0, "unionId illegal!");
        require(unionOwner[msg.sender] == 0, "already upload union!");
        if (topUnionId_ != sytemUnions) {
            require(
                unionsInfo[topUnionId_].topUnions != 0 &&
                    unionsInfo[topUnionId_].owner != address(0) &&
                    topUnionId_ != unionId_,
                "topUnion illegal!"
            );
        }

        // card
        (, , uint _lv, , ) = unions.cardInfoes(unions.cardIdMap(unionId_));
        unions.safeTransferFrom(msg.sender, address(this), unionId_);

        // update union+
        (uint _debt, ) = updateDaoDebt();
        unionOwner[msg.sender] = unionId_;
        unionsInfo[unionId_] = DataTypes.UnionsInfo({
            owner: msg.sender,
            lv: _lv,
            unionId: unionId_,
            topUnions: topUnionId_,
            members: 0,
            subUnions: new uint[](0),
            tax: 0,
            taxDebt: 0,
            geTax: 0,
            geTaxDebt: 0,
            dao: 0,
            daoToClaim: 0,
            daoDebt: _debt
        });

        if (topUnionId_ != sytemUnions) {
            unionsInfo[topUnionId_].subUnions.push(unionId_);
        }

        // update dao
        daoDebt.totalDao += dao[_lv - 1];

        emit UnionLv(unionId_, _lv);
        emit UploadUnion(msg.sender, topUnionId_, unionId_);

        return true;
    }

    function upgradeUnion(uint uid_, uint toCardId_) public {
        require(msg.sender == unionsInfo[uid_].owner, "not owner!");
        uint _lv = checkUnionLv(uid_);
        uint toLv = cardIdLv[toCardId_];
        require(_lv < 3, "already max lv!");
        uint diff;

        {
            uint price1 = nftPrice(unions.cardIdMap(uid_));
            uint price2 = nftPrice(toCardId_);
            diff = price2 - price1;
        }

        IERC20(USDT).transferFrom(msg.sender, address(this), diff);
        IERC20(USDT).approve(address(unions), diff);

        unions.upgrade(uid_, toCardId_);

        upgradeProcess(uid_, toLv, _lv);

        emit UpgradeUnion(msg.sender, uid_, toCardId_);
    }

    function nftPrice(uint cardId_) internal view returns (uint) {
        (, , , uint price, ) = unions.cardInfoes(cardId_);
        return price;
    }

    // unions upgrade logic
    function upgradeProcess(uint uid_, uint toLv, uint oldLv) internal {
        uint _bonus = updateDaoBonus(uid_);

        // update global dao
        (uint _debt, uint _day) = updateDaoDebt();

        // update dao info
        daoDebt.totalDao += (dao[toLv - 1] - dao[oldLv - 1]);
        daoDebt.debt = _debt;

        if (daoDebt.updateDays < _day) {
            daoDebt.updateDays = _day;
        }

        // update unions dao
        unionsInfo[uid_].daoToClaim += _bonus;
        unionsInfo[uid_].daoDebt = daoDebt.debt;
        unionsInfo[uid_].lv = toLv;
    }

    function joinUnion(uint unionsId_) public isStart {
        require(unionsInfo[unionsId_].owner != address(0), "not found unions!");
        require(userInfo[msg.sender].unionsId == 0, "already join unions!");
        userInfo[msg.sender].unionsId = unionsId_;
        unionsInfo[unionsId_].members += 1;
        unionsMembers[unionsId_].push(msg.sender);
        emit JoinUnion(msg.sender, unionsId_);
    }

    // User ---------------------------------------------------------------------------------------------------------------
    function updateDebt() internal view returns (uint _debt) {
        uint _rate = pool.dayOut / 1 days;
        _debt = pool.totalPower > 0
            ? (_rate * (block.timestamp - pool.lastRewardTime) * ACC) /
                pool.totalPower +
                pool.globalDebt
            : 0 + pool.globalDebt;
    }

    function updateReward(address user_) internal view returns (uint _reward) {
        DataTypes.UserInfo storage user = userInfo[user_];
        uint _debt = updateDebt();
        _reward = user.power > 0 ? (user.power * (_debt - user.debt)) / ACC : 0;
    }

    function getPower(uint power_) public view returns (uint finalPower) {
        uint _day = (block.timestamp - pool.startTime) / 1 days;

        if (_day > 58) {
            finalPower = power_ * maxAcc;
            return finalPower;
        }

        finalPower = power_;
        for (uint i = 0; i < _day; i++) {
            finalPower = (finalPower * powerAcc) / 1000;
        }
    }

    function getKunId(uint tid_) internal view returns (uint cid_) {
        // 1: blue , 0: green
        (cid_, , ) = kun.characters(tid_);
    }

    // stake nft-721A in pool
    function deposit(uint unionsId_, uint[] calldata kunId_) public isStart {
        DataTypes.UserInfo storage user = userInfo[msg.sender];
        require(
            unionsInfo[unionsId_].owner != address(0) && unionsId_ != 0,
            "not found unions!"
        );
        if (user.unionsId == 0) {
            joinUnion(unionsId_);
        }

        // update user toClaim
        if (user.power != 0) {
            user.toClaim += updateReward(msg.sender);
        }
        for (uint i; i < kunId_.length; i++) {
            // update user this stake power
            uint _power = baseNftPower[getKunId(kunId_[i])];
            _power = getPower(_power);

            // update global
            updatePool();
            TVL += _power;
            pool.totalPower += _power;

            // update user
            user.power += _power;
            user.lastTime = block.timestamp;
            user.debt = pool.globalDebt;

            // update card
            kunInfo[kunId_[i]] = DataTypes.KunInfo({
                owner: msg.sender,
                kunId: kunId_[i],
                kunPower: _power,
                depositTime: block.timestamp
            });
            kunIdList[msg.sender].push(kunId_[i]);

            // kun
            kun.safeTransferFrom(msg.sender, address(this), kunId_[i]);
            emit Deposit(msg.sender, unionsId_, kunId_[i]);
        }
    }

    // claim
    function claim() public isStart {
        DataTypes.UserInfo storage user = userInfo[msg.sender];
        require(user.power > 0, "not found power!");
        require(user.unionsId != 0, "not found unions!");

        uint _reward = updateReward(msg.sender);
        if (user.toClaim > 0) {
            _reward += user.toClaim;
            user.toClaim = 0;
        }

        if (_reward > 0) {
            //user
            uint _debt = updateDebt();
            user.claimed += _reward;
            user.debt = _debt;
            user.lastTime = block.timestamp;

            //global
            pool.totalClaimed += _reward;

            // tax
            if (user.unionsId != sytemUnions) {
                taxProcess(msg.sender, _reward);
            }

            // transfer
            IERC20(MSW).transfer(msg.sender, _reward);
            emit Claim(msg.sender, user.unionsId, _reward);
        }
    }

    // unstake nft-721A from pool
    function withdraw(uint kunID_) public isStart {
        require(kunInfo[kunID_].owner == msg.sender, "not your kun!");

        // global
        updatePool();
        //user
        claim();
        processWithdraw(msg.sender, kunID_);
    }

    function withdrawAll() public isStart {
        // global
        updatePool();
        //user
        claim();
        uint[] memory _kunIdList = kunIdList[msg.sender];
        for (uint i; i < _kunIdList.length; i++) {
            processWithdraw(msg.sender, _kunIdList[i]);
        }
    }

    // logic process -----------------------------------------------------------------------------------------------

    // Update reward variables of the pool to be up-to-date. debt & time
    function updatePool() internal {
        if (!pool.status) {
            return;
        }

        if (pool.totalPower == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }

        uint _debt = updateDebt();
        pool.globalDebt = _debt;
        pool.lastRewardTime = block.timestamp;
    }

    function processWithdraw(address user_, uint kunId_) internal {
        DataTypes.UserInfo storage user = userInfo[user_];
        uint _power = kunInfo[kunId_].kunPower;

        // power
        pool.totalPower -= _power;
        user.power -= _power;

        // info
        kunInfo[kunId_] = DataTypes.KunInfo({
            owner: address(0),
            kunId: 0,
            kunPower: 0,
            depositTime: 0
        });

        // card transfer
        kun.safeTransferFrom(address(this), user_, kunId_);

        // withdraw
        uint _index;
        uint _length = kunIdList[user_].length;
        for (uint i = 0; i < _length; i++) {
            if (kunIdList[user_][i] == kunId_) {
                _index = i;
                break;
            }
        }
        kunIdList[user_][_index] = kunIdList[user_][_length - 1];
        kunIdList[user_].pop();

        emit Withdraw(user_, kunId_, _power);
    }

    // tax process -----------------------------------------------------------------------------------------------
    function taxProcess(address user_, uint amount_) internal {
        uint _tax;
        uint _lv;
        uint _thisId = userInfo[user_].unionsId;

        // first tax
        _tax = (amount_ * tax[unionsInfo[_thisId].lv]) / 1000;
        unionsInfo[_thisId].taxDebt += _tax;
        _lv = unionsInfo[_thisId].lv;

        // 3 generations tax
        if (unionsInfo[_thisId].topUnions != sytemUnions) {
            bool isFlat;
            uint topId;
            for (uint i = 0; i < 3; i++) {
                topId = unionsInfo[_thisId].topUnions;
                if (unionsInfo[topId].lv > _lv) {
                    _tax =
                        (amount_ * (tax[unionsInfo[topId].lv] - tax[_lv])) /
                        1000;
                    unionsInfo[topId].geTaxDebt += _tax;
                    _thisId = topId;
                    _lv = unionsInfo[topId].lv;
                    isFlat = false;
                } else if (!isFlat && unionsInfo[topId].lv == _lv) {
                    _tax = (amount_ * tax[0]) / 1000;
                    unionsInfo[topId].geTaxDebt += _tax;
                    _thisId = topId;
                    isFlat = true;
                } else {
                    _thisId = topId;
                    continue;
                }
            }
        }
    }

    function checkTax(uint uid_) public view returns (uint _tax) {
        _tax = unionsInfo[uid_].taxDebt > unionsInfo[uid_].tax
            ? unionsInfo[uid_].taxDebt - unionsInfo[uid_].tax
            : 0;
    }

    function claimTax() public isStart {
        uint uid_ = unionOwner[msg.sender];
        require(uid_ != 0, "not found unions!");
        require(msg.sender == unionsInfo[uid_].owner, "not owner!");
        require(unionsInfo[uid_].taxDebt > 0, "not found tax!");
        uint _tax = checkTax(uid_);
        if (_tax != 0) {
            unionsInfo[uid_].tax += _tax;

            IERC20(MSW).transfer(msg.sender, _tax);
            emit ClaimTax(msg.sender, unionOwner[msg.sender], _tax);
        }
    }

    function checkGeTax(uint uid_) public view returns (uint _tax) {
        _tax = unionsInfo[uid_].geTaxDebt > unionsInfo[uid_].geTax
            ? unionsInfo[uid_].geTaxDebt - unionsInfo[uid_].geTax
            : 0;
    }

    function claimGeTax() public isStart {
        uint uid_ = unionOwner[msg.sender];
        require(uid_ != 0, "not found unions!");
        require(msg.sender == unionsInfo[uid_].owner, "not owner!");
        require(unionsInfo[uid_].geTaxDebt > 0, "not found tax!");
        uint _tax = checkGeTax(uid_);
        if (_tax != 0) {
            unionsInfo[uid_].tax += _tax;

            IERC20(MSW).transfer(msg.sender, _tax);
            emit ClaimGeTax(msg.sender, unionOwner[msg.sender], _tax);
        }
    }

    // dao logic -----------------------------------------------------------------------------------------------
    function updateDaoDebt() public view returns (uint _debt, uint thisDay) {
        if (pool.startTime != 0) {
            thisDay = (block.timestamp - pool.startTime) / 1 days;

            if (thisDay != daoDebt.updateDays) {
                uint amount = pool.dayOut;
                _debt = daoDebt.totalDao > 0
                    ? (((amount * (thisDay - daoDebt.updateDays) * daoX) /
                        1000) / daoDebt.totalDao) + daoDebt.debt
                    : 0;
                return (_debt, thisDay);
            } else {
                _debt = daoDebt.debt;
                thisDay = daoDebt.updateDays;
            }
        }
    }

    function updateDaoBonus(uint uid_) public view returns (uint _bonus) {
        uint x = dao[unionsInfo[uid_].lv - 1];
        (uint _debt, ) = updateDaoDebt();

        if (_debt != 0) {
            _bonus = unionsInfo[uid_].daoDebt < _debt
                ? (_debt - unionsInfo[uid_].daoDebt) * x
                : 0;
        }
    }

    function checkDaoBonus(uint uid_) public view returns (uint _bonus) {
        _bonus = unionsInfo[uid_].daoToClaim + updateDaoBonus(uid_);
    }

    function claimDaoBonus(uint uid_) public {
        require(msg.sender == unionsInfo[uid_].owner, "not owner!");
        (uint _debt, uint _day) = updateDaoDebt();

        // calculate bonus
        uint _bonus = updateDaoBonus(uid_);
        if (unionsInfo[uid_].daoToClaim > 0) {
            _bonus += unionsInfo[uid_].daoToClaim;
            unionsInfo[uid_].daoToClaim = 0;
        }

        // update dao info
        if (daoDebt.updateDays < _day) {
            daoDebt.debt = _debt;
            daoDebt.updateDays = _day;
        }

        if (_bonus > 0) {
            unionsInfo[uid_].daoDebt = daoDebt.debt;
            unionsInfo[uid_].dao += _bonus;

            IERC20(MSW).transfer(msg.sender, _bonus);
            emit ClaimDao(msg.sender, unionOwner[msg.sender], _bonus);
        }
    }

    // check -----------------------------------------------------------------------------------------------
    // union
    function checkUnionOwner(uint unionsId_) public view returns (address) {
        return unionsInfo[unionsId_].owner;
    }

    function checkUnionLv(uint unionsId_) public view returns (uint) {
        return unionsInfo[unionsId_].lv;
    }

    function checkSubUnions(
        uint unionsId_
    ) public view returns (uint[] memory) {
        return unionsInfo[unionsId_].subUnions;
    }

    function checkTopUnions(uint unionsId_) public view returns (uint) {
        return unionsInfo[unionsId_].topUnions;
    }

    function checkUnionsMembers(
        uint unionsId_
    ) public view returns (address[] memory) {
        return unionsMembers[unionsId_];
    }

    // user
    function checkUserUnions(address user_) public view returns (uint) {
        return userInfo[user_].unionsId;
    }

    function checkUserPower(address user_) public view returns (uint) {
        return userInfo[user_].power;
    }

    function checkUserReward(address user_) public view returns (uint) {
        return userInfo[user_].toClaim + updateReward(user_);
    }

    function checkUserKunIdList(
        address user_
    ) public view returns (uint[] memory) {
        return kunIdList[user_];
    }
}