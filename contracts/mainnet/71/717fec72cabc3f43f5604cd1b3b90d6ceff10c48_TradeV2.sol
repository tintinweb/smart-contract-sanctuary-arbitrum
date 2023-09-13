// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev See DapiProxy.sol for comments about usage
interface IProxy {
    function read() external view returns (int224 value, uint32 timestamp);

    function api3ServerV1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@api3/airnode-protocol-v1/contracts/api3-server-v1/proxies/interfaces/IProxy.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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

// SPDX-License-Identifier: MIT
import "@api3/contracts/v0.8/interfaces/IProxy.sol";

contract DataFeedReader {
    // The proxy contract address obtained from the API3 Market UI.
    function readDataFeed(address proxyAddress)
        external
        view
        returns (int224 value, uint256 timestamp)
    {
        // Use the IProxy interface to read a dAPI via its
        // proxy contract .
        (value, timestamp) = IProxy(proxyAddress).read();
        // If you have any assumptions about `value` and `timestamp`,
        // make sure to validate them after reading from the proxy.
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Chainlink {

    // -- Constants -- //

    uint256 public constant UNIT = 10**18;
    uint256 public constant GRACE_PERIOD_TIME = 3600;


    // -- Variables -- //
    
    AggregatorV3Interface internal sequencerUptimeFeed;

    // -- Errors -- //

    error SequencerDown();
    error GracePeriodNotOver();

    /**
    * For a list of available sequencer proxy addresses, see:
    * https://docs.chain.link/docs/l2-sequencer-flag/#available-networks
    */

    // -- Constructor -- //

    constructor() {
        sequencerUptimeFeed = AggregatorV3Interface(0xFdB631F5EE196F0ed6FAa767959853A9F217697D);
    }

    function getPrice(address feed) public view returns (uint256) {

        if (feed == address(0)) return 0;

    	(
	      /*uint80 roundId*/,
	      int256 answer,
	      uint256 startedAt,
	      /*uint256 updatedAt*/,
	      /*uint80 answeredInRound*/
	    ) = sequencerUptimeFeed.latestRoundData();

	    // Answer == 0: Sequencer is up
	    // Answer == 1: Sequencer is down
	    bool isSequencerUp = answer == 0;
	    if (!isSequencerUp) {
	      revert SequencerDown();
	    }

	    // Make sure the grace period has passed after the sequencer is back up.
	    uint256 timeSinceUp = block.timestamp - startedAt;

	    if (timeSinceUp <= GRACE_PERIOD_TIME) {
	      revert GracePeriodNotOver();
	    }

    	AggregatorV3Interface priceFeed = AggregatorV3Interface(feed);
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        uint8 decimals = priceFeed.decimals();

        // Return 18 decimals standard
        return uint256(price) * UNIT / 10**decimals;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPool {
    function totalSupply() external view returns (uint256);

    function creditUserProfit(address destination, uint256 amount) external;
    
    function updateOpenInterest(uint256 amount, bool isDecrease) external;

    function getUtilization() external view returns (uint256);

    function getBalance(address account) external view returns (uint256);

    function getPoolOI () external view returns (uint256,uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRouter {
    function trading() external view returns (address);

    function capPool() external view returns (address);

    function oracle() external view returns (address);

    function treasury() external view returns (address);

    function darkOracle() external view returns (address);

    function isSupportedCurrency(address currency) external view returns (bool);

    function currencies(uint256 index) external view returns (address);

    function currenciesLength() external view returns (uint256);

    function getDecimals(address currency) external view returns(uint8);

    function getPool(address currency) external view returns (address);

    function getPoolShare(address currency) external view returns(uint256);

    function getCapShare(address currency) external view returns(uint256);

    function getPoolRewards(address currency) external view returns (address);

    function getCapRewards(address currency) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract DataStore {
    
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    uint256 public constant BPS_DIVIDER = 10000;
    address public gov;
    address public currency;
    address public GML;

    address public trade;
    address public pool;

    
    uint256 public poolFeeShare = 5000; // in bps
    uint256 public keeperFeeShare = 1000; // in bps
    uint256 public poolWithdrawalFee = 10; // in bps
    uint256 public minimumMarginLevel = 2000; // 20% in bps, at which account is liquidated

    address[] public currencies;
    mapping (address => bool) supported;
    mapping (uint256 => bool) isActive;

        // Funding
	uint256 public constant fundingInterval = 1 hours; // In seconds.

	mapping(uint256 => int256) private fundingTrackers; // market => funding tracker (long) (short is opposite) // in UNIT * bps
	mapping(uint256 => uint256) private fundingLastUpdated; // market => last time fundingTracker was updated. In seconds.

    struct MarketData { 
        uint256 marketType; // 1 = crypto , 2 = forex  
        string symbol;
        address feed;
        uint256 maxLeverage;
        uint256 maxOI;
        uint256 fee; // in bps
        uint256 fundingFactor; // Yearly funding rate if OI is completely skewed to one side. In bps.
        uint256 minSize;
        uint256 minSettlementTime; // time before keepers can execute order (price finality) if chainlink price didn't change   
    }

    struct OrderData {
      uint256 orderId;
        address user;
        address currency;
        string market;
        uint256 marketId;
        uint256 price;
        bool isLong;
        uint256 leverage;
        uint8 orderType; // 0 = market, 1 = limit, 2 = stop
        uint256 margin;
        uint256 timestamp;
        uint256 takeProfit;
        uint256 stopLoss;
        bool isActive;
    }

    struct PositionData {
        address user;
        string market;
        uint256 marketId;
        bool isLong;
        uint256 size;
		uint256 margin;
		int256 fundingTracker;
		uint256 price;
		uint256 timestamp;
    }

    mapping (uint256 => PositionData) public userPositonItem;
    EnumerableSet.UintSet private positionKeys; // [position keys..]
    mapping(address => EnumerableSet.UintSet) private userPositionIds;

    mapping(uint256 => OrderData) public orders;
    mapping (address => EnumerableSet.UintSet) private userOrderIds;
    EnumerableSet.UintSet private orderIdsSet; 

        
    mapping(uint256 => uint256) public openIntrestLong;
    mapping(uint256 => uint256) public openIntrestShort;

    uint256 public markertPairId;
    mapping (uint256 => bool) public isMarketAdded;


    uint256[] public marketList; // "ETH-USD", "BTC-USD", etc
    mapping(uint256 => MarketData) public marketItems;

    mapping(address => uint256) private balances; // user => amount
    mapping(address => uint256) private lockedMargins; // user => amount

    uint256 public orderId;

    constructor (){
        gov = msg.sender;
    }

   function transferIn(address user, uint256 amount) external onlyContract {
		IERC20(currency).safeTransferFrom(user, address(this), amount);
	}

    function transferOut(address user, uint256 amount) external onlyContract {
        IERC20(currency).safeTransfer(user, amount);
	}

    function linkData (address _trading) external onlyGov{
        trade = _trading;
        // pool = _pool;
    }

    function addMarket(MarketData memory marketInfo) external onlyGov {
        uint256 id =  markertPairId++;
        require(isMarketAdded[id] == false,"id has been used");
        marketItems[id] = marketInfo;
        marketList.push(id);
        isMarketAdded[id] = true;
    }

    function updateMarket(uint256 martketId ,MarketData memory marketInfo) external onlyGov {
        require(isMarketAdded[martketId] == false,"id has been used");
        marketItems[martketId] = marketInfo;
    }

    function setPoolShare(uint256 bps) external onlyGov {
        poolFeeShare = bps;
    }

    function incrementOpenInterest ( uint256 marketId, uint256 amount, bool isLong ) external onlyContract {
        if (isLong){
            openIntrestLong[marketId] += amount;
        }else{
            openIntrestShort[marketId] += amount;
        }
    }

    function decreaseOpenIntrest ( uint256 marketId, uint256 amount, bool isLong ) external onlyContract {
        if (isLong){
            if (amount > openIntrestLong[marketId]){
                openIntrestLong[marketId] = 0;
            }else{
                openIntrestLong[marketId] -= amount;
            }
        }else{
            if (amount > openIntrestShort[marketId]) {
                openIntrestShort[marketId] = 0;
            }else {
                openIntrestShort[marketId] = 0;
            }
        }
    }

    

    function getOpenIntrestLong (uint256 marketId) external view returns(uint256) {
        return openIntrestLong[marketId];

    }

    function getOpenIntrestShort (uint256 marketId) external view returns(uint256) {
        return openIntrestShort[marketId];
    }

    function getMarketPairsData () external view returns(uint256[] memory){
        return marketList;
    }

    function getMarket (uint256 id) external view returns (MarketData memory _marketData){
        return marketItems[id];
    }

    function getOrder (uint256 id) external view returns (OrderData memory _orders){
        return orders[id];
    }
    

    

    function getOrders() external view returns (OrderData[] memory _orders) {
        uint256 length = orderIdsSet.length();
        _orders = new OrderData[](length);
        for (uint256 i =0; i < length; i++){
            _orders[i] = orders[orderIdsSet.at(i)];
        }
        return _orders;
    }

    
    function activateLimitOrders(uint256 id) external onlyContract {
        OrderData storage order = orders[id];
        require(order.price > 0,"!price");
        require(order.orderType == 1,"!limit");
        order.isActive = true;
    }

    function getUserOrders(address user) external view returns (OrderData[] memory _userOrders){
        uint256 length = userOrderIds[user].length();
        _userOrders = new OrderData[](length);

        for (uint256 i = 0; i <length; i++){
            _userOrders[i] = orders[userOrderIds[user].at(i)];
        }
        return _userOrders;
    }

    function getUserPositions (address user) 
        external view returns (PositionData[] memory _positions){

        uint256 length = userPositionIds[user].length();
        _positions = new PositionData[](length);
        for (uint256 i =0; i< length; i++){
            _positions[i] = userPositonItem[userPositionIds[user].at(i)];
        }
        return _positions;
    }

    function addOrder (OrderData memory order) external onlyContract returns(uint256){
        uint256 nextOrderId = ++orderId;
        order.orderId = nextOrderId;
        userOrderIds[order.user].add(nextOrderId);
        orders[nextOrderId] = order;
        orderIdsSet.add(nextOrderId);
        return nextOrderId;
    }

    function removeOrder (uint256 _orderId) external onlyContract {
        OrderData memory order = orders[_orderId];
        userOrderIds[order.user].remove(_orderId);
        orderIdsSet.remove(_orderId);
        delete orders[_orderId];
    }

    function addMargin (uint256 id, uint256 amount) external onlyContract{
         OrderData storage order = orders[id];
        require(order.price > 0,"!price");
        require(amount > 0, "!amount");
        uint256 newMargin = order.margin + amount;
        uint256 newLeverage = (order.leverage * order.margin) / newMargin;
        order.margin = newMargin;
        order.leverage = newLeverage;
    }
 
    function addOrUpdateUserPosition (address user, uint256 nextPositionId) external onlyContract {
        userPositionIds[user].add(nextPositionId);
        positionKeys.add(nextPositionId);
    }

	function isSupportedCurrency(address token) external view returns(bool) {
        require( token != address(0),"!currency" );
        require(supported[token] != false,"!supported");
		return supported[token];
	}

	function currenciesLength() external view returns(uint256) {
		return currencies.length;
	}

	function setCurrencies(address token) external onlyGov {
        require( token != address(0),"!currency" );
        supported[token] = true;
        currencies.push(token);
	}


    function removeUserPosition (address user, uint256 id) external onlyContract{
        userPositionIds[user].remove(id);
    }

    
	function getFundingFactor (uint256 marketId) external view returns(uint256) {
        return marketItems[marketId].fundingFactor;
	}

    function getFundingLastUpdated(uint256 marketId) external view returns(uint256) {
		return fundingLastUpdated[marketId];
	}
    
    function getFundingTracker(uint256 marketId) external view returns(int256) {
		return fundingTrackers[marketId];
	}

    function setFundingLastUpdated(uint256 marketId, uint256 timestamp) external onlyContract {
		fundingLastUpdated[marketId] = timestamp;
	}

	function updateFundingTracker(uint256 marketId, int256 fundingIncrement) external onlyContract {
		fundingTrackers[marketId] += fundingIncrement;
	}


    // Mods
        modifier onlyContract() {
        require(msg.sender == trade || msg.sender == pool || msg.sender == gov, '!contract');
        _;
    }

    modifier onlyGov() {
        require(msg.sender == gov, '!gov');
        _;
    }



}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Store.sol";
import "./ChainlinkFeed.sol";
import "./API3.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IPool.sol";

contract TradeV2 {
    uint256 public BPS_DIVIDER = 10000;
    uint256 public size = 10000;
    uint256 public constant UNIT = 10 ** 18;

    uint256 public minMargin = 100000000000000;
    uint256 public minLeverage = 5;
    uint256 public maxLeverage = 50;

    address public gov;
    address public owner;
    address public router;
    uint256 public fee = 80;

    Chainlink public chainlink;
    DataStore public Store;
    DataFeedReader public api3Feed;

    uint256 public liquidationThreshold = 8000; // In bps. 8000 = 80%. 4 bytes
    address public treasury;

    int256 public fundingTracker;
    uint256 public utilizationMultiplier = 100; // in bps

    // Events
    event PositionCreated(
        uint256 orderId,
        address indexed user,
        address indexed currency,
        uint256 marketId,
        uint256 entry,
        bool isLong,
        uint256 leverage,
        uint256 orderType,
        uint256 margin,
        uint256 takeProfit,
        uint256 stopLoss,
        bool isActive
    );

    event AddMargin(
        uint256 indexed id,
        address indexed user,
        uint256 margin,
        uint256 newMargin,
        uint256 newLeverage
    );

    event ReduceMargin(
        uint256 indexed id,
        address indexed user,
        uint256 margin,
        uint256 newMargin,
        uint256 newLeverage
    );

    event FeeGenerated(
        uint256 amount,
        address indexed currency,
        uint256 timestamp
    );

    event OpenOrder(
        uint256 indexed positionId,
        address indexed user,
        uint256 indexed marketId
    );

    event ClosePosition(
        uint256 orderId,
        address user,
        address currency,
        uint256 marketId,
        bool isLong,
        uint256 leverage,
        uint256 margin,
        uint256 takeProfit,
        uint256 stopLoss,
        bool isActive,
        uint256 pnl,
        uint256 earning,
        bool isLiquidated
    );

    event LiquidatedOrder(
        uint256 orderId,
        address user,
        address currency,
        uint256 marketId,
        bool isLong,
        uint256 margin,
        uint256 takeProfit,
        uint256 stopLoss,
        uint256 pnl,
        uint256 earning
    );

    event OrderCancelled(uint256 indexed orderId, address indexed user);

    constructor() {
        gov = msg.sender;
        owner = msg.sender;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setLiquidation(uint256 t) external onlyOwner {
        liquidationThreshold = t;
    }

    function setRouter(address _router) external onlyOwner {
        router = _router;
        treasury = IRouter(router).treasury();
    }

    function setUtilizaitonMultiplier(uint256 val) external onlyOwner {
        utilizationMultiplier = val;
    }

    function link(address _store, address _feed) external onlyOwner {
        Store = DataStore(_store);
        api3Feed = DataFeedReader(_feed);
    }

    function _transferIn(address currency, uint256 amount) internal {
        if (amount == 0 || currency == address(0)) return;
        IERC20(currency).transferFrom(msg.sender, address(this), amount);
    }

    function treasuryTransfer(address currency, uint256 amount) internal {
        if (amount == 0 || currency == address(0)) return;
        IERC20(currency).transferFrom(msg.sender, treasury, amount);
    }

    function _transferOut(
        address currency,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0 || currency == address(0) || to == address(0)) return;
        IERC20(currency).transfer(to, amount);
    }

    function feeCharges(
        uint256 margin
    ) private view returns (uint256, uint256) {
        uint256 charge = (fee * margin) / 10000;
        uint256 currentMargin = margin - charge;
        return (charge, currentMargin);
    }

    uint256 treasuryShare = 3000;

    function poolShare(uint256 amount) public view returns (uint256) {
        uint256 share = (treasuryShare * amount) / 10000;
        return share;
    }

    function updateShare(uint256 amount) external onlyOwner {
        treasuryShare = amount;
    }

    function updateMaxLeverage(uint256 amount) external onlyOwner {
        maxLeverage = amount;
    }

    /// @dev Submitted Pyth price is bound by the Chainlink price
    function _boundPriceWithChainlink(
        uint256 maxDeviation,
        uint256 api3prcie,
        uint256 price
    ) internal view returns (bool) {
        if (api3prcie == 0 || maxDeviation == 0) return true;
        if (
            price >= (api3prcie * (BPS_DIVIDER - maxDeviation)) / BPS_DIVIDER &&
            price <= (api3prcie * (BPS_DIVIDER + maxDeviation)) / BPS_DIVIDER
        ) {
            return true;
        }
        return false;
    }

    function submitTrade(
        DataStore.OrderData memory dataEntry,
        uint256 marketId,
        uint256 leverage,
        address currency
    ) external {
        require(IRouter(router).isSupportedCurrency(currency), "!currency");
        require(dataEntry.price > 0, "!limit price");
        require(dataEntry.leverage <= maxLeverage);
        require(
            dataEntry.orderType == 0 || dataEntry.orderType == 1,
            "!limit / market"
        );
        DataStore.MarketData memory market = Store.getMarket(marketId);

        uint256 poolUtilization = getUtilization(currency);

        require(poolUtilization < 10 ** 4, "!utilization");

        (uint256 cPrice, ) = _getAPI3Feed(market.feed);

        require(cPrice > 0, "!price feed");
        require(dataEntry.margin > minMargin, "!minMargin");
        require(leverage >= minLeverage, "!leverage");

        (uint256 feeCharge, uint256 currentMargin) = feeCharges(
            dataEntry.margin
        );

        emit FeeGenerated(feeCharge, dataEntry.currency, block.timestamp);

        treasuryTransfer(currency, feeCharge);
        _transferIn(currency, currentMargin);

        // market entry
        uint256 orderId;
        if (dataEntry.orderType == 0) {
            dataEntry.price = cPrice;
            dataEntry.margin = currentMargin;
            dataEntry.isActive = true;
            orderId = Store.addOrder(dataEntry);
            emit OpenOrder(orderId, dataEntry.user, marketId);
        }

        // limit entry
        if (dataEntry.orderType == 1) {
            dataEntry.margin = currentMargin;
            dataEntry.isActive = false;
            orderId = Store.addOrder(dataEntry);
            emit OpenOrder(orderId, dataEntry.user, marketId);
        }

        uint256 amount = dataEntry.margin * leverage;
        Store.incrementOpenInterest(marketId, amount, dataEntry.isLong);

        IncrementPoolOpenInterest(amount, currency, false);

        emit PositionCreated(
            orderId,
            msg.sender,
            dataEntry.currency,
            marketId,
            cPrice,
            dataEntry.isLong,
            dataEntry.leverage,
            dataEntry.orderType,
            currentMargin,
            dataEntry.takeProfit,
            dataEntry.stopLoss,
            dataEntry.isActive
        );
    }

    function processLimitOrders(uint256[] calldata orderIds) external {
        for (uint256 i = 0; i < orderIds.length; i++) {
            uint256 id = orderIds[i];
            DataStore.OrderData memory order = Store.getOrder(id);
            DataStore.MarketData memory market = Store.getMarket(
                order.marketId
            );
            (uint256 currentPrice, ) = _getAPI3Feed(market.feed);
            if (order.isLong == true && order.price >= currentPrice) {
                Store.activateLimitOrders(id);
            }
            if (order.isLong == false && order.price <= currentPrice) {
                Store.activateLimitOrders(id);
            }
        }
    }


    function closeTrade(uint256 orderId) public {
        DataStore.OrderData memory order = Store.getOrder(orderId);
        require(order.user != address(0), "!address");
        require(order.user == msg.sender, "!user");
        require(order.margin > 0, "!margin");

        (uint256 earning, uint256 pnl, bool isNegative) = getEarning(
            order.orderId
        );
        uint256 threshold = (order.margin * liquidationThreshold) / BPS_DIVIDER;

        address pool = IRouter(router).getPool(order.currency);

        bool liquidated = false;

        if (isNegative == true) {
            if (earning >= threshold) {
                liquidated = true;
            }

            if (earning <= order.margin) {
                uint256 amount = order.margin - earning;
                _transferOut(order.currency, order.user, amount);
                _transferOut(order.currency, treasury, earning);
            } else {
                _transferOut(order.currency, treasury, order.margin);
            }

            Store.removeOrder(orderId);

            emit ClosePosition(
                order.orderId,
                order.user,
                order.currency,
                order.marketId,
                order.isLong,
                order.leverage,
                order.margin,
                order.takeProfit,
                order.stopLoss,
                order.isActive,
                pnl,
                earning,
                liquidated
            );

            Store.decreaseOpenIntrest(
                order.marketId,
                order.margin * order.leverage,
                order.isLong
            );
            IncrementPoolOpenInterest(
                order.margin * order.leverage,
                order.currency,
                true
            );
        } else {
            _transferOut(order.currency, order.user, order.margin);
            IPool(pool).creditUserProfit(order.user, earning);
            Store.removeOrder(orderId);

            emit ClosePosition(
                order.orderId,
                order.user,
                order.currency,
                order.marketId,
                order.isLong,
                order.leverage,
                order.margin,
                order.takeProfit,
                order.stopLoss,
                order.isActive,
                pnl,
                earning,
                liquidated
            );

            Store.decreaseOpenIntrest(
                order.marketId,
                order.margin * order.leverage,
                order.isLong
            );
            IncrementPoolOpenInterest(
                order.margin * order.leverage,
                order.currency,
                true
            );
        }
    }


    function closeMultipleTrades(uint256[] calldata orderIds) external {
        for (uint256 i = 0; i < orderIds.length; i++) {
            closeTrade(orderIds[i]);
        }
    }

    // Increasing margin reduces leverage/risk
    function addMargin(uint256 id, uint256 amount, address currency) external {
        DataStore.OrderData memory order = Store.getOrder(id);
        require(msg.sender == order.user, "!user");
        require(amount > minMargin, "!minMargin");

        uint256 poolUtilization = getUtilization(currency);
        require(poolUtilization < 10 ** 4, "!utilization");

        (uint256 feeCharge, uint256 currentMargin) = feeCharges(amount);

        emit FeeGenerated(feeCharge, order.currency, block.timestamp);

        _transferIn(currency, feeCharge);
        Store.addMargin(id, currentMargin);
    }

    function processCompletedTrades(uint256[] memory orderIds) external {
        for (uint256 i = 0; i < orderIds.length; i++) {
            uint256 id = orderIds[i];
            DataStore.OrderData memory order = Store.getOrder(id);
            DataStore.MarketData memory market = Store.getMarket(
                order.marketId
            );
            (uint256 currentPrice, ) = _getAPI3Feed(market.feed);
            require(order.takeProfit > 0, "!tp");
            require(order.stopLoss > 0, "!sl");
            // crossed tp
            if (order.isLong == true && order.takeProfit >= currentPrice) {
                closeTrade(id);
            }

            if (order.isLong == false && order.takeProfit <= currentPrice) {
                closeTrade(id);
            }

            // crossed sl
            if (order.isLong == true && currentPrice <= order.stopLoss) {
                closeTrade(id);
            }

            if (order.isLong == false && order.stopLoss >= currentPrice) {
                closeTrade(id);
            }
        }
    }



    // Data Collection

    function getOrder(
        uint256 id
    ) external view returns (DataStore.OrderData memory _orders) {
        DataStore.OrderData memory order = Store.getOrder(id);
        return order;
    }

    function getMarket(
        uint256 id
    ) external view returns (DataStore.MarketData memory market) {
        DataStore.MarketData memory data = Store.getMarket(id);
        return data;
    }

    function getUtilization(address token) public view returns (uint256) {
        address pool = IRouter(router).getPool(token);
        (uint256 poolOI, uint256 multiplier) = IPool(pool).getPoolOI();
        uint256 utilization = (poolOI * multiplier) /
            IERC20(token).balanceOf(pool);
        return utilization;
    }

    function getAllOrders()
        external
        view
        returns (DataStore.OrderData[] memory _orders)
    {
        DataStore.OrderData[] memory orders = Store.getOrders();
        return orders;
    }

    function getUserOrdersFromStore(
        address user
    ) public view returns (DataStore.OrderData[] memory _users) {
        return Store.getUserOrders(user);
    }

    function _getPnL(
        uint256 marketId,
        bool isLong,
        uint256 price,
        uint256 positionPrice,
        uint256 size,
        int256 fundingTracker
    ) internal view returns (int256 pnl, bool isNegative, int256 fundingFee) {
        if (price == 0 || positionPrice == 0 || size == 0) return (0, false, 0);

        int256 currentFundingTracker = Store.getFundingTracker(marketId);
        fundingFee =
            (int256(size) * (currentFundingTracker - fundingTracker)) /
            (int256(BPS_DIVIDER) * int256(UNIT)); // funding tracker is in UNIT * bps

        if (isLong) {
            if (price >= positionPrice) {
                pnl =
                    (int256(size) * (int256(price) - int256(positionPrice))) /
                    int256(positionPrice);
                isNegative = false;
                pnl -= fundingFee; // positive = longs pay, negative = longs receive
                return (pnl, isNegative, fundingFee);
            } else {
                pnl =
                    (int256(size) * (int256(price) - int256(positionPrice))) /
                    int256(positionPrice);
                isNegative = true;
                pnl -= fundingFee; // positive = longs pay, negative = longs receive
                return (pnl, isNegative, fundingFee);
            }
        } else {
            pnl =
                (int256(size) * (int256(positionPrice) - int256(price))) /
                int256(positionPrice);

            if (price >= positionPrice) {
                pnl =
                    (int256(size) * (int256(price) - int256(positionPrice))) /
                    int256(positionPrice);
                isNegative = false;
                pnl += fundingFee; // positive = longs pay, negative = longs receive
                return (pnl, isNegative, fundingFee);
            } else {
                pnl =
                    (int256(size) * (int256(price) - int256(positionPrice))) /
                    int256(positionPrice);
                isNegative = true;
                pnl += fundingFee;
                return (pnl, isNegative, fundingFee);
            }
        }
    }

    function getEarning(
        uint256 id
    ) public view returns (uint256 earning, uint256 pnl, bool) {
        DataStore.OrderData memory order = Store.getOrder(id);

        DataStore.MarketData memory market = Store.getMarket(order.marketId);

        if (order.isActive != true) {
            return (0, 0, false);
        }
        (uint256 currentPrice, ) = _getAPI3Feed(market.feed);

        (int256 increment, bool isNegative, ) = _getPnL(
            order.marketId,
            order.isLong,
            currentPrice,
            order.price,
            size,
            fundingTracker
        );

        if (isNegative == true) {
            increment = increment * -1;
            pnl = uint256(increment) * order.leverage;
        } else {
            pnl = uint256(increment) * order.leverage;
        }

        earning = (pnl * order.margin) / BPS_DIVIDER;
        return (earning, pnl, isNegative);
    }

    function liquidateOrders(uint256 orderId) public {
        DataStore.OrderData memory order = Store.getOrder(orderId);
        require(order.user != address(0), "!null address");
        // gets pnl and earning
        (uint256 earning, uint256 pnl, bool isNegative) = getEarning(orderId);

        uint256 threshold = (order.margin * liquidationThreshold) / BPS_DIVIDER;
        address currency = order.currency;
        if (isNegative == true && earning >= threshold) {
            _transferOut(currency, order.user, order.margin - threshold);
            Store.removeOrder(orderId);
            emit LiquidatedOrder(
                order.orderId,
                order.user,
                order.currency,
                order.marketId,
                order.isLong,
                order.margin,
                order.takeProfit,
                order.stopLoss,
                pnl,
                earning
            );
        }
    }

    function LiquidatebleOrders(uint256[] memory orderIds) external {
        for (uint256 i = 0; i < orderIds.length; i++) {
            uint256 id = orderIds[i];
            DataStore.OrderData memory order = Store.getOrder(id);
            require(order.user != address(0), "!user");
            liquidateOrders(order.orderId);
        }
    }

    function getUserPositionsWithUpls(
        address user
    )
        external
        view
        returns (DataStore.OrderData[] memory _positions, int256[] memory _upls)
    {
        _positions = getUserOrdersFromStore(user);
        uint256 length = _positions.length;
        _upls = new int256[](length);
        for (uint256 i = 0; i < length; i++) {
            DataStore.OrderData memory position = _positions[i];

            DataStore.MarketData memory market = Store.getMarket(
                position.marketId
            );

            // uint256 chainlinkPrice = _getChainlinkPrice(market.feed);
            (uint256 cPrice, ) = _getAPI3Feed(market.feed);

            if (cPrice == 0) continue;

            (int256 pnl, , ) = _getPnL(
                position.marketId,
                position.isLong,
                cPrice,
                position.price,
                size,
                fundingTracker
            );
            _upls[i] = pnl;
        }

        return (_positions, _upls);
    }

    function getOrderUPL(
        uint256 id
    ) public view returns (int256 upl, bool isNegative) {
        DataStore.OrderData memory position = Store.getOrder(id);
        DataStore.MarketData memory market = Store.getMarket(position.marketId);
        (uint256 cPrice, ) = _getAPI3Feed(market.feed);
        if (position.isActive == false) {
            return (0, false);
        }
        (int256 pnl, bool booValue, ) = _getPnL(
            position.marketId,
            position.isLong,
            cPrice,
            position.price,
            size,
            fundingTracker
        );
        return (pnl, booValue);
    }

    function getOILong(uint256 marketId) external view returns (uint256) {
        return Store.getOpenIntrestLong(marketId);
    }

    function getOIShort(uint256 marketId) external view returns (uint256) {
        return Store.getOpenIntrestShort(marketId);
    }

    function IncrementPoolOpenInterest(
        uint amount,
        address currency,
        bool isDecrease
    ) private {
        address pool = IRouter(router).getPool(currency);
        IPool(pool).updateOpenInterest(amount, isDecrease);
    }

    function _updateFundingTracker(uint256 marketId) internal {
        uint256 lastUpdated = Store.getFundingLastUpdated(marketId);
        uint256 _now = block.timestamp;

        if (lastUpdated == 0) {
            Store.setFundingLastUpdated(marketId, _now);
            return;
        }

        if (lastUpdated + Store.fundingInterval() > _now) return;

        int256 fundingIncrement = getAccruedFunding(marketId, 0); // in UNIT * bps
        if (fundingIncrement == 0) return;
        Store.updateFundingTracker(marketId, fundingIncrement);
        Store.setFundingLastUpdated(marketId, _now);
    }

    function getAccruedFunding(
        uint256 marketId,
        uint256 intervals
    ) public view returns (int256) {
        if (intervals == 0) {
            intervals =
                (block.timestamp - Store.getFundingLastUpdated(marketId)) /
                Store.fundingInterval();
        }

        if (intervals == 0) return 0;

        uint256 OILong = Store.getOpenIntrestLong(marketId);
        uint256 OIShort = Store.getOpenIntrestShort(marketId);

        if (OIShort == 0 && OILong == 0) return 0;

        uint256 OIDiff = OIShort > OILong ? OIShort - OILong : OILong - OIShort;
        uint256 yearlyFundingFactor = Store.getFundingFactor(marketId); // in bps
        // intervals = hours since fundingInterval = 1 hour
        uint256 accruedFunding = (UNIT *
            yearlyFundingFactor *
            OIDiff *
            intervals) / (24 * 365 * (OILong + OIShort)); // in UNIT * bps

        if (OILong > OIShort) {
            // Longs pay shorts. Increase funding tracker.
            return int256(accruedFunding);
        } else {
            // Shorts pay longs. Decrease funding tracker.
            return -1 * int256(accruedFunding);
        }
    }

    // Data Request

    function _getChainlinkPrice(address feed) public view returns (uint256) {
        if (feed == address(0)) return 0;

        (, int256 price, , uint256 timeStamp, ) = AggregatorV3Interface(feed)
            .latestRoundData();

        if (price <= 0 || timeStamp == 0) return 0;

        uint8 decimals = AggregatorV3Interface(feed).decimals();

        uint256 feedPrice;
        if (decimals != 8) {
            feedPrice = (uint256(price) * 10 ** 8) / 10 ** decimals;
        } else {
            feedPrice = uint256(price);
        }

        return feedPrice;
    }

    function _getAPI3Feed(address feed) public view returns (uint256, uint256) {
        (int224 value, uint256 timestamp) = api3Feed.readDataFeed(feed);

        uint256 dataValue = uint224(value);
        return (dataValue, timestamp);
    }

    function getChainlinkPrice(
        uint256 marketId
    ) external view returns (uint256) {
        DataStore.MarketData memory market = Store.getMarket(marketId);
        return _getChainlinkPrice(market.feed);
    }

    function getAPI3Feed(uint256 marketId) external view returns (uint256) {
        DataStore.MarketData memory market = Store.getMarket(marketId);
        (uint256 data, ) = _getAPI3Feed(market.feed);
        return data;
    }

    // Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }
}