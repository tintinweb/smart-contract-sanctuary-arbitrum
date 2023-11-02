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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0

import "./IRecurveToken.sol";

pragma solidity ^0.8.20;

interface IMasterChef {
    /// @dev functions return information. no states changed.
    function poolLength() external view returns (uint256);

    function pendingRecurve(
        address _stakeToken,
        address _user
    ) external view returns (uint256);

    function userInfo(
        address _stakeToken,
        address _user
    ) external view returns (uint256, uint256, address);

    function poolInfo(
        address _stakeToken
    ) external view returns (uint256, uint256, uint256, uint256);

    function devAddr() external view returns (address);

    function refAddr() external view returns (address);

    function bonusMultiplier() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function RecurvePerBlock() external view returns (uint256);

    /// @dev configuration functions
    function addPool(
        address _stakeToken,
        uint256 _allocPoint,
        uint256 _depositFee
    ) external;

    function setPool(
        address _stakeToken,
        uint256 _allocPoint,
        uint256 _depositFee
    ) external;

    function updatePool(address _stakeToken) external;

    function removePool(address _stakeToken) external;

    /// @dev user interaction functions
    function deposit(
        address _for,
        address _stakeToken,
        uint256 _amount
    ) external;

    function withdraw(
        address _for,
        address _stakeToken,
        uint256 _amount
    ) external;

    function depositRecurve(address _for, uint256 _amount) external;

    function withdrawRecurve(address _for, uint256 _amount) external;

    function harvest(address _for, address _stakeToken) external;

    function harvest(address _for, address[] calldata _stakeToken) external;

    function emergencyWithdraw(address _for, address _stakeToken) external;

    function mintExtraReward(
        address _stakeToken,
        address _to,
        uint256 _amount
    ) external;

    function Recurve() external returns (IRecurveToken);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IMasterChefCallback {
    function masterChefCall(
        address stakeToken,
        address userAddr,
        uint256 unboostedReward
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRecurveToken {
    function mint(address to, uint256 amount) external;
    function pause() external;
    function unpause() external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function isPaused() external view returns (bool);
    function cap() external view returns (uint256);
    function addMinter(address account) external;
    function renounceMinter() external;
    function revokeMinter(address account) external;
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function hasRole(bytes32 role, address account) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

interface IReferral {
    function setMasterChef(address _masterChef) external;

    function activate(address referrer) external;

    function activateBySign(
        address referee,
        address referrer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function isActivated(address _address) external view returns (bool);

    function updateReferralReward(
        address accountAddress,
        uint256 reward
    ) external;

    function claimReward() external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

interface IStake {
    // Stake specific functions
    function safeRecurveTransfer(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

library LinkList {
    address public constant start = address(1);
    address public constant end = address(1);
    address public constant empty = address(0);

    struct List {
        uint256 llSize;
        mapping(address => address) next;
    }

    function init(List storage list) internal returns (List storage) {
        list.next[start] = end;

        return list;
    }

    function has(List storage list, address addr) internal view returns (bool) {
        return list.next[addr] != empty;
    }

    function add(
        List storage list,
        address addr
    ) internal returns (List storage) {
        require(
            !has(list, addr),
            "LinkList::add:: addr is already in the list"
        );
        list.next[addr] = list.next[start];
        list.next[start] = addr;
        list.llSize++;

        return list;
    }

    function remove(
        List storage list,
        address addr,
        address prevAddr
    ) internal returns (List storage) {
        require(has(list, addr), "LinkList::remove:: addr not whitelisted yet");
        require(
            list.next[prevAddr] == addr,
            "LinkList::remove:: wrong prevConsumer"
        );
        list.next[prevAddr] = list.next[addr];
        list.next[addr] = empty;
        list.llSize--;

        return list;
    }

    function getAll(
        List storage list
    ) internal view returns (address[] memory) {
        address[] memory addrs = new address[](list.llSize);
        address curr = list.next[start];
        for (uint256 i = 0; curr != end; i++) {
            addrs[i] = curr;
            curr = list.next[curr];
        }
        return addrs;
    }

    function getPreviousOf(
        List storage list,
        address addr
    ) internal view returns (address) {
        address curr = list.next[start];
        require(
            curr != empty,
            "LinkList::getPreviousOf:: please init the linkedlist first"
        );
        for (uint256 i = 0; curr != end; i++) {
            if (list.next[curr] == addr) return curr;
            curr = list.next[curr];
        }
        return end;
    }

    function getNextOf(
        List storage list,
        address curr
    ) internal view returns (address) {
        return list.next[curr];
    }

    function length(List storage list) internal view returns (uint256) {
        return list.llSize;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library RecurveAddress {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../library/LinkList.sol";
import "../library/RecurveAddress.sol";
import "../library/SafeMath.sol";
import "../interfaces/IRecurveToken.sol";
import "../interfaces/IStake.sol";
import "../interfaces/IMasterChef.sol";
import "../interfaces/IMasterChefCallback.sol";
import "../interfaces/IReferral.sol";

// MasterChef is the master of Recurve. He can make Recurve and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. 
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is IMasterChef, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using LinkList for LinkList.List;
    using RecurveAddress for address;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many Staking tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        address fundedBy;
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 allocPoint; // How many allocation points assigned to this pool.
        uint256 lastRewardBlock; // Last block number that Recurve distribution occurs.
        uint256 accRecurvePerShare; // Accumulated Recurve per share, times 1e12. See below.
        uint256 depositFee;
    }

    // Recurve token.
    IRecurveToken public override Recurve;
    // Stake address.
    IStake public stake;
    // Dev address.
    address public override devAddr;
    uint256 public devBps;
    // Refferal address.
    address public override refAddr;
    uint256 public refBps;
    // Recurve per block.
    uint256 public override RecurvePerBlock;
    // Bonus muliplier for early users.
    uint256 public override bonusMultiplier;

    // Pool link list.
    LinkList.List public pools;
    // Info of each pool.
    mapping(address => PoolInfo) public override poolInfo;
    // Info of each user that stakes Staking tokens.
    mapping(address => mapping(address => UserInfo)) public override userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public override totalAllocPoint;
    // The block number when Recurve mining starts.
    uint256 public startBlock;

    // Does the pool allows some contracts to fund for an account.
    mapping(address => bool) public stakeTokenCallerAllowancePool;

    // list of contracts that the pool allows to fund.
    mapping(address => LinkList.List) public stakeTokenCallerContracts;

    event Deposit(
        address indexed funder,
        address indexed fundee,
        address indexed stakeToken,
        uint256 amount
    );
    event Withdraw(
        address indexed funder,
        address indexed fundee,
        address indexed stakeToken,
        uint256 amount
    );
    event EmergencyWithdraw(
        address indexed user,
        address indexed stakeToken,
        uint256 amount
    );
    event Harvest(
        address indexed funder,
        address indexed fundee,
        address indexed stakeToken,
        uint256 reward
    );

    event SetStakeTokenCallerAllowancePool(
        address indexed stakeToken,
        bool isAllowed
    );
    event AddStakeTokenCallerContract(
        address indexed stakeToken,
        address indexed caller
    );
    event SetRecurvePerBlock(uint256 prevRecurvePerBlock, uint256 currentRecurvePerBlock);
    event RemoveStakeTokenCallerContract(
        address indexed stakeToken,
        address indexed caller
    );
    event SetRefAddress(address indexed refAddress);
    event SetDevAddress(address indexed devAddress);
    event SetRefBps(uint256 refBps);
    event SetDevBps(uint256 devBps);
    event UpdateMultiplier(uint256 bonusMultiplier);

    constructor(
        IRecurveToken _Recurve,
        IStake _stake,
        address _devAddr,
        address _refAddr,
        uint256 _RecurvePerBlock,
        uint256 _startBlock
    ) Ownable(msg.sender) {
        require(
            _devAddr != address(0) && _devAddr != address(1),
            "constructor: _devAddr must not be address(0) or address(1)"
        );
        require(
            _refAddr != address(0) && _refAddr != address(1),
            "constructor: _refAddr must not be address(0) or address(1)"
        );

        bonusMultiplier = 1;
        Recurve = _Recurve;
        stake = _stake;
        devAddr = _devAddr;
        refAddr = _refAddr;
        RecurvePerBlock = _RecurvePerBlock;
        startBlock = _startBlock;
        devBps = 0;
        refBps = 0;
        pools.init();

        // add Recurve pool
        pools.add(address(_Recurve));
        poolInfo[address(_Recurve)] = PoolInfo({
            allocPoint: 0,
            lastRewardBlock: startBlock,
            accRecurvePerShare: 0,
            depositFee: 0
        });
        totalAllocPoint = 0;
    }

    // Only permitted funder can continue the execution
    modifier onlyPermittedTokenFunder(
        address _beneficiary,
        address _stakeToken
    ) {
        require(
            _isFunder(_beneficiary, _stakeToken),
            "onlyPermittedTokenFunder: caller is not permitted"
        );
        _;
    }

    // Only stake token caller contract can continue the execution (stakeTokenCaller must be a funder contract)
    modifier onlyStakeTokenCallerContract(address _stakeToken) {
        require(
            stakeTokenCallerContracts[_stakeToken].has(_msgSender()),
            "onlyStakeTokenCallerContract: bad caller"
        );
        _;
    }

    // Set funder allowance for a stake token pool
    function setStakeTokenCallerAllowancePool(
        address _stakeToken,
        bool _isAllowed
    ) external onlyOwner {
        stakeTokenCallerAllowancePool[_stakeToken] = _isAllowed;
        emit SetStakeTokenCallerAllowancePool(_stakeToken, _isAllowed);
    }

    // Setter function for adding stake token contract caller
    function addStakeTokenCallerContract(
        address _stakeToken,
        address _caller
    ) external onlyOwner {
        require(
            stakeTokenCallerAllowancePool[_stakeToken],
            "addStakeTokenCallerContract: the pool doesn't allow a contract caller"
        );
        LinkList.List storage list = stakeTokenCallerContracts[_stakeToken];
        if (list.getNextOf(LinkList.start) == LinkList.empty) {
            list.init();
        }
        list.add(_caller);
        emit AddStakeTokenCallerContract(_stakeToken, _caller);
    }

    // Setter function for removing stake token contract caller
    function removeStakeTokenCallerContract(
        address _stakeToken,
        address _caller
    ) external onlyOwner {
        require(
            stakeTokenCallerAllowancePool[_stakeToken],
            "removeStakeTokenCallerContract: the pool doesn't allow a contract caller"
        );
        LinkList.List storage list = stakeTokenCallerContracts[_stakeToken];
        list.remove(_caller, list.getPreviousOf(_caller));
        emit RemoveStakeTokenCallerContract(_stakeToken, _caller);
    }

    function setDevAddress(address _devAddr) external onlyOwner {
        require(
            _devAddr != address(0) && _devAddr != address(1),
            "setDevAddress: _devAddr must not be address(0) or address(1)"
        );
        devAddr = _devAddr;
        emit SetDevAddress(_devAddr);
    }

    function setDevBps(uint256 _devBps) external onlyOwner {
        require(_devBps <= 1000, "setDevBps::bad devBps");
        massUpdatePools();
        devBps = _devBps;
        emit SetDevBps(_devBps);
    }

    function setRefAddress(address _refAddr) external onlyOwner {
        require(
            _refAddr != address(0) && _refAddr != address(1),
            "setRefAddress: _refAddr must not be address(0) or address(1)"
        );
        refAddr = _refAddr;
        emit SetRefAddress(_refAddr);
    }

    function setRefBps(uint256 _refBps) external onlyOwner {
        require(_refBps <= 100, "setRefBps::bad refBps");
        massUpdatePools();
        refBps = _refBps;
        emit SetRefBps(_refBps);
    }

    // Set Recurve per block.
    function setRecurvePerBlock(uint256 _RecurvePerBlock) external onlyOwner {
        massUpdatePools();
        uint256 prevRecurvePerBlock = RecurvePerBlock;
        RecurvePerBlock = _RecurvePerBlock;
        emit SetRecurvePerBlock(prevRecurvePerBlock, RecurvePerBlock);
    }

    // Add a pool. Can only be called by the owner.
    function addPool(
        address _stakeToken,
        uint256 _allocPoint,
        uint256 _depositFee
    ) external override onlyOwner {
        require(
            _stakeToken != address(0) && _stakeToken != address(1),
            "addPool: _stakeToken must not be address(0) or address(1)"
        );
        require(!pools.has(_stakeToken), "addPool: _stakeToken duplicated");

        massUpdatePools();

        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        pools.add(_stakeToken);
        poolInfo[_stakeToken] = PoolInfo({
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accRecurvePerShare: 0,
            depositFee: _depositFee
        });
    }

    // Update the given pool's Recurve allocation point. Can only be called by the owner.
    function setPool(
        address _stakeToken,
        uint256 _allocPoint,
        uint256 _depositFee
    ) external override onlyOwner {
        require(
            _stakeToken != address(0) && _stakeToken != address(1),
            "setPool: _stakeToken must not be address(0) or address(1)"
        );
        require(pools.has(_stakeToken), "setPool: _stakeToken not in the list");

        massUpdatePools();

        totalAllocPoint = totalAllocPoint
            .sub(poolInfo[_stakeToken].allocPoint)
            .add(_allocPoint);
        poolInfo[_stakeToken].allocPoint = _allocPoint;
        poolInfo[_stakeToken].depositFee = _depositFee;
    }

    // Remove pool. Can only be called by the owner.
    function removePool(address _stakeToken) external override onlyOwner {
        require(_stakeToken != address(Recurve), "removePool: can't remove Recurve pool");
        require(pools.has(_stakeToken), "removePool: pool not add yet");
        require(
            IERC20(_stakeToken).balanceOf(address(this)) == 0,
            "removePool: pool not empty"
        );

        massUpdatePools();

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_stakeToken].allocPoint);
        pools.remove(_stakeToken, pools.getPreviousOf(_stakeToken));
        poolInfo[_stakeToken].allocPoint = 0;
        poolInfo[_stakeToken].lastRewardBlock = 0;
        poolInfo[_stakeToken].accRecurvePerShare = 0;
        poolInfo[_stakeToken].depositFee = 0;
    }

    // Return the length of poolInfo
    function poolLength() external view override returns (uint256) {
        return pools.length();
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(
        uint256 _lastRewardBlock,
        uint256 _currentBlock
    ) private view returns (uint256) {
        return _currentBlock.sub(_lastRewardBlock).mul(bonusMultiplier);
    }

    function updateMultiplier(uint256 _bonusMultiplier) public onlyOwner {
        bonusMultiplier = _bonusMultiplier;
        emit UpdateMultiplier(_bonusMultiplier);
    }

    // Validating if a msg sender is a funder
    function _isFunder(
        address _beneficiary,
        address _stakeToken
    ) internal view returns (bool) {
        if (stakeTokenCallerAllowancePool[_stakeToken])
            return stakeTokenCallerContracts[_stakeToken].has(_msgSender());
        return _beneficiary == _msgSender();
    }

    // View function to see pending Recurves on frontend.
    function pendingRecurve(
        address _stakeToken,
        address _user
    ) external view override returns (uint256) {
        PoolInfo storage pool = poolInfo[_stakeToken];
        UserInfo storage user = userInfo[_stakeToken][_user];
        uint256 accRecurvePerShare = pool.accRecurvePerShare;
        uint256 totalStakeToken = IERC20(_stakeToken).balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && totalStakeToken != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 RecurveReward = multiplier
                .mul(RecurvePerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accRecurvePerShare = accRecurvePerShare.add(
                RecurveReward.mul(1e12).div(totalStakeToken)
            );
        }
        return user.amount.mul(accRecurvePerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        address current = pools.next[LinkList.start];
        while (current != LinkList.end) {
            updatePool(current);
            current = pools.getNextOf(current);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(address _stakeToken) public override {
        PoolInfo storage pool = poolInfo[_stakeToken];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 totalStakeToken = IERC20(_stakeToken).balanceOf(address(this));
        if (totalStakeToken == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 RecurveReward = multiplier.mul(RecurvePerBlock).mul(pool.allocPoint).div(
            totalAllocPoint
        );
        Recurve.mint(devAddr, RecurveReward.mul(devBps).div(10000));
        Recurve.mint(address(stake), RecurveReward.mul(refBps).div(10000));
        Recurve.mint(address(stake), RecurveReward);
        pool.accRecurvePerShare = pool.accRecurvePerShare.add(
            RecurveReward.mul(1e12).div(totalStakeToken)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit token to MasterChef for Recurve allocation.
    function deposit(
        address _for,
        address _stakeToken,
        uint256 _amount
    )
        external
        override
        onlyPermittedTokenFunder(_for, _stakeToken)
        nonReentrant
    {
        require(
            _stakeToken != address(0) && _stakeToken != address(1),
            "setPool: _stakeToken must not be address(0) or address(1)"
        );
        require(_stakeToken != address(Recurve), "deposit: use depositRecurve instead");
        require(pools.has(_stakeToken), "deposit: no pool");

        PoolInfo storage pool = poolInfo[_stakeToken];
        UserInfo storage user = userInfo[_stakeToken][_for];

        if (user.fundedBy != address(0))
            require(user.fundedBy == _msgSender(), "deposit: only funder");

        updatePool(_stakeToken);

        if (user.amount > 0) _harvest(_for, _stakeToken);
        if (user.fundedBy == address(0)) user.fundedBy = _msgSender();
        if (_amount > 0) {
            uint256 depositFeeAmount = _amount.mul(pool.depositFee).div(10000);
            if (depositFeeAmount > 0) {
                _amount = _amount.sub(depositFeeAmount);
                IERC20(_stakeToken).safeTransferFrom(
                    address(_msgSender()),
                    devAddr,
                    depositFeeAmount
                );
            }
            IERC20(_stakeToken).safeTransferFrom(
                address(_msgSender()),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRecurvePerShare).div(1e12);
        emit Deposit(_msgSender(), _for, _stakeToken, _amount);
    }

    // Withdraw token from MasterChef.
    function withdraw(
        address _for,
        address _stakeToken,
        uint256 _amount
    ) external override nonReentrant {
        require(
            _stakeToken != address(0) && _stakeToken != address(1),
            "setPool: _stakeToken must not be address(0) or address(1)"
        );
        require(_stakeToken != address(Recurve), "withdraw: use withdrawRecurve instead");
        require(pools.has(_stakeToken), "withdraw: no pool");

        PoolInfo storage pool = poolInfo[_stakeToken];
        UserInfo storage user = userInfo[_stakeToken][_for];

        require(user.fundedBy == _msgSender(), "withdraw: only funder");
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_stakeToken);
        _harvest(_for, _stakeToken);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            IERC20(_stakeToken).safeTransfer(_msgSender(), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRecurvePerShare).div(1e12);
        if (user.amount == 0) user.fundedBy = address(0);
        emit Withdraw(_msgSender(), _for, _stakeToken, _amount);
    }

    // Deposit Recurve to MasterChef.
    function depositRecurve(
        address _for,
        uint256 _amount
    )
        external
        override
        onlyPermittedTokenFunder(_for, address(Recurve))
        nonReentrant
    {
        PoolInfo storage pool = poolInfo[address(Recurve)];
        UserInfo storage user = userInfo[address(Recurve)][_for];

        if (user.fundedBy != address(0))
            require(user.fundedBy == _msgSender(), "depositRecurve: bad sof");

        updatePool(address(Recurve));

        if (user.amount > 0) _harvest(_for, address(Recurve));
        if (user.fundedBy == address(0)) user.fundedBy = _msgSender();
        if (_amount > 0) {
            uint256 depositFeeAmount = _amount.mul(pool.depositFee).div(10000);
            if (depositFeeAmount > 0) {
                _amount = _amount.sub(depositFeeAmount);
                IERC20(address(Recurve)).safeTransferFrom(
                    address(_msgSender()),
                    devAddr,
                    depositFeeAmount
                );
            }
            IERC20(address(Recurve)).safeTransferFrom(
                address(_msgSender()),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRecurvePerShare).div(1e12);
        emit Deposit(_msgSender(), _for, address(Recurve), _amount);
    }

    // Withdraw Recurve
    function withdrawRecurve(
        address _for,
        uint256 _amount
    ) external override nonReentrant {
        PoolInfo storage pool = poolInfo[address(Recurve)];
        UserInfo storage user = userInfo[address(Recurve)][_for];

        require(user.fundedBy == _msgSender(), "withdrawRecurve: only funder");
        require(user.amount >= _amount, "withdrawRecurve: not good");

        updatePool(address(Recurve));
        _harvest(_for, address(Recurve));

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            IERC20(address(Recurve)).safeTransfer(address(_msgSender()), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRecurvePerShare).div(1e12);
        if (user.amount == 0) user.fundedBy = address(0);
        emit Withdraw(_msgSender(), _for, address(Recurve), user.amount);
    }

    // Harvest Recurve earned from a specific pool.
    function harvest(
        address _for,
        address _stakeToken
    ) external override nonReentrant {
        PoolInfo storage pool = poolInfo[_stakeToken];
        UserInfo storage user = userInfo[_stakeToken][_for];

        updatePool(_stakeToken);
        _harvest(_for, _stakeToken);

        user.rewardDebt = user.amount.mul(pool.accRecurvePerShare).div(1e12);
    }

    // Harvest Recurve earned from pools.
    function harvest(
        address _for,
        address[] calldata _stakeTokens
    ) external override nonReentrant {
        for (uint256 i = 0; i < _stakeTokens.length; i++) {
            PoolInfo storage pool = poolInfo[_stakeTokens[i]];
            UserInfo storage user = userInfo[_stakeTokens[i]][_for];
            updatePool(_stakeTokens[i]);
            _harvest(_for, _stakeTokens[i]);
            user.rewardDebt = user.amount.mul(pool.accRecurvePerShare).div(1e12);
        }
    }

    // Internal function to harvest Recurve
    function _harvest(address _for, address _stakeToken) internal {
        PoolInfo memory pool = poolInfo[_stakeToken];
        UserInfo memory user = userInfo[_stakeToken][_for];
        require(user.fundedBy == _msgSender(), "_harvest: only funder");
        require(user.amount > 0, "_harvest: nothing to harvest");
        uint256 pending = user.amount.mul(pool.accRecurvePerShare).div(1e12).sub(
            user.rewardDebt
        );
        require(
            pending <= Recurve.balanceOf(address(stake)),
            "_harvest: wait what.. not enough Recurve"
        );
        stake.safeRecurveTransfer(_for, pending);
        if (stakeTokenCallerContracts[_stakeToken].has(_msgSender())) {
            _masterChefCallee(_msgSender(), _stakeToken, _for, pending);
        }
        _referralCallee(_for, pending);
        emit Harvest(_msgSender(), _for, _stakeToken, pending);
    }

    function _referralCallee(address _for, uint256 _pending) internal {
        if (!refAddr.isContract()) {
            return;
        }
        stake.safeRecurveTransfer(address(refAddr), _pending.mul(refBps).div(10000));
        (bool success, ) = refAddr.call(
            abi.encodeWithSelector(
                IReferral.updateReferralReward.selector,
                _for,
                _pending.mul(refBps).div(10000)
            )
        );
        require(
            success,
            "_referralCallee:  failed to execute updateReferralReward"
        );
    }

    // Observer function for those contract implementing onBeforeLock, execute an onBeforelock statement
    function _masterChefCallee(
        address _caller,
        address _stakeToken,
        address _for,
        uint256 _pending
    ) internal {
        if (!_caller.isContract()) {
            return;
        }
        (bool success, ) = _caller.call(
            abi.encodeWithSelector(
                IMasterChefCallback.masterChefCall.selector,
                _stakeToken,
                _for,
                _pending
            )
        );
        require(
            success,
            "_masterChefCallee:  failed to execute masterChefCall"
        );
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(
        address _for,
        address _stakeToken
    ) external override nonReentrant {
        UserInfo storage user = userInfo[_stakeToken][_for];
        require(
            user.fundedBy == _msgSender(),
            "emergencyWithdraw: only funder"
        );
        IERC20(_stakeToken).safeTransfer(address(_for), user.amount);

        emit EmergencyWithdraw(_for, _stakeToken, user.amount);

        user.amount = 0;
        user.rewardDebt = 0;
        user.fundedBy = address(0);
    }

    // This is a function for mining an extra amount of Recurve, should be called only by stake token caller contract (boosting purposed)
    function mintExtraReward(
        address _stakeToken,
        address _to,
        uint256 _amount
    ) external override onlyStakeTokenCallerContract(_stakeToken) {
        Recurve.mint(_to, _amount);
    }
}