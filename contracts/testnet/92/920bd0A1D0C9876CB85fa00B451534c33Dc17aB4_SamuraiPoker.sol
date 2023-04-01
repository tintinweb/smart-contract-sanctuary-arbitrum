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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// import "hardhat/console.sol";

interface ILottoRNG {
    function requestRandomNumbers(
        uint256 n,
        uint256 gasLimit
    ) external payable returns (uint256 id);

    function getFee(uint256 gasLimit) external view returns (uint256 fee);

    function depositFee() external payable;
}

interface IEngine {
    function getWinner(
        uint8[] calldata playerOneHand,
        uint8[] calldata playerTwoHand
    ) external view returns (uint8 winner);
}

interface IBankRoll {
    function deposit(address erc20Address, uint256 amount) external payable;
}

contract SamuraiPoker is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using Address for address payable;

    ILottoRNG public lottoRNG;
    IEngine public engine;
    IBankRoll public bankRoll;
    Counters.Counter public totalGames;
    address[] public currencyList;
    uint256[] public openedGames;
    uint256[] public finishedGames;

    uint256 public gasLimit = 1000000;
    uint256 public houseEdge = 500;

    mapping(address => Currency) public allowedCurrencies;
    mapping(uint256 => Game) public games;
    mapping(address => uint256[]) public playerGames;
    mapping(uint256 => uint256) public randomRequests;

    struct Game {
        address playerOne;
        address playerTwo;
        uint256 requestId;
        uint256[] randomNumbers;
        address currency;
        uint256 bet;
        uint256 dateCreated;
        uint256 datePlayAgainst;
        uint256 dateClosed;
        uint8 winner;
        uint8[] playerOneHand;
        uint8[] playerTwoHand;
    }

    struct Currency {
        uint256 minBet;
        uint256 maxBet;
        bool accepted;
    }

    /* ========== INITIALIZER ========== */
    constructor(address _lottoRNGAddress, address _bankRollAddress) {
        lottoRNG = ILottoRNG(_lottoRNGAddress);
        bankRoll = IBankRoll(_bankRollAddress);
    }

    /* ========== FUNCTIONS ========== */

    function createGame(
        address erc20Address,
        uint256 amount
    ) external payable nonReentrant whenNotPaused {
        require(
            allowedCurrencies[erc20Address].accepted,
            "Currency is not accepted"
        );
        require(
            amount >= allowedCurrencies[erc20Address].minBet &&
                amount <= allowedCurrencies[erc20Address].maxBet,
            "minBet or maxBet error"
        );
        uint256 fee = lottoRNG.getFee(gasLimit) / 2;

        if (erc20Address == address(0)) {
            require(msg.value >= amount + fee, "Wrong amount");
        } else {
            require(msg.value >= fee, "Wrong amount");
            _transferIn(erc20Address, amount, _msgSender());
        }

        totalGames.increment();
        uint256 gameId = totalGames.current();
        games[gameId].playerOne = _msgSender();
        games[gameId].currency = erc20Address;
        games[gameId].bet = amount;
        games[gameId].dateCreated = block.timestamp;
        openedGames.push(gameId);
        playerGames[_msgSender()].push(gameId);
        lottoRNG.depositFee{value: fee}();
        emit GameCreated(
            gameId,
            _msgSender(),
            erc20Address,
            amount,
            block.timestamp
        );
    }

    function playAgainst(
        uint256 gameId
    ) external payable nonReentrant whenNotPaused {
        require(
            games[gameId].datePlayAgainst == 0 && games[gameId].dateClosed == 0,
            "Game is already running or finished"
        );
        require(
            games[gameId].playerOne != _msgSender(),
            "You can't play against yourself"
        );

        uint256 fee = lottoRNG.getFee(gasLimit) / 2;

        if (games[gameId].currency == address(0)) {
            require(msg.value >= games[gameId].bet + fee, "Wrong amount");
        } else {
            require(msg.value >= fee, "Wrong amount");
            _transferIn(
                games[gameId].currency,
                games[gameId].bet,
                _msgSender()
            );
        }

        games[gameId].playerTwo = _msgSender();
        games[gameId].datePlayAgainst = block.timestamp;
        uint256 requestId = lottoRNG.requestRandomNumbers{value: fee}(
            10,
            gasLimit
        );
        games[gameId].requestId = requestId;
        randomRequests[requestId] = gameId;
        playerGames[_msgSender()].push(gameId);
        emit PlayedAgainst(
            gameId,
            requestId,
            _msgSender(),
            games[gameId].currency,
            games[gameId].bet,
            block.timestamp
        );
    }

    function closeGame(uint256 gameId) external nonReentrant {
        require(games[gameId].dateCreated > 0, "Game is not created yet");
        require(
            games[gameId].playerOne == _msgSender() || owner() == _msgSender(),
            "You didn't create this game"
        );
        require(
            games[gameId].datePlayAgainst == 0 && games[gameId].dateClosed == 0,
            "Too late to close this game"
        );
        games[gameId].dateClosed == block.timestamp;
        _removeFromOpenedGames(gameId);
        if (games[gameId].currency == address(0)) {
            payable(games[gameId].playerOne).sendValue(games[gameId].bet);
        } else {
            _transferOut(
                games[gameId].currency,
                games[gameId].bet,
                games[gameId].playerOne
            );
        }
        emit GameClosed(gameId, block.timestamp);
    }

    /* ========== RNG FUNCTION ========== */
    function receiveRandomNumbers(
        uint256 _id,
        uint256[] calldata values
    ) external {
        require(_msgSender() == address(lottoRNG), "LottoRNG Only");
        uint256 gameId = randomRequests[_id];
        require(games[gameId].dateClosed == 0, "Game already closed");

        games[gameId].randomNumbers = values;
        games[gameId].dateClosed = block.timestamp;
        (uint8[] memory playerOneHand, uint8[] memory playerTwoHand) = getCards(
            values
        );
        games[gameId].playerOneHand = playerOneHand;
        games[gameId].playerTwoHand = playerTwoHand;
        games[gameId].dateClosed = block.timestamp;

        uint8 winner = engine.getWinner(playerOneHand, playerTwoHand);
        games[gameId].winner = winner;
        _removeFromOpenedGames(gameId);
        (
            uint256 prizeWithoutHouseEdge,
            uint256 houseEdgeAmount
        ) = _getHouseEdgeAmount(games[gameId].bet * 2);
        if (winner == 0) {
            _transferOut(
                games[gameId].currency,
                prizeWithoutHouseEdge / 2,
                games[gameId].playerOne
            );
            _transferOut(
                games[gameId].currency,
                prizeWithoutHouseEdge / 2,
                games[gameId].playerTwo
            );
        } else if (winner == 1) {
            _transferOut(
                games[gameId].currency,
                prizeWithoutHouseEdge,
                games[gameId].playerOne
            );
        } else if (winner == 2) {
            _transferOut(
                games[gameId].currency,
                prizeWithoutHouseEdge,
                games[gameId].playerTwo
            );
        }
        if (games[gameId].currency == address(0)) {
            bankRoll.deposit{value: houseEdgeAmount}(
                address(0),
                houseEdgeAmount
            );
        } else {
            IERC20(games[gameId].currency).approve(
                address(bankRoll),
                houseEdgeAmount
            );
            bankRoll.deposit(games[gameId].currency, houseEdgeAmount);
        }
        emit RandomNumbersReceived(
            gameId,
            playerOneHand,
            playerTwoHand,
            winner,
            games[gameId].currency,
            games[gameId].bet,
            block.timestamp
        );
    }

    /* ========== ADMIN FUNCTIONS ========== */
    function setLottoRNG(address lottoRNGAddress) external onlyOwner {
        lottoRNG = ILottoRNG(lottoRNGAddress);
        emit LottoRNGSet(lottoRNGAddress);
    }

    function setEngine(address engineAddress) external onlyOwner {
        engine = IEngine(engineAddress);
        emit EngineSet(engineAddress);
    }

    function setGasLimit(uint256 _gasLimit) external onlyOwner {
        gasLimit = _gasLimit;
        emit GasLimitSet(_gasLimit);
    }

    function setHouseEdge(uint256 _houseEdge) external onlyOwner {
        houseEdge = _houseEdge;
        emit HouseEdgeSet(_houseEdge);
    }

    function addCurrency(
        address _currencyAddress,
        uint256 _minBet,
        uint256 _maxBet
    ) external onlyOwner {
        require(
            !allowedCurrencies[_currencyAddress].accepted,
            "Currency is already accepted"
        );
        currencyList.push(_currencyAddress);
        allowedCurrencies[_currencyAddress] = Currency({
            minBet: _minBet,
            maxBet: _maxBet,
            accepted: true
        });
    }

    function removeCurrency(address _currencyAddress) external onlyOwner {
        require(
            allowedCurrencies[_currencyAddress].accepted,
            "Currency is not accepted"
        );
        delete allowedCurrencies[_currencyAddress];
        for (uint i = 0; i < currencyList.length; i++) {
            if (currencyList[i] == _currencyAddress) {
                currencyList[i] = currencyList[currencyList.length - 1];
                currencyList.pop();
                break;
            }
        }
    }

    function setMinMaxBet(
        address _currencyAddress,
        uint256 _minBet,
        uint256 _maxBet
    ) external onlyOwner {
        require(
            allowedCurrencies[_currencyAddress].accepted,
            "Currency is not accepted"
        );
        allowedCurrencies[_currencyAddress].minBet = _minBet;
        allowedCurrencies[_currencyAddress].maxBet = _maxBet;
        emit MinMaxBetSet(_currencyAddress, _minBet, _maxBet);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function rescue(address erc20Address, uint256 amount) external onlyOwner {
        if (erc20Address == address(0)) {
            payable(_msgSender()).sendValue(amount);
        } else {
            IERC20(erc20Address).safeTransfer(_msgSender(), amount);
        }
    }

    function rescueAll(address erc20Address) external onlyOwner {
        if (erc20Address == address(0)) {
            payable(_msgSender()).sendValue(address(this).balance);
        } else {
            IERC20(erc20Address).safeTransfer(
                _msgSender(),
                IERC20(erc20Address).balanceOf(address(this))
            );
        }
    }

    /* ========== UTILS ========== */
    function _transferIn(
        address token,
        uint256 amount,
        address sender
    ) internal returns (uint256 transferedAmount) {
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(sender, address(this), amount);
        transferedAmount =
            IERC20(token).balanceOf(address(this)) -
            balanceBefore;
    }

    function _transferOut(
        address token,
        uint256 amount,
        address recipient
    ) internal returns (uint256 transferedAmount) {
        if (token == address(0)) {
            uint256 balanceBefore = address(this).balance;
            payable(recipient).sendValue(amount);
            transferedAmount = balanceBefore - address(this).balance;
        } else {
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransfer(recipient, amount);
            transferedAmount =
                balanceBefore -
                IERC20(token).balanceOf(address(this));
        }
    }

    function _removeFromOpenedGames(uint256 _gameId) internal {
        for (uint256 i = 0; i < openedGames.length; i++) {
            if (openedGames[i] == _gameId) {
                openedGames[i] = openedGames[openedGames.length - 1];
                openedGames.pop();
                break;
            }
        }
        finishedGames.push(_gameId);
    }

    function getCards(
        uint256[] calldata randomValues
    )
        public
        pure
        returns (uint8[] memory playerOneHand, uint8[] memory playerTwoHand)
    {
        playerOneHand = new uint8[](5);
        playerTwoHand = new uint8[](5);
        for (uint8 i = 0; i < randomValues.length; i++) {
            if (i < 5) {
                playerOneHand[i] = uint8(randomValues[i] % 6);
            } else {
                playerTwoHand[i - 5] = uint8(randomValues[i] % 6);
            }
        }
    }

    function _getHouseEdgeAmount(
        uint256 amount
    )
        internal
        view
        returns (uint256 prizeWithoutHouseEdge, uint256 houseEdgeAmount)
    {
        houseEdgeAmount = (amount * houseEdge) / 10_000;
        prizeWithoutHouseEdge = amount - houseEdgeAmount;
    }

    /* ========== GETTERS ========== */
    function getOpenedGames()
        external
        view
        returns (uint256[] memory _openedGames)
    {
        _openedGames = openedGames;
    }

    function getLastFinishedGames(
        uint256 length
    ) external view returns (uint256[] memory lastFinishedGames) {
        lastFinishedGames = new uint[](length);
        for (uint i = 0; i < length; i++) {
            lastFinishedGames[i] = finishedGames[
                finishedGames.length - length + i
            ];
        }
    }

    function getPlayerGames(
        address playerAddress
    ) external view returns (uint256[] memory _playerGames) {
        _playerGames = playerGames[playerAddress];
    }

    function getRandomResults(
        uint256 gameId
    ) external view returns (uint256[] memory values) {
        values = games[gameId].randomNumbers;
    }

    function getPlayersHands(
        uint256 gameId
    )
        external
        view
        returns (uint8[] memory playerOneHand, uint8[] memory playerTwoHand)
    {
        playerOneHand = games[gameId].playerOneHand;
        playerTwoHand = games[gameId].playerTwoHand;
    }

    function getGameData(
        uint256 gameId
    ) external view returns (Game memory game) {
        game = Game({
            playerOne: games[gameId].playerOne,
            playerTwo: games[gameId].playerTwo,
            requestId: games[gameId].requestId,
            randomNumbers: games[gameId].randomNumbers,
            currency: games[gameId].currency,
            bet: games[gameId].bet,
            dateCreated: games[gameId].dateCreated,
            datePlayAgainst: games[gameId].datePlayAgainst,
            dateClosed: games[gameId].dateClosed,
            winner: games[gameId].winner,
            playerOneHand: games[gameId].playerOneHand,
            playerTwoHand: games[gameId].playerTwoHand
        });
    }

    /* ========== EVENTS ========== */
    event MinMaxBetSet(address indexed currency, uint256 min, uint256 max);
    event HouseEdgeSet(uint256 houseEdge);
    event GasLimitSet(uint256 gasLimit);
    event EngineSet(address engine);
    event LottoRNGSet(address rng);
    event RandomNumbersReceived(
        uint256 gameId,
        uint8[] playerOneHand,
        uint8[] playerTwoHand,
        uint8 winner,
        address currency,
        uint256 bet,
        uint256 timestamp
    );
    event GameClosed(uint256 gameId, uint256 timestamp);
    event PlayedAgainst(
        uint256 gameId,
        uint256 requestId,
        address player,
        address currency,
        uint256 bet,
        uint256 timestamp
    );
    event GameCreated(
        uint256 gameId,
        address player,
        address currency,
        uint256 bet,
        uint256 timestamp
    );
}