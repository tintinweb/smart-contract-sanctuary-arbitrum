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
pragma solidity 0.8.26;

import "../libraries/CallParams.sol";

interface IShogunMulticallV1 {
    struct Call {
        CallParams.Params params;   // encoded params
        address target;             // `call.to` - address of smart contract that should be called
        uint256 msgValue;           // `msg.value` that should be attached to the call
        bytes data;               // `call.data` that should be passed to the call
    }

    /**
     * @notice Executes multiple calls
     * @param calls Encoded array of calls that must be executed
     * @param swapTokenOut Token OUT address (address(0) if native token) for swap calls
     * @param swapDestination Receiver of Tokens OUT after swap
     * @param swapAmountOutMin Minimum amount to receive after swap
     */
    function multicall(
        Call[] memory calls,
        address swapTokenOut,
        address swapDestination,
        uint256 swapAmountOutMin
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Library for decoding call params, tightly encoded into bytes32 and updating calldata
/// Main purpose - decrease amount of calldata passed to Multicall contract
library CallParams {
/*
    Encoded call params (256 bits total)
    (160 bits) - token address that should be approved/checked `balanceOf(address(this))`
    (8 bits) - uint8 index of calldata word which should be replaced with `balanceOf(address(this))`
    (8 bits) - uint8 index of calldata word which should adjusted proportionally to `balanceOf(address(this))`
                Example usage: adjust `amountOutMin` proportionally to difference between `balanceOf` and `amountIn`
    (8 bits) - uint8 index of calldata word which should adjusted proportionally to native balance
                Example usage: adjust `amountOutMin` proportionally to difference between address(this).balance and `amountIn`
    (8 bits) - uint8 index of calldata word which should be considered as amountIn for approval
    ...
    empty bits
    ...
    (1 bit) - boolean, true = should approve tokens if required
    (1 bit) - boolean, true = should update calldata value proportionally to `balanceOf(address(this))` difference
    (1 bit) - boolean, true = should replace calldata value with `balanceOf(address(this))`
    (1 bit) - boolean, true = should update calldata value proportionally to native balance difference
    (1 bit) - boolean, true = should pass full native balance
*/
    type Params is bytes32;

    // bits shift right values
    uint256 private constant PASS_FULL_NATIVE_BALANCE_SHR = 0;
    uint256 private constant REPLACE_NATIVE_BALANCE_SHR = 1;
    uint256 private constant PROPORTIONALLY_UPDATE_NATIVE_BALANCE_SHR = 2;
    uint256 private constant REPLACE_BALANCE_OF_SHR = 3;
    uint256 private constant PROPORTIONALLY_UPDATE_BALANCE_OF_SHR = 4;
    uint256 private constant APPROVE_SHR = 5;

    uint256 private constant TOKEN_ADDRESS_SHR = 256 - 160;
    uint256 private constant BALANCE_OF_REPLACE_INDEX_SHR = 256 - 160 - 8;
    uint256 private constant NATIVE_BALANCE_REPLACE_INDEX_SHR = 256 - 160 - 8 * 2;
    uint256 private constant UPDATE_PROPORTIONALLY_TO_BALANCE_OF_INDEX_SHR = 256 - 160 - 8 * 3;
    uint256 private constant UPDATE_PROPORTIONALLY_TO_NATIVE_BALANCE_INDEX_SHR = 256 - 160 - 8 * 4;
    uint256 private constant AMOUNT_IN_INDEX_SHR = 256 - 160 - 8 * 5;

    // Special params
    bytes32 private constant SLIPPAGE_CHECK = 0xF000000000000000000000000000000000000000000000000000000000000000;

    error InvalidIndex(uint32 startIndex, uint32 calldataLength);

    /**
     * @notice Returns ERC20 token decoded from params
     * @param params Call params
     */
    function getToken(Params params) internal pure returns (IERC20 token) {
        assembly {
            token := and(
                shr(TOKEN_ADDRESS_SHR, params),
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            )
        }
    }

    // --------------------------      SPECIAL PARAMS      --------------------------

    /**
     * @notice Returns true slippage check is required
     * @param params Call params
     * @dev This means no external call will be required. The only thing to do now is check slippage
     */
    function checkSlippage(Params params) internal pure returns (bool) {
        return Params.unwrap(params) == SLIPPAGE_CHECK;
    }

    // --------------------------      CALLDATA FUNCTIONS      --------------------------

    /**
     * @notice Updates calldata according to requirements
     * @param params Call params
     * @param callData Calldata
     */
    function updateCallData(
        Params params,
        bytes memory callData,
        uint256 initialMsgValue
    ) internal view {
        if (shouldReplaceBalanceOf(params)) {
            // usually for updating `amountIn`
            uint256 balance = getToken(params).balanceOf(address(this));
            uint8 indexToReplace = getIndexToReplaceWithBalanceOf(params);

            if (shouldUpdateProportionallyToBalanceOf(params)) {
                // usually for updating `amountOutMin`
                uint256 currentValue = getCalldataValueAtIndex(
                    callData,
                    indexToReplace
                );
                uint8 indexToUpdate = getIndexToUpdateProportionallyToBalanceOf(params);
                uint256 currentValueToReplace = getCalldataValueAtIndex(
                    callData,
                    indexToUpdate
                );

                // replacing value proportionally to difference with balanceOf amount
                replaceCalldataValue(
                    callData,
                    indexToUpdate,
                    currentValueToReplace * balance / currentValue
                );
            }

            replaceCalldataValue(
                callData,
                indexToReplace,
                balance
            );
        }

        // if msg. value doesn't change - no need to update calldata
        if (shouldPassFullNativeBalance(params)) {
            uint256 nativeBalance = address(this).balance;
            if (shouldReplaceNativeBalance(params)) {
                uint8 indexToReplace = getIndexToReplaceWithNativeBalance(params);

                replaceCalldataValue(
                    callData,
                    indexToReplace,
                    nativeBalance
                );
            }

            if (shouldUpdateProportionallyToNativeBalance(params)) {
                uint8 indexToUpdate = getIndexToUpdateProportionallyToNativeBalance(params);

                // usually for updating `amountOutMin`
                uint256 currentValueToReplace = getCalldataValueAtIndex(
                    callData,
                    indexToUpdate
                );

                // replacing value proportionally to difference with native balance amount
                replaceCalldataValue(
                    callData,
                    indexToUpdate,
                    currentValueToReplace * nativeBalance / initialMsgValue
                );
            }
        }
    }

    /**
     * @notice Replaces calldata value at `index` with `newValue`
     * @param callData Calldata memory
     * @param index Index of 32-byte calldata word to replace
     * @param newValue New value to replace with
     */
    function replaceCalldataValue(
        bytes memory callData,
        uint8 index,
        uint256 newValue
    ) internal pure {
        uint256 startIndex = getStartIndex(callData.length, index);

        assembly {
            mstore(add(callData, startIndex), newValue)
        }
    }

    /**
     * @notice Gets uint256 calldata value from specific index
     * @param callData Calldata memory
     * @param index Index of 32-byte calldata word to get
     * @return value uint256 value
     */
    function getCalldataValueAtIndex(
        bytes memory callData,
        uint8 index
    ) internal pure returns(uint256 value) {
        uint256 startIndex = getStartIndex(callData.length, index);

        assembly {
            value := mload(add(callData, startIndex))
        }
    }

    /**
     * @notice Gets amountIn value for approval (amountToSpend)
     * @param params Call params
     * @param callData Calldata memory
     * @return amountIn Amount of tokens that expected to be spent
     */
    function getAmountIn(
        Params params,
        bytes memory callData
    ) internal pure returns(uint256 amountIn) {
        uint256 startIndex = getStartIndex(
            callData.length,
            getIndexOfAmountIn(params)
        );

        assembly {
            amountIn := mload(add(callData, startIndex))
        }
    }

    /**
     * @notice Gets start index for specific value in calldata
     * @param callDataLength Calldata length
     * @param index Index of 32-byte calldata word
     * @return startIndex Start index of value in calldata
     */
    function getStartIndex(uint256 callDataLength, uint256 index) private pure returns(uint256 startIndex) {
        // 32 for prefix + 4 for selector
        startIndex = 32 + 4 + index * 32;

        if (startIndex > callDataLength) {
            revert InvalidIndex(uint32(startIndex), uint32(callDataLength));
        }
    }

    // --------------------------      BOOLEAN ENCODING      --------------------------

    /**
     * @notice Should this call pass all smart contracts native balance as `msg.value`?
     * @param params Call params
     */
    function shouldPassFullNativeBalance(Params params) internal pure returns (bool value) {
        assembly {value := and(shr(PASS_FULL_NATIVE_BALANCE_SHR, params), 1)}
    }

    /**
     * @notice Should calldata value be proportionally update to native balance?
     * @param params Call params
     */
    function shouldUpdateProportionallyToNativeBalance(Params params) internal pure returns (bool value) {
        assembly {value := and(shr(PROPORTIONALLY_UPDATE_NATIVE_BALANCE_SHR, params), 1)}
    }

    /**
     * @notice Should calldata value be replaced with `balanceOf(address(this))`?
     * @param params Call params
     */
    function shouldReplaceBalanceOf(Params params) internal pure returns (bool value) {
        assembly {value := and(shr(REPLACE_BALANCE_OF_SHR, params), 1)}
    }

    /**
     * @notice Should calldata value be replaced with native balance?
     * @param params Call params
     */
    function shouldReplaceNativeBalance(Params params) internal pure returns (bool value) {
        assembly {value := and(shr(REPLACE_NATIVE_BALANCE_SHR, params), 1)}
    }

    /**
     * @notice Should calldata value be proportionally update to `balanceOf(address(this))`?
     * @param params Call params
     */
    function shouldUpdateProportionallyToBalanceOf(Params params) internal pure returns (bool value) {
        assembly {value := and(shr(PROPORTIONALLY_UPDATE_BALANCE_OF_SHR, params), 1)}
    }

    /**
     * @notice Should approve token if required?
     * @param params Call params
     */
    function shouldApproveIfRequired(Params params) internal pure returns (bool value) {
        assembly {value := and(shr(APPROVE_SHR, params), 1)}
    }

    // --------------------------      INDEX ENCODING      --------------------------

    /**
     * @notice Returns index of calldata value that should be replaced with balanceOf amount
     * @param params Call params
     */
    function getIndexToReplaceWithBalanceOf(Params params) internal pure returns (uint8 index) {
        assembly {index := and(shr(BALANCE_OF_REPLACE_INDEX_SHR, params), 0xFF)}
    }

    /**
     * @notice Returns index of calldata value that should be updated proportionally to token balanceOf
     * @param params Call params
     */
    function getIndexToUpdateProportionallyToBalanceOf(Params params) internal pure returns (uint8 index) {
        assembly {index := and(shr(UPDATE_PROPORTIONALLY_TO_BALANCE_OF_INDEX_SHR, params), 0xFF)}
    }

    /**
     * @notice Returns index of calldata value that should be replaced with native balance
     * @param params Call params
     */
    function getIndexToReplaceWithNativeBalance(Params params) internal pure returns (uint8 index) {
        assembly {index := and(shr(REPLACE_NATIVE_BALANCE_SHR, params), 0xFF)}
    }

    /**
     * @notice Returns index of calldata value that should be updated proportionally to native balance
     * @param params Call params
     */
    function getIndexToUpdateProportionallyToNativeBalance(Params params) internal pure returns (uint8 index) {
        assembly {index := and(shr(UPDATE_PROPORTIONALLY_TO_NATIVE_BALANCE_INDEX_SHR, params), 0xFF)}
    }

    /**
     * @notice Returns index of calldata value that should be considered amountIn for approval
     * @param params Call params
     */
    function getIndexOfAmountIn(Params params) internal pure returns (uint8 index) {
        assembly {index := and(shr(AMOUNT_IN_INDEX_SHR, params), 0xFF)}
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./utils/TokenRecovery.sol";
import "./interfaces/IShogunMulticallV1.sol";

/// @title Multicall contract designed to interact with DEXes for efficient swaps
/// Supports multiple routes, split routes
/// Allows adjusting `amountIn`, `amountOutMin` and other values depending on token balance and native balance.
contract ShogunMulticallV1 is TokenRecovery, IShogunMulticallV1 {
    using SafeERC20 for IERC20;
    using CallParams for CallParams.Params;

    error BelowAmountOutMin(uint256 received);
    error CallFailed(uint256 index, bytes errorData);

    /**
     * @param initialOwner Initial smart contract owner
     */
    constructor(address initialOwner) TokenRecovery(initialOwner) {}

    receive() external payable {}

    /**
     * @notice Executes multiple calls
     * @param calls Encoded array of calls that must be executed
     * @param swapTokenOut Token OUT address (address(0) if native token) for swap calls
     * @param swapDestination Receiver of Tokens OUT after swap
     * @param swapAmountOutMin Minimum amount to receive after swap
     */
    function multicall(
        Call[] memory calls,
        address swapTokenOut,
        address swapDestination,
        uint256 swapAmountOutMin
    ) external payable {
        uint256 initialAmount = _getBalance(swapTokenOut, swapDestination);

        for(uint256 i = 0; i < calls.length; i++) {
            Call memory call = calls[i];

            // special params case - no call is required
            if (call.params.checkSlippage()) {
                uint256 received = _getBalance(swapTokenOut, swapDestination) - initialAmount;
                if (received < swapAmountOutMin) revert BelowAmountOutMin(received);
                continue;
            }

            call.params.updateCallData(call.data, call.msgValue);

            if (call.params.shouldApproveIfRequired()) {
                _safeApproveIfRequired(
                    call.params.getToken(),
                    call.target,
                    call.params.getAmountIn(call.data)
                );
            }

            if (call.params.shouldPassFullNativeBalance()) {
                call.msgValue = address(this).balance;
            }

            (bool success, bytes memory data) = call.target.call{value: call.msgValue}(call.data);
            if (!success) revert CallFailed(i, data);
        }
    }

    /**
     * @notice Approves ERC20 token to `spender` in case of insufficient allowance
     * @param token ERC20 token that needs to be approved
     * @param spender Spender address
     * @param amountToSpend Amount of tokens to spend
     */
    function _safeApproveIfRequired(
        IERC20 token,
        address spender,
        uint256 amountToSpend
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance < amountToSpend) {
            // Approves to 0 in case token processes `approve` like `increaseAllowance`
            if (allowance != 0) {
                token.approve(spender, 0);
            }
            token.approve(spender, type(uint256).max);
        }
    }

    /**
     * @notice Returns balance of token OUT
     * @param token ERC20 token address (address(0) if native token)
     * @param account Account, which balance should be checked
     */
    function _getBalance(
        address token,
        address account
    ) internal view returns(uint256) {
        if (token == address(0)) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Emergency recovery functions
abstract contract TokenRecovery is Ownable {
    using SafeERC20 for IERC20;

    /**
     * @param initialOwner Initial smart contract owner
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @notice Emergency recover of stuck ERC20 tokens
     * @param token ERC20 token address
     * @param receiver ERC20 tokens receiver address
     * @dev Can be called only by the owner
     */
    function emergencyERC20Recover(
        IERC20 token,
        address receiver
    ) external onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(receiver, amount);
    }

    /**
     * @notice Emergency recover of stuck native tokens
     * @param receiver Native tokens receiver address
     * @dev Can be called only by the owner
     */
    function emergencyEthRecover(
        address payable receiver
    ) external onlyOwner {
        (bool success,) = receiver.call{value: address(this).balance}("");
        require(success);
    }
}