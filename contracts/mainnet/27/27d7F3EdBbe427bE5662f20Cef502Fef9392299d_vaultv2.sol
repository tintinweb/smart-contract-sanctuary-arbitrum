/**
 *Submitted for verification at Arbiscan.io on 2023-11-10
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
library SafeMath {
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol


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

// File: @openzeppelin/contracts/interfaces/draft-IERC6093.sol


// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

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
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;




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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// File: vaultv2.sol









pragma solidity ^0.8.20;

    interface GDtoken is IERC20{
        function mint(address recipient, uint256 _amount) external;
        function burn(address _from, uint256 _amount) external ;
    }

    interface IERC20Extented is IERC20 {
    function decimals() external  view returns (uint8);
    }

    interface oracle {
        function getGMETHprice() external  view returns(uint256);
        function getGMBTCprice() external  view returns(uint256);
        function getAssetPrice() external view returns(uint256);
        function getStableAssetPrice() external pure returns(uint256);
    }

    // Define the interface for the exchange router
    interface IExchangeRouter {
        struct CreateDepositParams {
            address receiver;
            address callbackContract;
            address uiFeeReceiver;
            address market;
            address initialLongToken;
            address initialShortToken;
            address[] longTokenSwapPath;
            address[] shortTokenSwapPath;
            uint256 minMarketTokens;
            bool shouldUnwrapNativeToken;
            uint256 executionFee;
            uint256 callbackGasLimit;
        }

        // Struct for CreateWithdrawalParams
        struct CreateWithdrawalParams {
            address receiver;
            address callbackContract;
            address uiFeeReceiver;
            address market;
            address[] longTokenSwapPath;
            address[] shortTokenSwapPath;
            uint256 minLongTokenAmount;
            uint256 minShortTokenAmount;
            bool shouldUnwrapNativeToken;
            uint256 executionFee;
            uint256 callbackGasLimit;
        }
        // Function to send Wrapped Native Tokens (WNT) to a receiver
        function sendWnt(address receiver, uint256 amount) external payable;

        // Function to send tokens to a receiver
        function sendTokens(address token, address receiver, uint256 amount) external payable;

        // Function to create a new deposit
        function createDeposit(CreateDepositParams calldata params) external payable returns (bytes32);

        // Function to create a new withdrawal
        function createWithdrawal(CreateWithdrawalParams calldata params) external payable returns (bytes32);
    }

    

    struct PoolInfo {
        IERC20 lpToken;    
        GDtoken GDlptoken; 
        uint256 EarnRateSec;     
        uint256 totalStaked; 
        uint256 lastUpdate; 
        uint256 vaultcap;
        uint256 depositFees;
        uint256 withdrawFees;
        uint256 APR;
        bool stakable;
        bool withdrawable;
        bool rewardStart;
    }

  

    // Define the DepositUtils and WithdrawalUtils contracts and structs here
    // You should include the necessary contract and struct definitions or import them if they exist in other files.
    // Make sure to define them according to your specific use case.

    contract vaultv2 is ReentrancyGuard, Ownable{

        using SafeERC20 for IERC20;
        using SafeMath for uint256;

        address public rebalanceRole;
        oracle public Oracle;

        // Declare a variable to hold the ExchangeRouter address
        address public exchangeRouter;
        PoolInfo[] public poolInfo;

        IERC20 public WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        IERC20 public USDC = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
        address GMarketAddress = 0x70d95587d40A2caf56bd97485aB3Eec10Bee6336;

        struct UserWithdrawAmount {
            uint256 ethAmount;
            uint256 usdcAmount;
            uint256 burnEthGDAmount;
            uint256 burnUsdcGDAmount;
        }

        struct TotalPendingWithdrawAmount {
            uint256 ethAmount;
            uint256 usdcAmount;
        }

        TotalPendingWithdrawAmount public totalPendingWithdraw;
        TotalPendingWithdrawAmount public totalPendingWithdrawAfterContractAmount;


        mapping(address => UserWithdrawAmount) public withdrawMap;
        constructor(address _oracle, address _exchangeRouter, GDtoken _gdUSDC, GDtoken _gdETH) Ownable(msg.sender) {
            exchangeRouter = _exchangeRouter;
            rebalanceRole = msg.sender;
            Oracle = oracle(_oracle);

            poolInfo.push(PoolInfo({
                lpToken: USDC,
                GDlptoken: _gdUSDC,
                totalStaked:0,
                EarnRateSec:0,
                lastUpdate: block.timestamp,
                vaultcap: 0,
                stakable: true,
                withdrawable: true,
                rewardStart: false,
                depositFees: 250, 
                withdrawFees: 250, 
                APR: 1000
                
            }));

            poolInfo.push(PoolInfo({
                lpToken: WETH,
                GDlptoken: _gdETH,
                totalStaked:0,
                EarnRateSec:0,
                lastUpdate: block.timestamp,
                vaultcap: 0,
                stakable: true,
                withdrawable: true,
                rewardStart: false,
                depositFees: 250,
                withdrawFees: 250, 
                APR: 800
                
            }));

            
          
        }

        address wntReceiver = 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55;
        address wntReceiverWithdraw = 0x0628D46b5D145f183AdB6Ef1f2c97eD1C4701C55;

        receive() external payable {}

        function updateOracle(oracle _oracle) external onlyOwner{
            Oracle = _oracle;
        }

        function updateRebalancer(address _rebalance) external onlyOwner{
            rebalanceRole = _rebalance;
        }

        function Router(address _router) external onlyOwner{
            exchangeRouter = _router;
        }

        function getWithdrawETHneeded() external view returns(uint256){
            if (totalPendingWithdraw.ethAmount >= WETH.balanceOf(address(this))){
                return totalPendingWithdraw.ethAmount.sub(WETH.balanceOf(address(this)));

            }
            else {
                return 0;
            }

        }

        function getWithdrawUSDCneeded() external view returns(uint256){
            if (totalPendingWithdraw.usdcAmount >= USDC.balanceOf(address(this))){
                return totalPendingWithdraw.usdcAmount.sub(USDC.balanceOf(address(this)));

            }
            else {
                return 0;
            }

        }
        function getFreeWETH() external view returns(uint256){
              if (totalPendingWithdraw.ethAmount >= WETH.balanceOf(address(this))){
                return 0;
            }
            else {
                
                return WETH.balanceOf(address(this)).sub(totalPendingWithdraw.ethAmount);

            }

        }
        function getFreeUSDC() external view returns(uint256){
            if (totalPendingWithdraw.usdcAmount >= USDC.balanceOf(address(this))){
                return 0;
            }
            else {
                
                return USDC.balanceOf(address(this)).sub(totalPendingWithdraw.usdcAmount);

            }

        }

        function setFees(uint256 _pid, uint256 _percent) external onlyOwner {
            require(_percent < 1000, "not in range");
            poolInfo[_pid].depositFees = _percent;
        }

        function setWithdrawFees(uint256 _pid, uint256 _percent) external onlyOwner {
            require(_percent < 1000, "not in range");
            poolInfo[_pid].withdrawFees = _percent;
        }

        // Unlocks the staked + gained USDC and burns xUSDC
        function updatePool(uint256 _pid) internal {
            uint256 timepass = block.timestamp.sub(poolInfo[_pid].lastUpdate);
            poolInfo[_pid].lastUpdate = block.timestamp;
            uint256 reward = poolInfo[_pid].EarnRateSec.mul(timepass);
            poolInfo[_pid].totalStaked = poolInfo[_pid].totalStaked.add(reward);
            
        }

        function currentPoolTotal(uint256 _pid) public view returns (uint256) {
            uint reward =0;
            if (poolInfo[_pid].rewardStart) {
                uint256 timepass = block.timestamp.sub(poolInfo[_pid].lastUpdate);
                reward = poolInfo[_pid].EarnRateSec.mul(timepass);
            }
            return poolInfo[_pid].totalStaked.add(reward);
        }

        function displayStakedBalance(address _address, uint256 _pid) public view returns(uint256) {
            GDtoken GDT = poolInfo[_pid].GDlptoken;
            uint256 totalShares = GDT.totalSupply();
            uint256 amountOut = GDT.balanceOf(_address).mul(currentPoolTotal(_pid)).div(totalShares);
            return amountOut;
        }

        function updatePoolRate(uint256 _pid) internal {
            poolInfo[_pid].EarnRateSec =  poolInfo[_pid].totalStaked.mul(poolInfo[_pid].APR).div(10**4).div(365 days);
        }


        function setPoolCap(uint256 _pid, uint256 _vaultcap) external onlyOwner {
            poolInfo[_pid].vaultcap = _vaultcap;
        }

        function setAPR(uint256 _pid, uint256 _apr) external onlyOwner {
            require(_apr > 200 && _apr < 4000, " apr not in range");
            poolInfo[_pid].APR = _apr;
            if (poolInfo[_pid].rewardStart){
                updatePool(_pid);
            }
            updatePoolRate(_pid);
        }

        function setOpenVault(uint256 _pid, bool open) external onlyOwner {

            poolInfo[_pid].stakable = open;
            
        }

        function setOpenAllVault(bool open) external onlyOwner {
            for (uint256 _pid = 0; _pid < poolInfo.length; ++ _pid){
                poolInfo[_pid].stakable = open;
            }
            
        }

        function startReward(uint256 _pid) external onlyOwner {
            require(!poolInfo[_pid].rewardStart, "already started");
            poolInfo[_pid].rewardStart = true;
            poolInfo[_pid].lastUpdate = block.timestamp;
            
        }

        function pauseReward(uint256 _pid) external onlyOwner {
            require(poolInfo[_pid].rewardStart, "not started");

            updatePool(_pid);
            updatePoolRate(_pid);
            poolInfo[_pid].rewardStart = false;
            poolInfo[_pid].lastUpdate = block.timestamp;
            
        }

        function openWithdraw(uint256 _pid, bool open) external onlyOwner {

            poolInfo[_pid].withdrawable = open;
        }

        function openAllWithdraw(bool open) external onlyOwner {

            for (uint256 _pid = 0; _pid < poolInfo.length; ++ _pid){

                poolInfo[_pid].withdrawable = open;
            }
        }

        function checkDuplicate(GDtoken _GDlptoken) internal view returns(bool) {
        
            for (uint256 i = 0; i < poolInfo.length; ++i){
                if (poolInfo[i].GDlptoken == _GDlptoken){
                    return false;
                }        
            }
            return true;
        }

        function GDpriceToStakedtoken(uint256 _pid) public view returns(uint256) {
            GDtoken GDT = poolInfo[_pid].GDlptoken;
            uint256 totalShares = GDT.totalSupply();
            // Calculates the amount of USDC the xUSDC is worth
            uint256 amountOut = (currentPoolTotal(_pid)).mul(10**18).div(totalShares);
            return amountOut;
        }

        function enter(uint256 _amountin, uint256 _pid) public nonReentrant {

            require(_amountin > 0, "invalid amount");
            uint256 _amount = _amountin;
        
            GDtoken GDT = poolInfo[_pid].GDlptoken;
            IERC20 StakedToken = poolInfo[_pid].lpToken;

            uint256 decimalMul = 18 - IERC20Extented(address(StakedToken)).decimals();
            
            //decimals handlin
            _amount = _amountin.mul(10**decimalMul);
            

            require(_amountin <= StakedToken.balanceOf(msg.sender), "balance too low" );
            require(poolInfo[_pid].stakable, "not stakable");
            require((poolInfo[_pid].totalStaked + _amount) <= poolInfo[_pid].vaultcap, "cant deposit more than vault cap");

            if (poolInfo[_pid].rewardStart){
                updatePool(_pid);
            }
            
            // Gets the amount of USDC locked in the contract
            uint256 totalStakedTokens = poolInfo[_pid].totalStaked;
            // Gets the amount of gdUSDC in existence
            uint256 totalShares = GDT.totalSupply();

            uint256 balanceMultipier = 100000 - poolInfo[_pid].depositFees;
            uint256 amountAfterFee = _amount.mul(balanceMultipier).div(100000);
            // If no gdUSDC exists, mint it 1:1 to the amount put in
            if (totalShares == 0 || totalStakedTokens == 0) {
                GDT.mint(msg.sender, amountAfterFee);
            } 
            // Calculate and mint the amount of gdUSDC the USDC is worth. The ratio will change overtime
            else {
                uint256 what = amountAfterFee.mul(totalShares).div(totalStakedTokens);
                GDT.mint(msg.sender, what);
            }
            
            poolInfo[_pid].totalStaked = poolInfo[_pid].totalStaked.add(amountAfterFee);

            updatePoolRate(_pid);
            StakedToken.safeTransferFrom(msg.sender, address(this), _amountin);       
        }

        function leave(uint256 _share, uint256 _pid) public  nonReentrant returns(uint256){

            GDtoken GDT = poolInfo[_pid].GDlptoken;
            IERC20 StakedToken = poolInfo[_pid].lpToken;

            require(_share <= GDT.balanceOf(msg.sender), "balance too low");
            require(poolInfo[_pid].withdrawable, "withdraw window not opened");

            if (poolInfo[_pid].rewardStart){
                updatePool(_pid);
            }


            // Gets the amount of xUSDC in existence
            uint256 totalShares = GDT.totalSupply();
            // Calculates the amount of USDC the xUSDC is worth
            uint256 amountOut = _share.mul(poolInfo[_pid].totalStaked).div(totalShares);

            poolInfo[_pid].totalStaked = poolInfo[_pid].totalStaked.sub(amountOut);
            updatePoolRate(_pid);
            GDT.transferFrom(msg.sender, address(this), _share);

            uint256 amountSendOut = amountOut;

            uint256 decimalMul = 18 - IERC20Extented(address(StakedToken)).decimals();
            
            //decimals handlin
            amountSendOut = amountOut.div(10**decimalMul);   
            uint256 balanceMultipier = 100000 - poolInfo[_pid].withdrawFees;
            amountSendOut = amountSendOut.mul(balanceMultipier).div(100000);

            if (_pid == 1){
                withdrawMap[msg.sender].ethAmount = withdrawMap[msg.sender].ethAmount.add(amountSendOut);
                withdrawMap[msg.sender].burnEthGDAmount = withdrawMap[msg.sender].burnEthGDAmount.add(_share);
                totalPendingWithdraw.ethAmount = totalPendingWithdraw.ethAmount.add(amountSendOut); 


            }
            else {
                withdrawMap[msg.sender].usdcAmount = withdrawMap[msg.sender].usdcAmount.add(amountSendOut);
                withdrawMap[msg.sender].burnUsdcGDAmount = withdrawMap[msg.sender].burnUsdcGDAmount.add(_share);
                totalPendingWithdraw.usdcAmount = totalPendingWithdraw.usdcAmount.add(amountSendOut); 
            }
            
        
            return amountSendOut;
        }

        function resetUserWithdraw(address account) internal {
            withdrawMap[account].ethAmount = 0;
            withdrawMap[account].usdcAmount = 0;
            withdrawMap[account].burnEthGDAmount = 0;
            withdrawMap[account].burnUsdcGDAmount = 0;
        }

        function withdraw() public  nonReentrant { 
           uint256 ethAmountSendOut = withdrawMap[msg.sender].ethAmount;
           uint256 usdcAmountSendOut = withdrawMap[msg.sender].usdcAmount;
           
           uint256 GDburnETH =  withdrawMap[msg.sender].burnEthGDAmount;
           uint256 GDburnUSDC =  withdrawMap[msg.sender].burnUsdcGDAmount;

           resetUserWithdraw(msg.sender);
           totalPendingWithdraw.ethAmount = totalPendingWithdraw.ethAmount.sub(ethAmountSendOut);
           totalPendingWithdraw.usdcAmount = totalPendingWithdraw.usdcAmount.sub(usdcAmountSendOut);

           GDtoken GDTusdc = poolInfo[0].GDlptoken;
           GDtoken GDTeth = poolInfo[1].GDlptoken;
           GDTeth.burn(address(this),GDburnETH);
           GDTusdc.burn(address(this), GDburnUSDC);
           WETH.safeTransfer(msg.sender, ethAmountSendOut);
           USDC.safeTransfer(msg.sender, usdcAmountSendOut);

        }

        function withdrawable(address account) public view returns(bool)  { 
           uint256 ethAmountSendOut = withdrawMap[account].ethAmount;
           uint256 usdcAmountSendOut = withdrawMap[account].usdcAmount;
           return (WETH.balanceOf(address(this)) >= ethAmountSendOut && USDC.balanceOf(address(this)) >=usdcAmountSendOut);

        }

        function totalUSDvault() public view returns(uint256) {
            uint256 tokenPrice = Oracle.getAssetPrice();
            uint256 StablePrice = Oracle.getStableAssetPrice();
            uint256 totalStakedTokens = currentPoolTotal(0);
            uint256 totalStableStakedTokens = currentPoolTotal(1);
            uint256 totalUSD = tokenPrice.mul(totalStakedTokens).div(10**18); //decials 8 
            uint256 totalUSD2 = StablePrice.mul(totalStableStakedTokens).div(10**18); //decials 8 
            return totalUSD.add(totalUSD2);
        }

        function totalGMUSD() public view returns(uint256) {            
            uint256 GMprice = Oracle.getGMETHprice();
            uint256 GMamount = IERC20(GMarketAddress).balanceOf(address(this));
            return GMamount.mul(GMprice).div(10**28); //decials 8 
        }

        function withdrawProfit(IERC20 token, uint256 _amount) external onlyOwner {
            require(totalGMUSD() > totalUSDvault(), "undervalue");
            require(token != IERC20(GMarketAddress), "cant withdraw backing");
            token.transfer(owner(), _amount);
        }

        function withdrawARB(uint256 _amount) external onlyOwner {
            IERC20 token = IERC20(0x912CE59144191C1204E64559FE8253a0e49E6548);
            token.transfer(owner(), _amount);
        }

        // Function to withdraw all Ether from this contract to the owner
        function withdrawETH() external onlyOwner {
            uint256 balance = address(this).balance;
            require(balance > 0, "Contract balance is zero");

            (bool sent, ) = payable(owner()).call{value: balance}("");
            require(sent, "Failed to send Ether");
        }
                // Function to test deposit by calling multiple functions on ExchangeRouter
        function BuyGMtokens(uint256 wntAmount, uint256 tokenAmount, uint256 shortTokenAmount) external payable  {

            require(msg.sender ==  rebalanceRole,"not rebalancer");
            // Replace these values with your desired addresses and amounts        
            address tokenReceiver = 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55;
            address tokenAddress = address(WETH);
            address shortTokenReceiver = 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55;
            address shortTokenAddress = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

            _buyGMtokens(wntAmount, tokenReceiver, tokenAddress, 
            tokenAmount, shortTokenReceiver, shortTokenAddress, shortTokenAmount, 
            address(0), address(0), GMarketAddress);
            
        }

        function _buyGMtokens(uint256 wntAmount, 
            address tokenReceiver, address token1, uint256 amount1, address token2Receiver, address token2, 
            uint256 amount2, address callback, address uiFeeReceiverAddress, address marketAddress) internal  {

           
            IERC20(token1).approve(0x7452c558d45f8afC8c83dAe62C3f8A5BE19c71f6, amount1);
            IERC20(token2).approve(0x7452c558d45f8afC8c83dAe62C3f8A5BE19c71f6, amount2);

            // Create the CreateDepositParams struct with your desired values
            IExchangeRouter.CreateDepositParams memory depositParams = IExchangeRouter.CreateDepositParams(
                address(this), // Replace with receiver address
                callback, // Replace with callbackContract address
                uiFeeReceiverAddress, // Replace with uiFeeReceiver address
                marketAddress, // Replace with market address
                token1, // Replace with initialLongToken address
                token2, // Replace with initialShortToken address
                new address[](0), // Replace with longTokenSwapPath if needed
                new address[](0), // Replace with shortTokenSwapPath if needed
                0, // Replace with minMarketTokens
                false, // Replace with shouldUnwrapNativeToken (true or false)
                wntAmount, // Replace with executionFee
                0 // Replace with callbackGasLimit
            );

            // Call the functions on ExchangeRouter
            IExchangeRouter(exchangeRouter).sendWnt{value: wntAmount}(wntReceiver, wntAmount);
            IExchangeRouter(exchangeRouter).sendTokens(token1, tokenReceiver, amount1);
            IExchangeRouter(exchangeRouter).sendTokens(token2, token2Receiver, amount2);
            IExchangeRouter(exchangeRouter).createDeposit(depositParams);
        }


        function SwapToAssets(uint256 wntAmount, uint256 tokenAmount) external payable  {

            require(msg.sender ==  rebalanceRole,"not rebalancer");
            // Replace these values with your desired addresses and amounts

            address tokenReceiver = 0x0628D46b5D145f183AdB6Ef1f2c97eD1C4701C55;
            address tokenAddress = GMarketAddress;

            _swapToAssets(wntAmount, tokenReceiver,tokenAmount,tokenAddress,address(0),address(0),wntAmount);
        }


        // Function to test withdrawal with customizable parameters
        function _swapToAssets(
            uint256 wntAmount,
            address tokenReceiver,
            uint256 tokenAmount,
            address tokenAddress,
            address callback,
            address uiFeeReceiverAddress,
            uint256 executionFee
        
        ) internal {
            // Approve token transfers
            IERC20(tokenAddress).approve(0x7452c558d45f8afC8c83dAe62C3f8A5BE19c71f6, tokenAmount);

            // Create the CreateWithdrawalParams struct with custom values
            IExchangeRouter.CreateWithdrawalParams memory withdrawalParams = IExchangeRouter.CreateWithdrawalParams(
                address(this),
                callback,
                uiFeeReceiverAddress,
                tokenAddress,
                new address[](0),// Replace with longTokenSwapPath if needed
                new address[](0), // Replace with shortTokenSwapPath if needed
                0,
                0,
                false,
                executionFee,
                0
            );

            // Call the functions on ExchangeRouter
            IExchangeRouter(exchangeRouter).sendWnt{value: wntAmount}(wntReceiverWithdraw, wntAmount);
            IExchangeRouter(exchangeRouter).sendTokens(tokenAddress, tokenReceiver, tokenAmount);
            IExchangeRouter(exchangeRouter).createWithdrawal(withdrawalParams);
        }


}