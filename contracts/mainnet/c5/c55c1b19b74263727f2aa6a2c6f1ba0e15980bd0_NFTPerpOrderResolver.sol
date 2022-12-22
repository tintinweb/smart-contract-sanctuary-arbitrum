// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/INFTPerpOrder.sol";
import "./utils/Decimal.sol";
import "./utils/Errors.sol";
import { LibOrder } from "./utils/LibOrder.sol";
import "./utils/Structs.sol";

contract NFTPerpOrder is INFTPerpOrder, Ownable(), ReentrancyGuard(){
    using Decimal for Decimal.decimal;
    using LibOrder for Structs.Order;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    // All open orders
    EnumerableSet.Bytes32Set private openOrders;

    //Fee Manager address
    address private immutable feeManager;
    //Management Fee(paid in eth)
    uint256 public managementFee;
    //mapping(Order Hash/Id -> Order)
    mapping(bytes32 => Structs.Order) public order;
    //mapping(Order Hash/Id -> bool)
    mapping(bytes32 => bool) public orderExecuted;

    constructor(address _feeManager){
        feeManager = _feeManager;
    }


    //
    //      |============================================================================================|
    //      |        BUY/SELL        |     TYPE OF ORDER         |     PRICE LEVEL OF TRIGGER PRICE      |
    //      |============================================================================================|
    //      |          BUY           |    BUY LIMIT ORDER        |    Trigger Price < or = Latest Price  |
    //      |                        |    BUY STOP LOSS ORDER    |    Trigger Price > or = Latest Price  |
    //      |------------------------|---------------------------|---------------------------------------|
    //      |          SELL          |    SELL LIMIT ORDER       |    Trigger Price > or = Latest Price  |
    //      |                        |    SELL STOP LOSS ORDER   |    Trigger Price < or = Latest Price  |
    //      |============================================================================================|
    //
    ///@notice Creates a Market Order(Limit or StopLoss Order). 
    ///        - https://www.investopedia.com/terms/l/limitorder.asp
    ///        - https://www.investopedia.com/articles/stocks/09/use-stop-loss.asp
    ///@param _amm amm
    ///@param _orderType order type
    ///@param _expirationTimestamp order expiry timestamp
    ///@param _triggerPrice trigger/execution price of an order
    ///@param _slippage slippage(0 for any slippage)
    ///@param _leverage leverage, only use when creating a BUY/SELL limit order
    ///@param _quoteAssetAmount quote asset amount, only use when creating a BUY/SELL limit order
    ///@return orderHash
    function createOrder(
        IAmm _amm,
        Structs.OrderType _orderType, 
        uint64 _expirationTimestamp,
        uint256 _triggerPrice,
        Decimal.decimal memory _slippage,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _quoteAssetAmount
    ) external payable override nonReentrant() returns(bytes32 orderHash){
        address _account = msg.sender;
        orderHash = _getOrderHash(_amm, _orderType, _account);
        // checks if order is valid
        _validOrder(_expirationTimestamp, orderHash);
        
        Structs.Order storage _order = order[orderHash];
        _order.trigger = _triggerPrice;
        _order.position.amm = _amm;
        _order.position.slippage = _slippage;

        if(_orderType == Structs.OrderType.SELL_LO || _orderType == Structs.OrderType.BUY_LO){
            // Limit Order quote asset amount should be gt zero
            if(_quoteAssetAmount.toUint() == 0)
                revert Errors.InvalidQuoteAssetAmount();

            _order.position.quoteAssetAmount = _quoteAssetAmount;
            _order.position.leverage = _leverage;

        } else {
            int256 positionSize = LibOrder.getPositionSize(_amm, _account);
            // Positon size cannot be equal to zero (No open position)
            if(positionSize == 0) 
                revert Errors.NoOpenPositon();
            // store quote asset amount of user's current open position (open notional)
            _order.position.quoteAssetAmount = LibOrder.getPositionNotional(_amm, _account);
        }

        uint256 _detail;
        //                             [256 bits]
        //        ===========================================================
        //        |  32 bits     |      160 bits      |       64 bits       |  
        //        -----------------------------------------------------------
        //        | orderType    |      account       | expirationTimestamp |
        //        ===========================================================

        _detail = uint256(_orderType) << 248 | (uint224(uint160(_account)) << 64 | _expirationTimestamp);

        _order.detail = _detail;
        // add order hash to open orders
        openOrders.add(orderHash);
        // trasnsfer fees to Fee-Manager Contract
        _transferFee();

        orderExecuted[orderHash] = false;

        emit OrderCreated(orderHash, _account, address(_amm), uint8(_orderType));
    }

    ///@notice Cancels an Order
    ///@param _orderHash order hash/ID
    function cancelOrder(bytes32 _orderHash) external override nonReentrant(){
        Structs.Order memory _order = order[_orderHash];
        if(!_order.isAccountOwner()) revert Errors.InvalidOperator();
        if(_orderExecuted(_orderHash)) revert Errors.OrderAlreadyExecuted();
        //can only cancel open orders
        if(!_isOpenOrder(_orderHash)) revert Errors.NotOpenOrder();

        //delete order data from mapping and Open Orders array;
        delete order[_orderHash];
        openOrders.remove(_orderHash);
    }

    ///@notice Executes an open order
    ///@param _orderHash order hash/ID
    function executeOrder(bytes32 _orderHash) public override nonReentrant(){
        if(!canExecuteOrder(_orderHash)) revert Errors.CannotExecuteOrder();
        orderExecuted[_orderHash] = true;
        Structs.Order memory _order = order[_orderHash];

        // execute order
        _order.executeOrder();

        //delete order data from Open Orders array;
        openOrders.remove(_orderHash);

        emit OrderExecuted(_orderHash);
    }

    function clearExpiredOrders() public override nonReentrant(){
        bytes32[] memory _openOrders = getOpenOrders();
        uint256 _openOrderLen = _openOrders.length;
        for (uint256 i = 0; i < _openOrderLen; i++) {
            bytes32 _orderHash = _openOrders[i];
            Structs.Order memory _openOrder = order[_orderHash];
            (,, uint64 expiry) = _openOrder.getOrderDetails();
            if(expiry != 0 && block.timestamp >= expiry){
                //delete order data from mapping and Open Orders array;
                delete order[_orderHash];
                openOrders.remove(_orderHash);
            }
        }
    }

    ///@notice Set new management fee
    ///@param _fee new fee amount
    function setManagementFee(uint256 _fee) external onlyOwner(){
        managementFee = _fee;
        emit SetManagementFee(_fee);
    }

    ///@notice Checks if an Order can be executed
    ///@return bool 
    function canExecuteOrder(bytes32 _orderHash) public view override returns(bool){
        return order[_orderHash].canExecuteOrder() && !_orderExecuted(_orderHash);
    }

    ///@notice Fetches all Open Orders
    ///@return bytes[] - array of all Open Orders
    function getOpenOrders() public view returns(bytes32[] memory){
        return openOrders.values();
    }

    //checks if Order is valid during Order creation 
    function _validOrder(
        uint64 expirationTimestamp, 
        bytes32  _orderHash
    ) internal view {
        // cannot have two orders  with same ID
        if(_isOpenOrder(_orderHash)) revert Errors.OrderAlreadyExists();
        // ensure - expiration timestamp == 0 (no expiry) or not lt current timestamp
        if(expirationTimestamp > 0 && expirationTimestamp < block.timestamp)
            revert Errors.InvalidExpiration();
    }

    function _orderExecuted(bytes32 _orderHash) internal view returns(bool){
        return orderExecuted[_orderHash];
    }

    function _isOpenOrder(bytes32 _orderHash) internal view returns(bool){
        return openOrders.contains(_orderHash);
    }

    function _getOrderHash(IAmm _amm, Structs.OrderType _orderType, address _account) internal pure returns(bytes32){
        return keccak256(
            abi.encodePacked(
                _amm, 
                _orderType, 
                _account
            )
        );
    }

    function _transferFee() internal {
        if(managementFee > 0){
            if(msg.value != managementFee) revert Errors.IncorrectFee();
            (bool sent,) = feeManager.call{value: msg.value}("");
            if(!sent) revert Errors.TransferFailed();
        }
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "./NFTPerpOrder.sol";
import "./NFTPerpOrder.sol";
import "./interfaces/IResolver.sol";
import "./interfaces/OpsReady.sol";

contract NFTPerpOrderResolver is OpsReady, IResolver {
    NFTPerpOrder public immutable _NFTPerpOrder_;

    constructor(address _nftPerpOrder, address _ops) OpsReady(_ops){
        _NFTPerpOrder_ = NFTPerpOrder(_nftPerpOrder);
    }

    //https://docs.gelato.network/developer-products/gelato-ops-smart-contract-automation-hub/methods-for-submitting-your-task/smart-contract
    function startTask() external {
        IOps(ops).createTask(
            address(_NFTPerpOrder_), 
            _NFTPerpOrder_.executeOrder.selector,
            address(this),
            abi.encodeWithSelector(this.checker.selector)
        );
    }
    
    //https://docs.gelato.network/developer-products/gelato-ops-smart-contract-automation-hub/guides/writing-a-resolver/smart-contract-resolver#checking-multiple-functions-in-one-resolver
    function checker() external view returns (bool canExec, bytes memory execPayload) {
        bytes32[] memory _openOrders = _NFTPerpOrder_.getOpenOrders();
        uint256 _openOrderLen = _openOrders.length;
        for (uint256 i = 0; i < _openOrderLen; i++) {

            canExec = _NFTPerpOrder_.canExecuteOrder(_openOrders[i]);

            execPayload = abi.encodeWithSelector(
                _NFTPerpOrder_.executeOrder.selector,
                _openOrders[i]
            );

            if (canExec) break;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Decimal } from "../utils/Decimal.sol";
import { SignedDecimal } from "../utils/SignedDecimal.sol";

interface IAmm {
    /**
     * @notice asset direction, used in getInputPrice, getOutputPrice, swapInput and swapOutput
     * @param ADD_TO_AMM add asset to Amm
     * @param REMOVE_FROM_AMM remove asset from Amm
     */
    enum Dir {
        ADD_TO_AMM,
        REMOVE_FROM_AMM
    }

    struct Ratios {
        Decimal.decimal feeRatio;
        Decimal.decimal initMarginRatio;
        Decimal.decimal maintenanceMarginRatio;
        Decimal.decimal partialLiquidationRatio;
        Decimal.decimal liquidationFeeRatio;
    }

    function swapInput(
        Dir _dirOfQuote,
        Decimal.decimal calldata _quoteAssetAmount,
        Decimal.decimal calldata _baseAssetAmountLimit,
        bool _canOverFluctuationLimit
    ) external returns (Decimal.decimal memory);

    function swapOutput(
        Dir _dirOfBase,
        Decimal.decimal calldata _baseAssetAmount,
        Decimal.decimal calldata _quoteAssetAmountLimit
    ) external returns (Decimal.decimal memory);

    function settleFunding()
        external
        returns (
            SignedDecimal.signedDecimal memory premiumFraction,
            Decimal.decimal memory markPrice,
            Decimal.decimal memory indexPrice
        );

    function repegPrice()
        external
        returns (
            Decimal.decimal memory,
            Decimal.decimal memory,
            Decimal.decimal memory,
            Decimal.decimal memory,
            SignedDecimal.signedDecimal memory
        );

    function repegK(Decimal.decimal memory _multiplier)
        external
        returns (
            Decimal.decimal memory,
            Decimal.decimal memory,
            Decimal.decimal memory,
            Decimal.decimal memory,
            SignedDecimal.signedDecimal memory
        );

    function updateFundingRate(
        SignedDecimal.signedDecimal memory,
        SignedDecimal.signedDecimal memory,
        Decimal.decimal memory
    ) external;

    //
    // VIEW
    //

    function calcFee(
        Dir _dirOfQuote,
        Decimal.decimal calldata _quoteAssetAmount,
        bool _isOpenPos
    ) external view returns (Decimal.decimal memory fees);

    function getMarkPrice() external view returns (Decimal.decimal memory);

    function getIndexPrice() external view returns (Decimal.decimal memory);

    function getReserves() external view returns (Decimal.decimal memory, Decimal.decimal memory);

    function getFeeRatio() external view returns (Decimal.decimal memory);

    function getInitMarginRatio() external view returns (Decimal.decimal memory);

    function getMaintenanceMarginRatio() external view returns (Decimal.decimal memory);

    function getPartialLiquidationRatio() external view returns (Decimal.decimal memory);

    function getLiquidationFeeRatio() external view returns (Decimal.decimal memory);

    function getMaxHoldingBaseAsset() external view returns (Decimal.decimal memory);

    function getOpenInterestNotionalCap() external view returns (Decimal.decimal memory);

    function getBaseAssetDelta() external view returns (SignedDecimal.signedDecimal memory);

    function fundingPeriod() external view returns (uint256);

    function quoteAsset() external view returns (IERC20);

    function open() external view returns (bool);

    function getRatios() external view returns (Ratios memory);

    function calcPriceRepegPnl(Decimal.decimal memory _repegTo)
        external
        view
        returns (SignedDecimal.signedDecimal memory repegPnl);

    function calcKRepegPnl(Decimal.decimal memory _k)
        external
        view
        returns (SignedDecimal.signedDecimal memory repegPnl);

    function isOverFluctuationLimit(Dir _dirOfBase, Decimal.decimal memory _baseAssetAmount)
        external
        view
        returns (bool);

    function isOverSpreadLimit() external view returns (bool);

    function getInputTwap(Dir _dir, Decimal.decimal calldata _quoteAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getOutputTwap(Dir _dir, Decimal.decimal calldata _baseAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getInputPrice(Dir _dir, Decimal.decimal calldata _quoteAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getOutputPrice(Dir _dir, Decimal.decimal calldata _baseAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getInputPriceWithReserves(
        Dir _dir,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) external view returns (Decimal.decimal memory);

    function getOutputPriceWithReserves(
        Dir _dir,
        Decimal.decimal memory _baseAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) external view returns (Decimal.decimal memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Decimal } from "../utils/Decimal.sol";
import { SignedDecimal } from "../utils/SignedDecimal.sol";
import { IAmm } from "./IAmm.sol";
import { IDelegateApproval } from "./IDelegateApproval.sol";

interface IClearingHouse {
    /// @notice BUY = LONG, SELL = SHORT
    enum Side {
        BUY,
        SELL
    }

    /**
     * @title Position
     * @notice This struct records position information
     * @param size denominated in amm.baseAsset
     * @param margin isolated margin (collateral amt)
     * @param openNotional the quoteAsset value of the position. the cost of the position
     * @param lastUpdatedCumulativePremiumFraction for calculating funding payment, recorded at position update
     * @param blockNumber recorded at every position update
     */
    struct Position {
        SignedDecimal.signedDecimal size;
        Decimal.decimal margin;
        Decimal.decimal openNotional;
        SignedDecimal.signedDecimal lastUpdatedCumulativePremiumFractionLong;
        SignedDecimal.signedDecimal lastUpdatedCumulativePremiumFractionShort;
        uint256 blockNumber;
    }

    enum PnlCalcOption {
        SPOT_PRICE,
        ORACLE
    }

    //
    // EVENTS
    //

    /**
     * @notice This event is emitted when position is changed
     * @param trader - trader
     * @param amm - amm
     * @param margin - updated margin
     * @param exchangedPositionNotional - the position notional exchanged in the trade
     * @param exchangedPositionSize - the position size exchanged in the trade
     * @param fee - trade fee
     * @param positionSizeAfter - updated position size
     * @param realizedPnl - realized pnl on the trade
     * @param unrealizedPnlAfter - unrealized pnl remaining after the trade
     * @param badDebt - margin cleared by insurance fund (optimally 0)
     * @param liquidationPenalty - liquidation fee
     * @param markPrice - updated mark price
     * @param fundingPayment - funding payment (+: paid, -: received)
     */
    event PositionChanged(
        address indexed trader,
        address indexed amm,
        uint256 margin,
        uint256 exchangedPositionNotional,
        int256 exchangedPositionSize,
        uint256 fee,
        int256 positionSizeAfter,
        int256 realizedPnl,
        int256 unrealizedPnlAfter,
        uint256 badDebt,
        uint256 liquidationPenalty,
        uint256 markPrice,
        int256 fundingPayment
    );

    /**
     * @notice This event is emitted when position is liquidated
     * @param trader - trader
     * @param amm - amm
     * @param liquidator - liquidator
     * @param liquidatedPositionNotional - liquidated position notional
     * @param liquidatedPositionSize - liquidated position size
     * @param liquidationReward - liquidation reward to the liquidator
     * @param insuranceFundProfit - insurance fund profit on liquidation
     * @param badDebt - liquidation fee cleared by insurance fund (optimally 0)
     */
    event PositionLiquidated(
        address indexed trader,
        address indexed amm,
        address indexed liquidator,
        uint256 liquidatedPositionNotional,
        uint256 liquidatedPositionSize,
        uint256 liquidationReward,
        uint256 insuranceFundProfit,
        uint256 badDebt
    );

    /**
     * @notice emitted on funding payments
     * @param amm - amm
     * @param markPrice - mark price on funding
     * @param indexPrice - index price on funding
     * @param premiumFractionLong - total premium longs pay (when +ve), receive (when -ve)
     * @param premiumFractionShort - total premium shorts receive (when +ve), pay (when -ve)
     * @param insuranceFundPnl - insurance fund pnl from funding
     */
    event FundingPayment(
        address indexed amm,
        uint256 markPrice,
        uint256 indexPrice,
        int256 premiumFractionLong,
        int256 premiumFractionShort,
        int256 insuranceFundPnl
    );

    /**
     * @notice emitted on adding or removing margin
     * @param trader - trader address
     * @param amm - amm address
     * @param amount - amount changed
     * @param fundingPayment - funding payment
     */
    event MarginChanged(
        address indexed trader,
        address indexed amm,
        int256 amount,
        int256 fundingPayment
    );

    /**
     * @notice emitted on repeg (convergence event)
     * @param amm - amm address
     * @param quoteAssetReserveBefore - quote reserve before repeg
     * @param baseAssetReserveBefore - base reserve before repeg
     * @param quoteAssetReserveAfter - quote reserve after repeg
     * @param baseAssetReserveAfter - base reserve after repeg
     * @param repegPnl - effective pnl incurred on vault positions after repeg
     * @param repegDebt - amount borrowed from insurance fund
     */
    event Repeg(
        address indexed amm,
        uint256 quoteAssetReserveBefore,
        uint256 baseAssetReserveBefore,
        uint256 quoteAssetReserveAfter,
        uint256 baseAssetReserveAfter,
        int256 repegPnl,
        uint256 repegDebt
    );

    /// @notice emitted on setting repeg bots
    event RepegBotSet(address indexed amm, address indexed bot);

    //
    // EXTERNAL
    //

    function delegateApproval() external view returns(IDelegateApproval);

    /**
     * @notice open a position
     * @param _amm amm address
     * @param _side enum Side; BUY for long and SELL for short
     * @param _quoteAssetAmount quote asset amount in 18 digits. Can Not be 0
     * @param _leverage leverage in 18 digits. Can Not be 0
     * @param _baseAssetAmountLimit base asset amount limit in 18 digits (slippage). 0 for any slippage
     */
    function openPosition(
        IAmm _amm,
        Side _side,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _baseAssetAmountLimit
    ) external;

    function openPositionFor(
        IAmm _amm,
        Side _side,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _baseAssetAmountLimit,
        address _trader
    ) external;

    /**
     * @notice close position
     * @param _amm amm address
     * @param _quoteAssetAmountLimit quote asset amount limit in 18 digits (slippage). 0 for any slippage
     */
    function closePosition(IAmm _amm, Decimal.decimal memory _quoteAssetAmountLimit)
        external;

    function closePositionFor(IAmm _amm, Decimal.decimal memory _quoteAssetAmountLimit, address _trader)
        external;


    /**
     * @notice partially close position
     * @param _amm amm address
     * @param _partialCloseRatio % to close
     * @param _quoteAssetAmountLimit quote asset amount limit in 18 digits (slippage). 0 for any slippage
     */
    function partialClose(
        IAmm _amm,
        Decimal.decimal memory _partialCloseRatio,
        Decimal.decimal memory _quoteAssetAmountLimit
    ) external;

    function partialCloseFor(
        IAmm _amm,
        Decimal.decimal memory _partialCloseRatio,
        Decimal.decimal memory _quoteAssetAmountLimit,
        address _trader
    ) external;

    /**
     * @notice add margin to increase margin ratio
     * @param _amm amm address
     * @param _addedMargin added margin in 18 digits
     */
    function addMargin(IAmm _amm, Decimal.decimal calldata _addedMargin)
        external;
    
    function addMarginFor(IAmm _amm, Decimal.decimal calldata _addedMargin, address _trader)
        external;
       
    /**
     * @notice remove margin to decrease margin ratio
     * @param _amm amm address
     * @param _removedMargin removed margin in 18 digits
     */
    function removeMargin(IAmm _amm, Decimal.decimal calldata _removedMargin)
        external;

    function removeMarginFor(IAmm _amm, Decimal.decimal calldata _removedMargin, address _trader)
        external;
        
    /**
     * @notice liquidate trader's underwater position. Require trader's margin ratio less than maintenance margin ratio
     * @param _amm amm address
     * @param _trader trader address
     */
    function liquidate(IAmm _amm, address _trader) external;

    /**
     * @notice settle funding payment
     * @dev dynamic funding mechanism refer (https://nftperp.notion.site/Technical-Stuff-8e4cb30f08b94aa2a576097a5008df24)
     * @param _amm amm address
     */
    function settleFunding(IAmm _amm) external;

  
    //
    // PUBLIC
    //

    /**
     * @notice get personal position information
     * @param _amm IAmm address
     * @param _trader trader address
     * @return struct Position
     */
    function getPosition(IAmm _amm, address _trader) external view returns (Position memory);

    /**
     * @notice get margin ratio, marginRatio = (margin + funding payment + unrealized Pnl) / positionNotional
     * @param _amm amm address
     * @param _trader trader address
     * @return margin ratio in 18 digits
     */
    function getMarginRatio(IAmm _amm, address _trader)
        external
        view
        returns (SignedDecimal.signedDecimal memory);

    /**
     * @notice get position notional and unrealized Pnl without fee expense and funding payment
     * @param _amm amm address
     * @param _trader trader address
     * @param _pnlCalcOption enum PnlCalcOption, SPOT_PRICE for spot price and ORACLE for oracle price
     * @return positionNotional position notional
     * @return unrealizedPnl unrealized Pnl
     */
    // unrealizedPnlForLongPosition = positionNotional - openNotional
    // unrealizedPnlForShortPosition = positionNotionalWhenBorrowed - positionNotionalWhenReturned =
    // openNotional - positionNotional = unrealizedPnlForLongPosition * -1
    function getPositionNotionalAndUnrealizedPnl(
        IAmm _amm,
        address _trader,
        PnlCalcOption _pnlCalcOption
    )
        external
        view
        returns (
            Decimal.decimal memory positionNotional,
            SignedDecimal.signedDecimal memory unrealizedPnl
        );

    /**
     * @notice get latest cumulative premium fraction.
     * @param _amm IAmm address
     * @return latestCumulativePremiumFractionLong cumulative premium fraction long
     * @return latestCumulativePremiumFractionShort cumulative premium fraction short
     */
    function getLatestCumulativePremiumFraction(IAmm _amm)
        external
        view
        returns (
            SignedDecimal.signedDecimal memory latestCumulativePremiumFractionLong,
            SignedDecimal.signedDecimal memory latestCumulativePremiumFractionShort
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;
pragma abicoder v2;

interface IDelegateApproval {
    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @param actions The actions to be approved
    event DelegationApproved(address indexed trader, address delegate, uint8 actions);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @param actions The actions to be revoked
    event DelegationRevoked(address indexed trader, address delegate, uint8 actions);

    /// @param delegate The address of delegate
    /// @param actions The actions to be approved
    function approve(address delegate, uint8 actions) external;

    /// @param delegate The address of delegate
    /// @param actions The actions to be revoked
    function revoke(address delegate, uint8 actions) external;

    /// @return action The value of action `_CLEARINGHOUSE_OPENPOSITION`
    function getClearingHouseOpenPositionAction() external pure returns (uint8);

    /// @return action The value of action `_CLEARINGHOUSE_CLOSEPOSITION`
    function getClearingHouseClosePositionAction() external pure returns (uint8);

    /// @return action The value of action `_CLEARINGHOUSE_ADDMARGIN`
    function getClearingHouseAddMarginAction() external pure returns (uint8);

    /// @return action The value of action `_CLEARINGHOUSE_REMOVEMARGIN`
    function getClearingHouseRemoveMarginAction() external pure returns (uint8);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @return actions The approved actions
    function getApprovedActions(address trader, address delegate) external view returns (uint8);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @param actions The actions to be checked
    /// @return true if delegate is allowed to perform **each** actions for trader, otherwise false
    function hasApprovalFor(
        address trader,
        address delegate,
        uint8 actions
    ) external view returns (bool);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @return true if delegate can open position for trader, otherwise false
    function canOpenPositionFor(address trader, address delegate) external view returns (bool);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @return true if delegate can close position for trader, otherwise false
    function canClosePositionFor(address trader, address delegate) external view returns (bool);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @return true if delegate can add margin for trader, otherwise false
    function canAddMarginFor(address trader, address delegate) external view returns (bool);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @return true if delegate can remove margin for trader, otherwise false
    function canRemoveMarginFor(address trader, address delegate) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;
import { Decimal } from "../utils/Decimal.sol";
import { SignedDecimal } from "../utils/SignedDecimal.sol";
import { IAmm } from "./IAmm.sol";
import "../utils/Structs.sol";

interface INFTPerpOrder {
    event OrderCreated(bytes32 indexed orderHash, address indexed account, address indexed amm, uint8 orderType);
    event OrderExecuted(bytes32 indexed orderhash);
    event SetManagementFee(uint256 _fee);

    function createOrder(
        IAmm _amm,
        Structs.OrderType _orderType, 
        uint64 _expirationTimestamp,
        uint256 _triggerPrice,
        Decimal.decimal memory _slippage,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _quoteAssetAmount
    ) external payable returns(bytes32);

    function executeOrder(bytes32 _orderHash) external;

    function cancelOrder(bytes32 _orderHash) external;

    function clearExpiredOrders() external;

    function canExecuteOrder(bytes32 _orderhash) external view returns(bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IResolver {
    function checker()
        external
        view
        returns (bool canExec, bytes memory execPayload);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {
    SafeERC20,
    IERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IOps {
    function createTask(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external returns (bytes32 task);
    
    function gelato() external view returns (address payable);
}

abstract contract OpsReady {
    address public immutable ops;
    address payable public immutable gelato;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    modifier onlyOps() {
        require(msg.sender == ops, "OpsReady: onlyOps");
        _;
    }

    constructor(address _ops) {
        ops = _ops;
        gelato = IOps(_ops).gelato();
    }

    function _transfer(uint256 _amount, address _paymentToken) internal {
        if (_paymentToken == ETH) {
            (bool success, ) = gelato.call{value: _amount}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_paymentToken), gelato, _amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { DecimalMath } from "./DecimalMath.sol";

library Decimal {
    using DecimalMath for uint256;

    struct decimal {
        uint256 d;
    }

    function zero() internal pure returns (decimal memory) {
        return decimal(0);
    }

    function one() internal pure returns (decimal memory) {
        return decimal(DecimalMath.unit(18));
    }

    function toUint(decimal memory x) internal pure returns (uint256) {
        return x.d;
    }

    function modD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        return decimal((x.d * (DecimalMath.unit(18))) % y.d);
    }

    function cmp(decimal memory x, decimal memory y) internal pure returns (int8) {
        if (x.d > y.d) {
            return 1;
        } else if (x.d < y.d) {
            return -1;
        }
        return 0;
    }

    /// @dev add two decimals
    function addD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.addd(y.d);
        return t;
    }

    /// @dev subtract two decimals
    function subD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.subd(y.d);
        return t;
    }

    /// @dev multiple two decimals
    function mulD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.muld(y.d);
        return t;
    }

    /// @dev multiple a decimal by a uint256
    function mulScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d * y;
        return t;
    }

    /// @dev divide two decimals
    function divD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.divd(y.d);
        return t;
    }

    /// @dev divide a decimal by a uint256
    function divScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d / y;
        return t;
    }

    /// @dev square root
    function sqrt(decimal memory _y) internal pure returns (decimal memory) {
        uint256 y = _y.d * 1e18;
        uint256 z;
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        return decimal(z);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

library DecimalMath {
    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (uint256) {
        return 10**uint256(decimals);
    }

    /// @dev Adds x and y, assuming they are both fixed point with 18 decimals.
    function addd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x + y;
    }

    /// @dev Subtracts y from x, assuming they are both fixed point with 18 decimals.
    function subd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x - y;
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function muld(uint256 x, uint256 y) internal pure returns (uint256) {
        return muld(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function muld(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return (x * y) / (unit(decimals));
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divd(uint256 x, uint256 y) internal pure returns (uint256) {
        return divd(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divd(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return (x * unit(decimals)) / (y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Errors {
    error IncorrectFee();
    error NotOpenOrder();
    error NoOpenPositon();
    error InvalidAccount();
    error TransferFailed();
    error InvalidOperator();
    error InvalidExpiration();
    error OrderAlreadyExists();
    error CannotExecuteOrder();
    error OrderAlreadyExecuted();
    error InvalidQuoteAssetAmount();
    error InvalidManagerOrOperator();
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAmm.sol";
import "../interfaces/IClearingHouse.sol";
import "../interfaces/INFTPerpOrder.sol";
import "./Decimal.sol";
import "./SignedDecimal.sol";
import "./Structs.sol";

library LibOrder {
    using Decimal for Decimal.decimal;
    using SignedDecimal for SignedDecimal.signedDecimal;

    IClearingHouse public constant clearingHouse = IClearingHouse(0x24D9D8767385805334ebd35243Dc809d0763b891);

    // Execute open order
    function executeOrder(Structs.Order memory orderStruct) internal {
        (Structs.OrderType orderType, address account,) = getOrderDetails(orderStruct);

        Decimal.decimal memory quoteAssetAmount = orderStruct.position.quoteAssetAmount;
        Decimal.decimal memory slippage = orderStruct.position.slippage;
        IAmm _amm = orderStruct.position.amm;
        
        if(orderType == Structs.OrderType.BUY_SLO || orderType == Structs.OrderType.SELL_SLO){
            // calculate current notional amount of user's position
            // - if notional amount gt initial quoteAsset amount set partially close position
            // - else close entire positon
            Decimal.decimal memory positionNotional = getPositionNotional(_amm, account);
            if(positionNotional.d > quoteAssetAmount.d){
                // partially close position
                clearingHouse.partialCloseFor(
                    _amm, 
                    quoteAssetAmount.divD(positionNotional), 
                    slippage, 
                    account
                );
            } else {
                // fully close position
                clearingHouse.closePositionFor(
                    _amm, 
                    slippage, 
                    account
                );
            } 
        } else {
            IClearingHouse.Side side = orderType == Structs.OrderType.BUY_LO ? IClearingHouse.Side.BUY : IClearingHouse.Side.SELL;
            // execute Limit Order(open position)
            clearingHouse.openPositionFor(
                _amm, 
                side, 
                quoteAssetAmount, 
                orderStruct.position.leverage, 
                slippage, 
                account
            );
        }
    }

    function _approveToCH(IERC20 _token, uint256 _amount) internal {
        _token.approve(address(clearingHouse), _amount);
    }

    function isAccountOwner(Structs.Order memory orderStruct) public view returns(bool){
        (, address account ,) = getOrderDetails(orderStruct);
        return msg.sender == account;
    }

    function canExecuteOrder(Structs.Order memory orderStruct) public view returns(bool){
        (Structs.OrderType orderType, address account , uint64 expiry) = getOrderDetails(orderStruct);
        // should be markprice
        uint256 _markPrice = orderStruct.position.amm.getMarkPrice().toUint();
        // order has not expired
        bool _ts = expiry == 0 || block.timestamp < expiry;
        // price trigger is met
        bool _pr;
        // account has allowance
        bool _ha;
        // order contract is delegate
        bool isDelegate;
        // position size
        int256 positionSize = getPositionSize(orderStruct.position.amm, account);
        //how to check if a position is open?
        bool _op = positionSize != 0;

        if(orderType == Structs.OrderType.BUY_SLO || orderType == Structs.OrderType.SELL_SLO){
            isDelegate = clearingHouse.delegateApproval().canClosePositionFor(account, address(this));
            _ha = hasEnoughBalanceAndApproval(
                orderStruct.position.amm,
                getPositionNotional(orderStruct.position.amm, account),
                0,
                positionSize > 0 ? IClearingHouse.Side.SELL : IClearingHouse.Side.BUY,
                false,
                account
            );
            _pr = orderType == Structs.OrderType.BUY_SLO 
                    ? _markPrice >= orderStruct.trigger
                    : _markPrice <= orderStruct.trigger;
        } else {
            isDelegate = clearingHouse.delegateApproval().canOpenPositionFor(account, address(this));
            _ha = hasEnoughBalanceAndApproval(
                orderStruct.position.amm,
                orderStruct.position.quoteAssetAmount.mulD(orderStruct.position.leverage),
                orderStruct.position.quoteAssetAmount.toUint(),
                 orderType == Structs.OrderType.BUY_LO ? IClearingHouse.Side.BUY : IClearingHouse.Side.SELL,
                true,
                account
            );
            _op = true;
            _pr = orderType == Structs.OrderType.BUY_LO 
                    ? _markPrice <= orderStruct.trigger
                    : _markPrice >= orderStruct.trigger;
        }

        return _ts && _pr && _op && _ha && isDelegate;
    }


    function hasEnoughBalanceAndApproval(
        IAmm _amm, 
        Decimal.decimal memory _positionNotional,
        uint256 _qAssetAmt,
        IClearingHouse.Side _side, 
        bool _isOpenPos, 
        address account
    ) internal view returns(bool){
        uint256 fees = calculateFees(
            _amm, 
            _positionNotional,
            _side, 
            _isOpenPos
        ).toUint();
        uint256 balance = getAccountBalance(_amm.quoteAsset(), account);
        uint256 chApproval = getAllowanceCH(_amm.quoteAsset(), account);
        return balance >= _qAssetAmt + fees  && chApproval >= _qAssetAmt + fees;
    }


    ///@dev Get user's position size
    function getPositionSize(IAmm amm, address account) public view returns(int256){
         return clearingHouse.getPosition(amm, account).size.toInt();
    }

    ///@dev Get User's positon notional amount
    function getPositionNotional(IAmm amm, address account) public view returns(Decimal.decimal memory){
         return clearingHouse.getPosition(amm, account).openNotional;
    }
    function getPositionMargin(IAmm amm, address account) public view returns(Decimal.decimal memory){
        return clearingHouse.getPosition(amm, account).margin;
    }
    
    ///@dev Get Order Info/Details
    function getOrderDetails(
        Structs.Order memory orderStruct
    ) public pure returns(Structs.OrderType, address, uint64){
        //Todo: make more efficient
        return (
            Structs.OrderType(uint8(orderStruct.detail >> 248)),
            address(uint160(orderStruct.detail << 32 >> 96)),
            uint64(orderStruct.detail << 192 >> 192)
        );  
    }
    function getAllowanceCH(IERC20 token, address account) internal view returns(uint256){
        return token.allowance(account, address(clearingHouse));
    }

    function getAccountBalance(IERC20 token, address account) internal view returns(uint256){
        return token.balanceOf(account);
    }

    function calculateFees(
        IAmm _amm,
        Decimal.decimal memory _positionNotional,
        IClearingHouse.Side _side,
        bool _isOpenPos
    ) internal view returns (Decimal.decimal memory fees) {
        fees = _amm.calcFee(
            _side == IClearingHouse.Side.BUY ? IAmm.Dir.ADD_TO_AMM : IAmm.Dir.REMOVE_FROM_AMM,
            _positionNotional,
            _isOpenPos
        );
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { SignedDecimalMath } from "./SignedDecimalMath.sol";
import { Decimal } from "./Decimal.sol";

library SignedDecimal {
    using SignedDecimalMath for int256;

    struct signedDecimal {
        int256 d;
    }

    function zero() internal pure returns (signedDecimal memory) {
        return signedDecimal(0);
    }

    function toInt(signedDecimal memory x) internal pure returns (int256) {
        return x.d;
    }

    function isNegative(signedDecimal memory x) internal pure returns (bool) {
        if (x.d < 0) {
            return true;
        }
        return false;
    }

    function abs(signedDecimal memory x) internal pure returns (Decimal.decimal memory) {
        Decimal.decimal memory t;
        if (x.d < 0) {
            t.d = uint256(0 - x.d);
        } else {
            t.d = uint256(x.d);
        }
        return t;
    }

    /// @dev add two decimals
    function addD(signedDecimal memory x, signedDecimal memory y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d.addd(y.d);
        return t;
    }

    /// @dev subtract two decimals
    function subD(signedDecimal memory x, signedDecimal memory y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d.subd(y.d);
        return t;
    }

    /// @dev multiple two decimals
    function mulD(signedDecimal memory x, signedDecimal memory y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d.muld(y.d);
        return t;
    }

    /// @dev multiple a signedDecimal by a int256
    function mulScalar(signedDecimal memory x, int256 y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d * y;
        return t;
    }

    /// @dev divide two decimals
    function divD(signedDecimal memory x, signedDecimal memory y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d.divd(y.d);
        return t;
    }

    /// @dev divide a signedDecimal by a int256
    function divScalar(signedDecimal memory x, int256 y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d / y;
        return t;
    }

    /// @dev square root
    function sqrt(signedDecimal memory _y) internal pure returns (signedDecimal memory) {
        int256 y = _y.d * 1e18;
        int256 z;
        if (y > 3) {
            z = y;
            int256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        return signedDecimal(z);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

/// @dev Implements simple signed fixed point math add, sub, mul and div operations.
library SignedDecimalMath {
    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (int256) {
        return int256(10**uint256(decimals));
    }

    /// @dev Adds x and y, assuming they are both fixed point with 18 decimals.
    function addd(int256 x, int256 y) internal pure returns (int256) {
        return x + y;
    }

    /// @dev Subtracts y from x, assuming they are both fixed point with 18 decimals.
    function subd(int256 x, int256 y) internal pure returns (int256) {
        return x - y;
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function muld(int256 x, int256 y) internal pure returns (int256) {
        return muld(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function muld(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return (x * y) / unit(decimals);
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divd(int256 x, int256 y) internal pure returns (int256) {
        return divd(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divd(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return (x * unit(decimals)) / (y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "../interfaces/IAmm.sol";
import "./Decimal.sol";

library Structs {
    enum OrderType {
        SELL_LO, 
        BUY_LO, 
        SELL_SLO,
        BUY_SLO
    }

    struct Position {
        IAmm amm;
        Decimal.decimal quoteAssetAmount;
        Decimal.decimal slippage;
        Decimal.decimal leverage;
    }

    struct Order {
        // ordertype, account, expirationTimestamp
        uint256 detail;
        uint256 trigger;
        Position position;
    }
}