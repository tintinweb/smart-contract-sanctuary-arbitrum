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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @notice Minimal interface for Bank.
/// @author Romuald Hog.
interface IBank {
    /// @notice Gets the token's allow status used on the games smart contracts.
    /// @param token Address of the token.
    /// @return Whether the token is enabled for bets.
    function isAllowedToken(address token) external view returns (bool);

    /// @notice Payouts a winning bet, and allocate the house edge fee.
    /// @param user Address of the gamer.
    /// @param token Address of the token.
    /// @param profit Number of tokens to be sent to the gamer.
    /// @param fees Bet amount and bet profit fees amount.
    function payout(
        address user,
        address token,
        uint256 profit,
        uint256 fees,
        uint256 betAmountFees
    ) external payable;

    /// @notice Accounts a loss bet.
    /// @dev In case of an ERC20, the bet amount should be transfered prior to this tx.
    /// @dev In case of the gas token, the bet amount is sent along with this tx.
    /// @param tokenAddress Address of the token.
    /// @param amount Loss bet amount.
    /// @param fees Bet amount and bet profit fees amount.
    function cashIn(
        address user,
        address tokenAddress,
        uint256 amount,
        uint256 fees,
        uint256 betAmountFees
    ) external payable;

    /// @notice Calculates the max bet amount based on the token balance, the balance risk, and the game multiplier.
    /// @param token Address of the token.
    /// @param multiplier The bet amount leverage determines the user's profit amount. 10000 = 100% = no profit.
    /// @return Maximum bet amount for the token.
    /// @dev The multiplier should be at least 10000.
    function getMaxBetAmount(
        address token,
        uint256 multiplier
    ) external view returns (uint256);

    function getVRFSubId(address token) external view returns (uint64);

    function getTokenOwner(address token) external view returns (address);

    function getMinBetUnit(address token) external view returns (uint256);

    function getMaxBetUnit(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IBank} from "../Bank/IBank.sol";
import {ISupraRouter} from "./ISupraRouter.sol";

/// @title Game base contract
/// @author Romuald Hog, edited by munji([email protected])
/// @notice This should be parent contract of each games.
/// It defines all the games common functions and state variables.
abstract contract Game is Ownable, Pausable, Multicall, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ----------------------------------------------------------------------------------------------------------------------------------- //
    // ----------------------------------------------------    written by munji  --------------------------------------------------------- //
    // -----------------------------------------------------    audit required   --------------------------------------------------------- //
    // ----------------------------------------------------------------------------------------------------------------------------------- //

    /**
        TODO

     */

    ISupraRouter public supraRouter;
    uint256 public houseEdge; // differ by games, divisor = 10000
    uint256 numConfirmations = 1;
    uint8 RNG_MIN = 1;
    uint8 RNG_MAX = 100;
    mapping(address => uint64) public tokenToPendingCount;
    event SetNumConfirmations(uint256 _numConfirmations);
    event SetRngMinMax(uint8 _min, uint8 _max);

    struct Bet {
        bool resolved;
        address user;
        address token;
        uint256 id; //requestId
        uint256 amount; //total bet amount
        uint256 blockNumber;
        uint256 payout;
        uint8 rngCount;
        uint256 betUnit;
    }

    function setSupraRouter(address _supraRouter) external onlyOwner {
        supraRouter = ISupraRouter(_supraRouter);
    }

    function setHouseEdge(uint256 _houseEdge) external onlyOwner {
        houseEdge = _houseEdge;
        emit SetHouseEdge(_houseEdge);
    }

    function setNumConfirmations(uint256 _numConfirmations) external onlyOwner {
        numConfirmations = _numConfirmations;
        emit SetNumConfirmations(_numConfirmations);
    }

    function setRngMinMax(uint8 _min, uint8 _max) external onlyOwner {
        RNG_MIN = _min;
        RNG_MAX = _max;
        emit SetRngMinMax(_min, _max);
    }

    constructor(
        address _bankAddress,
        address _supraRouterAddress,
        uint16 _houseEdge
    ) {
        if (_bankAddress == address(0)) {
            revert InvalidAddress();
        }
        bank = IBank(_bankAddress);

        if (_supraRouterAddress == address(0)) {
            revert InvalidAddress();
        }
        supraRouter = ISupraRouter(_supraRouterAddress);

        houseEdge = _houseEdge;
    }

    // nonce, from, betToken, numWords
    event RequestSent(
        uint256 _id,
        address _user,
        address _token,
        uint8 _rngCount
    );

    /// @notice Bet amount exceed the max bet unit.
    /// @param maxBetUnit Bet unit.
    error ExceedMaxBetUnit(uint256 maxBetUnit);

    // ----------------------------------------------------------------------------------------------------------------------------------- //
    // ----------------------------------------------------    coded by BetSwirl  -------------------------------------------------------- //
    // ----------------------------------------------------------------------------------------------------------------------------------- //

    /// @notice Bet information struct.
    /// @param resolved Whether the bet has been resolved.
    /// @param user Address of the gamer.
    /// @param token Address of the token.
    /// @param id Bet ID generated by Oracle VRF.
    /// @param amount The bet amount.
    /// @param blockNumber Block number of the bet used to refund in case Oracle's callback fail.
    /// @param payout The payout amount.

    /// @notice Maps bets IDs to Bet information.
    mapping(uint256 => Bet) public bets;

    /// @notice Maps users addresses to bets IDs
    mapping(address => uint256[]) internal _userBets;

    /// @notice Maps tokens addresses to token configuration.
    // mapping(address => Token) public tokens;

    /// @notice The bank that manage to payout a won bet and collect a loss bet.
    IBank public immutable bank;

    /// @notice Emitted after the house edge is set for a token.
    /// @param houseEdge House edge rate.
    event SetHouseEdge(uint256 houseEdge);

    /// @notice Emitted after the bet amount is transfered to the user.
    /// @param id The bet ID.
    /// @param user Address of the gamer.
    /// @param amount Number of tokens refunded.
    // / @param chainlinkVRFCost The Oracle VRF cost refunded to player.
    event BetRefunded(uint256 id, address user, uint256 amount);
    // uint256 chainlinkVRFCost

    /// @notice Insufficient bet unit.
    /// @param minBetUnit Bet unit.
    error UnderMinBetUnit(uint256 minBetUnit);

    /// @notice Bet provided doesn't exist or was already resolved.
    error NotPendingBet();

    /// @notice Bet isn't resolved yet.
    error NotFulfilled();

    /// @notice House edge is capped at 8%.
    error ExcessiveHouseEdge();

    /// @notice Token is not allowed.
    error ForbiddenToken();

    /// @notice Reverting error when sender isn't allowed.
    error AccessDenied();

    /// @notice Reverting error when provided address isn't valid.
    error InvalidAddress();

    /// @notice Reverting error when token has pending bets.
    error TokenHasPendingBets();

    /// @notice Calculates the amount's fee based on the house edge.
    /// @param amount From which the fee amount will be calculated.
    /// @return The fee amount.
    function _getFees(uint256 amount) internal view returns (uint256) {
        return (houseEdge * amount) / 10000;
    }

    /// @notice Creates a new bet and request randomness to Oracle,
    /// transfer the ERC20 tokens to the contract or refund the bet amount overflow if the bet amount exceed the maxBetAmount.
    /// @param tokenAddress Address of the token.
    /// @param tokenAmount The number of tokens bet.
    /// @param multiplier The bet amount leverage determines the user's profit amount. 10000 = 100% = no profit.
    /// @return A new Bet struct information.
    function _newBet(
        address tokenAddress,
        uint256 tokenAmount, // total bet amount
        uint256 betUnit, // bet unit
        uint256 multiplier,
        uint8 rngCount
    ) internal whenNotPaused nonReentrant returns (Bet memory) {
        // Token storage token = tokens[tokenAddress];
        if (bank.isAllowedToken(tokenAddress) == false) {
            revert ForbiddenToken();
        }
        require(
            rngCount >= RNG_MIN && rngCount <= RNG_MAX,
            "rngCount out of range"
        );

        address user = msg.sender;
        bool isGasToken = tokenAddress == address(0);
        // uint256 fee = isGasToken ? (msg.value - tokenAmount) : msg.value;
        uint256 betAmount = isGasToken ? msg.value : tokenAmount; // -fee

        // Bet amount is capped.
        {
            uint256 minBetUnit = bank.getMinBetUnit(tokenAddress);
            if (betAmount < minBetUnit) {
                revert UnderMinBetUnit(betUnit);
            }

            uint256 maxBetUnit = bank.getMaxBetUnit(tokenAddress);
            if (betAmount > maxBetUnit) {
                revert ExceedMaxBetUnit(betUnit);
            }

            uint256 maxBetAmount = bank.getMaxBetAmount(
                tokenAddress,
                multiplier
            );
            if (betAmount > maxBetAmount) {
                if (isGasToken) {
                    Address.sendValue(payable(user), betAmount - maxBetAmount);
                }
                // betAmount = maxBetAmount;
                revert("betAmount exceed maxBetAmount, please contact support");
            }
        }

        uint256 id = supraRouter.generateRequest(
            "_callback(uint256,uint256[])",
            rngCount,
            numConfirmations,
            9918 // clientSeed
        );

        emit RequestSent(id, user, tokenAddress, rngCount);

        Bet memory newBet = Bet({
            resolved: false,
            user: user,
            token: tokenAddress,
            id: id,
            amount: betAmount,
            blockNumber: block.number,
            payout: 0,
            rngCount: rngCount,
            betUnit: betUnit
        });

        _userBets[user].push(id);
        bets[id] = newBet;
        tokenToPendingCount[tokenAddress]++;

        // If ERC20, transfer the tokens
        if (!isGasToken) {
            IERC20(tokenAddress).safeTransferFrom(
                user,
                address(this),
                betAmount
            );
        }

        return newBet;
    }

    /// @notice Resolves the bet based on the game child contract result.
    /// In case bet is won, the bet amount minus the house edge is transfered to user from the game contract, and the profit is transfered to the user from the Bank.
    /// In case bet is lost, the bet amount is transfered to the Bank from the game contract.
    /// @param bet The Bet struct information.
    /// @param payout What should be sent to the user in case of a won bet. Payout = bet amount + profit amount.
    /// @return The payout amount.
    /// @dev Should not revert as it resolves the bet with the randomness.
    function _resolveBet(
        Bet storage bet,
        uint256 payout
    ) internal returns (uint256) {
        if (bet.resolved == true || bet.id == 0) {
            revert NotPendingBet();
        }
        bet.resolved = true;

        address token = bet.token;
        tokenToPendingCount[token]--;

        uint256 betAmount = bet.amount; //total bet amount
        bool isGasToken = bet.token == address(0);
        uint256 betAmountFee = _getFees(betAmount);
        address user = bet.user;

        if (payout > betAmount) {
            // The user has won more than his bet

            uint256 profit = payout - betAmount;
            uint256 profitFee = _getFees(profit);
            uint256 fee = betAmountFee + profitFee;

            payout -= fee;

            uint256 betAmountPayout = betAmount - betAmountFee;
            uint256 profitPayout = profit - profitFee;
            // Transfer the bet amount payout to the player
            if (isGasToken) {
                Address.sendValue(payable(user), betAmountPayout);
            } else {
                IERC20(token).safeTransfer(user, betAmountPayout);
                // Transfer the bet amount fee to the bank.
                IERC20(token).safeTransfer(address(bank), betAmountFee);
            }

            // Transfer the payout from the bank, the bet amount fee to the bank, and account fees.
            bank.payout{value: isGasToken ? betAmountFee : 0}(
                user,
                token,
                profitPayout,
                fee,
                betAmountFee
            );
        } else if (payout > 0) {
            // The user has won something smaller than his bet

            uint256 fee = _getFees(payout);
            payout -= fee;
            uint256 bankCashIn = betAmount - payout;

            // Transfer the bet amount payout to the player
            if (isGasToken) {
                Address.sendValue(payable(user), payout);
            } else {
                IERC20(token).safeTransfer(user, payout);
                // Transfer the lost bet amount and fee to the bank
                IERC20(token).safeTransfer(address(bank), bankCashIn);
            }

            bank.cashIn{value: isGasToken ? bankCashIn : 0}(
                user,
                token,
                bankCashIn,
                fee,
                betAmountFee
            );
        } else {
            // The user did not win anything
            if (!isGasToken) {
                IERC20(token).safeTransfer(address(bank), betAmount);
            }
            bank.cashIn{value: isGasToken ? betAmount : 0}(
                user,
                token,
                betAmount,
                0,
                betAmountFee
            );
        }

        bet.payout = payout;
        return payout;
    }

    /// @notice Gets the list of the last user bets.
    /// @param user Address of the gamer.
    /// @param dataLength The amount of bets to return.
    /// @return A list of Bet.
    function _getLastUserBets(
        address user,
        uint256 dataLength
    ) internal view returns (Bet[] memory) {
        uint256[] memory userBetsIds = _userBets[user];
        uint256 betsLength = userBetsIds.length;

        if (betsLength < dataLength) {
            dataLength = betsLength;
        }

        Bet[] memory userBets = new Bet[](dataLength);
        if (dataLength != 0) {
            uint256 userBetsIndex;
            for (uint256 i = betsLength; i > betsLength - dataLength; i--) {
                userBets[userBetsIndex] = bets[userBetsIds[i - 1]];
                userBetsIndex++;
            }
        }

        return userBets;
    }

    /// @notice Pauses the contract to disable new bets.
    function pause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /// @notice Refunds the bet to the user if the Oracle VRF callback failed.
    /// @param id The Bet ID.
    function refundBet(uint256 id) external {
        Bet storage bet = bets[id];
        if (bet.resolved == true || bet.id == 0) {
            revert NotPendingBet();
        } else if (block.number < bet.blockNumber + 30) {
            revert NotFulfilled();
        }

        tokenToPendingCount[bet.token]--;

        bet.resolved = true;
        bet.payout = bet.amount;

        // uint256 chainlinkVRFCost = bet.vrfCost;
        if (bet.token == address(0)) {
            Address.sendValue(payable(bet.user), bet.amount); //+ chainlinkVRFCost
        } else {
            IERC20(bet.token).safeTransfer(bet.user, bet.amount);
            // Address.sendValue(payable(bet.user), chainlinkVRFCost);
        }

        emit BetRefunded(id, bet.user, bet.amount); // chainlinkVRFCost
    }

    /// @notice Returns whether the token has pending bets.
    /// @return Whether the token has pending bets.
    function hasPendingBets(address token) public view returns (bool) {
        return tokenToPendingCount[token] != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISupraRouter {
    function generateRequest(
        string memory _functionSig,
        uint8 _rngCount,
        uint256 _numConfirmations,
        uint256 _clientSeed
    ) external returns (uint256);

    function generateRequest(
        string memory _functionSig,
        uint8 _rngCount,
        uint256 _numConfirmations
    ) external returns (uint256);
}

//SPDX-License-Identifier: MIT

import {Game} from "./Game.sol";
pragma solidity 0.8.17;

/// @title nekopachi slot
/// @author munji ([email protected])
contract pachiSlotV6 is Game {
    uint8[36] public reel;
    mapping(uint256 => uint256[2]) payouts;

    event PlaceSpin(
        uint256 id,
        address indexed user,
        address indexed token,
        uint256 amount
    );

    event RequestPaid(
        uint256 _id,
        address _from,
        address tokenAddress,
        uint256[3][] _reels,
        uint256[] _payouts,
        uint256 _totalPayout,
        uint256 _totalInput
    );

    constructor(
        address bankAddress,
        address _supraRouterAddress,
        uint16 _houseEdge
    ) Game(bankAddress, _supraRouterAddress, _houseEdge) {
        uint8[2][8] memory symbols = [
            [0, 8],
            [1, 7],
            [2, 6],
            [3, 5],
            [4, 4],
            [5, 3],
            [6, 2],
            [7, 1]
        ];

        // Multiplier payouts of each combination, first place is x2, second place is x3
        // (Multipliers are multiplied by ten as of solidity does not support floating point numbers,
        //  division by ten is done after the payout calculation)
        payouts[0] = [2, 25];
        payouts[1] = [5, 45];
        payouts[2] = [10, 100];
        payouts[3] = [15, 250];
        payouts[4] = [25, 550];
        payouts[5] = [45, 1650];
        payouts[6] = [150, 6550];
        payouts[7] = [1150, 10e4];

        // Populate the reels with symbols with their corresponding number of occurrence
        // (this slot has 3 same reels so we use only 1 reel)
        uint8 counter = 0;
        for (uint8 symbol = 0; symbol < symbols.length; symbol++) {
            for (uint8 occur = 0; occur < symbols[symbol][1]; occur++) {
                reel[counter] = symbols[symbol][0];
                counter++;
            }
        }
    }

    /// @notice Calculates the target payout amount.
    /// @param betAmount Bet amount.
    /// @return The target payout amount.
    function _getPayout(uint256 betAmount) private pure returns (uint256) {
        return betAmount * 10000; // 최대 10000배
    }

    function spin(
        address tokenAddress,
        uint256 betUnit,
        uint8 rngCount
    ) external payable whenNotPaused {
        uint256 _totalInput = betUnit * rngCount;
        uint256 theorecticalMax = 10000 * uint256(rngCount);

        Bet memory bet = _newBet(
            tokenAddress,
            _totalInput,
            betUnit,
            _getPayout(theorecticalMax), // theoretical max payout
            rngCount
        );

        emit PlaceSpin({
            id: bet.id,
            user: bet.user,
            token: bet.token,
            amount: bet.amount
        });
    }

    function _callback(
        uint256 _id,
        uint256[] calldata _randomNumbers
    ) external {
        require(
            msg.sender == address(supraRouter),
            "only supra router can call this function"
        );
        Bet storage bet = bets[_id];

        uint256[3][] memory _reels = new uint256[3][](_randomNumbers.length);
        uint256[] memory _payouts = new uint256[](_randomNumbers.length);
        uint256 _totalPayout = 0;

        for (uint8 i = 0; i < _randomNumbers.length; i++) {
            uint256 r1 = reel[(_randomNumbers[i] % 100) % 36];
            uint256 r2 = reel[((_randomNumbers[i] % 10000) / 100) % 36];
            uint256 r3 = reel[((_randomNumbers[i] % 1000000) / 10000) % 36];

            uint256 payout = 0;

            // Checks if the symbols on reel 1 and 2 are the same
            if (r1 == r2) {
                // "pos" indicates on which position is the multiplier on "payouts" array
                uint8 pos = 0;
                // Checks if the symbols on reel 2 and 3 are the same and update pos to the corresponding position
                if (r2 == r3) pos = 1;
                payout = (bet.betUnit * payouts[r1][pos]) / 10;
            }

            _reels[i] = [r1, r2, r3];
            _payouts[i] = payout;
            _totalPayout += payout;
        }

        uint256 resolvedPayout = _resolveBet(bet, _totalPayout);

        emit RequestPaid({
            _id: _id,
            _from: bet.user,
            tokenAddress: bet.token,
            _reels: _reels,
            _payouts: _payouts,
            _totalPayout: resolvedPayout,
            _totalInput: bet.amount
        });
    }

    // TODO:function spinWithNativeToken
}