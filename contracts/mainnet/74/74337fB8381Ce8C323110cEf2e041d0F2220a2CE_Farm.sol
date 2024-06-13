// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import {IFarm, IERC20} from "./interfaces/IFarm.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Farming Contract
/// @notice Implements staking functionality to earn rewards over time based on staked tokens.
/// @dev Inherits from Ownable for ownership management and uses SafeERC20 for safe ERC20 interactions.
contract Farm is IFarm, Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Used for precision in reward calculations.
    uint256 public constant PRECISION = 1e18;

    /// @notice The minimum time gap required for token withdrawal after pool ends.
    uint256 public constant WITHDRAW_TOKEN_GAP = 14 days;

    // solhint-disable-next-line
    uint256 public immutable poolStartTime;

    IERC20 public rewardToken;
    uint256 public totalAllocPoint;
    uint256 public poolEndTime;
    uint256 public sharesPerSecond;
    uint256 public totalPendingShare;

    /// @dev Set of addresses that are authorized to perform certain operations.
    EnumerableSet.AddressSet private _operators;
    PoolInfo[] private _poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) private _userInfo;

    /// @inheritdoc IFarm
    function operators(uint256 index) external view returns (address) {
        return _operators.at(index);
    }

    /// @inheritdoc IFarm
    function operatorsCount() external view returns (uint256) {
        return _operators.length();
    }

    /// @inheritdoc IFarm
    function operatorsContains(address operator) external view returns (bool) {
        return _operators.contains(operator);
    }

    /// @inheritdoc IFarm
    function poolInfo(uint256 index) external view returns (PoolInfo memory) {
        return _poolInfo[index];
    }

    /// @inheritdoc IFarm
    function poolLength() external view returns (uint256) {
        return _poolInfo.length;
    }

    /// @inheritdoc IFarm
    function userInfo(uint256 pid, address user) external view returns (UserInfo memory) {
        return _userInfo[pid][user];
    }

    /// @inheritdoc IFarm
    function pendingShare(uint256 pid, address user) external view returns (uint256) {
        PoolInfo storage pool = _poolInfo[pid];
        UserInfo storage user_ = _userInfo[pid][user];
        uint256 accRewardSharePerShare = pool.accRewardSharePerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0)
            accRewardSharePerShare += ((((getGeneratedReward(pool.lastRewardTime, block.timestamp) * pool.allocPoint) /
                totalAllocPoint) * PRECISION) / tokenSupply);
        return ((user_.amount * accRewardSharePerShare) / PRECISION) - user_.rewardDebt;
    }

    /// @inheritdoc IFarm
    function getGeneratedReward(uint256 fromTime, uint256 toTime) public view returns (uint256) {
        if (fromTime >= toTime) return 0;
        if (toTime >= poolEndTime) {
            if (fromTime >= poolEndTime) return 0;
            if (fromTime <= poolStartTime) return (poolEndTime - poolStartTime) * sharesPerSecond;
            return (poolEndTime - fromTime) * sharesPerSecond;
        } else {
            if (toTime <= poolStartTime) return 0;
            if (fromTime <= poolStartTime) return (toTime - poolStartTime) * sharesPerSecond;
            return (toTime - fromTime) * sharesPerSecond;
        }
    }

    /// @dev Constructor initializes the farming contract with the necessary details.
    /// @param rewardToken_ Address of the reward token.
    /// @param poolStartTime_ The start time of the pool.
    /// @param poolEndTime_ The end time of the pool.
    /// @param sharesPerSecond_ The amount of shares distributed per second.
    constructor(
        address rewardToken_,
        uint256 poolStartTime_,
        uint256 poolEndTime_,
        uint256 sharesPerSecond_
    ) Ownable(msg.sender) {
        if (block.timestamp >= poolStartTime_) revert CurrentTimeGtPoolStartTime(block.timestamp, poolStartTime_);
        if (poolStartTime_ > poolEndTime_) revert PoolStartTimeGtEndTime(poolStartTime_, poolEndTime_);
        if (rewardToken_ == address(0)) revert RewardTokenZero();
        rewardToken = IERC20(rewardToken_);
        poolStartTime = poolStartTime_;
        poolEndTime = poolEndTime_;
        sharesPerSecond = sharesPerSecond_;
    }

    /// @inheritdoc IFarm
    function deposit(uint256 pid, uint256 amount) external returns (bool) {
        return depositFor(pid, amount, msg.sender);
    }

    /// @inheritdoc IFarm
    /// @dev Updates pool and user information, calculates pending rewards, and transfers tokens.
    function depositFor(uint256 pid, uint256 amount, address target) public returns (bool) {
        if (target == address(0)) revert DepositForTargetZero();
        address caller = msg.sender;
        PoolInfo storage pool = _poolInfo[pid];
        UserInfo storage user = _userInfo[pid][target];
        updatePool(pid);
        if (user.amount > 0) {
            uint256 pending_ = ((user.amount * pool.accRewardSharePerShare) / PRECISION) - user.rewardDebt;
            if (pending_ > 0) {
                totalPendingShare -= pending_;
                _safeRewardTokenShareTransfer(target, pending_);
                emit RewardPaid(target, pending_);
            }
        }
        if (amount > 0) {
            pool.token.safeTransferFrom(caller, address(this), amount);
            user.amount += amount;
        }
        user.rewardDebt = (user.amount * pool.accRewardSharePerShare) / PRECISION;
        emit Deposited(target, pid, caller, amount);
        return true;
    }

    /// @inheritdoc IFarm
    /// @dev Updates pool and user information, calculates pending rewards, and transfers tokens.
    function withdraw(uint256 pid, uint256 amount) external returns (bool) {
        address caller = msg.sender;
        PoolInfo storage pool = _poolInfo[pid];
        UserInfo storage user = _userInfo[pid][caller];
        if (user.amount < amount) revert WithdrawAmountGtAvailable(user.amount, amount);
        updatePool(pid);
        uint256 pending_ = ((user.amount * pool.accRewardSharePerShare) / PRECISION) - user.rewardDebt;
        if (pending_ > 0) {
            totalPendingShare -= pending_;
            _safeRewardTokenShareTransfer(caller, pending_);
            emit RewardPaid(caller, pending_);
        }
        if (amount > 0) {
            user.amount -= amount;
            pool.token.safeTransfer(caller, amount);
        }
        user.rewardDebt = (user.amount * pool.accRewardSharePerShare) / PRECISION;
        emit Withdrawn(caller, pid, amount);
        return true;
    }

    /// @inheritdoc IFarm
    /// @dev Clears user's staked balance and reward debt, then transfers tokens.
    function emergencyWithdraw(uint256 pid) external returns (bool) {
        address caller = msg.sender;
        UserInfo storage user = _userInfo[pid][caller];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        _poolInfo[pid].token.safeTransfer(caller, amount);
        emit EmergencyWithdrawn(caller, pid, amount);
        return true;
    }

    /// @inheritdoc IFarm
    /// @dev Can be used to recover tokens mistakenly sent to the contract. Checks for pool end time and withdrawal gap.
    function withdrawToken(IERC20 token, uint256 amount, address to) external onlyOwner returns (bool) {
        massUpdatePools();
        uint256 poolLength_ = _poolInfo.length;
        if (block.timestamp < poolEndTime + WITHDRAW_TOKEN_GAP) {
            if (token == rewardToken) revert WithdrawTokenRecoverTokenEqRewardToken(address(token));
            for (uint256 pid = 0; pid < poolLength_; pid++)
                if (token == _poolInfo[pid].token) revert WithdrawTokenRecoverTokenEqPoolToken(address(token));
        } else if (token == rewardToken) {
            uint256 rewardBalance = rewardToken.balanceOf(address(this));
            if (rewardBalance <= totalPendingShare)
                revert WithdrawTokenRewardBalanceLteTotalPendingShare(rewardBalance, totalPendingShare);
            uint256 availableAmount = rewardBalance - totalPendingShare;
            if (amount > availableAmount) revert WithdrawTokenWithdrawAmountGtAvailable(amount, availableAmount);
        }
        token.safeTransfer(to, amount);
        emit TokenWithdrawn(address(token), to, amount);
        return true;
    }

    /// @inheritdoc IFarm
    function addPool(
        uint256 allocPoint,
        IERC20 token,
        bool withUpdate,
        uint256 lastRewardTime
    ) external onlyOperator returns (bool) {
        uint256 len = _poolInfo.length;
        for (uint256 pid = 0; pid < len; pid++)
            if (_poolInfo[pid].token == token) revert AddPoolDuplicateExistsPool(address(token));
        if (token == rewardToken) revert AddPoolTokenEqRewardToken(address(token));
        if (withUpdate) massUpdatePools();
        if (block.timestamp < poolStartTime) {
            if (lastRewardTime == 0) lastRewardTime = poolStartTime;
            else if (lastRewardTime < poolStartTime) lastRewardTime = poolStartTime;
        } else if (lastRewardTime == 0 || lastRewardTime < block.timestamp) lastRewardTime = block.timestamp;
        bool _isStarted = (lastRewardTime <= poolStartTime) || (lastRewardTime <= block.timestamp);
        PoolInfo memory poolInfo_ = PoolInfo({
            token: token,
            allocPoint: allocPoint,
            lastRewardTime: lastRewardTime,
            accRewardSharePerShare: 0,
            isStarted: _isStarted
        });
        _poolInfo.push(poolInfo_);
        if (_isStarted) totalAllocPoint = totalAllocPoint + allocPoint;
        emit PoolAdded(len, poolInfo_);
        return true;
    }

    /// @inheritdoc IFarm
    function updatePoolAllocPoint(uint256 pid, uint256 allocPoint) external onlyOperator returns (bool) {
        massUpdatePools();
        PoolInfo storage pool = _poolInfo[pid];
        if (pool.isStarted) totalAllocPoint = totalAllocPoint - pool.allocPoint + allocPoint;
        pool.allocPoint = allocPoint;
        emit PoolAllocPointUpdated(pid, allocPoint);
        return true;
    }

    /// @inheritdoc IFarm
    function setSharesPerSecond(uint256 sharesPerSecond_) external onlyOperator returns (bool) {
        sharesPerSecond = sharesPerSecond_;
        emit SharesPerSecondSetted(sharesPerSecond_);
        return true;
    }

    /// @inheritdoc IFarm
    function setPoolEndTime(uint256 poolEndTime_) external onlyOperator returns (bool) {
        if (poolEndTime_ < block.timestamp) revert SetPoolEndTimeEndTimeLtCurrentTime(poolEndTime_, block.timestamp);
        if (poolEndTime_ <= poolStartTime) revert SetPoolEndTimeEndTimeLtStartTime(poolEndTime_, poolStartTime);
        poolEndTime = poolEndTime_;
        emit PoolEndTimeSetted(poolEndTime_);
        return true;
    }

    /// @inheritdoc IFarm
    function addOperators(address[] memory operators_) external onlyOwner returns (bool) {
        uint256 len = operators_.length;
        for (uint256 i = 0; i < len; i++) if (_operators.add(operators_[i])) emit OperatorAdded(operators_[i]);
        return true;
    }

    /// @inheritdoc IFarm
    function removeOperators(address[] memory operators_) external onlyOwner returns (bool) {
        uint256 len = operators_.length;
        for (uint256 i = 0; i < len; i++) if (_operators.remove(operators_[i])) emit OperatorRemoved(operators_[i]);
        return true;
    }

    /// @inheritdoc IFarm
    function massUpdatePools() public returns (bool) {
        uint256 len = _poolInfo.length;
        for (uint256 pid = 0; pid < len; pid++) updatePool(pid);
        return true;
    }

    /// @inheritdoc IFarm
    function updatePool(uint256 pid) public returns (bool) {
        PoolInfo storage pool = _poolInfo[pid];
        if (block.timestamp <= pool.lastRewardTime) return false;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return true;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint += pool.allocPoint;
        }
        if (totalAllocPoint > 0) {
            uint256 reward_ = (getGeneratedReward(pool.lastRewardTime, block.timestamp) * pool.allocPoint) /
                totalAllocPoint;
            totalPendingShare += reward_;
            pool.accRewardSharePerShare = pool.accRewardSharePerShare + ((reward_ * PRECISION) / tokenSupply);
        }
        pool.lastRewardTime = block.timestamp;
        emit PoolUpdated(pid);
        return true;
    }

    /// @dev Transfers reward tokens safely.
    /// @param to The address to transfer rewards to.
    /// @param amount The amount of rewards to transfer.
    /// @dev Uses SafeERC20.safeTransfer to prevent token transfer errors.
    function _safeRewardTokenShareTransfer(address to, uint256 amount) private {
        uint256 rewardBal = rewardToken.balanceOf(address(this));
        if (rewardBal > 0) {
            if (amount > rewardBal) rewardToken.safeTransfer(to, rewardBal);
            else rewardToken.safeTransfer(to, amount);
        }
    }

    /// @dev Ensures the function is called by an operator.
    modifier onlyOperator() {
        if (!_operators.contains(msg.sender)) revert CallerNotOperator(msg.sender);
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Interface for a Farming Contract
/// @notice This interface defines the core functions, events and errors for a farming contract where users can stake tokens to earn rewards over time.
interface IFarm {
    /// @notice Defines the user's stake information in a farm pool.
    /// @param amount The amount of tokens the user has staked.
    /// @param rewardDebt The amount of rewards already accounted for the user.
    /// @dev Stores the amount of tokens staked by a user and the corresponding reward debt.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    /// @notice Defines information about each pool in the farm.
    /// @param token The ERC20 token used for staking in this pool.
    /// @param allocPoint How many allocation points assigned to this pool. Determines the share of rewards.
    /// @param lastRewardTime Last timestamp that rewards were calculated for the pool.
    /// @param accRewardSharePerShare Accumulated rewards per share, scaled to some factor.
    /// @param isStarted If true, rewards can be earned from this pool.
    /// @dev Stores the staking token, allocation points, reward calculation data, and the pool's status.
    struct PoolInfo {
        IERC20 token;
        uint256 allocPoint;
        uint256 lastRewardTime;
        uint256 accRewardSharePerShare;
        bool isStarted;
    }

    /// @notice Gets the address of an operator by index.
    /// @param index The index of the operator in the list of operators.
    /// @return The address of the operator at the given index.
    function operators(uint256 index) external view returns (address);

    /// @notice Gets the total number of operators.
    /// @return The total number of operators.
    function operatorsCount() external view returns (uint256);

    /// @notice Checks if an address is an operator.
    /// @param operator The address to check.
    /// @return True if the address is an operator, false otherwise.
    function operatorsContains(address operator) external view returns (bool);

    /// @notice Gets the token used for rewards.
    /// @return The ERC20 reward token.
    function rewardToken() external view returns (IERC20);

    /// @notice Gets the total allocation points across all pools.
    /// @return The total allocation points.
    function totalAllocPoint() external view returns (uint256);

    /// @notice Gets the start time of the pool.
    /// @dev Start time of the reward pool, immutable for contract lifetime.
    /// @return The pool's start time.
    function poolStartTime() external view returns (uint256);

    /// @notice Gets the end time of the pool.
    /// @return The pool's end time.
    function poolEndTime() external view returns (uint256);

    /// @notice Gets the reward rate per second.
    /// @return The reward rate in shares per second.
    function sharesPerSecond() external view returns (uint256);

    /// @notice Calculates the total pending shares awaiting distribution.
    /// @return The total pending shares.
    function totalPendingShare() external view returns (uint256);

    /// @notice Gets information about a specific pool.
    /// @param index The index of the pool.
    /// @return A `PoolInfo` struct with the pool's details.
    function poolInfo(uint256 index) external view returns (PoolInfo memory);

    /// @notice Gets the total number of pools.
    /// @return The total number of pools.
    function poolLength() external view returns (uint256);

    /// @notice Gets a user's stake information in a specific pool.
    /// @param pid The ID of the pool.
    /// @param user The address of the user.
    /// @return A `UserInfo` struct with the user's stake information.
    function userInfo(uint256 pid, address user) external view returns (UserInfo memory);

    /// @notice Calculates the pending share for a user in a given pool.
    /// @param pid Pool ID for which to calculate the pending share.
    /// @param user Address of the user for whom to calculate the pending share.
    /// @return The amount of pending share for the user in the specified pool.
    function pendingShare(uint256 pid, address user) external view returns (uint256);

    /// @notice Calculates the reward generated between two timestamps.
    /// @param fromTime Start time for the calculation.
    /// @param toTime End time for the calculation.
    /// @return The amount of reward generated between the given timestamps.
    function getGeneratedReward(uint256 fromTime, uint256 toTime) external view returns (uint256);

    /// @notice Emitted when a user deposits tokens into a pool.
    /// @param user The address of the user.
    /// @param pid The ID of the pool.
    /// @param depositor The address that performed the deposit.
    /// @param amount The amount of tokens deposited.
    event Deposited(address indexed user, uint256 indexed pid, address indexed depositor, uint256 amount);

    /// @notice Emitted when a user withdraws tokens from a pool.
    /// @param user The address of the user.
    /// @param pid The ID of the pool.
    /// @param amount The amount of tokens withdrawn.
    event Withdrawn(address indexed user, uint256 indexed pid, uint256 amount);

    /// @notice Emitted when a user performs an emergency withdrawal from a pool.
    /// @param user The address of the user.
    /// @param pid The ID of the pool.
    /// @param amount The amount of tokens withdrawn in an emergency.
    event EmergencyWithdrawn(address indexed user, uint256 indexed pid, uint256 amount);

    /// @notice Emitted when tokens are withdrawn from the contract by an operator.
    /// @param token The address of the token withdrawn.
    /// @param to The address the tokens were sent to.
    /// @param amount The amount of tokens withdrawn.
    event TokenWithdrawn(address indexed token, address indexed to, uint256 amount);

    /// @notice Emitted when rewards are paid out to a user.
    /// @param user The address of the user.
    /// @param amount The amount of rewards paid.
    event RewardPaid(address indexed user, uint256 amount);

    /// @notice Emitted when an operator is added.
    /// @param operator The address of the operator added.
    event OperatorAdded(address indexed operator);

    /// @notice Emitted when an operator is removed.
    /// @param operator The address of the operator removed.
    event OperatorRemoved(address indexed operator);

    /// @notice Emitted when a new pool is added to the farm.
    /// @param pid The ID of the new pool.
    /// @param poolInfo The details of the pool added.
    event PoolAdded(uint256 pid, PoolInfo poolInfo);

    /// @notice Emitted when the end time of the pool is set.
    /// @param endTime The new end time of the pool.
    event PoolEndTimeSetted(uint256 endTime);

    /// @notice Emitted when the shares per second are set.
    /// @param sharesPerSecond The new shares per second rate.
    event SharesPerSecondSetted(uint256 sharesPerSecond);

    /// @notice Emitted when a pool's allocation points are updated.
    /// @param pid The ID of the pool updated.
    /// @param allocPoint The new allocation points for the pool.
    event PoolAllocPointUpdated(uint256 indexed pid, uint256 allocPoint);

    /// @notice Emitted when a pool is updated.
    /// @param pid The ID of the pool updated.
    event PoolUpdated(uint256 indexed pid);

    /// @notice Error thrown when the current time is greater than the pool's start time.
    /// @param currentTime The current timestamp.
    /// @param poolStartTime The start time of the pool.
    error CurrentTimeGtPoolStartTime(uint256 currentTime, uint256 poolStartTime);

    /// @notice Error thrown when the pool's start time is greater than its end time.
    /// @param startTime The start time of the pool.
    /// @param endTime The end time of the pool.
    error PoolStartTimeGtEndTime(uint256 startTime, uint256 endTime);

    /// @notice Error thrown when the reward token is the zero address.
    error RewardTokenZero();

    /// @notice Error thrown when the caller is not an operator.
    /// @param caller The address of the caller.
    error CallerNotOperator(address caller);

    /// @notice Error thrown when setting an operator to the zero address.
    error SetOperatorOperatorZero();

    /// @notice Error thrown when attempting to deposit for the zero address.
    error DepositForTargetZero();

    /// @notice Error thrown when attempting to recover tokens equal to the reward token.
    /// @param token The address of the token attempted to be withdrawn.
    error WithdrawTokenRecoverTokenEqRewardToken(address token);

    /// @notice Error thrown when attempting to recover tokens equal to a pool's staking token.
    /// @param token The address of the token attempted to be withdrawn.
    error WithdrawTokenRecoverTokenEqPoolToken(address token);

    /// @notice Error thrown when the reward token's balance is less than or equal to the total pending shares.
    /// @param rewardBalance The balance of the reward token.
    /// @param totalPendingShare The total pending shares.
    error WithdrawTokenRewardBalanceLteTotalPendingShare(uint256 rewardBalance, uint256 totalPendingShare);

    /// @notice Error thrown when the amount to be withdrawn is greater than the available balance.
    /// @param amount The amount attempted to be withdrawn.
    /// @param available The available balance.
    error WithdrawTokenWithdrawAmountGtAvailable(uint256 amount, uint256 available);

    /// @notice Error thrown when setting the pool's end time to a timestamp earlier than the current time.
    /// @param poolEndTime The new end time for the pool.
    /// @param currentTime The current timestamp.
    error SetPoolEndTimeEndTimeLtCurrentTime(uint256 poolEndTime, uint256 currentTime);

    /// @notice Error thrown when setting the pool's end time to a timestamp earlier than its start time.
    /// @param poolEndTime The new end time for the pool.
    /// @param poolStartTime The start time of the pool.
    error SetPoolEndTimeEndTimeLtStartTime(uint256 poolEndTime, uint256 poolStartTime);

    /// @notice Error thrown when the withdrawal amount is greater than the available balance.
    /// @param amount The amount attempted to be withdrawn.
    /// @param available The available balance.
    error WithdrawAmountGtAvailable(uint256 amount, uint256 available);

    /// @notice Error thrown when a duplicate pool exists for a given token.
    /// @param token The address of the token.
    error AddPoolDuplicateExistsPool(address token);

    /// @notice Error thrown when a reward token equal for a given token.
    /// @param token The address of the token.
    error AddPoolTokenEqRewardToken(address token);

    /// @notice Allows a user to deposit tokens into a specified pool.
    /// @param pid The pool ID.
    /// @param amount The amount of tokens to deposit.
    /// @return bool Returns true if the deposit was successful.
    function deposit(uint256 pid, uint256 amount) external returns (bool);

    /// @notice Allows a user or contract to deposit tokens on behalf of another address.
    /// @param pid The pool ID.
    /// @param amount The amount of tokens to deposit.
    /// @param target The address for which the deposit is being made.
    /// @return bool Returns true if the deposit was successful.
    function depositFor(uint256 pid, uint256 amount, address target) external returns (bool);

    /// @notice Allows a user to withdraw staked tokens from a pool.
    /// @param pid The pool ID.
    /// @param amount The amount of tokens to withdraw.
    /// @return bool Returns true if the withdrawal was successful.
    function withdraw(uint256 pid, uint256 amount) external returns (bool);

    /// @notice Allows a user to withdraw all staked tokens from a pool without collecting rewards.
    /// @param pid The pool ID.
    /// @return bool Returns true if the emergency withdrawal was successful.
    function emergencyWithdraw(uint256 pid) external returns (bool);

    /// @notice Allows the owner to withdraw ERC20 tokens from the contract.
    /// @param token The token to withdraw.
    /// @param amount The amount of tokens to withdraw.
    /// @param to The recipient of the tokens.
    /// @return bool Returns true if the withdrawal was successful.
    function withdrawToken(IERC20 token, uint256 amount, address to) external returns (bool);

    /// @notice Allows the operator to add a new pool to the farm.
    /// @param allocPoint The allocation points for the new pool.
    /// @param token The staking token for the new pool.
    /// @param withUpdate Whether to update all pools before adding the new one.
    /// @param lastRewardTime The last time rewards were calculated for the new pool.
    /// @return True if the pool was added successfully, false otherwise.
    function addPool(uint256 allocPoint, IERC20 token, bool withUpdate, uint256 lastRewardTime) external returns (bool);

    /// @notice Allows the operator to update the allocation points for a specific pool.
    /// @param pid The ID of the pool.
    /// @param allocPoint The new allocation points for the pool.
    /// @return True if the update was successful, false otherwise.
    function updatePoolAllocPoint(uint256 pid, uint256 allocPoint) external returns (bool);

    /// @notice Update all pools to reflect changes in allocation points or reward rates.
    /// @return True if the update was successful for all pools, false otherwise.
    function massUpdatePools() external returns (bool);

    /// @notice Allows the operator to set the rate of rewards per second.
    /// @param sharesPerSecond_ The new reward rate in shares per second.
    /// @return True if the update was successful, false otherwise.
    function setSharesPerSecond(uint256 sharesPerSecond_) external returns (bool);

    /// @notice Allows the operator to set the end time for the pool, after which no more rewards are distributed.
    /// @param poolEndTime_ The new end time for the pool.
    /// @return True if the end time was set successfully, false otherwise.
    function setPoolEndTime(uint256 poolEndTime_) external returns (bool);

    /// @notice Update a specific pool to reflect changes in allocation points or reward rates.
    /// @param pid The ID of the pool to update.
    /// @return True if the pool was updated successfully, false otherwise.
    function updatePool(uint256 pid) external returns (bool);

    /// @notice Allows the owner to add multiple operators.
    /// @param operators_ The addresses to be added as operators.
    /// @return True if all operators were added successfully, false otherwise.
    function addOperators(address[] memory operators_) external returns (bool);

    /// @notice Allows the owner to remove multiple operators.
    /// @param operators_ The addresses to be removed as operators.
    /// @return True if all operators were removed successfully, false otherwise.
    function removeOperators(address[] memory operators_) external returns (bool);
}