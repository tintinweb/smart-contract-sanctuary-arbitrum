/**
 *Submitted for verification at Arbiscan on 2023-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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
}

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
}

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
}

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

library IDOSaleStructs {
    struct ReturnInfo {
        uint256 price;
        uint256 raise;
        uint256 minAmount;
        uint256 maxAmount;
        uint256 startTime;
        uint256 duration;
        uint256 totalSold;
        uint256 totalEarned;
        uint256 totalBonus;
        address presaleTokenAddress;
        string presaleTokenSymbol;
        uint8 presaleTokenDecimals;
        uint256 userPreSaleTokenBal;
        bool whitelistIsEnable;
        uint256 userSpentAmount;
        uint256 userBoughtAmount;
        uint256 userRewardsAmount;
        uint256 userBonusesAmount;
        uint256 vestingManagersCount;
        bool IsWhitelisted;
        address userReferrer;
        address[] vestingManagers;
        address[] userVestingWallets;
        uint256 totalDistributionRatio;
    }
}

interface ICrowdsale {
    struct Vesting {
        address vestingManager;
        uint256 distributionPercentage;
    }

    event TokenSold(address indexed beneficiary, uint256 indexed amount);

    event TokenTransferred(address indexed receiver, uint256 indexed amount);

    event BonusTransferred(address indexed receiver, uint256 indexed amount);

    event RewardEarned(address indexed referrer, uint256 indexed amount, uint256 indexed level);

    function price() external view returns (uint256);
    function raise() external view returns (uint256);
    function start() external view returns (uint256);
    function duration() external view returns (uint256);
    function minAmount() external view returns (uint256);
    function maxAmount() external view returns (uint256);
    function getVestingManagersCount() external view returns (uint256);
    function getVestingManager(uint256 index) external view returns (address, uint256);
    function getVestingManagers() external view returns (address[] memory);
    function getVestingWallets(address beneficiary) external view returns (address[] memory);
    function getWhiteListBuyer(uint256 startPosition, uint256 length) external view returns(address[] memory whiteList);
    function getWhiteListBuyerByIndex(uint256 index) external view returns(address);
    function getwhiteListBuyerLength() external view returns (uint256);
    function checkIsWhitelisted(address account) external view returns (bool);
    function walletFor(address beneficiary, address vestingManager) external view returns (address);
    function preSaleInfoReturn(address account) external view returns (IDOSaleStructs.ReturnInfo memory result);
    
    function totalSold() external view returns (uint256);
    function totalEarned() external view returns (uint256);
    function totalBonus() external view returns (uint256);

    function ICOToken() external view returns (address);

    function setPrice(uint256) external;
    function setRaise(uint256) external;
    function setStart(uint64) external;
    function setDuration(uint64) external;
    function setMinAmount(uint256 minAmount_) external;
    function setMaxAmount(uint256 maxAmount_) external;
    function setWhitelistState(bool flag) external;
    function addVestingManager(address vestingManager_, uint256 distributionPercentage_) external;
    function removeVestingManager(uint256 index) external;

    function pause() external;
    function unpause() external;

    function withdraw(address) external;
    function withdrawETH() external;
    function buy(address referrer) external payable;
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

interface IWalletFactory {
    function createManagedVestingWallet(address beneficiary, address vestingManager) external returns (address);
    function walletFor(address beneficiary, address vestingManager, bool strict) external view returns (address);
}

contract CrowdSaleMAYAToken is ICrowdsale, Ownable, Pausable, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     *  预定义的最大推荐级别
     */
    uint256 public constant REFERRAL_PROGRAM_LEVELS = 3;

    /**
     *  获取百分比分母
     */
    uint256 internal constant PERCENTAGE_DENOM = 10000;

    /**
     *  获取价格
     */
    uint256 public price;

    /**
     *  想要筹集的数量
     */
    uint256 public raise;

    /**
     *  最小数量
     */
    uint256 public minAmount;

    /**
     *  最大数量
     */
    uint256 public maxAmount;

    /**
     *  开始时间
     */
    uint256 public start;

    /**
     *  持续时间
     */
    uint256 public duration;

    /**
     *  总共卖出的代币数量
     */
    uint256 public totalSold;

    /**
     *  获取所有推荐人获得的总奖励
     */
    uint256 public totalEarned;

    /**
     *  获得总奖金
     */
    uint256 public totalBonus;

    /**
     *  预售代币
     */
    address public immutable ICOToken;

    /**
     *  是否启用白名单
     */
    bool public whitelistIsEnable;

    /**
     *   获取用户推荐人
     */
    mapping(address => address) public referrers;

    /**
     *   获取用户花费的代币数量
     */
    mapping(address => uint256) public spent;

    /**
     *   获取用户购买的代币数量（MAYA）
     */
    mapping(address => uint256) public bought;

    /**
     *  获取用户推荐奖励
     */
    mapping(address => uint256) public rewards;

    /**
     *  获取用户奖金
     */
    mapping(address => uint256) public bonuses;

    /**
     *  用于创建归属钱包的工厂地址
     */
    address internal _walletFactory;

    /**
     *  内部归属经理存储
     */
    Vesting[] internal _vestingManagers;

    /**
     *  白名单用户列表
     */
    EnumerableSet.AddressSet private _whiteListUsers;

    modifier onlySalePeriod {
        require(block.timestamp >= start && block.timestamp < (start + duration), "Sale: sale not started or already finished");
        _;
    }

    modifier whenNotStarted {
        require(start == 0 || (start > 0 && block.timestamp < start), "Sale: sale already started");
        _;
    }

    /**
     *  ICOToken_  用于售卖的MAYA代币地址;
     *  walletFactory_  The IWalletFactory implementation.
     */
    constructor(address ICOToken_, address walletFactory_) {
        require(ICOToken_ != address(0), "Can not be 0");
        ICOToken = ICOToken_;
        _walletFactory = walletFactory_;
    }

    /**
     *   分页获取白名单用户列表
     */
    function getWhiteListBuyer(uint256 startPosition, uint256 length) external view virtual override returns(address[] memory whiteList) {
        uint256 end = (startPosition + length) < _whiteListUsers.length() ? (startPosition + length) : _whiteListUsers.length();
        length = end > startPosition ? end - startPosition : 0;
        whiteList = new address[](length);
        for (uint256 i = startPosition; i < end; i++) {
            whiteList[i - startPosition] = _whiteListUsers.at(i); 
        }
    }

    /**
     *   通过索引获取白名单用户列表
     */
    function getWhiteListBuyerByIndex(uint256 index) external view virtual override returns(address) {
       return _whiteListUsers.at(index);
    }

    /**
     *   获取白名单用户列表长度
     */
    function getwhiteListBuyerLength() public view virtual override returns (uint256) {
        return _whiteListUsers.length();
    }

    /**
     *   判断一个账号是否为白名单
     */
    function checkIsWhitelisted(address account) external view virtual override returns (bool) {
        return _whiteListUsers.contains(account);
    }

    /**
     *   获取归属经理数组长度
     */
    function getVestingManagersCount() external view virtual override returns (uint256) {
        return _vestingManagers.length;
    }

    /**
     *  返回归属经理人地址及其分配比例
     */
    function getVestingManager(uint256 index) external view virtual override returns (address, uint256) {
        return (_vestingManagers[index].vestingManager, _vestingManagers[index].distributionPercentage);
    }

    /**
     *  获取归属经理人地址数组
     */
    function getVestingManagers() public view virtual override returns (address[] memory) {
        address[] memory vestingManagers = new address[](_vestingManagers.length);
        for (uint256 i = 0; i < _vestingManagers.length; ++i) {
            vestingManagers[i] = _vestingManagers[i].vestingManager;
        }
        return vestingManagers;
    }

    /**
     *  返回给定钱包的所有归属钱包（来自使用相同钱包工厂的任何销售）
     */
    function getVestingWallets(address beneficiary) public view virtual override returns (address[] memory) {
        address[] memory wallets = new address[](_vestingManagers.length);
        for (uint256 i = 0; i < _vestingManagers.length; ++i) {
            address vestingManager = _vestingManagers[i].vestingManager;
            wallets[i] = _walletFor(beneficiary, vestingManager);
        }
        return wallets;
    }

    /**
     *  获取用户的归属钱包
     */
    function walletFor(address beneficiary, address vestingManager) external view virtual override returns (address) {
        return _walletFor(beneficiary, vestingManager);
    }

    /**
     *  返回合约信息
     */
    function preSaleInfoReturn(address account) external view virtual override returns (IDOSaleStructs.ReturnInfo memory result) {
        result.price = price;
        result.raise = raise;
        result.minAmount = minAmount;
        result.maxAmount = maxAmount;
        result.startTime = start;
        result.duration = duration;
        result.totalSold = totalSold;
        result.totalEarned = totalEarned;
        result.totalBonus = totalBonus;
        result.presaleTokenAddress = ICOToken;
        result.presaleTokenSymbol = IBEP20(ICOToken).symbol();
        result.presaleTokenDecimals = IBEP20(ICOToken).decimals();
        result.userPreSaleTokenBal = IBEP20(ICOToken).balanceOf(account);
        result.whitelistIsEnable = whitelistIsEnable;
        result.userSpentAmount = spent[account];
        result.userBoughtAmount = bought[account];
        result.userRewardsAmount = rewards[account];
        result.userBonusesAmount = bonuses[account];
        result.vestingManagersCount = _vestingManagers.length;
        result.IsWhitelisted = _whiteListUsers.contains(account);
        result.userReferrer = referrers[account];
        result.vestingManagers = getVestingManagers();
        result.userVestingWallets = getVestingWallets(account);
        result.totalDistributionRatio = _getDistributionPercentageTotal();
    }

    /**
     *  设置价格   参数：BUSD的价格（18位精度）
     */
    function setPrice(uint256 price_) external virtual override onlyOwner whenNotStarted {
        require(price_ > 0, "Sale: wrong price");
        price = price_;
    }

    /**
     *  设置想要筹集的数量 参数：BUSD的价格（18位精度）
     */
    function setRaise(uint256 raise_) external virtual override onlyOwner whenNotStarted {
        raise = raise_;
    }

    /**
     *  设置售卖开始时间  以秒为单位， 时间戳格式
     */
    function setStart(uint64 start_) external virtual override onlyOwner whenNotStarted {
        require(start_ > block.timestamp, "Sale: past timestamp");
        start = start_;
    }

    /**
     *  设置售卖持续时间  以秒为单位
     */
    function setDuration(uint64 duration_) external virtual override onlyOwner whenNotStarted {
        duration = duration_;
    }

    /**
     *   设置一位受益人的最低可能金额
     */
    function setMinAmount(uint256 minAmount_) external virtual override onlyOwner whenNotStarted {
        minAmount = minAmount_;
    }

    /**
     *  设置一位受益人的最高可能金额
     */
    function setMaxAmount(uint256 maxAmount_) external virtual override onlyOwner whenNotStarted {
        maxAmount = maxAmount_;
    }

    /**
     *  设置是否启用白名单
     */
    function setWhitelistState(bool flag) external  virtual override onlyOwner whenNotStarted {
        whitelistIsEnable = flag;
    }

    /**
     *  添加归属经理  参数：新的归属经理、分配百分比（保留 3 位小数）
     *  要开始销售，所有经理的分配百分比总和必须为 10000 (100%)
     */
    function addVestingManager(address vestingManager_, uint256 distributionPercentage_) external virtual override onlyOwner whenNotStarted {
        uint256 distributionPercentageTotal = _getDistributionPercentageTotal();
        distributionPercentageTotal += distributionPercentage_;
        require(distributionPercentageTotal <= 10000, "Sale: wrong total distribution percentage");
        _vestingManagers.push(Vesting(vestingManager_, distributionPercentage_));
    }

    /**
     *  移除归属经理
     */
    function removeVestingManager(uint256 index) external virtual override onlyOwner whenNotStarted {
        require(index < _vestingManagers.length, "Sale: wrong index");
        uint256 lastIndex = _vestingManagers.length - 1;
        _vestingManagers[index].vestingManager = _vestingManagers[lastIndex].vestingManager;
        _vestingManagers[index].distributionPercentage = _vestingManagers[lastIndex].distributionPercentage;
        _vestingManagers.pop();
    }

    /**
     *  批量添加白名单用户
     */
    function addWhitelistBuyers(address[] memory _buyers) public onlyOwner {
        for (uint i = 0; i < _buyers.length; i++) {
            _whiteListUsers.add(_buyers[i]);
        }
    }

    /**
     *  批量移除白名单用户
     */
    function removeWhitelistBuyers(address[] memory _buyers) public onlyOwner {
        for (uint i = 0; i < _buyers.length; i++) {
            _whiteListUsers.remove(_buyers[i]);
         }
    }

    /**
     *  将给定的 `token` 代币从合约账户中提取给所有者  仅限所有者操作
     */
    function withdraw(address token) external virtual override onlyOwner {
        require(token != address(0), "Sale: zero address given");
        IERC20 tokenImpl = IERC20(token);
        tokenImpl.safeTransfer(msg.sender, tokenImpl.balanceOf(address(this)));
    }

    /**
     *  将 ETH 从合约账户中提取给所有者  仅限所有者操作
     */
    function withdrawETH() external virtual override onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     *  暂停合约
     */
    function pause() external virtual override onlyOwner onlySalePeriod {
        _pause();
    }

    /**
     *  重新开始合约
     */
    function unpause() external virtual override onlyOwner onlySalePeriod {
        _unpause();
    }

    /**
     *  购买代币
     *  referrer     推荐人  推荐人，如果存在的话。 如果可能，也将设置在 ICOToken 代币中，以便从未来的转账中获得奖励
     *  只能在销售期间使用
     *  所有者可在紧急情况下暂停
     */
    function buy(address referrer) external payable virtual override onlySalePeriod whenNotPaused nonReentrant {
        _buy(referrer);
    }

    function _buy(address referrer) internal {
        require(_getDistributionPercentageTotal() == 10000, "Sale: vestings are not correct");
        if (whitelistIsEnable) {
            require(_whiteListUsers.contains(_msgSender()), "You are not in whitelist");
        }
        if (referrer != address(0)) {
            address existingReferrer = referrers[msg.sender];
            if (existingReferrer != address(0)) {
                require(existingReferrer == referrer, "Sale: referrer already set");
            }
            // check is referrer have vesting wallet
            address[] memory wallets = _getVestingWallets(referrer);
            // can check only first element, cause there is no case when first element is not set but second one is
            require(wallets.length > 0 && wallets[0] != address(0), "Sale: invalid referrer");
        }

        uint256 amountIn = msg.value;

        require(amountIn >= minAmount, "Sale: minAmount");
        spent[msg.sender] += amountIn;
        require(spent[msg.sender] <= maxAmount, "Sale: maxAmount");

        referrers[msg.sender] = referrer;

        IBEP20 erc20Impl = IBEP20(ICOToken);
        uint256 decimals = erc20Impl.decimals();

        uint256[] memory amountArtyOuts = new uint256[](5);
        for (uint256 i = 0; i < _vestingManagers.length; ++i) {
            uint256 amountBusdInByVestingManager = (amountIn * _vestingManagers[i].distributionPercentage) / PERCENTAGE_DENOM;

            uint256 amountOut = (amountBusdInByVestingManager * 10 ** decimals) / price;

            amountArtyOuts[0] = amountOut;
            amountArtyOuts[1] = (amountOut * 500) / PERCENTAGE_DENOM;  // 5%
            amountArtyOuts[2] = (amountOut * 300) / PERCENTAGE_DENOM;  // 3%
            amountArtyOuts[3] = (amountOut * 200) / PERCENTAGE_DENOM;  // 2%
            amountArtyOuts[4] = _getBonus(amountIn, amountOut);

            _execute(_vestingManagers[i].vestingManager, msg.sender, amountArtyOuts);
        }
    }

    function _execute(address vestingManager, address beneficiary, uint256[] memory amountArtyOuts) private {
        (address[] memory allLevelsVestingWallets, address[] memory allLevelsReferrers) = _getAllLevelsVestingWallets(vestingManager, beneficiary);

        totalSold += amountArtyOuts[0];
        emit TokenTransferred(allLevelsVestingWallets[0], amountArtyOuts[0]);
        emit TokenSold(beneficiary, amountArtyOuts[0]);

        IERC20 erc20Impl = IERC20(ICOToken);

        bought[beneficiary] += amountArtyOuts[0];
        erc20Impl.safeTransfer(allLevelsVestingWallets[0], amountArtyOuts[0]);

        if(block.timestamp >= start && block.timestamp <= start + 86400 && bought[msg.sender] * 2500 / 10000 > 0) {
            erc20Impl.safeTransfer(allLevelsVestingWallets[0], bought[msg.sender] * 2500 / 10000);
        }

        for (uint256 i = 1; i < allLevelsVestingWallets.length; ++i) {
            if (allLevelsVestingWallets[i] == address(0)) {
                break;
            }
            totalEarned += amountArtyOuts[i];
            emit RewardEarned(allLevelsVestingWallets[i], amountArtyOuts[i], i);
            rewards[allLevelsReferrers[i]] += amountArtyOuts[i];
            erc20Impl.safeTransfer(allLevelsVestingWallets[i], amountArtyOuts[i]);
        }
        if (amountArtyOuts[4] > 0) {
            emit BonusTransferred(allLevelsVestingWallets[0], amountArtyOuts[0]);
            totalBonus += amountArtyOuts[4];
            bonuses[beneficiary] += amountArtyOuts[4];
            erc20Impl.safeTransfer(allLevelsVestingWallets[0], amountArtyOuts[4]);
        }
    }

    function _getVestingWallets(address beneficiary) internal view returns (address[] memory) {
        address[] memory wallets = new address[](_vestingManagers.length);
        for (uint256 i = 0; i < _vestingManagers.length; ++i) {
            address vestingManager = _vestingManagers[i].vestingManager;
            wallets[i] = _walletFor(beneficiary, vestingManager);
        }
        return wallets;
    }

    function _getDistributionPercentageTotal() internal view returns (uint256) {
        uint256 distributionPercentageTotal = 0;
        for (uint256 i = 0; i < _vestingManagers.length; ++i) {
            distributionPercentageTotal += _vestingManagers[i].distributionPercentage;
        }
        return distributionPercentageTotal;
    }

    function _getAllLevelsVestingWallets(address vestingManager, address beneficiary) internal returns (address[] memory, address[] memory) {
        address[] memory allLevelsVestingWallets = new address[](REFERRAL_PROGRAM_LEVELS + 1);
        address[] memory allLevelsReferrers = new address[](REFERRAL_PROGRAM_LEVELS + 1);

        address vestingWallet = _walletFor(beneficiary, vestingManager);

        if (vestingWallet == address(0)) {
            IWalletFactory factoryImpl = IWalletFactory(_walletFactory);
            vestingWallet = factoryImpl.createManagedVestingWallet(beneficiary, vestingManager);
        }

        allLevelsVestingWallets[0] = vestingWallet;

        address referrer = referrers[beneficiary];
        for (uint256 i = 1; i <= REFERRAL_PROGRAM_LEVELS; ++i) {
            address referrerVestingWallet = _walletFor(referrer, vestingManager);
            if (referrerVestingWallet == address(0)) {
                break;
            }
            allLevelsVestingWallets[i] = referrerVestingWallet;
            allLevelsReferrers[i] = referrer;
            referrer = referrers[referrer];
        }

        return (allLevelsVestingWallets, allLevelsReferrers);
    }

    function _getBonus(uint256 amountIn, uint256 amountOut) internal pure returns (uint256) {
        uint256 bonus = 0;
        if (amountIn >= 5000 ether) {
            bonus = ((amountOut * 500) / PERCENTAGE_DENOM);
        } else if (amountIn >= 2500 ether) {
            bonus = ((amountOut * 300) / PERCENTAGE_DENOM);
        }
        return bonus;
    }

    function _walletFor(address beneficiary, address vestingManager) internal view returns (address) {
        return IWalletFactory(_walletFactory).walletFor(beneficiary, vestingManager, true);
    }
}