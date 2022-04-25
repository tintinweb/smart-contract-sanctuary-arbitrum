// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
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
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

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
 * ```
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
 */
library EnumerableSetUpgradeable {
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
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
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
            set._indexes[value] = set._values.length;
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
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./UtilitiesUpgradeable.sol";

// Do not add state to this contract.
//
contract AdminableUpgradeable is UtilitiesUpgradeable {

    mapping(address => bool) private admins;

    function __Adminable_init() internal initializer {
        UtilitiesUpgradeable.__Utilities__init();
    }

    function addAdmin(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function addAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = true;
        }
    }

    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function removeAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = false;
        }
    }

    function setPause(bool _shouldPause) external onlyAdminOrOwner {
        if(_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function isAdmin(address _address) public view returns(bool) {
        return admins[_address];
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(admins[msg.sender] || isOwner(), "Not admin or owner");
        _;
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract UtilitiesUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable {

    function __Utilities__init() internal initializer {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();

        _pause();
    }

    modifier nonZeroAddress(address _address) {
        require(address(0) != _address, "0 address");
        _;
    }

    modifier nonZeroLength(uint[] memory _array) {
        require(_array.length > 0, "Empty array");
        _;
    }

    modifier lengthsAreEqual(uint[] memory _array1, uint[] memory _array2) {
        require(_array1.length == _array2.length, "Unequal lengths");
        _;
    }

    modifier onlyEOA() {
        /* solhint-disable avoid-tx-origin */
        require(msg.sender == tx.origin, "No contracts");
        _;
    }

    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomizer {

    // Sets the number of blocks that must pass between increment the commitId and seeding the random
    // Admin
    function setNumBlocksAfterIncrement(uint8 _numBlocksAfterIncrement) external;

    // Increments the commit id.
    // Admin
    function incrementCommitId() external;

    // Adding the random number needs to be done AFTER incrementing the commit id on a separate transaction. If
    // these are done together, there is a potential vulnerability to front load a commit when the bad actor
    // sees the value of the random number.
    function addRandomForCommit(uint256 _seed) external;

    // Returns a request ID for a random number. This is unique.
    function requestRandomNumber() external returns(uint256);

    // Returns the random number for the given request ID. Will revert
    // if the random is not ready.
    function revealRandomNumber(uint256 _requestId) external view returns(uint256);

    // Returns if the random number for the given request ID is ready or not. Call
    // before calling revealRandomNumber.
    function isRandomReady(uint256 _requestId) external view returns(bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./AdventureSettings.sol";

contract Adventure is Initializable, AdventureSettings {

     using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    function initialize() external initializer {
        AdventureSettings.__AdventureSettings_init();
    }

    // Comes from World.
    function startAdventure(
        address _owner,
        uint256 _tokenId,
        string calldata _adventureName,
        uint256[] calldata _itemInputIds)
    external
    override
    whenNotPaused
    onlyAdminOrOwner
    {
        _startAdventure(_owner, _tokenId, _adventureName, _itemInputIds);
    }

    // Comes from World.
    function finishAdventure(
        address _owner,
        uint256 _tokenId)
    external
    override
    whenNotPaused
    onlyAdminOrOwner
    {
        _finishAdventure(_owner, _tokenId);
    }

    // Comes from end user
    function restartAdventuring(
        uint256[] calldata _tokenIds,
        string calldata _adventureName,
        uint256[][] calldata _itemInputIds)
    external
    onlyEOA
    whenNotPaused
    nonZeroLength(_tokenIds)
    {
        require(_tokenIds.length == _itemInputIds.length, "Adventure: Bad array lengths");

        // Ensure token is owned by caller.
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            require(world.ownerForStakedToad(_tokenIds[i]) == msg.sender,
                "Adventure: User does not own toad");

            _finishAdventure(msg.sender, _tokenIds[i]);
            _startAdventure(msg.sender, _tokenIds[i], _adventureName, _itemInputIds[i]);
        }
    }

    function _startAdventure(
        address _owner,
        uint256 _tokenId,
        string calldata _adventureName,
        uint256[] calldata _itemInputIds)
    private
    {
        require(isKnownAdventure(_adventureName), "Adventure: Unknown adventure");

        AdventureInfo storage _adventureInfo = nameToAdventureInfo[_adventureName];

        require(block.timestamp >= _adventureInfo.adventureStart,
            "Adventure: Adventure has not started");
        require(_adventureInfo.adventureStop == 0 || block.timestamp < _adventureInfo.adventureStop,
            "Adventure: Adventure has ended");
        require(_adventureInfo.maxTimesPerToad == 0 || tokenIdToNameToCount[_tokenId][_adventureName] < _adventureInfo.maxTimesPerToad,
            "Adventure: Toad has reached max times for this adventure");
        require(_adventureInfo.maxTimesGlobally == 0 || _adventureInfo.currentTimesGlobally < _adventureInfo.maxTimesGlobally,
            "Adventure: Adventure has reached max times globally");
        require(_adventureInfo.isInputRequired.length == _itemInputIds.length,
            "Adventure: Incorrect number of inputs");

        // Set toad start time/length
        tokenIdToToadAdventureInfo[_tokenId].adventureName = _adventureName;
        tokenIdToToadAdventureInfo[_tokenId].startTime = block.timestamp;

        // Request random
        uint256 _requestId = randomizer.requestRandomNumber();
        tokenIdToToadAdventureInfo[_tokenId].requestId = _requestId;

        // Increment global/toad counts
        _adventureInfo.currentTimesGlobally++;
        tokenIdToNameToCount[_tokenId][_adventureName]++;

        uint256 _bugzReduction;

        // Save off inputs and transfer items
        (tokenIdToToadAdventureInfo[_tokenId].timeReduction,
            _bugzReduction,
            tokenIdToToadAdventureInfo[_tokenId].chanceOfSuccessChange) = _handleTransferringInputs(
            _itemInputIds,
            _adventureInfo,
            _adventureName,
            _owner,
            _tokenId);

        _handleTransferringBugz(
            _bugzReduction,
            _adventureInfo,
            _tokenId,
            _owner);

        emit AdventureStarted(
            _tokenId,
            _adventureName,
            _requestId,
            block.timestamp,
            _adventureEndTime(_tokenId),
            _chanceOfSuccess(_tokenId),
            _itemInputIds);
    }

    function _handleTransferringBugz(
        uint256 _bugzReduction,
        AdventureInfo storage _adventureInfo,
        uint256 _tokenId,
        address _owner)
    private
    {
        uint256 _bugzCost = _bugzReduction >= _adventureInfo.bugzCost
            ? 0
            : _adventureInfo.bugzCost - _bugzReduction;

        tokenIdToToadAdventureInfo[_tokenId].bugzSpent = _bugzCost;

        // Burn bugz
        if(_bugzCost > 0) {
            bugz.burn(_owner, _bugzCost);
        }
    }

    function _handleTransferringInputs(
        uint256[] calldata _itemInputIds,
        AdventureInfo storage _adventureInfo,
        string calldata _adventureName,
        address _owner,
        uint256 _tokenId)
    private
    returns(uint256 _timeReduction, uint256 _bugzReduction, int256 _chanceOfSuccessChange)
    {
        for(uint256 i = 0; i < _itemInputIds.length; i++) {
            uint256 _itemId = _itemInputIds[i];

            if(_itemId == 0 && !_adventureInfo.isInputRequired[i]) {
                continue;
            } else if(_itemId == 0) {
                revert("Adventure: Input is required");
            } else {
                require(nameToInputIndexToInputInfo[_adventureName][i].itemIds.contains(_itemId),
                    "Adventure: Incorrect input");

                uint256 _quantity = nameToInputIndexToInputInfo[_adventureName][i].itemIdToQuantity[_itemId];

                itemz.burn(_owner, _itemId, _quantity);

                tokenIdToToadAdventureInfo[_tokenId].inputItemIds.add(_itemId);
                tokenIdToToadAdventureInfo[_tokenId].inputIdToQuantity[_itemId] = _quantity;

                _timeReduction += nameToInputIndexToInputInfo[_adventureName][i].itemIdToTimeReduction[_itemId];
                _chanceOfSuccessChange += nameToInputIndexToInputInfo[_adventureName][i].itemIdToChanceOfSuccessChange[_itemId];
                _bugzReduction += nameToInputIndexToInputInfo[_adventureName][i].itemIdToBugzReduction[_itemId];
            }
        }
    }

    function _finishAdventure(
        address _owner,
        uint256 _tokenId)
    private
    {
        ToadAdventureInfo storage _toadAdventureInfo = tokenIdToToadAdventureInfo[_tokenId];

        require(_toadAdventureInfo.startTime > 0, "Adventure: Toad is not adventuring");

        AdventureInfo storage _adventureInfo = nameToAdventureInfo[_toadAdventureInfo.adventureName];

        require(block.timestamp >= _adventureEndTime(_tokenId),
            "Adventure: Toad is not done adventuring");

        require(randomizer.isRandomReady(_toadAdventureInfo.requestId),
            "Adventure: Random is not ready");

        // Prevents re-entrance, just in case
        delete _toadAdventureInfo.startTime;

        uint256 _randomNumber = randomizer.revealRandomNumber(_toadAdventureInfo.requestId);

        uint256 _successResult = _randomNumber % 100000;

        uint256 _rewardItemId;
        uint256 _rewardQuantity;

        bool _wasAdventureSuccess = _successResult < _chanceOfSuccess(_tokenId);

        if(_wasAdventureSuccess) {
            // Success!
            // Fresh random
            _randomNumber = uint256(keccak256(abi.encode(_randomNumber, _randomNumber)));

            (_rewardItemId, _rewardQuantity) = _handleAdventureSuccess(
                _randomNumber,
                _adventureInfo,
                _toadAdventureInfo,
                _owner);
        } else {
            // Failure!

            _handleAdventureFailure(
                _adventureInfo,
                _toadAdventureInfo,
                _owner);
        }

        // Clear out data
        uint256[] memory _oldInputItemIds = _toadAdventureInfo.inputItemIds.values();
        for(uint256 i = 0; i < _oldInputItemIds.length; i++) {
            _toadAdventureInfo.inputItemIds.remove(_oldInputItemIds[i]);
        }

        // Badgez! May have badgez for failure case, so check either way.
        _addBadgezIfNeeded(_owner);

        emit AdventureEnded(
            _tokenId,
            _wasAdventureSuccess,
            _rewardItemId,
            _rewardQuantity);
    }

    function _handleAdventureSuccess(
        uint256 _randomNumber,
        AdventureInfo storage _adventureInfo,
        ToadAdventureInfo storage _toadAdventureInfo,
        address _owner)
    private
    returns(uint256, uint256)
    {
        uint256 _rewardResult = _randomNumber % 100000;
        uint256 _topRange = 0;

        // Figure out adventure rewards
        for(uint256 i = 0; i < _adventureInfo.rewardOptions.length; i++) {

            RewardOption storage _rewardOption = _adventureInfo.rewardOptions[i];

            int256 _odds = _rewardOption.baseOdds;
            if(_toadAdventureInfo.inputItemIds.contains(_rewardOption.boostItemId)) {
                _odds += _rewardOption.boostAmount;
            }
            require(_odds >= 0, "Adventure: Bad odds!");

            _topRange += uint256(_odds);

            if(_rewardResult < _topRange) {
                if(_rewardOption.itemId > 0 && _rewardOption.rewardQuantity > 0) {
                    itemz.mint(_owner, _rewardOption.itemId, _rewardOption.rewardQuantity);
                    userToRewardIdToCount[_owner][_rewardOption.itemId] += _rewardOption.rewardQuantity;
                }

                if(_rewardOption.badgeId > 0) {
                    badgez.mintIfNeeded(_owner, _rewardOption.badgeId);
                }

                return (_rewardOption.itemId, _rewardOption.rewardQuantity);
            }
        }

        return (0, 0);
    }

    function _handleAdventureFailure(
        AdventureInfo storage _adventureInfo,
        ToadAdventureInfo storage _toadAdventureInfo,
        address _owner)
    private
    {
        if(_adventureInfo.bugzReturnedOnFailure && _toadAdventureInfo.bugzSpent > 0) {
            bugz.mint(_owner, _toadAdventureInfo.bugzSpent);
        }
    }

    function _addBadgezIfNeeded(
        address _owner)
    private
    {
        uint256 _log1Count = userToRewardIdToCount[_owner][log1Id];
        uint256 _log2Count = userToRewardIdToCount[_owner][log2Id];
        uint256 _log3Count = userToRewardIdToCount[_owner][log3Id];
        uint256 _log4Count = userToRewardIdToCount[_owner][log4Id];
        uint256 _log5Count = userToRewardIdToCount[_owner][log5Id];

        if(_log1Count > 0
            && _log2Count > 0
            && _log3Count > 0
            && _log4Count > 0
            && _log5Count > 0)
        {
            badgez.mintIfNeeded(_owner, allLogTypesBadgeId);
        }
    }

    function _chanceOfSuccess(uint256 _tokenId) private view returns(uint256) {
        ToadAdventureInfo storage _toadAdventureInfo = tokenIdToToadAdventureInfo[_tokenId];
        AdventureInfo storage _adventureInfo = nameToAdventureInfo[_toadAdventureInfo.adventureName];

        int256 _chanceSuccess = int256(_adventureInfo.chanceSuccess) + _toadAdventureInfo.chanceOfSuccessChange;
        if(_chanceSuccess <= 0) {
            return 0;
        } else if(_chanceSuccess >= 100000) {
            return 100000;
        } else {
            return uint256(_chanceSuccess);
        }
    }

    function _adventureEndTime(uint256 _tokenId) private view returns(uint256) {
        ToadAdventureInfo storage _toadAdventureInfo = tokenIdToToadAdventureInfo[_tokenId];
        AdventureInfo storage _adventureInfo = nameToAdventureInfo[_toadAdventureInfo.adventureName];

        return _toadAdventureInfo.startTime + _adventureInfo.lengthForToad - _toadAdventureInfo.timeReduction;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./AdventureState.sol";

abstract contract AdventureContracts is Initializable, AdventureState {

    function __AdventureContracts_init() internal initializer {
        AdventureState.__AdventureState_init();
    }

    function setContracts(
        address _randomizerAddress,
        address _itemzAddress,
        address _bugzAddress,
        address _badgezAddress,
        address _worldAddress)
    external onlyAdminOrOwner
    {
        randomizer = IRandomizer(_randomizerAddress);
        itemz = IItemz(_itemzAddress);
        bugz = IBugz(_bugzAddress);
        badgez = IBadgez(_badgezAddress);
        world = IWorld(_worldAddress);
    }

    modifier contractsAreSet() {
        require(areContractsSet(), "Adventure: Contracts aren't set");
        _;
    }

    function areContractsSet() public view returns(bool) {
        return address(randomizer) != address(0)
            && address(itemz) != address(0)
            && address(bugz) != address(0)
            && address(badgez) != address(0)
            && address(world) != address(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./AdventureContracts.sol";

abstract contract AdventureSettings is Initializable, AdventureContracts {

     using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    function __AdventureSettings_init() internal initializer {
        AdventureContracts.__AdventureContracts_init();
    }

    function addAdventure(
        string calldata _name,
        AdventureInfo calldata _adventureInfo,
        InputItem[] calldata _inputItems)
    external
    onlyAdminOrOwner
    {
        require(!isKnownAdventure(_name), "Adventure: Adventure already known");
        require(_adventureInfo.isInputRequired.length == _inputItems.length, "Adventure: Bad array lengths");

        nameToAdventureInfo[_name] = _adventureInfo;

        for(uint256 i = 0; i < _inputItems.length; i++) {
            require(_inputItems[i].itemOptions.length > 0, "Adventure: Bad array lengths");

            for(uint256 j = 0; j < _inputItems[i].itemOptions.length; j++) {

                uint256 _itemId = _inputItems[i].itemOptions[j].itemId;

                nameToInputIndexToInputInfo[_name][i].itemIds.add(_itemId);
                nameToInputIndexToInputInfo[_name][i].itemIdToQuantity[_itemId] = _inputItems[i].itemOptions[j].quantity;
                nameToInputIndexToInputInfo[_name][i].itemIdToTimeReduction[_itemId] = _inputItems[i].itemOptions[j].timeReduction;
                nameToInputIndexToInputInfo[_name][i].itemIdToBugzReduction[_itemId] = _inputItems[i].itemOptions[j].bugzReduction;
                nameToInputIndexToInputInfo[_name][i].itemIdToChanceOfSuccessChange[_itemId] = _inputItems[i].itemOptions[j].chanceOfSuccessChange;
            }
        }

        emit AdventureAdded(_name, _adventureInfo, _inputItems);
    }

    function isKnownAdventure(string calldata _name) public view returns(bool) {
        return nameToAdventureInfo[_name].adventureStart != 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../../shared/randomizer/IRandomizer.sol";
import "../../shared/AdminableUpgradeable.sol";
import "../itemz/IItemz.sol";
import "../bugz/IBugz.sol";
import "../badgez/IBadgez.sol";
import "../world/IWorld.sol";
import "./IAdventure.sol";

abstract contract AdventureState is Initializable, IAdventure, AdminableUpgradeable {

    // Used for the AdventureAddedEvent and as a function parameter
    struct InputItem {
        InputItemOption[] itemOptions;
    }

    struct InputItemOption {
        uint256 itemId;
        uint256 quantity;
        uint256 timeReduction;
        uint256 bugzReduction;
        int256 chanceOfSuccessChange;
    }

    event AdventureAdded(
        string _name,
        AdventureInfo _adventureInfo,
        InputItem[] _inputItems);

    event AdventureStarted(
        uint256 _tokenId,
        string _adventureName,
        uint256 _requestId,
        uint256 _startTime,
        uint256 _estimatedEndTime,
        uint256 _chanceOfSuccess,
        uint256[] _itemInputIds);

    event AdventureEnded(
        uint256 _tokenId,
        bool _succeeded,
        uint256 _rewardItemId,
        uint256 _rewardQuantity);

    IRandomizer public randomizer;
    IItemz public itemz;
    IBugz public bugz;
    IBadgez public badgez;
    IWorld public world;

    mapping(string => AdventureInfo) public nameToAdventureInfo;
    mapping(string => mapping(uint256 => InputInfo)) internal nameToInputIndexToInputInfo;

    mapping(uint256 => ToadAdventureInfo) internal tokenIdToToadAdventureInfo;
    // Keeps track of how many times a given toad has gone on an adventure.
    mapping(uint256 => mapping(string => uint256)) public tokenIdToNameToCount;

    mapping(address => mapping(uint256 => uint256)) public userToRewardIdToCount;

    uint256 public allLogTypesBadgeId;

    uint256 public log1Id;
    uint256 public log2Id;
    uint256 public log3Id;
    uint256 public log4Id;
    uint256 public log5Id;

    function __AdventureState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();

        allLogTypesBadgeId = 6;

        log1Id = 3;
        log2Id = 4;
        log3Id = 5;
        log4Id = 6;
        log5Id = 7;
    }
}

struct AdventureInfo {
    // The time that this adventure becomes active.
    uint256 adventureStart;
    // May be 0 if no planned stop date
    uint256 adventureStop;
    uint256 lengthForToad;
    uint256 bugzCost;
    // May be 0 if no max per toad
    uint256 maxTimesPerToad;
    // May be 0 if no max.
    uint256 maxTimesGlobally;
    // The current number of adventures that have been gone on.
    uint256 currentTimesGlobally;
    // The index of these inputs is used to find the different items that will
    // satisify the needs.
    bool[] isInputRequired;
    RewardOption[] rewardOptions;
    // The chance this adventure is a success. Out of 100,000.
    uint256 chanceSuccess;
    bool bugzReturnedOnFailure;
}

struct RewardOption {
    // The item ID of this reward;
    uint256 itemId;
    // The odds that this reward is picked out of 100,000
    int256 baseOdds;
    // The amount given out.
    uint256 rewardQuantity;
    // The id used as an input that will boost the odds, one way or another, for this reward option
    uint256 boostItemId;
    // The amount, positive or negative, that will change the baseOdds if the boostItemId was used as the input
    int256 boostAmount;
    // If greater than 0, this badge will be earned on hitting this reward.
    uint256 badgeId;
}

struct InputInfo {
    EnumerableSetUpgradeable.UintSet itemIds;
    mapping(uint256 => uint256) itemIdToQuantity;
    mapping(uint256 => uint256) itemIdToTimeReduction;
    mapping(uint256 => uint256) itemIdToBugzReduction;
    mapping(uint256 => int256) itemIdToChanceOfSuccessChange;
}

// Information about a toadz current adventure.
struct ToadAdventureInfo {
    string adventureName;
    // The start time of the adventure. Used to indicate if a toad is currently on an adventure. To save gas, other fields are not cleared.
    uint256 startTime;
    uint256 requestId;
    uint256 timeReduction;
    int256 chanceOfSuccessChange;
    // The number of bugz spent on this adventure. Only needed if the adventure fails
    // and the bugz are returned on failure.
    uint256 bugzSpent;

    EnumerableSetUpgradeable.UintSet inputItemIds;
    mapping(uint256 => uint256) inputIdToQuantity;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAdventure {

    function startAdventure(address _owner, uint256 _tokenId, string calldata _adventureName, uint256[] calldata _itemInputIds) external;

    function finishAdventure(address _owner, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IBadgez is IERC1155Upgradeable {

    function mintIfNeeded(address _to, uint256 _id) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IBugz is IERC20Upgradeable {

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IItemz is IERC1155Upgradeable {

    function mint(address _to, uint256 _id, uint256 _amount) external;

    function mintBatch(address _to, uint256[] calldata _ids, uint256[] calldata _amounts) external;

    function burn(address _from, uint256 _id, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWorld {

    function ownerForStakedToad(uint256 _tokenId) external view returns(address);

    function locationForStakedToad(uint256 _tokenId) external view returns(Location);

    function balanceOf(address _owner) external view returns (uint256);
}

enum Location {
    NOT_STAKED,
    WORLD,
    HUNTING_GROUNDS,
    ADVENTURE
}