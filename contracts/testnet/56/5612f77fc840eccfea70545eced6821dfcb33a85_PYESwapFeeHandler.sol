/**
 *Submitted for verification at Arbiscan on 2023-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;











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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}






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

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}






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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

        if (returndata.length > 0) {


            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}


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
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {



        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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




        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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




        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}







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









    struct Set {

        bytes32[] _values;


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

        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {





            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];


                set._values[toDeleteIndex] = lastValue;

                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }


            set._values.pop();


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


        assembly {
            result := store
        }

        return result;
    }



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


        assembly {
            result := store
        }

        return result;
    }
}




interface IPYESwapRouter {

    function addLiquidity(
        address tokenA,
        address tokenB,
        address feeTaker,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        address feeTaker,
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

    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut, 
        uint amountInMax, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function getAmountsOut(
        uint256 amountIn, 
        address[] calldata path, 
        uint totalFee
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut, 
        address[] calldata path, 
        uint totalFee
    ) external view returns (uint256[] memory amounts);

    function factory() external view returns (address);

}




interface ISmartChefPYE {

    function addWETHDonation(uint256 _amount) external;

    function totalShares() external view returns (uint256);

    function endTime() external view returns (uint256);
}




interface IPYESwapToken {

    function burn(uint256 amount) external;

}











enum Module {
    RESOLVER,
    TIME,
    PROXY,
    SINGLE_EXEC
}

struct ModuleData {
    Module[] modules;
    bytes[] args;
}

interface IAutomate {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}


/**
 * @dev Inherit this contract to allow your smart contract to
 * - Make synchronous fee payments.
 * - Have call restrictions for functions to be automated.
 */

abstract contract AutomateReady {
    IAutomate public immutable automate;
    address public immutable dedicatedMsgSender;
    address private immutable _gelato;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant OPS_PROXY_FACTORY =
        0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    /**
     * @dev
     * Only tasks created by _taskCreator defined in constructor can call
     * the functions with this modifier.
     */
    modifier onlyDedicatedMsgSender() {
        require(msg.sender == dedicatedMsgSender, "Only dedicated msg.sender");
        _;
    }

    /**
     * @dev
     * _taskCreator is the address which will create tasks for this contract.
     */
    constructor(address _automate, address _taskCreator) {
        automate = IAutomate(_automate);
        _gelato = IAutomate(_automate).gelato();
        (dedicatedMsgSender, ) = IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(
            _taskCreator
        );
    }

    /**
     * @dev
     * Transfers fee to gelato for synchronous fee payments.
     *
     * _fee & _feeToken should be queried from IAutomate.getFeeDetails()
     */
    function _transfer(uint256 _fee, address _feeToken) internal {
        if (_feeToken == ETH) {
            (bool success, ) = _gelato.call{value: _fee}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_feeToken), _gelato, _fee);
        }
    }

    function _getFeeDetails()
        internal
        view
        returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = automate.getFeeDetails();
    }
}


/**
 * @dev Inherit this contract to allow your smart contract
 * to be a task creator and create tasks.
 */
abstract contract AutomateTaskCreator is AutomateReady {
    using SafeERC20 for IERC20;

    address public immutable fundsOwner;
    ITaskTreasuryUpgradable public immutable taskTreasury;

    constructor(address _automate, address _fundsOwner)
        AutomateReady(_automate, address(this))
    {
        fundsOwner = _fundsOwner;
        taskTreasury = automate.taskTreasury();
    }

    /**
     * @dev
     * Withdraw funds from this contract's Gelato balance to fundsOwner.
     */
    function withdrawFunds(uint256 _amount, address _token) external {
        require(
            msg.sender == fundsOwner,
            "Only funds owner can withdraw funds"
        );

        taskTreasury.withdrawFunds(payable(fundsOwner), _token, _amount);
    }

    function _depositFunds(uint256 _amount, address _token) internal {
        uint256 ethValue = _token == ETH ? _amount : 0;
        taskTreasury.depositFunds{value: ethValue}(
            address(this),
            _token,
            _amount
        );
    }

    function _createTask(
        address _execAddress,
        bytes memory _execDataOrSelector,
        ModuleData memory _moduleData,
        address _feeToken
    ) internal returns (bytes32) {
        return
            automate.createTask(
                _execAddress,
                _execDataOrSelector,
                _moduleData,
                _feeToken
            );
    }

    function _cancelTask(bytes32 _taskId) internal {
        automate.cancelTask(_taskId);
    }

    function _resolverModuleArg(
        address _resolverAddress,
        bytes memory _resolverData
    ) internal pure returns (bytes memory) {
        return abi.encode(_resolverAddress, _resolverData);
    }

    function _timeModuleArg(uint256 _startTime, uint256 _interval)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(uint128(_startTime), uint128(_interval));
    }

    function _proxyModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }

    function _singleExecModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }
}


contract PYESwapFeeHandler is Ownable, AutomateTaskCreator {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 public weth;
    address public buyBackToken;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    EnumerableSet.AddressSet private tokensToSwapA;
    EnumerableSet.AddressSet private tokensToSwapB;
    mapping(address => uint256) public minimumSwapAmt;

    uint16 public development;
    uint16 public staking;
    uint16 public buyBack;

    address public developmentDest;
    address public stakingDest;
    address public vestingDest;
    bool public isStakingContract;
    bool public distributeToVesting;
    bool public useDead;

    uint256 public minimumDistribution;
    uint256 public gasReserve;
    uint32 public lastDistributed;
    uint32 public distCooldown;
    uint32 public lastSwapA;
    uint32 public swapCooldownA;
    uint32 public lastSwapB;
    uint32 public swapCooldownB;

    bytes32 private distributeTaskId;
    bytes32 private swapATaskId;
    bytes32 private swapBTaskId;

    uint256 private constant A_FACTOR = 10**18;

    IPYESwapRouter public router;
    address[] public buyBackPath;

    event RewardsDistributed(uint256 devShare, uint256 stakingShare, uint256 buybackShare, uint256 burned);

    event MinDistributionSet(uint256 minDistribution);

    event GasReserveSet(uint256 _gasReserve);

    event CooldownsSet(uint32 _distCooldown, uint32 _swapCooldownA, uint32 _swapCooldownB);
    event RouterUpdated(address _router);
    event BurnDestinationUpdated(bool _useDead);
    event BurnTokenUpdated(address _pyes);
    event FeeDestinationsSet(address developmentAddress, address stakingAddress, address vestingAddress);
    event FeeShareSet(uint16 _development, uint16 _staking, uint16 _buyBack);

    event TokenAdded(address indexed token, uint256 minSwapAmt, string tokenList);

    event TokenRemoved(address indexed token, string tokenList);

    event DistributeTaskStarted(
        bytes32 _distributeTaskId, 
        uint256 _minimumDistribution, 
        uint32 _distCooldown, 
        uint256 timestamp
    );

    event DistributeTaskStopped(bytes32 _distributeTaskId, uint256 timestamp);

    event SwapATaskStarted(bytes32 _swapATaskId, uint32 _swapCooldownA, uint256 timestamp);

    event SwapATaskStopped(bytes32 _swapATaskId, uint256 timestamp);

    event SwapBTaskStarted(bytes32 _swapBTaskId, uint32 _swapCooldownB, uint256 timestamp);

    event SwapBTaskStopped(bytes32 _swapBTaskId, uint256 timestamp);

    constructor (
        address _weth, 
        address payable _automate,
        address _developmentDest,
        address _stakingDest,
        address _vestingDest,
        uint16 devFee,
        uint16 stakingFee,
        uint16 buyBackFee,
        address _router,
        address _pyes,
        uint256 _minimumDistribution,
        uint256 _gasReserve
    ) AutomateTaskCreator(_automate, msg.sender) Ownable() {
        router = IPYESwapRouter(_router); 
        weth = IERC20(_weth);
        buyBackToken = _pyes;
        buyBackPath.push(_weth);
        buyBackPath.push(buyBackToken);
        minimumDistribution = _minimumDistribution;
        development = devFee;
        staking = stakingFee;
        buyBack = buyBackFee;
        developmentDest = _developmentDest;
        stakingDest = _stakingDest;
        vestingDest = _vestingDest;
        isStakingContract = _stakingDest != address(0);
        distributeToVesting = _vestingDest != address(0);
        gasReserve = _gasReserve;
        emit GasReserveSet(_gasReserve);
        emit FeeShareSet(devFee, stakingFee, buyBackFee);
        emit FeeDestinationsSet(_developmentDest, _stakingDest, _vestingDest);
        emit MinDistributionSet(_minimumDistribution);
        emit RouterUpdated(_router);
    }

    function updateBurnToken(address _pyes) external onlyOwner {
        buyBackToken = _pyes;
        buyBackPath[1] = _pyes;
        emit BurnTokenUpdated(_pyes);
    }

    function updateRouter(address _router) external onlyOwner {
        router = IPYESwapRouter(_router);
        emit RouterUpdated(_router);
    }

    function updateFeeShare(uint16 _development, uint16 _staking, uint16 _buyBack) external onlyOwner {
        require(_development + _staking + _buyBack == 10000, "Fee shares must equal 10000");
        development = _development;
        staking = _staking;
        buyBack = _buyBack;
        emit FeeShareSet(_development, _staking, _buyBack);
    }

    function updateFeeDest(address _developmentDest, address _stakingDest, address _vestingDest) external onlyOwner {
        developmentDest = _developmentDest;
        stakingDest = _stakingDest;
        isStakingContract = _stakingDest != address(0);
        vestingDest = _vestingDest;
        distributeToVesting = vestingDest != address(0);
        emit FeeDestinationsSet(developmentDest, stakingDest, vestingDest);
    }


    function updateMinimumDistribution(uint256 _minimumDistribution) external onlyOwner {
        minimumDistribution = _minimumDistribution;
        emit MinDistributionSet(_minimumDistribution);
    }

    function updateGasReserve(uint256 _gasReserve) external onlyOwner {
        gasReserve = _gasReserve;
        emit GasReserveSet(_gasReserve);
    }

    function updateCooldowns(uint32 _distCooldown, uint32 _swapCooldownA, uint32 _swapCooldownB) external onlyOwner {
        distCooldown = _distCooldown;
        swapCooldownA = _swapCooldownA;
        swapCooldownB = _swapCooldownB;
        emit CooldownsSet(_distCooldown, _swapCooldownA, _swapCooldownB);
    }

    function updateBurnDestination(bool _useDead) external onlyOwner {
        useDead = _useDead;
        emit BurnDestinationUpdated(_useDead);
    }

    function addTokenToSwapA(address _token, uint256 _minSwapAmt) external onlyOwner {
        require(!tokensToSwapA.contains(_token), "Token already in list");
        if (tokensToSwapB.contains(_token)) {
            tokensToSwapB.remove(_token);
            emit TokenRemoved(_token, "B");
        }
        tokensToSwapA.add(_token);
        minimumSwapAmt[_token] = _minSwapAmt;
        emit TokenAdded(_token, _minSwapAmt, "A");
    }

    function addTokenToSwapB(address _token, uint256 _minSwapAmt) external onlyOwner {
        require(!tokensToSwapB.contains(_token), "Token already in list");
        if (tokensToSwapA.contains(_token)) {
            tokensToSwapA.remove(_token);
            emit TokenRemoved(_token, "A");
        }
        tokensToSwapB.add(_token);
        minimumSwapAmt[_token] = _minSwapAmt;
        emit TokenAdded(_token, _minSwapAmt, "B");
    }

    function removeTokenToSwapA(address _token) external onlyOwner {
        require(tokensToSwapA.contains(_token), "Token not in list");
        tokensToSwapA.remove(_token);
        delete minimumSwapAmt[_token];
        emit TokenRemoved(_token, "A");
    }

    function removeTokenToSwapB(address _token) external onlyOwner {
        require(tokensToSwapB.contains(_token), "Token not in list");
        tokensToSwapB.remove(_token);
        delete minimumSwapAmt[_token];
        emit TokenRemoved(_token, "B");
    }

    function distributeRewards() external {
        _distributeRewards();
    }

    function swapATokens() external {
        _swapA();
    }
    
    function swapBTokens() external {
        _swapB();
    }

    function swapABTokens() external {
        _swapAB();
    }

    function swapNonList(address _token) external {
        uint256 bal = IERC20(_token).balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = address(weth);
        router.swapExactTokensForTokens(
            bal,
            0,
            path,
            address(this),
            block.timestamp + 5 minutes
        );
    }

    function startDistributeTask() external onlyOwner {
        ModuleData memory moduleData = ModuleData({
            modules: new Module[](2),
            args: new bytes[](2)
        });

        moduleData.modules[0] = Module.RESOLVER;
        moduleData.modules[1] = Module.PROXY;

        moduleData.args[0] = _resolverModuleArg(
            address(this),
            abi.encodeCall(this.canAutoDistributeRewards, ())
        );
        moduleData.args[1] = _proxyModuleArg();

        distributeTaskId = _createTask(
            address(this),
            abi.encode(this.autoDistributeRewards.selector),
            moduleData,
            address(weth)
        );

        emit DistributeTaskStarted(distributeTaskId, minimumDistribution, distCooldown, block.timestamp);
    }

    function stopDistributeTask() external {
        _cancelTask(distributeTaskId);
        emit DistributeTaskStopped(distributeTaskId, block.timestamp);
        delete distributeTaskId;
    }

    function autoDistributeRewards() external onlyDedicatedMsgSender {
        (uint256 fee, address feeToken) = _getFeeDetails();
        _transfer(fee, feeToken);

        _distributeRewards();
    }

    function startSwapATask() external onlyOwner {
        ModuleData memory moduleData = ModuleData({
            modules: new Module[](2),
            args: new bytes[](2)
        });

        moduleData.modules[0] = Module.RESOLVER;
        moduleData.modules[1] = Module.PROXY;

        moduleData.args[0] = _resolverModuleArg(
            address(this),
            abi.encodeCall(this.canAutoSwapA, ())
        );
        moduleData.args[1] = _proxyModuleArg();

        swapATaskId = _createTask(
            address(this),
            abi.encode(this.autoSwapA.selector),
            moduleData,
            address(weth)
        );
        emit SwapATaskStarted(swapATaskId, swapCooldownA, block.timestamp);
    }

    function stopSwapATask() external {
        _cancelTask(swapATaskId);
        emit SwapATaskStopped(swapATaskId, block.timestamp);
        delete swapATaskId;
    }

    function autoSwapA() external onlyDedicatedMsgSender {
        (uint256 fee, address feeToken) = _getFeeDetails();
        _transfer(fee, feeToken);

        _swapA();
    }

    function startSwapBTask() external onlyOwner {
        ModuleData memory moduleData = ModuleData({
            modules: new Module[](2),
            args: new bytes[](2)
        });

        moduleData.modules[0] = Module.RESOLVER;
        moduleData.modules[1] = Module.PROXY;

        moduleData.args[0] = _resolverModuleArg(
            address(this),
            abi.encodeCall(this.canAutoSwapB, ())
        );
        moduleData.args[1] = _proxyModuleArg();

        swapBTaskId = _createTask(
            address(this),
            abi.encode(this.autoSwapB.selector),
            moduleData,
            address(weth)
        );
        emit SwapBTaskStarted(swapBTaskId, swapCooldownB, block.timestamp);
    }

    function stopSwapBTask() external {
        _cancelTask(swapBTaskId);
        emit SwapBTaskStopped(swapBTaskId, block.timestamp);
        delete swapBTaskId;
    }

    function autoSwapB() external onlyDedicatedMsgSender {
        (uint256 fee, address feeToken) = _getFeeDetails();
        _transfer(fee, feeToken);

        _swapB();
    }

    function canAutoDistributeRewards() external view returns (bool canExec, bytes memory execPayload) {
        uint256 rewardBalance = weth.balanceOf(address(this)) - gasReserve;

        canExec = (
            rewardBalance >= minimumDistribution && 
            uint32(block.timestamp) >= lastDistributed + distCooldown
        );
        
        execPayload = abi.encodeCall(this.autoDistributeRewards, ());
    }

    function canAutoSwapA() external view returns (bool canExec, bytes memory execPayload) {
        canExec = (uint32(block.timestamp) >= lastSwapA + swapCooldownA);
        
        execPayload = abi.encodeCall(this.autoSwapA, ());
    }

    function canAutoSwapB() external view returns (bool canExec, bytes memory execPayload) {
        canExec = (uint32(block.timestamp) >= lastSwapB + swapCooldownB);
        
        execPayload = abi.encodeCall(this.autoSwapB, ());
    }

    function _swapA() internal {
        uint256 length = tokensToSwapA.length();
        address tkn;
        uint256 bal;
        address[] memory path = new address[](2);
        path[1] = address(weth);
        for (uint i = 0; i < length; i++) {
            tkn = tokensToSwapA.at(i);
            bal = IERC20(tkn).balanceOf(address(this));
            if (bal > minimumSwapAmt[tkn]) {
                path[0] = tkn;
                IERC20(tkn).approve(address(router), bal);
                router.swapExactTokensForTokens(
                    bal,
                    0,
                    path,
                    address(this),
                    block.timestamp + 5 minutes
                );
            } else {
                continue;
            }
        }
        lastSwapA = uint32(block.timestamp);
    }

    function _swapB() internal {
        uint256 length = tokensToSwapB.length();
        address tkn;
        uint256 bal;
        address[] memory path = new address[](2);
        path[1] = address(weth);
        for (uint i = 0; i < length; i++) {
            tkn = tokensToSwapB.at(i);
            bal = IERC20(tkn).balanceOf(address(this));
            if (bal > minimumSwapAmt[tkn]) {
                path[0] = tkn;
                IERC20(tkn).approve(address(router), bal);
                router.swapExactTokensForTokens(
                    bal,
                    0,
                    path,
                    address(this),
                    block.timestamp + 5 minutes
                );
            } else {
                continue;
            }
        }
        lastSwapB = uint32(block.timestamp);
    }   

    function _swapAB() internal {
        _swapA();
        _swapB();
    }

    function _distributeRewards() internal {
        uint256 rewardBalance = weth.balanceOf(address(this)) - gasReserve;
        require(rewardBalance >= minimumDistribution, "Too few tokens");
        uint256 devShare = (rewardBalance * development) / 10000;
        uint256 stakingShare = (rewardBalance * staking) / 10000;
        uint256 buybackShare = (rewardBalance * buyBack) / 10000;
        uint256 burnedAmount;
        if (devShare > 0) { 
            weth.safeTransfer(developmentDest, devShare); 
        }

        if (stakingShare > 0) {
            if (isStakingContract) {
                if (distributeToVesting) {
                    if (ISmartChefPYE(vestingDest).endTime() < block.timestamp) {
                        distributeToVesting = false;
                    }
                    uint256 _stakingShares = ISmartChefPYE(stakingDest).totalShares();
                    uint256 _vestingShares = ISmartChefPYE(vestingDest).totalShares();
                    uint256 _totalShares = _stakingShares + _vestingShares;

                    uint256 _vestingRate = (_vestingShares * A_FACTOR) / _totalShares;

                    uint256 _vestingShare = (_vestingRate * stakingShare) / A_FACTOR;
                    uint256 _stakingShare = stakingShare - _vestingShare;

                    weth.approve(stakingDest, _stakingShare);
                    ISmartChefPYE(stakingDest).addWETHDonation(_stakingShare);

                    weth.approve(vestingDest, _vestingShare);
                    ISmartChefPYE(vestingDest).addWETHDonation(_vestingShare);
                } else {
                    weth.approve(stakingDest, stakingShare);
                    ISmartChefPYE(stakingDest).addWETHDonation(stakingShare);
                }
            } else {
                weth.safeTransfer(stakingDest, stakingShare);
            }
        }
        if (buybackShare > 0) {
            weth.approve(address(router), buybackShare);
            uint256[] memory amounts = router.swapExactTokensForTokens(
                buybackShare,
                0,
                buyBackPath,
                useDead ? DEAD : address(this),
                block.timestamp + 5 minutes
            );
            if (!useDead) { IPYESwapToken(buyBackToken).burn(amounts[1]); }
            burnedAmount = amounts[1];
        }

        lastDistributed = uint32(block.timestamp);
        emit RewardsDistributed(devShare, stakingShare, buybackShare, burnedAmount);
    }
       
}