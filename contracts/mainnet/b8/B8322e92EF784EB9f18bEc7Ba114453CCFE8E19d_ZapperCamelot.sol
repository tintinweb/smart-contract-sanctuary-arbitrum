// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ICamelotPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint16 token0feePercent,
            uint16 token1FeePercent
        );

    function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256);

    function kLast() external view returns (uint256);

    function setFeePercent(uint16 token0FeePercent, uint16 token1FeePercent) external;

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data,
        address referrer
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;

    function stableSwap() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

// import UniswapV2Router01

interface ICamelotRouter is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMatrixVault is IERC20 {

    function want() external view returns (address);

    function deposit(uint256) external;

    function withdraw(uint256 _shares) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint);

  function balanceOf(address owner) external view returns (uint);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);

  function transfer(address to, uint value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint);

  function permit(
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint);

  function price1CumulativeLast() external view returns (uint);

  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);

  function burn(address to) external returns (uint amount0, uint amount1);

  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;

  function stable() external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWFTM is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../interfaces/IUniswapV2Pair.sol';
// import "hardhat/console.sol";
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

/// @title Swap Helper to perform swaps and setting routes in matrix strategies
contract MatrixSwapHelper {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public unirouter;

    /// @dev Enumerable set of external tokens and routers
    /// strategy can interact with
    EnumerableSet.AddressSet internal whitelistedAddresses;

    struct SwapPath {
        address unirouter;
        address[] path;
    }

    mapping(bytes32 => SwapPath) internal swapPaths;

    constructor(address _uniRouter) {
        unirouter = _uniRouter;
    }

    function getWhitelistedAddresses() public virtual returns (address[] memory) {
        return whitelistedAddresses.values();
    }

    function getSwapPath(address _fromToken, address _toToken) public view virtual returns (SwapPath memory _swapPath) {
        bytes32 _swapKey = keccak256(abi.encodePacked(_fromToken, _toToken));
        require(swapPaths[_swapKey].unirouter != address(0), 'path-not-found');
        return swapPaths[_swapKey];
    }

    function _setSwapPath(
        address _fromToken,
        address _toToken,
        address _unirouter,
        address[] memory _path
    ) internal virtual {
        require(_path[0] == _fromToken, 'invalid-path');
        require(_path[_path.length - 1] == _toToken, 'invalid-path');
        _checkPath(_path);

        bytes32 _swapKey = keccak256(abi.encodePacked(_fromToken, _toToken));
        address _router = _unirouter == address(0) ? unirouter : _unirouter;

        _checkRouter(_router);

        swapPaths[_swapKey] = SwapPath(_router, _path);
    }

    /// @dev Checks that tokens in path are whitelisted
    /// @notice Override this to skip checks
    function _checkPath(address[] memory _path) internal virtual {
        for (uint256 i; i < _path.length; i++) {
            //console.log(_path[i]);
            require(whitelistedAddresses.contains(_path[i]), 'token-not-whitelisted');
        }
    }

    /// @dev Checks that router for swap is whitelisted
    /// @notice Override this to skip checks
    function _checkRouter(address _router) internal virtual {
        require(whitelistedAddresses.contains(_router), 'router-not-whitelisted');
    }

    function _swap(
        address _fromToken,
        address _toToken,
        uint256 _amount
    ) internal virtual returns (uint256 _toTokenAmount) {
        if (_fromToken == _toToken) return _amount;
        SwapPath memory _swapPath = getSwapPath(_fromToken, _toToken);

        IERC20(_fromToken).safeApprove(_swapPath.unirouter, 0);
        IERC20(_fromToken).safeApprove(_swapPath.unirouter, type(uint256).max);

        // debugging: uncomment this block
        // console.log("router:", _swapPath.unirouter);
        // console.log("_fromToken:", IERC20Metadata(_fromToken).symbol());
        // console.log("_toToken", IERC20Metadata(_toToken).symbol());
        // console.log("_path:");
        // for (uint256 i; i < _swapPath.path.length; i++) {
        //     console.log(_swapPath.path[i]);
        //     console.log(IERC20Metadata(_swapPath.path[i]).symbol());
        // }

        uint256 _toTokenBefore = IERC20(_toToken).balanceOf(address(this));
        IUniswapV2Router02(_swapPath.unirouter).swapExactTokensForTokens(_amount, 0, _swapPath.path, address(this), block.timestamp);

        _toTokenAmount = IERC20(_toToken).balanceOf(address(this)) - _toTokenBefore;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IWFTM.sol";
import "./interfaces/IMatrixVault.sol";
import "./strategies/MatrixSwapHelper.sol";

contract Zapper is MatrixSwapHelper, Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    event DefaultRouterChanged(
        address indexed _oldRouter,
        address indexed _newRouter
    );
    event CustomRouterSet(
        address indexed _lpToken,
        address indexed _customRouter
    );

    event ZapIn(
        address indexed _user,
        address indexed _vault,
        address indexed _want,
        uint256 _amountIn
    );

    event ZapOut(
        address indexed _user,
        address indexed _vault,
        address indexed _want,
        uint256 _amountOut
    );

    string public constant VERSION = "1.2";

    address public WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address internal constant SPOOKYSWAP_ROUTER =
        0xF491e7B69E4244ad4002BC14e878a34207E38c29;

    address internal constant BASED_ROUTER =
        0xaf2098E3AF3AC27a3a9362ACa2D883eFC36c7FAC;
    /// @dev Mapping of LP ERC20 -> Router
    /// In order to support a wider range of UniV2 forks
    mapping(address => address) public customRouter;

    /// @dev Mapping of Factory -> Router to retrieve
    /// the default router for LP token
    mapping(address => address) public factoryToRouter;

    /// @dev Default router for LP Tokens
    address public defaultRouter;

    /// @notice SPOOKYSWAP ROUTER AS DEFAULT FOR LP TOKENS AND SWAPS
    constructor() MatrixSwapHelper(BASED_ROUTER) {
        /// Default router to put LPs in:
        _setDefaultRouter(BASED_ROUTER);

        // Factory to Router
        // spookyswap
        factoryToRouter[
            0x152eE697f2E276fA89E96742e9bB9aB1F2E61bE3
        ] = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;

        // spiritswap
        factoryToRouter[
            0xEF45d134b73241eDa7703fa787148D9C9F4950b0
        ] = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;

        // tombswap
        factoryToRouter[
            0xE236f6890F1824fa0a7ffc39b1597A5A6077Cfe9
        ] = 0x6D0176C5ea1e44b08D3dd001b0784cE42F47a3A7;

        // hyperjump
        factoryToRouter[
            0x991152411A7B5A14A8CF0cDDE8439435328070dF
        ] = 0x53c153a0df7E050BbEFbb70eE9632061f12795fB;

        // wigoswap
        factoryToRouter[
            0xC831A5cBfb4aC2Da5ed5B194385DFD9bF5bFcBa7
        ] = 0x5023882f4D1EC10544FCB2066abE9C1645E95AA0;

        // based
        factoryToRouter[
            0x407C47E3FDB7952Ee53aa232B5f28566A024A759
        ] = 0xaf2098E3AF3AC27a3a9362ACa2D883eFC36c7FAC;
    }

    receive() external payable {}

    /// @notice Get swap custom swap paths, if any
    /// @dev Otherwise reverts to default FROMTOKEN-WFTM-TOTOKEN behavior
    function getSwapPath(address _fromToken, address _toToken)
        public
        view
        override
        returns (SwapPath memory _swapPath)
    {
        bytes32 _swapKey = keccak256(abi.encodePacked(_fromToken, _toToken));
        if (swapPaths[_swapKey].path.length == 0) {
            if (_fromToken != WFTM && _toToken != WFTM) {
                address[] memory _path = new address[](3);
                _path[0] = _fromToken;
                _path[1] = WFTM;
                _path[2] = _toToken;
                _swapPath.path = _path;
            } else {
                address[] memory _path = new address[](2);
                _path[0] = _fromToken;
                _path[1] = _toToken;
                _swapPath.path = _path;
            }
            _swapPath.unirouter = unirouter;
        } else {
            return swapPaths[_swapKey];
        }
    }

    /// @dev Allows owner to set a custom swap path from a token to another
    /// @param _unirouter Can also set a custom unirouter for the swap, or address(0) for default router (spooky)
    function setSwapPath(
        address _fromToken,
        address _toToken,
        address _unirouter,
        address[] memory _path
    ) external onlyOwner {
        _setSwapPath(_fromToken, _toToken, _unirouter, _path);
    }

    function zapToLp(
        address _fromToken,
        address _toLpToken,
        uint256 _amountIn,
        uint256 _minLpAmountOut
    ) external payable {
        uint256 _lpAmountOut = _zapToLp(
            _fromToken,
            _toLpToken,
            _amountIn,
            _minLpAmountOut
        );

        IERC20(_toLpToken).safeTransfer(msg.sender, _lpAmountOut);
    }

    function zapToMatrix(
        address _fromToken,
        address _matrixVault,
        uint256 _amountIn,
        uint256 _minLpAmountOut
    ) external payable {
        IMatrixVault _vault = IMatrixVault(_matrixVault);
        address _toLpToken = _vault.want();

        uint256 _lpAmountOut = _zapToLp(
            _fromToken,
            _toLpToken,
            _amountIn,
            _minLpAmountOut
        );

        uint256 _vaultBalanceBefore = _vault.balanceOf(address(this));
        IERC20(_toLpToken).safeApprove(_matrixVault, _lpAmountOut);
        _vault.deposit(_lpAmountOut);
        uint256 _vaultAmountOut = _vault.balanceOf(address(this)) -
            _vaultBalanceBefore;
        require(_vaultAmountOut > 0, "deposit-in-vault-failed");
        _vault.transfer(msg.sender, _vaultAmountOut);

        emit ZapIn(msg.sender, address(_vault), _toLpToken, _lpAmountOut);
    }

    function unzapFromMatrix(
        address _matrixVault,
        address _toToken,
        uint256 _withdrawAmount,
        uint256 _minAmountOut
    ) external {
        IMatrixVault _vault = IMatrixVault(_matrixVault);
        address _fromLpToken = _vault.want();

        _vault.transferFrom(msg.sender, address(this), _withdrawAmount);
        _vault.withdraw(_withdrawAmount);

        uint256 _amountOut = _unzapFromLp(
            _fromLpToken,
            _toToken,
            IERC20(_fromLpToken).balanceOf(address(this)),
            _minAmountOut
        );

        emit ZapOut(msg.sender, address(_vault), _fromLpToken, _amountOut);
    }

    function unzapFromLp(
        address _fromLpToken,
        address _toToken,
        uint256 _amountLpIn,
        uint256 _minAmountOut
    ) external {
        IERC20(_fromLpToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amountLpIn
        );
        _unzapFromLp(_fromLpToken, _toToken, _amountLpIn, _minAmountOut);
    }

    /// @notice In case tokens got stuck/mistakenly sent here
    function sweepERC20(address _token) external onlyOwner {
        IERC20(_token).safeTransfer(
            msg.sender,
            IERC20(_token).balanceOf(_token)
        );
    }

    function setDefaultRouter(address _newDefaultRouter) external onlyOwner {
        _setDefaultRouter(_newDefaultRouter);
    }

    function setCustomRouter(address _token, address _router)
        external
        onlyOwner
    {
        require(_token != address(0), "invalid-token-addr");
        require(_router != defaultRouter, "invalid-custom-router");
        emit CustomRouterSet(_token, _router);
        customRouter[_token] = _router;
    }

    function _setDefaultRouter(address _newDefaultRouter) internal {
        require(_newDefaultRouter != address(0), "invalid-default-router");
        emit DefaultRouterChanged(defaultRouter, _newDefaultRouter);
        defaultRouter = _newDefaultRouter;
    }

    function addRouter(address _factory, address _router) external onlyOwner {
        require(factoryToRouter[_factory] == address(0), "already-set");

        factoryToRouter[_factory] = _router;
    }

    /// @notice Get router for LPToken
    function _getRouter(address _lpToken)
        internal
        view
        virtual
        returns (address)
    {
        if (customRouter[_lpToken] != address(0)) return customRouter[_lpToken];

        address _factory = IUniswapV2Pair(_lpToken).factory();
        require(factoryToRouter[_factory] != address(0), "unsupported-router");

        return factoryToRouter[_factory];
    }

    function _zapToLp(
        address _fromToken,
        address _toLpToken,
        uint256 _amountIn,
        uint256 _minLpAmountOut
    ) internal virtual returns (uint256 _lpAmountOut) {
        if (msg.value > 0) {
            // If you send FTM instead of WFTM these requirements must hold.
            require(_fromToken == WFTM, "invalid-from-token");
            require(_amountIn == msg.value, "invalid-amount-in");
            // Auto-wrap FTM to WFTM
            IWFTM(WFTM).deposit{value: msg.value}();
        } else {
            IERC20(_fromToken).safeTransferFrom(
                msg.sender,
                address(this),
                _amountIn
            );
        }

        address _router = _getRouter(_toLpToken);

        IERC20(_fromToken).safeApprove(_router, 0);
        IERC20(_fromToken).safeApprove(_router, _amountIn);

        address _token0 = IUniswapV2Pair(_toLpToken).token0();
        address _token1 = IUniswapV2Pair(_toLpToken).token1();

        address _defaultRouter = unirouter;
        unirouter = _router;
        // Uses lpToken' _router as the default router
        // You can override this by using setting a custom path
        // Using setSwapPath

        uint256 _token0Out = _swap(_fromToken, _token0, _amountIn / 2);
        uint256 _token1Out = _swap(
            _fromToken,
            _token1,
            _amountIn - (_amountIn / 2)
        );

        // Revert back to defaultRouter for swaps
        unirouter = _defaultRouter;

        IERC20(_token0).safeApprove(_router, 0);
        IERC20(_token1).safeApprove(_router, 0);
        IERC20(_token0).safeApprove(_router, _token0Out);
        IERC20(_token1).safeApprove(_router, _token1Out);

        uint256 _lpBalanceBefore = IERC20(_toLpToken).balanceOf(address(this));
        IUniswapV2Router02(_router).addLiquidity(
            _token0,
            _token1,
            _token0Out,
            _token1Out,
            0,
            0,
            address(this),
            block.timestamp
        );

        _lpAmountOut =
            IERC20(_toLpToken).balanceOf(address(this)) -
            _lpBalanceBefore;
        require(_lpAmountOut >= _minLpAmountOut, "slippage-rekt-you");
    }

    function _unzapFromLp(
        address _fromLpToken,
        address _toToken,
        uint256 _amountLpIn,
        uint256 _minAmountOut
    ) internal virtual returns (uint256 _amountOut) {
        address _router = _getRouter(_fromLpToken);

        address _token0 = IUniswapV2Pair(_fromLpToken).token0();
        address _token1 = IUniswapV2Pair(_fromLpToken).token1();

        IERC20(_fromLpToken).safeApprove(_router, 0);
        IERC20(_fromLpToken).safeApprove(_router, _amountLpIn);

        IUniswapV2Router02(_router).removeLiquidity(
            _token0,
            _token1,
            _amountLpIn,
            0,
            0,
            address(this),
            block.timestamp
        );

        address _defaultRouter = unirouter;
        unirouter = _router;
        // Uses lpToken' _router as the default router
        // You can override this by using setting a custom path
        // Using setSwapPath

        _swap(_token0, _toToken, IERC20(_token0).balanceOf(address(this)));
        _swap(_token1, _toToken, IERC20(_token1).balanceOf(address(this)));

        // Revert back to defaultRouter for swaps
        unirouter = _defaultRouter;

        _amountOut = IERC20(_toToken).balanceOf(address(this));

        require(_amountOut >= _minAmountOut, "slippage-rekt-you");

        if (_toToken == WFTM) {
            IWFTM(WFTM).withdraw(_amountOut);

            (bool _success, ) = msg.sender.call{value: _amountOut}("");
            require(_success, "ftm-transfer-failed");
        } else {
            IERC20(_toToken).transfer(msg.sender, _amountOut);
        }
    }

    function _checkPath(address[] memory _path) internal override {}

    function _checkRouter(address _router) internal override {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './Zapper.sol';
import './interfaces/camelot/ICamelotRouter.sol';
import './interfaces/camelot/ICamelotPair.sol';
import './interfaces/IWETH.sol';

//import "hardhat/console.sol";

contract ZapperCamelot is Zapper {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    address internal constant CAMELOT_ROUTER = 0xc873fEcbd354f5A56E00E710B90EF4201db2448d;
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant TREASURY = 0xEaD9f532C72CF35dAb18A42223eE7A1B19bC5aBF;

    constructor() {
        WFTM = WETH;
        _setDefaultRouter(CAMELOT_ROUTER);
    }

    function _getRouter(
        address /* _lpToken */
    ) internal view override returns (address) {
        return CAMELOT_ROUTER;
    }

    function _swap(
        address _fromToken,
        address _toToken,
        uint256 _amount
    ) internal override returns (uint256 _toTokenAmount) {
        if (_fromToken == _toToken) return _amount;
        SwapPath memory _swapPath = getSwapPath(_fromToken, _toToken);

        IERC20(_fromToken).safeApprove(_swapPath.unirouter, 0);
        IERC20(_fromToken).safeApprove(_swapPath.unirouter, type(uint256).max);

        //debugging: uncomment this block
        /*
        console.log("_inputAmount", _amount);
        console.log("_fromToken:", IERC20Metadata(_fromToken).symbol());
        console.log("_toToken:", IERC20Metadata(_toToken).symbol());
        console.log("_path:");
        for (uint256 i; i < _swapPath.path.length - 1; i++) {
            console.log(IERC20Metadata(_swapPath.path[i]).symbol());
        }
                    console.log(_swapPath.path[_swapPath.path.length - 1]);

        console.log(
            IERC20Metadata(_swapPath.path[_swapPath.path.length - 1]).symbol()
        );
        */

        uint256 _toTokenBefore = IERC20(_toToken).balanceOf(address(this));
        ICamelotRouter(_swapPath.unirouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount, 0, _swapPath.path, address(this), TREASURY, block.timestamp);

        _toTokenAmount = IERC20(_toToken).balanceOf(address(this)) - _toTokenBefore;

        //console.log("_toTokenAmount:", _toTokenAmount);
    }

    function _addLiquidity(
        address _router,
        address _token0,
        address _token1,
        uint256 _token0Out,
        uint256 _token1Out
    ) internal {
        ICamelotRouter(_router).addLiquidity(_token0, _token1, _token0Out, _token1Out, 0, 0, address(this), block.timestamp);
    }

    function _removeLiquidity(
        address _router,
        address _token0,
        address _token1,
        uint256 _amountLpIn
    ) internal {
        ICamelotRouter(_router).removeLiquidity(_token0, _token1, _amountLpIn, 0, 0, address(this), block.timestamp);
    }

    function _unzapFromLp(
        address _fromLpToken,
        address _toToken,
        uint256 _amountLpIn,
        uint256 _minAmountOut
    ) internal override returns (uint256 _amountOut) {
        address _router = _getRouter(_fromLpToken);

        address _token0 = ICamelotPair(_fromLpToken).token0();
        address _token1 = ICamelotPair(_fromLpToken).token1();

        IERC20(_fromLpToken).safeApprove(_router, 0);
        IERC20(_fromLpToken).safeApprove(_router, _amountLpIn);

        _removeLiquidity(_router, _token0, _token1, _amountLpIn);

        address _defaultRouter = unirouter;
        unirouter = _router;
        // Uses lpToken' _router as the default router
        // You can override this by using setting a custom path
        // Using setSwapPath

        _swap(_token0, _toToken, IERC20(_token0).balanceOf(address(this)));
        _swap(_token1, _toToken, IERC20(_token1).balanceOf(address(this)));

        // Revert back to defaultRouter for swaps
        unirouter = _defaultRouter;

        _amountOut = IERC20(_toToken).balanceOf(address(this));

        require(_amountOut >= _minAmountOut, 'slippage-rekt-you');

        if (_toToken == WETH) {
            IWETH(WETH).withdraw(_amountOut);

            (bool _success, ) = msg.sender.call{ value: _amountOut }('');
            require(_success, 'eth-transfer-failed');
        } else {
            IERC20(_toToken).transfer(msg.sender, _amountOut);
        }
    }

    function _getRatio(address _lpToken) internal view returns (uint256) {
        address _token0 = ICamelotPair(_lpToken).token0();
        address _token1 = ICamelotPair(_lpToken).token1();

        (uint256 opLp0, uint256 opLp1, , ) = ICamelotPair(_lpToken).getReserves();
        uint256 lp0Amt = (opLp0 * (10**18)) / (10**IERC20Metadata(_token0).decimals());
        uint256 lp1Amt = (opLp1 * (10**18)) / (10**IERC20Metadata(_token1).decimals());
        uint256 totalSupply = lp0Amt + (lp1Amt);
        return (lp0Amt * (10**18)) / (totalSupply);
    }

    function _zapToLp(
        address _fromToken,
        address _toLpToken,
        uint256 _amountIn,
        uint256 _minLpAmountOut
    ) internal override returns (uint256 _lpAmountOut) {
        if (msg.value > 0) {
            // If you send FTM instead of WETH these requirements must hold.
            require(_fromToken == WETH, 'invalid-from-token');
            require(_amountIn == msg.value, 'invalid-amount-in');
            // Auto-wrap FTM to WETH
            IWETH(WETH).deposit{ value: msg.value }();
        } else {
            IERC20(_fromToken).safeTransferFrom(msg.sender, address(this), _amountIn);
        }

        address _router = _getRouter(_toLpToken);

        IERC20(_fromToken).safeApprove(_router, 0);
        IERC20(_fromToken).safeApprove(_router, _amountIn);

        address _token0 = ICamelotPair(_toLpToken).token0();
        address _token1 = ICamelotPair(_toLpToken).token1();

        address _defaultRouter = unirouter;
        unirouter = _router;
        // Uses lpToken' _router as the default router
        // You can override this by using setting a custom path
        // Using setSwapPath

        uint256 _token0Out;
        uint256 _token1Out;

        uint256 _amount0In = (_amountIn * _getRatio(_toLpToken)) / 10**18;
        uint256 _amount1In = _amountIn - _amount0In;
        _token0Out = _swap(_fromToken, _token0, _amount0In);
        _token1Out = _swap(_fromToken, _token1, _amount1In);

        // Revert back to defaultRouter for swaps
        unirouter = _defaultRouter;

        IERC20(_token0).safeApprove(_router, 0);
        IERC20(_token1).safeApprove(_router, 0);
        IERC20(_token0).safeApprove(_router, _token0Out);
        IERC20(_token1).safeApprove(_router, _token1Out);

        uint256 _lpBalanceBefore = IERC20(_toLpToken).balanceOf(address(this));

        _addLiquidity(_router, _token0, _token1, _token0Out, _token1Out);

        _lpAmountOut = IERC20(_toLpToken).balanceOf(address(this)) - _lpBalanceBefore;
        require(_lpAmountOut >= _minLpAmountOut, 'slippage-rekt-you');
    }
}