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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
library SafeMathUpgradeable {
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

struct LiquidityPoolStorage {
    // slot
    address orderBook;
    // slot
    address mlp;
    // slot
    address _reserved6; // was liquidityManager
    // slot
    address weth;
    // slot
    uint128 _reserved1;
    uint32 shortFundingBaseRate8H; // 1e5
    uint32 shortFundingLimitRate8H; // 1e5
    uint32 fundingInterval; // 1e0
    uint32 lastFundingTime; // 1e0
    // slot
    uint32 _reserved2;
    // slot
    Asset[] assets;
    // slot
    mapping(bytes32 => SubAccount) accounts;
    // slot
    mapping(address => bytes32) _reserved3;
    // slot
    address _reserved4;
    uint96 _reserved5;
    // slot
    uint96 mlpPriceLowerBound; // safeguard against mlp price attacks
    uint96 mlpPriceUpperBound; // safeguard against mlp price attacks
    uint32 liquidityBaseFeeRate; // 1e5
    uint32 liquidityDynamicFeeRate; // 1e5
    // slot
    address nativeUnwrapper;
    // a sequence number that changes when LiquidityPoolStorage updated. this helps to keep track the state of LiquidityPool.
    uint32 sequence; // 1e0. note: will be 0 after 0xffffffff
    uint32 strictStableDeviation; // 1e5. strictStable price is 1.0 if in this damping range
    uint32 brokerTransactions; // transaction count for broker gas rebates
    // slot
    address vault;
    uint96 brokerGasRebate; // the number of native tokens for broker gas rebates per transaction
    // slot
    address maintainer;
    // slot
    mapping(address => bool) liquidityManager;
    bytes32[50] _gap;
}

struct Asset {
    // slot
    // assets with the same symbol in different chains are the same asset. they shares the same muxToken. so debts of the same symbol
    // can be accumulated across chains (see Reader.AssetState.deduct). ex: ERC20(fBNB).symbol should be "BNB", so that BNBs of
    // different chains are the same.
    // since muxToken of all stable coins is the same and is calculated separately (see Reader.ChainState.stableDeduct), stable coin
    // symbol can be different (ex: "USDT", "USDT.e" and "fUSDT").
    bytes32 symbol;
    // slot
    address tokenAddress; // erc20.address
    uint8 id;
    uint8 decimals; // erc20.decimals
    uint56 flags; // a bitset of ASSET_*
    uint24 _flagsPadding;
    // slot
    uint32 initialMarginRate; // 1e5
    uint32 maintenanceMarginRate; // 1e5
    uint32 minProfitRate; // 1e5
    uint32 minProfitTime; // 1e0
    uint32 positionFeeRate; // 1e5
    // note: 96 bits remaining
    // slot
    address referenceOracle;
    uint32 referenceDeviation; // 1e5
    uint8 referenceOracleType;
    uint32 halfSpread; // 1e5
    // note: 24 bits remaining
    // slot
    uint96 credit;
    uint128 _reserved2;
    // slot
    uint96 collectedFee;
    uint32 liquidationFeeRate; // 1e5
    uint96 spotLiquidity;
    // note: 32 bits remaining
    // slot
    uint96 maxLongPositionSize;
    uint96 totalLongPosition;
    // note: 64 bits remaining
    // slot
    uint96 averageLongPrice;
    uint96 maxShortPositionSize;
    // note: 64 bits remaining
    // slot
    uint96 totalShortPosition;
    uint96 averageShortPrice;
    // note: 64 bits remaining
    // slot, less used
    address muxTokenAddress; // muxToken.address. all stable coins share the same muxTokenAddress
    uint32 spotWeight; // 1e0
    uint32 longFundingBaseRate8H; // 1e5
    uint32 longFundingLimitRate8H; // 1e5
    // slot
    uint128 longCumulativeFundingRate; // Σ_t fundingRate_t
    uint128 shortCumulativeFunding; // Σ_t fundingRate_t * indexPrice_t
}

uint32 constant FUNDING_PERIOD = 3600 * 8;

uint56 constant ASSET_IS_STABLE = 0x00000000000001; // is a usdt, usdc, ...
uint56 constant ASSET_CAN_ADD_REMOVE_LIQUIDITY = 0x00000000000002; // can call addLiquidity and removeLiquidity with this token
uint56 constant ASSET_IS_TRADABLE = 0x00000000000100; // allowed to be assetId
uint56 constant ASSET_IS_OPENABLE = 0x00000000010000; // can open position
uint56 constant ASSET_IS_SHORTABLE = 0x00000001000000; // allow shorting this asset
uint56 constant ASSET_USE_STABLE_TOKEN_FOR_PROFIT = 0x00000100000000; // take profit will get stable coin
uint56 constant ASSET_IS_ENABLED = 0x00010000000000; // allowed to be assetId and collateralId
uint56 constant ASSET_IS_STRICT_STABLE = 0x01000000000000; // assetPrice is always 1 unless volatility exceeds strictStableDeviation

struct SubAccount {
    // slot
    uint96 collateral;
    uint96 size;
    uint32 lastIncreasedTime;
    // slot
    uint96 entryPrice;
    uint128 entryFunding; // entry longCumulativeFundingRate for long position. entry shortCumulativeFunding for short position
}

enum ReferenceOracleType {
    None,
    Chainlink
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "../liquidity/Types.sol";

interface ILiquidityManager {
    function getDexSpotConfiguration(uint8 dexId) external returns (DexSpotConfiguration memory);

    function getAllDexSpotConfiguration() external returns (DexSpotConfiguration[] memory);

    function getDexLiquidity(uint8 dexId) external returns (uint256[] memory liquidities, uint256 lpBalance);

    function getDexAdapterConfig(uint8 dexId) external view returns (bytes memory config);

    function getDexAdapterState(uint8 dexId, bytes32 key) external view returns (bytes32 state);

    function getDexAdapter(uint8 dexId) external view returns (DexRegistration memory registration);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "../core/Types.sol";

interface ILiquidityPool {
    /////////////////////////////////////////////////////////////////////////////////
    //                                 getters

    function getAssetInfo(uint8 assetId) external view returns (Asset memory);

    function getAllAssetInfo() external view returns (Asset[] memory);

    function getAssetAddress(uint8 assetId) external view returns (address);

    function getLiquidityPoolStorage()
        external
        view
        returns (
            // [0] shortFundingBaseRate8H
            // [1] shortFundingLimitRate8H
            // [2] lastFundingTime
            // [3] fundingInterval
            // [4] liquidityBaseFeeRate
            // [5] liquidityDynamicFeeRate
            // [6] sequence. note: will be 0 after 0xffffffff
            // [7] strictStableDeviation
            uint32[8] memory u32s,
            // [0] mlpPriceLowerBound
            // [1] mlpPriceUpperBound
            uint96[2] memory u96s
        );

    function getSubAccount(
        bytes32 subAccountId
    )
        external
        view
        returns (uint96 collateral, uint96 size, uint32 lastIncreasedTime, uint96 entryPrice, uint128 entryFunding);

    /////////////////////////////////////////////////////////////////////////////////
    //                             for Trader / Broker

    function withdrawAllCollateral(bytes32 subAccountId) external;

    /////////////////////////////////////////////////////////////////////////////////
    //                                 only Broker

    function depositCollateral(
        bytes32 subAccountId,
        uint256 rawAmount // NOTE: OrderBook SHOULD transfer rawAmount collateral to LiquidityPool
    ) external;

    function withdrawCollateral(
        bytes32 subAccountId,
        uint256 rawAmount,
        uint96 collateralPrice,
        uint96 assetPrice
    ) external;

    function withdrawProfit(
        bytes32 subAccountId,
        uint256 rawAmount,
        uint8 profitAssetId, // only used when !isLong
        uint96 collateralPrice,
        uint96 assetPrice,
        uint96 profitAssetPrice // only used when !isLong
    ) external;

    /**
     * @dev   Add liquidity.
     *
     * @param trader            liquidity provider address.
     * @param tokenId           asset.id that added.
     * @param rawAmount         asset token amount. decimals = erc20.decimals.
     * @param tokenPrice        token price. decimals = 18.
     * @param mlpPrice          mlp price.  decimals = 18.
     * @param currentAssetValue liquidity USD value of a single asset in all chains (even if tokenId is a stable asset).
     * @param targetAssetValue  weight / Σ weight * total liquidity USD value in all chains.
     */
    function addLiquidity(
        address trader,
        uint8 tokenId,
        uint256 rawAmount, // NOTE: OrderBook SHOULD transfer rawAmount collateral to LiquidityPool
        uint96 tokenPrice,
        uint96 mlpPrice,
        uint96 currentAssetValue,
        uint96 targetAssetValue
    ) external returns (uint96 mlpAmount);

    /**
     * @dev   Remove liquidity.
     *
     * @param trader            liquidity provider address.
     * @param mlpAmount         mlp amount. decimals = 18.
     * @param tokenId           asset.id that removed to.
     * @param tokenPrice        token price. decimals = 18.
     * @param mlpPrice          mlp price. decimals = 18.
     * @param currentAssetValue liquidity USD value of a single asset in all chains (even if tokenId is a stable asset). decimals = 18.
     * @param targetAssetValue  weight / Σ weight * total liquidity USD value in all chains. decimals = 18.
     */
    function removeLiquidity(
        address trader,
        uint96 mlpAmount, // NOTE: OrderBook SHOULD transfer mlpAmount mlp to LiquidityPool
        uint8 tokenId,
        uint96 tokenPrice,
        uint96 mlpPrice,
        uint96 currentAssetValue,
        uint96 targetAssetValue
    ) external returns (uint256 rawAmount);

    /**
     * @notice Open a position.
     *
     * @param  subAccountId     check LibSubAccount.decodeSubAccountId for detail.
     * @param  amount           position size. decimals = 18.
     * @param  collateralPrice  price of subAccount.collateral.
     * @param  assetPrice       price of subAccount.asset.
     */
    function openPosition(
        bytes32 subAccountId,
        uint96 amount,
        uint96 collateralPrice,
        uint96 assetPrice
    ) external returns (uint96);

    /**
     * @notice Close a position.
     *
     * @param  subAccountId     check LibSubAccount.decodeSubAccountId for detail.
     * @param  amount           position size. decimals = 18.
     * @param  profitAssetId    for long position (unless asset.useStable is true), ignore this argument;
     *                          for short position, the profit asset should be one of the stable coin.
     * @param  collateralPrice  price of subAccount.collateral. decimals = 18.
     * @param  assetPrice       price of subAccount.asset. decimals = 18.
     * @param  profitAssetPrice price of profitAssetId. ignore this argument if profitAssetId is ignored. decimals = 18.
     */
    function closePosition(
        bytes32 subAccountId,
        uint96 amount,
        uint8 profitAssetId, // only used when !isLong
        uint96 collateralPrice,
        uint96 assetPrice,
        uint96 profitAssetPrice // only used when !isLong
    ) external returns (uint96 tradingPrice);

    /**
     * @notice Broker can update funding each [fundingInterval] seconds by specifying utilizations.
     *
     *         Check _getFundingRate in Liquidity.sol on how to calculate funding rate.
     * @param  stableUtilization    Stable coin utilization in all chains. decimals = 5.
     * @param  unstableTokenIds     All unstable Asset id(s) MUST be passed in order. ex: 1, 2, 5, 6, ...
     * @param  unstableUtilizations Unstable Asset utilizations in all chains. decimals = 5.
     * @param  unstablePrices       Unstable Asset prices.
     */
    function updateFundingState(
        uint32 stableUtilization, // 1e5
        uint8[] calldata unstableTokenIds,
        uint32[] calldata unstableUtilizations, // 1e5
        uint96[] calldata unstablePrices
    ) external;

    function liquidate(
        bytes32 subAccountId,
        uint8 profitAssetId, // only used when !isLong
        uint96 collateralPrice,
        uint96 assetPrice,
        uint96 profitAssetPrice // only used when !isLong
    ) external returns (uint96);

    /**
     * @notice Redeem mux token into original tokens.
     *
     *         Only strict stable coins and un-stable coins are supported.
     */
    function redeemMuxToken(
        address trader,
        uint8 tokenId,
        uint96 muxTokenAmount // NOTE: OrderBook SHOULD transfer muxTokenAmount to LiquidityPool
    ) external;

    /**
     * @dev  Rebalance pool liquidity. Swap token 0 for token 1.
     *
     *       rebalancer must implement IMuxRebalancerCallback.
     */
    function rebalance(
        address rebalancer,
        uint8 tokenId0,
        uint8 tokenId1,
        uint96 rawAmount0,
        uint96 maxRawAmount1,
        bytes32 userData,
        uint96 price0,
        uint96 price1
    ) external;

    /**
     * @dev Broker can withdraw brokerGasRebate.
     */
    function claimBrokerGasRebate(address receiver) external returns (uint256 rawAmount);

    /////////////////////////////////////////////////////////////////////////////////
    //                            only LiquidityManager

    function transferLiquidityOut(uint8[] memory assetIds, uint256[] memory amounts) external;

    function transferLiquidityIn(uint8[] memory assetIds, uint256[] memory amounts) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

interface INativeUnwrapper {
    function unwrap(address payable to, uint256 rawAmount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "../orderbook/Types.sol";

interface IOrderBook {
    /**
     * @notice Liquidity Order can be filled after this time in seconds.
     */
    function liquidityLockPeriod() external view returns (uint32);

    /**
     * @notice Market Order MUST NOT be filled after this time in seconds.
     */
    function marketOrderTimeout() external view returns (uint32);

    /**
     * @notice Limit/Trigger Order MUST NOT be filled after this time in seconds.
     */
    function maxLimitOrderTimeout() external view returns (uint32);

    /**
     * @notice Return true if the filling of position order is temporarily paused.
     */
    function isPositionOrderPaused() external view returns (bool);

    /**
     * @notice Return true if the filling of liquidity/rebalance order is temporarily paused.
     */
    function isLiquidityOrderPaused() external view returns (bool);

    /**
     * @notice Get an Order by orderId.
     */
    function getOrder(uint64 orderId) external view returns (bytes32[3] memory, bool);

    /**
     * @notice Get more parameters (ex: tp/sl strategy parameters) of a position order by orderId.
     */
    function positionOrderExtras(uint64 orderId) external view returns (PositionOrderExtra memory);

    /**
     * @notice Cancel an Order by orderId.
     */
    function cancelOrder(uint64 orderId) external;

    /**
     * @notice Open/close position. called by Trader.
     *
     *         Market order will expire after marketOrderTimeout seconds.
     *         Limit/Trigger order will expire after deadline.
     * @param  subAccountId       sub account id. see LibSubAccount.decodeSubAccountId.
     * @param  collateralAmount   deposit collateral before open; or withdraw collateral after close. decimals = erc20.decimals.
     * @param  size               position size. decimals = 18.
     * @param  price              limit price. decimals = 18.
     * @param  profitTokenId      specify the profitable asset.id when closing a position and making a profit.
     *                            take no effect when opening a position or loss.
     * @param  flags              a bitset of LibOrder.POSITION_*.
     *                            POSITION_OPEN                     this flag means openPosition; otherwise closePosition
     *                            POSITION_MARKET_ORDER             this flag means ignore limitPrice
     *                            POSITION_WITHDRAW_ALL_IF_EMPTY    this flag means auto withdraw all collateral if position.size == 0
     *                            POSITION_TRIGGER_ORDER            this flag means this is a trigger order (ex: stop-loss order). otherwise this is a limit order (ex: take-profit order)
     * @param  deadline           a unix timestamp after which the limit/trigger order MUST NOT be filled. fill 0 for market order.
     * @param  referralCode       set referral code of the trading account.
     */
    function placePositionOrder2(
        bytes32 subAccountId,
        uint96 collateralAmount, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline, // 1e0
        bytes32 referralCode
    ) external payable;

    /**
     * @notice Add/remove liquidity. called by Liquidity Provider.
     *
     *         Can be filled after liquidityLockPeriod seconds.
     * @param  assetId   asset.id that added/removed to.
     * @param  rawAmount asset token amount. decimals = erc20.decimals.
     * @param  isAdding  true for add liquidity, false for remove liquidity.
     */
    function placeLiquidityOrder(
        uint8 assetId,
        uint96 rawAmount, // erc20.decimals
        bool isAdding
    ) external payable;

    /**
     * @notice Withdraw collateral/profit. called by Trader.
     *
     *         This order will expire after marketOrderTimeout seconds.
     * @param  subAccountId       sub account id. see LibSubAccount.decodeSubAccountId.
     * @param  rawAmount          collateral or profit asset amount. decimals = erc20.decimals.
     * @param  profitTokenId      specify the profitable asset.id.
     * @param  isProfit           true for withdraw profit. false for withdraw collateral.
     */
    function placeWithdrawalOrder(
        bytes32 subAccountId,
        uint96 rawAmount, // erc20.decimals
        uint8 profitTokenId,
        bool isProfit
    ) external;

    /**
     * @notice Rebalance pool liquidity. Swap token 0 for token 1.
     *
     *         msg.sender must implement IMuxRebalancerCallback.
     * @param  tokenId0      asset.id to be swapped out of the pool.
     * @param  tokenId1      asset.id to be swapped into the pool.
     * @param  rawAmount0    token 0 amount. decimals = erc20.decimals.
     * @param  maxRawAmount1 max token 1 that rebalancer is willing to pay. decimals = erc20.decimals.
     * @param  userData      any user defined data.
     */
    function placeRebalanceOrder(
        uint8 tokenId0,
        uint8 tokenId1,
        uint96 rawAmount0, // erc20.decimals
        uint96 maxRawAmount1, // erc20.decimals
        bytes32 userData
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "../interfaces/IWETH9.sol";
import "../interfaces/INativeUnwrapper.sol";
import "../libraries/LibMath.sol";
import "../core/Types.sol";

library LibAsset {
    using LibMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    function transferOut(
        Asset storage token,
        address recipient,
        uint256 rawAmount,
        address weth,
        address nativeUnwrapper
    ) internal {
        if (token.tokenAddress == weth) {
            IWETH(weth).transfer(nativeUnwrapper, rawAmount);
            INativeUnwrapper(nativeUnwrapper).unwrap(payable(recipient), rawAmount);
        } else {
            IERC20Upgradeable(token.tokenAddress).safeTransfer(recipient, rawAmount);
        }
    }

    function issueMuxToken(Asset storage token, address recipient, uint256 muxTokenAmount) internal {
        IERC20Upgradeable(token.muxTokenAddress).safeTransfer(recipient, muxTokenAmount);
    }

    function toWad(Asset storage token, uint256 rawAmount) internal view returns (uint96) {
        return (rawAmount * (10 ** (18 - token.decimals))).safeUint96();
    }

    function toRaw(Asset storage token, uint96 wadAmount) internal view returns (uint256) {
        return uint256(wadAmount) / 10 ** (18 - token.decimals);
    }

    // is a usdt, usdc, ...
    function isStable(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_IS_STABLE) != 0;
    }

    // can call addLiquidity and removeLiquidity with this token
    function canAddRemoveLiquidity(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_CAN_ADD_REMOVE_LIQUIDITY) != 0;
    }

    // allowed to be assetId
    function isTradable(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_IS_TRADABLE) != 0;
    }

    // can open position
    function isOpenable(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_IS_OPENABLE) != 0;
    }

    // allow shorting this asset
    function isShortable(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_IS_SHORTABLE) != 0;
    }

    // take profit will get stable coin
    function useStableTokenForProfit(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_USE_STABLE_TOKEN_FOR_PROFIT) != 0;
    }

    // allowed to be assetId and collateralId
    function isEnabled(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_IS_ENABLED) != 0;
    }

    // assetPrice is always 1 unless volatility exceeds strictStableDeviation
    function isStrictStable(Asset storage asset) internal view returns (bool) {
        return (asset.flags & ASSET_IS_STRICT_STABLE) != 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

library LibMath {
    function min(uint96 a, uint96 b) internal pure returns (uint96) {
        return a <= b ? a : b;
    }

    function min32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a <= b ? a : b;
    }

    function max32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a >= b ? a : b;
    }

    function wmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / 1e18;
    }

    function rmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / 1e5;
    }

    function wdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * 1e18) / b;
    }

    function safeUint32(uint256 n) internal pure returns (uint32) {
        require(n <= type(uint32).max, "O32"); // uint32 Overflow
        return uint32(n);
    }

    function safeUint96(uint256 n) internal pure returns (uint96) {
        require(n <= type(uint96).max, "O96"); // uint96 Overflow
        return uint96(n);
    }

    function safeUint128(uint256 n) internal pure returns (uint128) {
        require(n <= type(uint128).max, "O12"); // uint128 Overflow
        return uint128(n);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "../orderbook/Types.sol";
import "./LibSubAccount.sol";

library LibOrder {
    // position order flags
    uint8 constant POSITION_OPEN = 0x80; // this flag means openPosition; otherwise closePosition
    uint8 constant POSITION_MARKET_ORDER = 0x40; // this flag means ignore limitPrice
    uint8 constant POSITION_WITHDRAW_ALL_IF_EMPTY = 0x20; // this flag means auto withdraw all collateral if position.size == 0
    uint8 constant POSITION_TRIGGER_ORDER = 0x10; // this flag means this is a trigger order (ex: stop-loss order). otherwise this is a limit order (ex: take-profit order)
    uint8 constant POSITION_TPSL_STRATEGY = 0x08; // for open-position-order, this flag auto place take-profit and stop-loss orders when open-position-order fills.
    //                                               for close-position-order, this flag means ignore limitPrice and profitTokenId, and use extra.tpPrice, extra.slPrice, extra.tpslProfitTokenId instead.
    uint8 constant POSITION_SHOULD_REACH_MIN_PROFIT = 0x04; // this flag is used to ensure that either the minProfitTime is met or the minProfitRate ratio is reached when close a position. only available when minProfitTime > 0.

    // order data[1] SHOULD reserve lower 64bits for enumIndex
    bytes32 constant ENUM_INDEX_BITS = bytes32(uint256(0xffffffffffffffff));

    struct OrderList {
        uint64[] _orderIds;
        mapping(uint64 => bytes32[3]) _orders;
    }

    function add(OrderList storage list, uint64 orderId, bytes32[3] memory order) internal {
        require(!contains(list, orderId), "DUP"); // already seen this orderId
        list._orderIds.push(orderId);
        // The value is stored at length-1, but we add 1 to all indexes
        // and use 0 as a sentinel value
        uint256 enumIndex = list._orderIds.length;
        require(enumIndex <= type(uint64).max, "O64"); // Overflow uint64
        // order data[1] SHOULD reserve lower 64bits for enumIndex
        require((order[1] & ENUM_INDEX_BITS) == 0, "O1F"); // bad Order[1] Field
        order[1] = bytes32(uint256(order[1]) | uint256(enumIndex));
        list._orders[orderId] = order;
    }

    function remove(OrderList storage list, uint64 orderId) internal {
        bytes32[3] storage orderToRemove = list._orders[orderId];
        uint64 enumIndexToRemove = uint64(uint256(orderToRemove[1]));
        require(enumIndexToRemove != 0, "OID"); // orderId is not found
        // swap and pop
        uint256 indexToRemove = enumIndexToRemove - 1;
        uint256 lastIndex = list._orderIds.length - 1;
        if (lastIndex != indexToRemove) {
            uint64 lastOrderId = list._orderIds[lastIndex];
            // move the last orderId
            list._orderIds[indexToRemove] = lastOrderId;
            // replace enumIndex
            bytes32[3] storage lastOrder = list._orders[lastOrderId];
            lastOrder[1] = (lastOrder[1] & (~ENUM_INDEX_BITS)) | bytes32(uint256(enumIndexToRemove));
        }
        list._orderIds.pop();
        delete list._orders[orderId];
    }

    function contains(OrderList storage list, uint64 orderId) internal view returns (bool) {
        bytes32[3] storage order = list._orders[orderId];
        // order data[1] always contains enumIndex
        return order[1] != bytes32(0);
    }

    function length(OrderList storage list) internal view returns (uint256) {
        return list._orderIds.length;
    }

    function at(OrderList storage list, uint256 index) internal view returns (bytes32[3] memory order) {
        require(index < list._orderIds.length, "IDX"); // InDex overflow
        uint64 orderId = list._orderIds[index];
        order = list._orders[orderId];
    }

    function get(OrderList storage list, uint64 orderId) internal view returns (bytes32[3] memory) {
        return list._orders[orderId];
    }

    function getOrderType(bytes32[3] memory orderData) internal pure returns (OrderType) {
        return OrderType(uint8(uint256(orderData[0])));
    }

    function getOrderOwner(bytes32[3] memory orderData) internal pure returns (address) {
        return address(bytes20(orderData[0]));
    }

    // check Types.PositionOrder for schema
    function encodePositionOrder(
        uint64 orderId,
        bytes32 subAccountId,
        uint96 collateral, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 profitTokenId,
        uint8 flags,
        uint32 placeOrderTime,
        uint24 expire10s
    ) internal pure returns (bytes32[3] memory data) {
        require((subAccountId & LibSubAccount.SUB_ACCOUNT_ID_FORBIDDEN_BITS) == 0, "AID"); // bad subAccount ID
        data[0] = subAccountId | bytes32(uint256(orderId) << 8) | bytes32(uint256(OrderType.PositionOrder));
        data[1] = bytes32(
            (uint256(size) << 160) |
                (uint256(profitTokenId) << 152) |
                (uint256(flags) << 144) |
                (uint256(expire10s) << 96) |
                (uint256(placeOrderTime) << 64)
        );
        data[2] = bytes32((uint256(price) << 160) | (uint256(collateral) << 64));
    }

    // check Types.PositionOrder for schema
    function decodePositionOrder(bytes32[3] memory data) internal pure returns (PositionOrder memory order) {
        order.subAccountId = bytes32(bytes23(data[0]));
        order.collateral = uint96(bytes12(data[2] << 96));
        order.size = uint96(bytes12(data[1]));
        order.flags = uint8(bytes1(data[1] << 104));
        order.price = uint96(bytes12(data[2]));
        order.profitTokenId = uint8(bytes1(data[1] << 96));
        order.expire10s = uint24(bytes3(data[1] << 136));
        order.placeOrderTime = uint32(bytes4(data[1] << 160));
    }

    // check Types.LiquidityOrder for schema
    function encodeLiquidityOrder(
        uint64 orderId,
        address account,
        uint8 assetId,
        uint96 rawAmount, // erc20.decimals
        bool isAdding,
        uint32 placeOrderTime
    ) internal pure returns (bytes32[3] memory data) {
        uint8 flags = isAdding ? 1 : 0;
        data[0] = bytes32(
            (uint256(uint160(account)) << 96) | (uint256(orderId) << 8) | uint256(OrderType.LiquidityOrder)
        );
        data[1] = bytes32(
            (uint256(rawAmount) << 160) |
                (uint256(assetId) << 152) |
                (uint256(flags) << 144) |
                (uint256(placeOrderTime) << 64)
        );
    }

    // check Types.LiquidityOrder for schema
    function decodeLiquidityOrder(bytes32[3] memory data) internal pure returns (LiquidityOrder memory order) {
        order.id = uint64(bytes8(data[0] << 184));
        order.account = address(bytes20(data[0]));
        order.rawAmount = uint96(bytes12(data[1]));
        order.assetId = uint8(bytes1(data[1] << 96));
        uint8 flags = uint8(bytes1(data[1] << 104));
        order.isAdding = flags > 0;
        order.placeOrderTime = uint32(bytes4(data[1] << 160));
    }

    // check Types.WithdrawalOrder for schema
    function encodeWithdrawalOrder(
        uint64 orderId,
        bytes32 subAccountId,
        uint96 rawAmount, // erc20.decimals
        uint8 profitTokenId,
        bool isProfit,
        uint32 placeOrderTime
    ) internal pure returns (bytes32[3] memory data) {
        require((subAccountId & LibSubAccount.SUB_ACCOUNT_ID_FORBIDDEN_BITS) == 0, "AID"); // bad subAccount ID
        uint8 flags = isProfit ? 1 : 0;
        data[0] = subAccountId | bytes32(uint256(orderId) << 8) | bytes32(uint256(OrderType.WithdrawalOrder));
        data[1] = bytes32(
            (uint256(rawAmount) << 160) |
                (uint256(profitTokenId) << 152) |
                (uint256(flags) << 144) |
                (uint256(placeOrderTime) << 64)
        );
    }

    // check Types.WithdrawalOrder for schema
    function decodeWithdrawalOrder(bytes32[3] memory data) internal pure returns (WithdrawalOrder memory order) {
        order.subAccountId = bytes32(bytes23(data[0]));
        order.rawAmount = uint96(bytes12(data[1]));
        order.profitTokenId = uint8(bytes1(data[1] << 96));
        uint8 flags = uint8(bytes1(data[1] << 104));
        order.isProfit = flags > 0;
        order.placeOrderTime = uint32(bytes4(data[1] << 160));
    }

    // check Types.RebalanceOrder for schema
    function encodeRebalanceOrder(
        uint64 orderId,
        address rebalancer,
        uint8 tokenId0,
        uint8 tokenId1,
        uint96 rawAmount0, // erc20.decimals
        uint96 maxRawAmount1, // erc20.decimals
        bytes32 userData
    ) internal pure returns (bytes32[3] memory data) {
        data[0] = bytes32(
            (uint256(uint160(rebalancer)) << 96) |
                (uint256(tokenId0) << 88) |
                (uint256(tokenId1) << 80) |
                (uint256(orderId) << 8) |
                uint256(OrderType.RebalanceOrder)
        );
        data[1] = bytes32((uint256(rawAmount0) << 160) | (uint256(maxRawAmount1) << 64));
        data[2] = userData;
    }

    // check Types.RebalanceOrder for schema
    function decodeRebalanceOrder(bytes32[3] memory data) internal pure returns (RebalanceOrder memory order) {
        order.rebalancer = address(bytes20(data[0]));
        order.tokenId0 = uint8(bytes1(data[0] << 160));
        order.tokenId1 = uint8(bytes1(data[0] << 168));
        order.rawAmount0 = uint96(bytes12(data[1]));
        order.maxRawAmount1 = uint96(bytes12(data[1] << 96));
        order.userData = data[2];
    }

    function isOpenPosition(PositionOrder memory order) internal pure returns (bool) {
        return (order.flags & POSITION_OPEN) != 0;
    }

    function isMarketOrder(PositionOrder memory order) internal pure returns (bool) {
        return (order.flags & POSITION_MARKET_ORDER) != 0;
    }

    function isWithdrawIfEmpty(PositionOrder memory order) internal pure returns (bool) {
        return (order.flags & POSITION_WITHDRAW_ALL_IF_EMPTY) != 0;
    }

    function isTriggerOrder(PositionOrder memory order) internal pure returns (bool) {
        return (order.flags & POSITION_TRIGGER_ORDER) != 0;
    }

    function isTpslStrategy(PositionOrder memory order) internal pure returns (bool) {
        return (order.flags & POSITION_TPSL_STRATEGY) != 0;
    }

    function shouldReachMinProfit(PositionOrder memory order) internal pure returns (bool) {
        return (order.flags & POSITION_SHOULD_REACH_MIN_PROFIT) != 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "../core/Types.sol";

/**
 * SubAccountId
 *         96             88        80       72        0
 * +---------+--------------+---------+--------+--------+
 * | Account | collateralId | assetId | isLong | unused |
 * +---------+--------------+---------+--------+--------+
 */
library LibSubAccount {
    bytes32 constant SUB_ACCOUNT_ID_FORBIDDEN_BITS = bytes32(uint256(0xffffffffffffffffff));

    function getSubAccountOwner(bytes32 subAccountId) internal pure returns (address account) {
        account = address(uint160(uint256(subAccountId) >> 96));
    }

    function getSubAccountCollateralId(bytes32 subAccountId) internal pure returns (uint8) {
        return uint8(uint256(subAccountId) >> 88);
    }

    function getSubAccountAssetId(bytes32 subAccountId) internal pure returns (uint8) {
        return uint8(uint256(subAccountId) >> 80);
    }

    function isLong(bytes32 subAccountId) internal pure returns (bool) {
        return uint8((uint256(subAccountId) >> 72)) > 0;
    }

    struct DecodedSubAccountId {
        address account;
        uint8 collateralId;
        uint8 assetId;
        bool isLong;
    }

    function decodeSubAccountId(bytes32 subAccountId) internal pure returns (DecodedSubAccountId memory decoded) {
        require((subAccountId & SUB_ACCOUNT_ID_FORBIDDEN_BITS) == 0, "AID"); // bad subAccount ID
        decoded.account = address(uint160(uint256(subAccountId) >> 96));
        decoded.collateralId = uint8(uint256(subAccountId) >> 88);
        decoded.assetId = uint8(uint256(subAccountId) >> 80);
        decoded.isLong = uint8((uint256(subAccountId) >> 72)) > 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

uint256 constant DEX_UNISWAP = 0;
uint256 constant DEX_CURVE = 1;

struct DexSpotConfiguration {
    uint8 dexId;
    uint8 dexType;
    uint32 dexWeight;
    uint8[] assetIds;
    uint32[] assetWeightInDex;
    uint256[] totalSpotInDex;
}

struct DexRegistration {
    address adapter;
    bool disabled;
    uint32 slippage;
}

struct DexData {
    bytes config;
    mapping(bytes32 => bytes32) states;
}

struct PluginData {
    mapping(bytes32 => bytes32) states;
}

struct CallContext {
    uint8 dexId;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IWETH9.sol";
import "../interfaces/INativeUnwrapper.sol";
import "../libraries/LibOrder.sol";

enum OrderType {
    None, // 0
    PositionOrder, // 1
    LiquidityOrder, // 2
    WithdrawalOrder, // 3
    RebalanceOrder // 4
}

struct OrderBookStorage {
    mapping(address => bool) brokers;
    ILiquidityPool pool;
    uint64 nextOrderId;
    LibOrder.OrderList orders;
    IERC20Upgradeable mlp;
    IWETH weth;
    uint32 liquidityLockPeriod; // 1e0
    INativeUnwrapper nativeUnwrapper;
    mapping(address => bool) rebalancers;
    bool isPositionOrderPaused;
    bool isLiquidityOrderPaused;
    uint32 marketOrderTimeout;
    uint32 maxLimitOrderTimeout;
    address maintainer;
    address referralManager;
    mapping(uint64 => PositionOrderExtra) positionOrderExtras; // more strategy params for a position order
    mapping(bytes32 => EnumerableSetUpgradeable.UintSet) activatedTpslOrders;
    mapping(address => bool) aggregators; // aggregator can placeOrder for a user
    uint256 callbackGasLimit;
    mapping(address => bool) callbackWhitelist;
}

//                                  160        152       144         120        96   72   64               8        0
// +----------------------------------------------------------------------------------+--------------------+--------+
// |              subAccountId 184 (already shifted by 72bits)                        |     orderId 64     | type 8 |
// +----------------------------------+----------+---------+-----------+---------+---------+---------------+--------+
// |              size 96             | profit 8 | flags 8 | unused 24 | exp 24  | time 32 |      enumIndex 64      |
// +----------------------------------+----------+---------+-----------+---------+---------+---------------+--------+
// |             price 96             |                    collateral 96                   |        unused 64       |
// +----------------------------------+----------------------------------------------------+------------------------+
struct PositionOrder {
    uint64 id;
    bytes32 subAccountId; // 160 + 8 + 8 + 8 = 184
    uint96 collateral; // erc20.decimals
    uint96 size; // 1e18
    uint96 price; // 1e18
    uint8 profitTokenId;
    uint8 flags;
    uint32 placeOrderTime; // 1e0
    uint24 expire10s; // 10 seconds. deadline = placeOrderTime + expire * 10
}

struct PositionOrderExtra {
    // tp/sl strategy
    uint96 tpPrice; // take-profit price. decimals = 18. only valid when flags.POSITION_TPSL_STRATEGY.
    uint96 slPrice; // stop-loss price. decimals = 18. only valid when flags.POSITION_TPSL_STRATEGY.
    uint8 tpslProfitTokenId; // only valid when flags.POSITION_TPSL_STRATEGY.
    uint32 tpslDeadline; // only valid when flags.POSITION_TPSL_STRATEGY.
}

//                                  160       152       144          96          72    64              8        0
// +------------------------------------------------------------------+-----------+--------------------+--------+
// |                        account 160                               | unused 24 |     orderId 64     | type 8 |
// +----------------------------------+---------+---------+-----------+-----------+-----+--------------+--------+
// |             amount 96            | asset 8 | flags 8 | unused 48 |     time 32     |      enumIndex 64     |
// +----------------------------------+---------+---------+-----------+-----------------+-----------------------+
// |                                                 unused 256                                                 |
// +------------------------------------------------------------------------------------------------------------+
struct LiquidityOrder {
    uint64 id;
    address account;
    uint96 rawAmount; // erc20.decimals
    uint8 assetId;
    bool isAdding;
    uint32 placeOrderTime; // 1e0
}

//                                  160        152       144          96   72       64               8        0
// +------------------------------------------------------------------------+------------------------+--------+
// |              subAccountId 184 (already shifted by 72bits)              |       orderId 64       | type 8 |
// +----------------------------------+----------+---------+-----------+----+--------+---------------+--------+
// |             amount 96            | profit 8 | flags 8 | unused 48 |   time 32   |      enumIndex 64      |
// +----------------------------------+----------+---------+-----------+-------------+------------------------+
// |                                                unused 256                                                |
// +----------------------------------------------------------------------------------------------------------+
struct WithdrawalOrder {
    uint64 id;
    bytes32 subAccountId; // 160 + 8 + 8 + 8 = 184
    uint96 rawAmount; // erc20.decimals
    uint8 profitTokenId;
    bool isProfit;
    uint32 placeOrderTime; // 1e0
}

//                                          160       96      88      80        72    64                 8        0
// +---------------------------------------------------+-------+-------+----------+----------------------+--------+
// |                  rebalancer 160                   | id0 8 | id1 8 | unused 8 |      orderId 64      | type 8 |
// +------------------------------------------+--------+-------+-------+----------+----+-----------------+--------+
// |                amount0 96                |                amount1 96              |       enumIndex 64       |
// +------------------------------------------+----------------------------------------+--------------------------+
// |                                                 userData 256                                                 |
// +--------------------------------------------------------------------------------------------------------------+
struct RebalanceOrder {
    uint64 id;
    address rebalancer;
    uint8 tokenId0;
    uint8 tokenId1;
    uint96 rawAmount0; // erc20.decimals
    uint96 maxRawAmount1; // erc20.decimals
    bytes32 userData;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IOrderBook.sol";
import "../interfaces/ILiquidityManager.sol";
import "../libraries/LibAsset.sol";

contract Reader {
    struct ChainStorage {
        PoolStorage pool;
        AssetStorage[] assets;
        DexStorage[] dexes;
        uint32 liquidityLockPeriod; // 1e0
        uint32 marketOrderTimeout; // 1e0
        uint32 maxLimitOrderTimeout; // 1e0
        uint256 lpDeduct; // MLP totalSupply = PRE_MINED - Σ_chains lpDeduct
        uint256 stableDeduct; // debt of stable coins = PRE_MINED - Σ_chains stableDeduct
        bool isPositionOrderPaused;
        bool isLiquidityOrderPaused;
    }

    struct PoolStorage {
        uint32 shortFundingBaseRate8H; // 1e5
        uint32 shortFundingLimitRate8H; // 1e5
        uint32 fundingInterval; // 1e0
        uint32 liquidityBaseFeeRate; // 1e5
        uint32 liquidityDynamicFeeRate; // 1e5
        uint96 mlpPriceLowerBound;
        uint96 mlpPriceUpperBound;
        uint32 lastFundingTime; // 1e0
        uint32 sequence; // 1e0. note: will be 0 after 0xffffffff
        uint32 strictStableDeviation; // 1e5
    }

    struct AssetStorage {
        // assets with the same symbol in different chains are the same asset. they shares the same muxToken. so debts of the same symbol
        // can be accumulated across chains (see Reader.AssetState.deduct). ex: ERC20(fBNB).symbol should be "BNB", so that BNBs of
        // different chains are the same.
        // since muxToken of all stable coins is the same and is calculated separately (see Reader.ChainState.stableDeduct), stable coin
        // symbol can be different (ex: "USDT", "USDT.e" and "fUSDT").
        bytes32 symbol;
        address tokenAddress; // erc20.address
        address muxTokenAddress; // muxToken.address. all stable coins share the same muxTokenAddress
        uint8 id;
        uint8 decimals; // erc20.decimals
        uint56 flags; // a bitset of ASSET_*
        uint32 initialMarginRate; // 1e5
        uint32 maintenanceMarginRate; // 1e5
        uint32 positionFeeRate; // 1e5
        uint32 liquidationFeeRate; // 1e5
        uint32 minProfitRate; // 1e5
        uint32 minProfitTime; // 1e0
        uint96 maxLongPositionSize;
        uint96 maxShortPositionSize;
        uint32 spotWeight;
        uint32 longFundingBaseRate8H; // 1e5
        uint32 longFundingLimitRate8H; // 1e5
        uint8 referenceOracleType;
        address referenceOracle;
        uint32 referenceDeviation;
        uint32 halfSpread;
        uint128 longCumulativeFundingRate; // Σ_t fundingRate_t
        uint128 shortCumulativeFunding; // Σ_t fundingRate_t * indexPrice_t
        uint96 spotLiquidity;
        uint96 credit;
        uint96 totalLongPosition;
        uint96 totalShortPosition;
        uint96 averageLongPrice;
        uint96 averageShortPrice;
        uint128 collectedFee;
        uint256 deduct; // debt of a non-stable coin = PRE_MINED - Σ_chains deduct
    }

    struct DexConfig {
        uint8 dexId;
        uint8 dexType;
        uint8[] assetIds;
        uint32[] assetWeightInDEX;
        uint32 dexWeight;
        uint256[] totalSpotInDEX;
    }

    struct DexState {
        uint8 dexId;
        uint256 dexLPBalance;
        uint256[] liquidityBalance;
    }

    struct DexStorage {
        uint8 dexId;
        uint8 dexType;
        uint8[] assetIds;
        uint32[] assetWeightInDEX;
        uint256[] totalSpotInDEX;
        uint32 dexWeight;
        uint256 dexLPBalance;
        uint256[] liquidityBalance;
    }

    struct SubAccountState {
        uint96 collateral;
        uint96 size;
        uint32 lastIncreasedTime;
        uint96 entryPrice;
        uint128 entryFunding;
    }

    ILiquidityPool public pool;
    IERC20 public mlp;
    ILiquidityManager public dex;
    IOrderBook public orderBook;
    address[] public deductWhiteList;

    constructor(
        address pool_,
        address mlp_,
        address dex_,
        address orderBook_,
        address[] memory deductWhiteList_ // muxToken in these addresses are also not considered as debt
    ) {
        pool = ILiquidityPool(pool_);
        mlp = IERC20(mlp_);
        dex = ILiquidityManager(dex_);
        orderBook = IOrderBook(orderBook_);
        uint256 listLength = deductWhiteList_.length;
        for (uint256 i = 0; i < listLength; i++) {
            deductWhiteList.push(deductWhiteList_[i]);
        }
    }

    function getChainStorage() public returns (ChainStorage memory chain) {
        // from pool
        (uint32[8] memory u32s, uint96[2] memory u96s) = pool.getLiquidityPoolStorage();
        chain.pool = _convertPoolStorage(u32s, u96s);
        // from assets
        address stableMuxTokenAddress;
        Asset[] memory assets = pool.getAllAssetInfo();
        uint256 assetLength = assets.length;
        chain.assets = new AssetStorage[](assetLength);
        for (uint256 i = 0; i < assetLength; i++) {
            chain.assets[i] = _convertAssetStorage(assets[i]);
            if ((assets[i].flags & ASSET_IS_STABLE) != 0) {
                stableMuxTokenAddress = assets[i].muxTokenAddress;
            } else {
                chain.assets[i].deduct = getDeduct(assets[i].muxTokenAddress);
            }
        }
        // from liquidityManager
        DexSpotConfiguration[] memory dexConfigs = dex.getAllDexSpotConfiguration();
        uint256 dexConfigLength = dexConfigs.length;
        chain.dexes = new DexStorage[](dexConfigLength);
        for (uint256 i = 0; i < dexConfigLength; i++) {
            chain.dexes[i] = _convertDexStorage(dexConfigs[i]);
            uint8 dexId = dexConfigs[i].dexId;
            (uint256[] memory liquidities, uint256 lpBalance) = dex.getDexLiquidity(dexId);
            chain.dexes[i].dexLPBalance = lpBalance;
            if (lpBalance == 0) {
                chain.dexes[i].liquidityBalance = new uint256[](dexConfigs[i].assetIds.length);
            } else {
                chain.dexes[i].liquidityBalance = liquidities;
            }
        }
        // from orderBook
        chain.liquidityLockPeriod = orderBook.liquidityLockPeriod();
        chain.marketOrderTimeout = orderBook.marketOrderTimeout();
        chain.maxLimitOrderTimeout = orderBook.maxLimitOrderTimeout();
        chain.isPositionOrderPaused = orderBook.isPositionOrderPaused();
        chain.isLiquidityOrderPaused = orderBook.isLiquidityOrderPaused();

        // Deduct
        chain.lpDeduct = getDeduct(address(mlp));
        if (stableMuxTokenAddress != address(0)) {
            chain.stableDeduct = getDeduct(stableMuxTokenAddress);
        }
    }

    function getDeduct(address muxToken) internal view returns (uint256 deduct) {
        deduct = IERC20(muxToken).balanceOf(address(pool));
        for (uint256 i = 0; i < deductWhiteList.length; i++) {
            deduct += IERC20(muxToken).balanceOf(deductWhiteList[i]);
        }
        return deduct;
    }

    function getSubAccounts(bytes32[] memory subAccountIds) public view returns (SubAccountState[] memory subAccounts) {
        subAccounts = new SubAccountState[](subAccountIds.length);
        for (uint256 i = 0; i < subAccountIds.length; i++) {
            (uint96 collateral, uint96 size, uint32 lastIncreasedTime, uint96 entryPrice, uint128 entryFunding) = pool
                .getSubAccount(subAccountIds[i]);
            subAccounts[i] = SubAccountState(collateral, size, lastIncreasedTime, entryPrice, entryFunding);
        }
    }

    function getOrders(
        uint64[] memory orderIds
    ) public view returns (bytes32[3][] memory orders, bool[] memory isExist) {
        orders = new bytes32[3][](orderIds.length);
        isExist = new bool[](orderIds.length);
        for (uint256 i = 0; i < orderIds.length; i++) {
            (orders[i], isExist[i]) = orderBook.getOrder(orderIds[i]);
        }
    }

    function getSubAccountsAndOrders(
        bytes32[] memory subAccountIds,
        uint64[] memory orderIds
    )
        public
        view
        returns (SubAccountState[] memory subAccounts, bytes32[3][] memory orders, bool[] memory isOrderExist)
    {
        subAccounts = new SubAccountState[](subAccountIds.length);
        for (uint256 i = 0; i < subAccountIds.length; i++) {
            (uint96 collateral, uint96 size, uint32 lastIncreasedTime, uint96 entryPrice, uint128 entryFunding) = pool
                .getSubAccount(subAccountIds[i]);
            subAccounts[i] = SubAccountState(collateral, size, lastIncreasedTime, entryPrice, entryFunding);
        }
        orders = new bytes32[3][](orderIds.length);
        isOrderExist = new bool[](orderIds.length);
        for (uint256 i = 0; i < orderIds.length; i++) {
            (orders[i], isOrderExist[i]) = orderBook.getOrder(orderIds[i]);
        }
    }

    function getErc20Balances(address[] memory tokens, address owner) public view returns (uint256[] memory balances) {
        balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = IERC20(tokens[i]).balanceOf(owner);
        }
    }

    function getPositionOrdersExtra(uint64[] memory orderIds) public view returns (PositionOrderExtra[] memory extras) {
        extras = new PositionOrderExtra[](orderIds.length);
        for (uint256 i = 0; i < orderIds.length; i++) {
            extras[i] = orderBook.positionOrderExtras(orderIds[i]);
        }
    }

    function _convertPoolStorage(
        uint32[8] memory u32s,
        uint96[2] memory u96s
    ) internal pure returns (PoolStorage memory p) {
        p.shortFundingBaseRate8H = u32s[0];
        p.shortFundingLimitRate8H = u32s[1];
        p.lastFundingTime = u32s[2];
        p.fundingInterval = u32s[3];
        p.liquidityBaseFeeRate = u32s[4];
        p.liquidityDynamicFeeRate = u32s[5];
        p.sequence = u32s[6];
        p.strictStableDeviation = u32s[7];
        p.mlpPriceLowerBound = u96s[0];
        p.mlpPriceUpperBound = u96s[1];
    }

    function _convertAssetStorage(Asset memory asset) internal pure returns (AssetStorage memory a) {
        a.symbol = asset.symbol;
        a.tokenAddress = asset.tokenAddress;
        a.muxTokenAddress = asset.muxTokenAddress;
        a.id = asset.id;
        a.decimals = asset.decimals;
        a.flags = asset.flags;
        a.initialMarginRate = asset.initialMarginRate;
        a.maintenanceMarginRate = asset.maintenanceMarginRate;
        a.positionFeeRate = asset.positionFeeRate;
        a.liquidationFeeRate = asset.liquidationFeeRate;
        a.minProfitRate = asset.minProfitRate;
        a.minProfitTime = asset.minProfitTime;
        a.maxLongPositionSize = asset.maxLongPositionSize;
        a.maxShortPositionSize = asset.maxShortPositionSize;
        a.spotWeight = asset.spotWeight;
        a.longFundingBaseRate8H = asset.longFundingBaseRate8H;
        a.longFundingLimitRate8H = asset.longFundingLimitRate8H;
        a.referenceOracleType = asset.referenceOracleType;
        a.referenceOracle = asset.referenceOracle;
        a.referenceDeviation = asset.referenceDeviation;
        a.halfSpread = asset.halfSpread;

        a.longCumulativeFundingRate = asset.longCumulativeFundingRate;
        a.shortCumulativeFunding = asset.shortCumulativeFunding;
        a.spotLiquidity = asset.spotLiquidity;
        a.credit = asset.credit;
        a.totalLongPosition = asset.totalLongPosition;
        a.totalShortPosition = asset.totalShortPosition;
        a.averageLongPrice = asset.averageLongPrice;
        a.averageShortPrice = asset.averageShortPrice;
        a.collectedFee = asset.collectedFee;
    }

    function _convertDexStorage(
        DexSpotConfiguration memory dexSpotConfiguration
    ) internal pure returns (DexStorage memory d) {
        d.dexId = dexSpotConfiguration.dexId;
        d.dexType = dexSpotConfiguration.dexType;
        d.assetIds = dexSpotConfiguration.assetIds;
        d.assetWeightInDEX = dexSpotConfiguration.assetWeightInDex;
        d.dexWeight = dexSpotConfiguration.dexWeight;
        d.totalSpotInDEX = dexSpotConfiguration.totalSpotInDex;
    }
}