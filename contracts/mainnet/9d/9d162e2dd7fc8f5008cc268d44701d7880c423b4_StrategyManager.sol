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
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../token/ERC20/IERC20.sol";

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.25;

library DataTypes {
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    //timestamp of last update
    uint40 lastUpdateTimestamp;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    //aToken address
    address aTokenAddress;
    //stableDebtToken address
    address stableDebtTokenAddress;
    //variableDebtToken address
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the current treasury balance, scaled
    uint128 accruedToTreasury;
    //the outstanding unbacked aTokens minted through the bridging feature
    uint128 unbacked;
    //the outstanding debt borrowed against this asset in isolation mode
    uint128 isolationModeTotalDebt;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60: asset is paused
    //bit 61: borrowing in isolation mode is enabled
    //bit 62: siloed borrowing enabled
    //bit 63: flashloaning enabled
    //bit 64-79: reserve factor
    //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
    //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
    //bit 152-167 liquidation protocol fee
    //bit 168-175 eMode category
    //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
    //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
    //bit 252-255 unused

    uint256 data;
  }
}

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 */
interface IAaveLendingPoolV3 {
  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function supply(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @dev Deprecated: Use the `supply` function instead
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   */
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   */
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @notice Returns the normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(
    address asset
  ) external view returns (uint256);

  /**
   * @notice Returns the normalized variable debt per unit of asset
   * @dev WARNING: This function is intended to be used primarily by the protocol itself to get a
   * "dynamic" variable index based on time, current stored index and virtual rate at the current
   * moment (approx. a borrower would get if opening a position). This means that is always used in
   * combination with variable debt supply/balances.
   * If using this function externally, consider that is possible to have an increasing normalized
   * variable debt that is not equivalent to how the variable debt index would be updated in storage
   * (e.g. only updates with non-zero variable debt supply)
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(
    address asset
  ) external view returns (uint256);

  /**
   * @notice Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state and configuration data of the reserve
   */
  function getReserveData(
    address asset
  ) external view returns (DataTypes.ReserveData memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.25;

/**
 * @title IRewardsController
 * @author Aave
 * @notice Defines the basic interface for a Rewards Controller.
 */
interface IAaveRewardsController {
  /**
   * @dev Claims reward for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
   * @param assets List of assets to check eligible distributions before claiming rewards
   * @param amount The amount of rewards to claim
   * @param to The address that will be receiving the rewards
   * @param reward The address of the reward token
   * @return The amount of rewards claimed
   **/
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to,
    address reward
  ) external returns (uint256);

  /**
   * @dev Claims all rewards for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param to The address that will be receiving the rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardList"
   **/
  function claimAllRewards(
    address[] calldata assets,
    address to
  )
    external
    returns (
      address[] memory rewardsList,
      uint256[] memory claimedAmounts
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IEcclesiaDao {
  function accrueRevenue(
    address _token,
    uint256 _amount,
    uint256 leverageFee_
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// libraries
import { VirtualPool } from "../libs/VirtualPool.sol";
import { PoolMath } from "../libs/PoolMath.sol";
import { DataTypes } from "../libs/DataTypes.sol";
// interfaces
import { IEcclesiaDao } from "../interfaces/IEcclesiaDao.sol";
import { IStrategyManager } from "../interfaces/IStrategyManager.sol";

interface ILiquidityManager {
  // ======= STRUCTS ======= //

  struct CoverRead {
    uint256 coverId;
    uint64 poolId;
    uint256 coverAmount;
    bool isActive;
    uint256 premiumsLeft;
    uint256 dailyCost;
    uint256 premiumRate;
    uint32 lastTick; // Last last tick for which the cover is active
  }

  struct PositionRead {
    uint256 positionId;
    uint256 supplied;
    uint256 suppliedWrapped;
    uint256 commitWithdrawalTimestamp;
    uint256 strategyRewardIndex;
    uint64[] poolIds;
    uint256 newUserCapital;
    uint256 newUserCapitalWrapped;
    uint256[] coverRewards;
    uint256 strategyRewards;
  }

  struct Position {
    uint256 supplied;
    uint256 commitWithdrawalTimestamp;
    uint256 strategyRewardIndex;
    uint64[] poolIds;
  }

  struct PoolOverlap {
    uint64 poolId;
    uint256 amount;
  }

  struct VPoolRead {
    uint64 poolId;
    uint256 feeRate; // amount of fees on premiums in RAY
    uint256 leverageFeePerPool; // amount of fees per pool when using leverage
    IEcclesiaDao dao;
    IStrategyManager strategyManager;
    PoolMath.Formula formula;
    DataTypes.Slot0 slot0;
    uint256 strategyId;
    uint256 strategyRewardRate;
    address paymentAsset; // asset used to pay LP premiums
    address underlyingAsset; // asset required by the strategy
    address wrappedAsset; // tokenised strategy shares (ex: aTokens)
    bool isPaused;
    uint64[] overlappedPools;
    uint256 ongoingClaims;
    uint256[] compensationIds;
    uint256[] overlappedCapital;
    uint256 utilizationRate;
    uint256 totalLiquidity;
    uint256 availableLiquidity;
    uint256 strategyRewardIndex;
    uint256 lastOnchainUpdateTimestamp;
    uint256 premiumRate;
    // The amount of liquidity index that is in the current unfinished tick
    uint256 liquidityIndexLead;
  }

  function strategyManager() external view returns (IStrategyManager);

  function positions(
    uint256 tokenId_
  ) external view returns (Position memory);

  function coverToPool(
    uint256 tokenId_
  ) external view returns (uint64);

  function poolOverlaps(
    uint64 poolIdA_,
    uint64 poolIdB_
  ) external view returns (uint256);

  function coverInfo(
    uint256 tokenId_
  ) external view returns (CoverRead memory);

  function isCoverActive(
    uint256 tokenId
  ) external view returns (bool);

  function addClaimToPool(uint256 coverId_) external;

  function removeClaimFromPool(uint256 coverId_) external;

  function payoutClaim(uint256 poolId_, uint256 amount_) external;

  function takeInterestsWithYieldBonus(
    address account_,
    uint256 yieldBonus_,
    uint256[] calldata positionIds_
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

interface IStrategyManager {
  function getRewardIndex(
    uint256 strategyId
  ) external view returns (uint256);

  function getRewardRate(
    uint256 strategyId_
  ) external view returns (uint256);

  function underlyingAsset(
    uint256 strategyId_
  ) external view returns (address);

  function assets(
    uint256 strategyId_
  ) external view returns (address underlying, address wrapped);

  function wrappedToUnderlying(
    uint256 strategyId_,
    uint256 amountWrapped_
  ) external view returns (uint256);

  function depositToStrategy(
    uint256 strategyId_,
    uint256 amountUnderlying_
  ) external;

  function withdrawFromStrategy(
    uint256 strategyId_,
    uint256 amountCapitalUnderlying_,
    uint256 amountRewardsUnderlying_,
    address account_,
    uint256 /*yieldBonus_*/
  ) external;

  function depositWrappedToStrategy(uint256 strategyId_) external;

  function withdrawWrappedFromStrategy(
    uint256 strategyId_,
    uint256 amountCapitalUnderlying_,
    uint256 amountRewardsUnderlying_,
    address account_,
    uint256 /*yieldBonus_*/
  ) external;

  function payoutFromStrategy(
    uint256 strategyId_,
    uint256 amount,
    address claimant
  ) external;

  function computeReward(
    uint256 strategyId_,
    uint256 amount_,
    uint256 startRewardIndex_,
    uint256 endRewardIndex_
  ) external pure returns (uint256);

  function itCompounds(
    uint256 strategyId_
  ) external pure returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.25;

/// @title BitMath
/// @dev This library provides functionality for computing bit properties of an unsigned integer
library BitMath {
  /// @notice Returns the index of the least significant bit of the number,
  ///     where the least significant bit is at index 0 and the most significant bit is at index 255
  /// @dev The function satisfies the property:
  ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
  /// @param x the value for which to compute the least significant bit, must be greater than 0
  /// @return r the index of the least significant bit
  function leastSignificantBit(
    uint256 x
  ) internal pure returns (uint8 r) {
    require(x > 0);

    r = 255;
    if (x & type(uint128).max > 0) {
      r -= 128;
    } else {
      x >>= 128;
    }
    if (x & type(uint64).max > 0) {
      r -= 64;
    } else {
      x >>= 64;
    }
    if (x & type(uint32).max > 0) {
      r -= 32;
    } else {
      x >>= 32;
    }
    if (x & type(uint16).max > 0) {
      r -= 16;
    } else {
      x >>= 16;
    }
    if (x & type(uint8).max > 0) {
      r -= 8;
    } else {
      x >>= 8;
    }
    if (x & 0xf > 0) {
      r -= 4;
    } else {
      x >>= 4;
    }
    if (x & 0x3 > 0) {
      r -= 2;
    } else {
      x >>= 2;
    }
    if (x & 0x1 > 0) r -= 1;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

// Libraries
import { RayMath } from "../libs/RayMath.sol";
import { TickBitmap } from "../libs/TickBitmap.sol";
import { PoolMath } from "../libs/PoolMath.sol";

// Interfaces
import { IEcclesiaDao } from "../interfaces/IEcclesiaDao.sol";
import { IStrategyManager } from "../interfaces/IStrategyManager.sol";

library DataTypes {
  struct Slot0 {
    // The last tick at which the pool's liquidity was updated
    uint32 tick;
    // The distance in seconds between ticks
    uint256 secondsPerTick;
    uint256 coveredCapital;
    /**
     * The last timestamp at which the current tick changed
     * This value indicates the start of the current stored tick
     */
    uint256 lastUpdateTimestamp;
    // The index tracking how much premiums have been consumed in favor of LP
    uint256 liquidityIndex;
  }

  struct LpInfo {
    uint256 beginLiquidityIndex;
    uint256 beginClaimIndex;
  }

  struct Cover {
    uint256 coverAmount;
    uint256 beginPremiumRate;
    /**
     * If cover is active: last last tick for which the cover is valid
     * If cover is expired: slot0 tick at which the cover was expired minus 1
     */
    uint32 lastTick;
  }

  struct Compensation {
    uint64 fromPoolId;
    // The ratio is the claimed amount/ total liquidity in the claim pool
    uint256 ratio;
    uint256 strategyRewardIndexBeforeClaim;
    mapping(uint64 _poolId => uint256 _amount) liquidityIndexBeforeClaim;
  }

  struct VPool {
    uint64 poolId;
    uint256 feeRate; // amount of fees on premiums in RAY
    uint256 leverageFeePerPool; // amount of fees per pool when using leverage
    IEcclesiaDao dao;
    IStrategyManager strategyManager;
    PoolMath.Formula formula;
    Slot0 slot0;
    uint256 strategyId;
    address paymentAsset; // asset used to pay LP premiums
    address underlyingAsset; // asset covered & used by the strategy
    address wrappedAsset; // tokenised strategy shares (ex: aTokens)
    bool isPaused;
    uint64[] overlappedPools;
    uint256 ongoingClaims;
    uint256[] compensationIds;
    /**
     * Maps poolId 0 -> poolId 1 -> overlapping capital
     *
     * @dev poolId 0 -> poolId 0 points to a pool's own liquidity
     * @dev liquidity overlap is always registered in the lower poolId
     */
    mapping(uint64 _poolId => uint256 _amount) overlaps;
    mapping(uint256 _positionId => LpInfo) lpInfos;
    // Maps an word position index to a bitmap of tick states (initialized or not)
    mapping(uint24 _wordPos => uint256 _bitmap) tickBitmap;
    // Maps a tick to the amount of cover that expires after that tick ends
    mapping(uint32 _tick => uint256 _coverAmount) ticks;
    // Maps a cover ID to the premium position of the cover
    mapping(uint256 _coverId => Cover) covers;
  }

  struct VPoolConstructorParams {
    uint64 poolId;
    IEcclesiaDao dao;
    IStrategyManager strategyManager;
    uint256 strategyId;
    address paymentAsset;
    uint256 feeRate; //Ray
    uint256 leverageFeePerPool; //Ray
    uint256 uOptimal; //Ray
    uint256 r0; //Ray
    uint256 rSlope1; //Ray
    uint256 rSlope2; //Ray
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

// Libraries
import { RayMath } from "../libs/RayMath.sol";

// @bw move back into vpool ?

library PoolMath {
  using RayMath for uint256;

  // ======= CONSTANTS ======= //

  uint256 constant YEAR = 365 days;
  uint256 constant RAY = RayMath.RAY;
  uint256 constant MAX_SECONDS_PER_TICK = 1 days;
  uint256 constant FEE_BASE = RAY;
  uint256 constant PERCENTAGE_BASE = 100;
  uint256 constant FULL_CAPACITY = PERCENTAGE_BASE * RAY;

  // ======= STRUCTURES ======= //

  struct Formula {
    uint256 uOptimal;
    uint256 r0;
    uint256 rSlope1;
    uint256 rSlope2;
  }

  // ======= FUNCTIONS ======= //

  /**
   * @notice Computes the premium rate of a cover,
   * the premium rate is the APR cost for a cover  ,
   * these are paid by cover buyer on their cover amount.
   *
   * @param formula The formula of the pool
   * @param utilizationRate_ The utilization rate of the pool
   *
   * @return The premium rate of the cover expressed in rays
   *
   * @dev Not pure since reads self but pure for all practical purposes
   */
  function getPremiumRate(
    Formula calldata formula,
    uint256 utilizationRate_
  ) public pure returns (uint256 /* premiumRate */) {
    if (utilizationRate_ < formula.uOptimal) {
      // Return base rate + proportional slope 1 rate
      return
        formula.r0 +
        formula.rSlope1.rayMul(
          utilizationRate_.rayDiv(formula.uOptimal)
        );
    } else if (utilizationRate_ < FULL_CAPACITY) {
      // Return base rate + slope 1 rate + proportional slope 2 rate
      return
        formula.r0 +
        formula.rSlope1 +
        formula.rSlope2.rayMul(
          (utilizationRate_ - formula.uOptimal).rayDiv(
            FULL_CAPACITY - formula.uOptimal
          )
        );
    } else {
      // Return base rate + slope 1 rate + slope 2 rate
      /**
       * @dev Premium rate is capped because in case of overusage the
       * liquidity providers are exposed to the same risk as 100% usage but
       * cover buyers are not fully covered.
       * This means cover buyers only pay for the effective cover they have.
       */
      return formula.r0 + formula.rSlope1 + formula.rSlope2;
    }
  }

  /**
   * @notice Computes the liquidity index for a given period
   * @param utilizationRate_ The utilization rate
   * @param premiumRate_ The premium rate
   * @param timeSeconds_ The time in seconds
   * @return The liquidity index to add for the given time
   */
  function computeLiquidityIndex(
    uint256 utilizationRate_,
    uint256 premiumRate_,
    uint256 timeSeconds_
  ) public pure returns (uint /* liquidityIndex */) {
    return
      utilizationRate_
        .rayMul(premiumRate_)
        .rayMul(timeSeconds_)
        .rayDiv(YEAR);
  }

  /**
   * @notice Computes the premiums or interests earned by a liquidity position
   * @param userCapital_ The amount of liquidity in the position
   * @param endLiquidityIndex_ The end liquidity index
   * @param startLiquidityIndex_ The start liquidity index
   */
  function getCoverRewards(
    uint256 userCapital_,
    uint256 startLiquidityIndex_,
    uint256 endLiquidityIndex_
  ) public pure returns (uint256) {
    return
      (userCapital_.rayMul(endLiquidityIndex_) -
        userCapital_.rayMul(startLiquidityIndex_)) / 10_000;
  }

  /**
   * @notice Computes the new daily cost of a cover,
   * the emmission rate is the daily cost of a cover  .
   *
   * @param oldDailyCost_ The daily cost of the cover before the change
   * @param oldPremiumRate_ The premium rate of the cover before the change
   * @param newPremiumRate_ The premium rate of the cover after the change
   *
   * @return The new daily cost of the cover expressed in tokens/day
   */
  function getDailyCost(
    uint256 oldDailyCost_,
    uint256 oldPremiumRate_,
    uint256 newPremiumRate_
  ) public pure returns (uint256) {
    return (oldDailyCost_ * newPremiumRate_) / oldPremiumRate_;
  }

  /**
   * @notice Computes the new seconds per tick of a pool,
   * the seconds per tick is the time between two ticks  .
   *
   * @param oldSecondsPerTick_ The seconds per tick before the change
   * @param oldPremiumRate_ The premium rate before the change
   * @param newPremiumRate_ The premium rate after the change
   *
   * @return The new seconds per tick of the pool
   */
  function secondsPerTick(
    uint256 oldSecondsPerTick_,
    uint256 oldPremiumRate_,
    uint256 newPremiumRate_
  ) public pure returns (uint256) {
    return
      oldSecondsPerTick_.rayMul(oldPremiumRate_).rayDiv(
        newPremiumRate_
      );
  }

  /**
   * @notice Computes the updated premium rate of the pool based on utilization.
   * @param formula The formula of the pool
   * @param secondsPerTick_ The seconds per tick of the pool
   * @param coveredCapital_ The amount of covered capital
   * @param totalLiquidity_ The total amount liquidity
   * @param newCoveredCapital_ The new amount of covered capital
   * @param newTotalLiquidity_ The new total amount liquidity
   *
   * @return newPremiumRate The updated premium rate of the pool
   * @return newSecondsPerTick The updated seconds per tick of the pool
   */
  function updatePoolMarket(
    Formula calldata formula,
    uint256 secondsPerTick_,
    uint256 totalLiquidity_,
    uint256 coveredCapital_,
    uint256 newTotalLiquidity_,
    uint256 newCoveredCapital_
  )
    public
    pure
    returns (
      uint256 newPremiumRate,
      uint256 newSecondsPerTick,
      uint256 newUtilizationRate
    )
  {
    uint256 previousPremiumRate = getPremiumRate(
      formula,
      _utilization(coveredCapital_, totalLiquidity_)
    );

    newUtilizationRate = _utilization(
      newCoveredCapital_,
      newTotalLiquidity_
    );

    newPremiumRate = getPremiumRate(formula, newUtilizationRate);

    newSecondsPerTick = secondsPerTick(
      secondsPerTick_,
      previousPremiumRate,
      newPremiumRate
    );
  }

  /**
   * @notice Computes the percentage of the pool's liquidity used for covers.
   * @param coveredCapital_ The amount of covered capital
   * @param liquidity_ The total amount liquidity
   *
   * @return rate The utilization rate of the pool
   *
   * @dev The utilization rate is capped at 100%.
   */
  function _utilization(
    uint256 coveredCapital_,
    uint256 liquidity_
  ) public pure returns (uint256 /* rate */) {
    // If the pool has no liquidity then the utilization rate is 0
    if (liquidity_ == 0) return 0;

    /**
     * @dev Utilization rate is capped at 100% because in case of overusage the
     * liquidity providers are exposed to the same risk as 100% usage but
     * cover buyers are not fully covered.
     * This means cover buyers only pay for the effective cover they have.
     */
    if (liquidity_ < coveredCapital_) return FULL_CAPACITY;

    // Get a base PERCENTAGE_BASE percentage
    return (coveredCapital_ * PERCENTAGE_BASE).rayDiv(liquidity_);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.25;

/**
 * @title RayMath library
 * @author Aave
 * @dev Provides mul and div function for rays (decimals with 27 digits)
 **/

library RayMath {
  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(
    uint256 a,
    uint256 b
  ) internal pure returns (uint256) {
    return (a * b + halfRAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(
    uint256 a,
    uint256 b
  ) internal pure returns (uint256) {
    return ((a * RAY) + (b / 2)) / b;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

// Libraries
import { BitMath } from "./BitMath.sol";

/// @title Packed tick initialized state library
/// @notice Stores a packed mapping of tick index to its initialized state
/// @dev The mapping uses int24 for keys since ticks are represented as int32 and there are 256 (2^8) values per word.
library TickBitmap {
  /// @notice Computes the position in the mapping where the initialized bit for a tick lives
  /// @param tick The tick for which to compute the position
  /// @return wordPos The key in the mapping containing the word in which the bit is stored
  /// @return bitPos The bit position in the word where the flag is stored
  function position(
    uint32 tick
  ) private pure returns (uint24 wordPos, uint8 bitPos) {
    wordPos = uint24(tick >> 8);
    bitPos = uint8(uint32(tick % 256));
  }

  /// @notice Flips the initialized state for a given tick from false to true, or vice versa
  /// @param self The mapping in which to flip the tick
  /// @param tick The tick to flip
  function flipTick(
    mapping(uint24 => uint256) storage self,
    uint32 tick
  ) internal {
    (uint24 wordPos, uint8 bitPos) = position(tick);
    uint256 mask = 1 << bitPos;
    self[wordPos] ^= mask;
  }

  function isInitializedTick(
    mapping(uint24 => uint256) storage self,
    uint32 tick
  ) internal view returns (bool) {
    (uint24 wordPos, uint8 bitPos) = position(tick);
    uint256 mask = 1 << bitPos;
    return (self[wordPos] & mask) != 0;
  }

  /// @notice Returns the next initialized tick contained in the same word (or adjacent word)
  /// as the tick that is to the left (greater than) of the given tick
  /// @param self The mapping in which to compute the next initialized tick
  /// @param tick The starting tick
  function nextTick(
    mapping(uint24 => uint256) storage self,
    uint32 tick
  ) internal view returns (uint32 next, bool initialized) {
    // start from the word of the next tick, since the current tick state doesn't matter
    (uint24 wordPos, uint8 bitPos) = position(tick + 1);
    // all the 1s at or to the left of the bitPos
    uint256 mask = ~((1 << bitPos) - 1);
    uint256 masked = self[wordPos] & mask;

    // if there are no initialized ticks to the left of the current tick, return leftmost in the word
    initialized = masked != 0;
    // overflow/underflow is possible, but prevented externally by limiting tick
    next = initialized
      ? (tick +
        1 +
        uint32(BitMath.leastSignificantBit(masked) - bitPos))
      : (tick + 1 + uint32(type(uint8).max - bitPos));
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

// Libraries
import { RayMath } from "../libs/RayMath.sol";
import { TickBitmap } from "../libs/TickBitmap.sol";
import { PoolMath } from "../libs/PoolMath.sol";
import { DataTypes } from "../libs/DataTypes.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Interfaces
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IEcclesiaDao } from "../interfaces/IEcclesiaDao.sol";
import { IStrategyManager } from "../interfaces/IStrategyManager.sol";

// ======= ERRORS ======= //

error ZeroAddressAsset();
error DurationBelowOneTick();
error DurationOverflow();
error InsufficientCapacity();
error NotEnoughLiquidityForRemoval();

/**
 * @title Athena Virtual Pool
 * @author vblackwhale
 *
 * This library provides the logic to create and manage virtual pools.
 * The pool storage is located in the Liquidity Manager contract.
 *
 * Definitions:
 *
 * Ticks:
 * They are a serie equidistant points in time who's distance from one another is variable.
 * The initial tick spacing is its maximum possible value of 86400 seconds or 1 day.
 * The distance between ticks will reduce as usage grows and increase when usage falls.
 * The change in distance represents the speed at which cover premiums are spent given the pool's usage.
 *
 * Core pool metrics are computed with the following flow:
 * Utilization Rate (ray %) -> Premium Rate (ray %) -> Daily Cost (token/day)
 */
library VirtualPool {
  // ======= LIBS ======= //
  using VirtualPool for DataTypes.VPool;
  using RayMath for uint256;
  using SafeERC20 for IERC20;
  using TickBitmap for mapping(uint24 => uint256);

  // ======= CONSTANTS ======= //

  bytes32 private constant POOL_SLOT_HASH =
    keccak256("diamond.storage.VPool");
  bytes32 private constant COMPENSATION_SLOT_HASH =
    keccak256("diamond.storage.Compensation");

  uint256 constant YEAR = 365 days;
  uint256 constant RAY = RayMath.RAY;
  uint256 constant MAX_SECONDS_PER_TICK = 1 days;
  uint256 constant FEE_BASE = RAY;
  uint256 constant PERCENTAGE_BASE = 100;
  uint256 constant HUNDRED_PERCENT = FEE_BASE * PERCENTAGE_BASE;

  // ======= STRUCTS ======= //

  struct CoverInfo {
    uint256 premiumsLeft;
    uint256 dailyCost;
    uint256 premiumRate;
    bool isActive;
  }

  struct UpdatePositionParams {
    uint256 currentLiquidityIndex;
    uint256 tokenId;
    uint256 userCapital;
    uint256 strategyRewardIndex;
    uint256 latestStrategyRewardIndex;
    uint256 strategyId;
    bool itCompounds;
    uint256 endCompensationId;
    uint256 nbPools;
  }

  struct UpdatedPositionInfo {
    uint256 newUserCapital;
    uint256 coverRewards;
    uint256 strategyRewards;
    DataTypes.LpInfo newLpInfo;
  }

  // ======= STORAGE GETTERS ======= //

  /**
   * @notice Returns the storage slot position of a pool.
   *
   * @param poolId_ The pool ID
   *
   * @return pool The storage slot position of the pool
   */
  function getPool(
    uint64 poolId_
  ) internal pure returns (DataTypes.VPool storage pool) {
    // Generate a random storage storage slot position based on the pool ID
    bytes32 storagePosition = keccak256(
      abi.encodePacked(POOL_SLOT_HASH, poolId_)
    );

    // Set the position of our struct in contract storage
    assembly {
      pool.slot := storagePosition
    }
  }

  /**
   * @notice Returns the storage slot position of a compensation.
   *
   * @param compensationId_ The compensation ID
   *
   * @return comp The storage slot position of the compensation
   *
   * @dev Enables VirtualPool library to access child compensation storage
   */
  function getCompensation(
    uint256 compensationId_
  ) internal pure returns (DataTypes.Compensation storage comp) {
    // Generate a random storage storage slot position based on the compensation ID
    bytes32 storagePosition = keccak256(
      abi.encodePacked(COMPENSATION_SLOT_HASH, compensationId_)
    );

    // Set the position of our struct in contract storage
    assembly {
      comp.slot := storagePosition
    }
  }

  // ======= VIRTUAL STORAGE INIT ======= //

  /**
   * @notice Initializes a virtual pool & populates its storage
   *
   * @param params The pool's constructor parameters
   */
  function _vPoolConstructor(
    DataTypes.VPoolConstructorParams memory params
  ) internal {
    DataTypes.VPool storage pool = VirtualPool.getPool(params.poolId);

    (address underlyingAsset, address wrappedAsset) = params
      .strategyManager
      .assets(params.strategyId);

    if (
      underlyingAsset == address(0) ||
      params.paymentAsset == address(0)
    ) {
      revert ZeroAddressAsset();
    }

    pool.poolId = params.poolId;
    pool.dao = params.dao;
    pool.strategyManager = params.strategyManager;
    pool.paymentAsset = params.paymentAsset;
    pool.strategyId = params.strategyId;
    pool.underlyingAsset = underlyingAsset;
    pool.wrappedAsset = wrappedAsset;
    pool.feeRate = params.feeRate;
    pool.leverageFeePerPool = params.leverageFeePerPool;

    pool.formula = PoolMath.Formula({
      uOptimal: params.uOptimal,
      r0: params.r0,
      rSlope1: params.rSlope1,
      rSlope2: params.rSlope2
    });

    /// @dev the initial tick spacing is its maximum value 86400 seconds
    pool.slot0.secondsPerTick = MAX_SECONDS_PER_TICK;
    pool.slot0.lastUpdateTimestamp = block.timestamp;
    /// @dev initialize at 1 to enable expiring covers created a first tick
    pool.slot0.tick = 1;

    pool.overlappedPools.push(params.poolId);
  }

  // ================================= //
  // ======= LIQUIDITY METHODS ======= //
  // ================================= //

  /**
   * @notice Returns the total liquidity of the pool.
   *
   * @param poolId_ The pool ID
   */
  function totalLiquidity(
    uint64 poolId_
  ) public view returns (uint256) {
    return getPool(poolId_).overlaps[poolId_];
  }

  /**
   * @notice Returns the available liquidity of the pool.
   *
   * @param poolId_ The pool ID
   */
  function availableLiquidity(
    uint64 poolId_
  ) public view returns (uint256) {
    DataTypes.VPool storage self = getPool(poolId_);

    /// @dev Since payout can lead to available capital underflow, we return 0
    if (totalLiquidity(poolId_) <= self.slot0.coveredCapital)
      return 0;

    return totalLiquidity(poolId_) - self.slot0.coveredCapital;
  }

  /**
   * @notice Computes an updated slot0 & liquidity index up to a timestamp.
   * These changes are virtual an not reflected in storage in this function.
   *
   * @param poolId_ The pool ID
   * @param timestamp_ The timestamp to update the slot0 & liquidity index to
   *
   * @return slot0 The updated slot0
   */
  function _refreshSlot0(
    uint64 poolId_,
    uint256 timestamp_
  ) public view returns (DataTypes.Slot0 memory slot0) {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    // Make copy in memory to allow for mutations
    slot0 = self.slot0;

    // The remaining time in seconds to run through to sync up to the timestamp
    uint256 remaining = timestamp_ - slot0.lastUpdateTimestamp;

    // If the remaining time is less than the tick spacing then return the slot0
    if (remaining < slot0.secondsPerTick) return slot0;

    uint256 utilization = PoolMath._utilization(
      slot0.coveredCapital,
      totalLiquidity(self.poolId)
    );
    uint256 premiumRate = PoolMath.getPremiumRate(
      self.formula,
      utilization
    );

    // Default to ignore remaining time in case we do not enter loop
    uint256 secondsSinceTickStart = remaining;
    uint256 secondsParsed;

    // @bw could opti here by searching for next initialized tick to compute the liquidity index with same premium & utilization in one go, parsing multiple 256 value bitmaps. This should exit when remaining < secondsToNextTickEnd before finishing with the partial tick operation.
    while (slot0.secondsPerTick <= remaining) {
      secondsSinceTickStart = 0;

      // Search for the next tick, either last in bitmap or next initialized
      (uint32 nextTick, bool isInitialized) = self
        .tickBitmap
        .nextTick(slot0.tick);

      uint256 secondsToNextTickEnd = slot0.secondsPerTick *
        (nextTick - slot0.tick);

      if (secondsToNextTickEnd <= remaining) {
        // Remove parsed tick size from remaining time to current timestamp
        remaining -= secondsToNextTickEnd;
        secondsParsed = secondsToNextTickEnd;

        slot0.liquidityIndex += PoolMath.computeLiquidityIndex(
          utilization,
          premiumRate,
          secondsParsed
        );

        // If the tick has covers then update pool metrics
        if (isInitialized) {
          (slot0, utilization, premiumRate) = self
            ._crossingInitializedTick(slot0, nextTick);
        }
        // Pool is now synched at the start of nextTick
        slot0.tick = nextTick;
      } else {
        /**
         * Time bewteen start of the new tick and the current timestamp
         * This is ignored since this is not enough for a full tick to be processed
         */
        secondsSinceTickStart = remaining % slot0.secondsPerTick;
        // Ignore interests of current uncompleted tick
        secondsParsed = remaining - secondsSinceTickStart;
        // Number of complete ticks that we can take into account
        slot0.tick += uint32(secondsParsed / slot0.secondsPerTick);
        // Exit loop after the liquidity index update
        remaining = 0;

        slot0.liquidityIndex += PoolMath.computeLiquidityIndex(
          utilization,
          premiumRate,
          secondsParsed
        );
      }
    }

    // Remove ignored duration so the update aligns with current tick start
    slot0.lastUpdateTimestamp = timestamp_ - secondsSinceTickStart;
  }

  /**
   * @notice Updates the pool's slot0 when the available liquidity changes.
   *
   * @param poolId_ The pool ID
   * @param liquidityToAdd_ The amount of liquidity to add
   * @param liquidityToRemove_ The amount of liquidity to remove
   * @param skipLimitCheck_ Whether to skip the available liquidity check
   *
   * @dev The skipLimitCheck_ is used for deposits & payouts
   */
  function _syncLiquidity(
    uint64 poolId_,
    uint256 liquidityToAdd_,
    uint256 liquidityToRemove_,
    bool skipLimitCheck_
  ) public {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    uint256 liquidity = totalLiquidity(self.poolId);
    uint256 available = availableLiquidity(self.poolId);

    // Skip liquidity check for deposits & payouts
    if (!skipLimitCheck_)
      if (available + liquidityToAdd_ < liquidityToRemove_)
        revert NotEnoughLiquidityForRemoval();

    // uint256 totalCovered = self.slot0.coveredCapital;
    uint256 newTotalLiquidity = (liquidity + liquidityToAdd_) -
      liquidityToRemove_;

    (, self.slot0.secondsPerTick, ) = PoolMath.updatePoolMarket(
      self.formula,
      self.slot0.secondsPerTick,
      liquidity,
      self.slot0.coveredCapital,
      newTotalLiquidity,
      self.slot0.coveredCapital
    );
  }

  // =================================== //
  // ======= COVERS & LP METHODS ======= //
  // =================================== //

  // ======= LIQUIDITY POSITIONS ======= //

  /**
   * @notice Adds liquidity info to the pool and updates the pool's state.
   *
   * @param poolId_ The pool ID
   * @param tokenId_ The LP position token ID
   * @param amount_ The amount of liquidity to deposit
   */
  function _depositToPool(
    uint64 poolId_,
    uint256 tokenId_,
    uint256 amount_
  ) external {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    // Skip liquidity check for deposits
    _syncLiquidity(poolId_, amount_, 0, true);

    // This sets the point from which the position earns rewards & is impacted by claims
    // also overwrites previous LpInfo after a withdrawal
    self.lpInfos[tokenId_] = DataTypes.LpInfo({
      beginLiquidityIndex: self.slot0.liquidityIndex,
      beginClaimIndex: self.compensationIds.length
    });
  }

  /**
   * @notice Pays the rewards and fees to the position owner and the DAO.
   *
   * @param poolId_ The pool ID
   * @param rewards_ The rewards to pay
   * @param account_ The account to pay the rewards to
   * @param yieldBonus_ The yield bonus to apply to the rewards
   * @param nbPools_ The number of pools in the position
   */
  function _payRewardsAndFees(
    uint64 poolId_,
    uint256 rewards_,
    address account_,
    uint256 yieldBonus_,
    uint256 nbPools_
  ) public {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    if (0 < rewards_) {
      uint256 fees = (rewards_ * self.feeRate) / HUNDRED_PERCENT;
      uint256 yieldBonus = (rewards_ *
        (HUNDRED_PERCENT - yieldBonus_)) / HUNDRED_PERCENT;

      uint256 netFees = fees == 0 || fees < yieldBonus
        ? 0
        : fees - yieldBonus;

      uint256 leverageFee;
      if (1 < nbPools_) {
        // The risk fee is only applied when using leverage
        // @dev The leverage fee is per pool so it starts at 2 * leverageFeePerPool
        leverageFee =
          (rewards_ * (self.leverageFeePerPool * nbPools_)) /
          HUNDRED_PERCENT;
      } else if (account_ == address(self.dao)) {
        // Take profits for the DAO accumulate the net in the leverage risk wallet
        leverageFee = rewards_ - netFees;
      }

      uint256 totalFees = netFees + leverageFee;
      // With insane leverage then the user could have a total fee rate above 100%
      uint256 net = rewards_ < totalFees ? 0 : rewards_ - totalFees;

      // Pay position owner
      if (net != 0) {
        IERC20(self.paymentAsset).safeTransfer(account_, net);
      }

      // Pay treasury & leverage risk wallet
      if (totalFees != 0) {
        IERC20(self.paymentAsset).safeTransfer(
          address(self.dao),
          totalFees
        );

        self.dao.accrueRevenue(
          self.paymentAsset,
          netFees,
          leverageFee
        );
      }
    }
  }

  /// -------- TAKE INTERESTS -------- ///

  /**
   * @notice Takes the interests of a position and updates the pool's state.
   *
   * @param poolId_ The pool ID
   * @param tokenId_ The LP position token ID
   * @param account_ The account to pay the rewards to
   * @param supplied_ The amount of liquidity to take interest on
   * @param yieldBonus_ The yield bonus to apply to the rewards
   * @param poolIds_ The pool IDs of the position
   *
   * @return newUserCapital The user's capital after claims
   * @return coverRewards The rewards earned from cover premiums
   *
   * @dev Need to update user capital & payout strategy rewards upon calling this function
   */
  function _takePoolInterests(
    uint64 poolId_,
    uint256 tokenId_,
    address account_,
    uint256 supplied_,
    uint256 strategyRewardIndex_,
    uint256 latestStrategyRewardIndex_,
    uint256 yieldBonus_,
    uint64[] storage poolIds_
  )
    external
    returns (uint256 /*newUserCapital*/, uint256 /*coverRewards*/)
  {
    if (supplied_ == 0) return (0, 0);

    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    // Get the updated position info
    UpdatedPositionInfo memory info = _getUpdatedPositionInfo(
      poolId_,
      poolIds_,
      UpdatePositionParams({
        currentLiquidityIndex: self.slot0.liquidityIndex,
        tokenId: tokenId_,
        userCapital: supplied_,
        strategyRewardIndex: strategyRewardIndex_,
        latestStrategyRewardIndex: latestStrategyRewardIndex_,
        strategyId: self.strategyId,
        itCompounds: self.strategyManager.itCompounds(
          self.strategyId
        ),
        endCompensationId: self.compensationIds.length,
        nbPools: poolIds_.length
      })
    );

    // Pay cover rewards and send fees to treasury
    _payRewardsAndFees(
      poolId_,
      info.coverRewards,
      account_,
      yieldBonus_,
      poolIds_.length
    );

    // Update lp info to reflect the new state of the position
    self.lpInfos[tokenId_] = info.newLpInfo;

    // Return the user's capital & strategy rewards for withdrawal
    return (info.newUserCapital, info.strategyRewards);
  }

  /// -------- WITHDRAW -------- ///

  /**
   * @notice Withdraws liquidity from the pool and updates the pool's state.
   *
   * @param poolId_ The pool ID
   * @param tokenId_ The LP position token ID
   * @param supplied_ The amount of liquidity to withdraw
   * @param poolIds_ The pool IDs of the position
   *
   * @return newUserCapital The user's capital after claims
   * @return strategyRewards The rewards earned by the strategy
   */
  function _withdrawLiquidity(
    uint64 poolId_,
    uint256 tokenId_,
    uint256 supplied_,
    uint256 amount_,
    uint256 strategyRewardIndex_,
    uint256 latestStrategyRewardIndex_,
    uint64[] storage poolIds_
  ) external returns (uint256, uint256) {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    // Get the updated position info
    UpdatedPositionInfo memory info = _getUpdatedPositionInfo(
      poolId_,
      poolIds_,
      UpdatePositionParams({
        currentLiquidityIndex: self.slot0.liquidityIndex,
        tokenId: tokenId_,
        userCapital: supplied_,
        strategyRewardIndex: strategyRewardIndex_,
        latestStrategyRewardIndex: latestStrategyRewardIndex_,
        strategyId: self.strategyId,
        itCompounds: self.strategyManager.itCompounds(
          self.strategyId
        ),
        endCompensationId: self.compensationIds.length,
        nbPools: poolIds_.length
      })
    );

    // Pool rewards after commit are paid in favor of the DAO's leverage risk wallet
    _payRewardsAndFees(
      poolId_,
      info.coverRewards,
      address(self.dao),
      0, // No yield bonus for the DAO
      poolIds_.length
    );

    // Update lp info to reflect the new state of the position
    self.lpInfos[tokenId_] = info.newLpInfo;

    // Update liquidity index
    _syncLiquidity(poolId_, 0, amount_, false);

    // Return the user's capital & strategy rewards for withdrawal
    return (info.newUserCapital, info.strategyRewards);
  }

  // ======= COVERS ======= //

  /// -------- BUY -------- ///

  /**
   * @notice Registers a premium position for a cover,
   * it also initializes the last tick (expiration tick) of the cover is needed.
   *
   * @param self The pool
   * @param coverId_ The cover ID
   * @param beginPremiumRate_ The premium rate at the beginning of the cover
   * @param lastTick_ The last tick of the cover
   */
  function _addPremiumPosition(
    DataTypes.VPool storage self,
    uint256 coverId_,
    uint256 coverAmount_,
    uint256 beginPremiumRate_,
    uint32 lastTick_
  ) internal {
    self.ticks[lastTick_] += coverAmount_;

    self.covers[coverId_] = DataTypes.Cover({
      coverAmount: coverAmount_,
      beginPremiumRate: beginPremiumRate_,
      lastTick: lastTick_
    });

    /**
     * If the tick at which the cover expires is not initialized then initialize it
     * this indicates that the tick is not empty and has covers that expire
     */
    if (!self.tickBitmap.isInitializedTick(lastTick_)) {
      self.tickBitmap.flipTick(lastTick_);
    }
  }

  /**
   * @notice Registers a premium position of a cover and updates the pool's slot0.
   *
   * @param poolId_ The pool ID
   * @param coverId_ The cover ID
   * @param coverAmount_ The amount of cover to buy
   * @param premiums_ The amount of premiums deposited
   */
  function _registerCover(
    uint64 poolId_,
    uint256 coverId_,
    uint256 coverAmount_,
    uint256 premiums_
  ) external {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    // @bw could compute amount of time lost to rounding and conseqentially the amount of premiums lost, then register them to be able to harvest them / redistrib them
    uint256 available = availableLiquidity(self.poolId);

    /**
     * Check if pool has enough liquidity, when updating a cover
     * we closed the previous cover at this point so check for total
     * */
    if (available < coverAmount_) revert InsufficientCapacity();

    uint256 liquidity = totalLiquidity(self.poolId);

    (uint256 newPremiumRate, uint256 newSecondsPerTick, ) = PoolMath
      .updatePoolMarket(
        self.formula,
        self.slot0.secondsPerTick,
        liquidity,
        self.slot0.coveredCapital,
        liquidity,
        self.slot0.coveredCapital + coverAmount_
      );

    uint256 durationInSeconds = (premiums_ * YEAR * PERCENTAGE_BASE)
      .rayDiv(newPremiumRate) / coverAmount_;

    if (durationInSeconds < newSecondsPerTick)
      revert DurationBelowOneTick();

    /**
     * @dev The user can loose up to almost 1 tick of cover due to the floored division
     * The user can also win up to almost 1 tick of cover if it is opened at the start of a tick
     */
    uint256 tickDuration = durationInSeconds / newSecondsPerTick;
    // Check for overflow in case the cover amount is very low
    if (type(uint32).max < tickDuration) revert DurationOverflow();

    uint32 lastTick = self.slot0.tick + uint32(tickDuration);

    self._addPremiumPosition(
      coverId_,
      coverAmount_,
      newPremiumRate,
      lastTick
    );

    self.slot0.coveredCapital += coverAmount_;
    self.slot0.secondsPerTick = newSecondsPerTick;
  }

  /// -------- CLOSE -------- ///

  /**
   * @notice Closes a cover and updates the pool's slot0.
   *
   * @param poolId_ The pool ID
   * @param coverId_ The cover ID
   */
  function _closeCover(uint64 poolId_, uint256 coverId_) external {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    DataTypes.Cover memory cover = self.covers[coverId_];

    // Remove cover amount from the tick at which it expires
    uint256 coverAmount = cover.coverAmount;
    self.ticks[cover.lastTick] -= coverAmount;

    // If there is no more cover in the tick then flip it to uninitialized
    if (self.ticks[cover.lastTick] == 0) {
      self.tickBitmap.flipTick(cover.lastTick);
    }

    uint256 liquidity = totalLiquidity(self.poolId);

    (, self.slot0.secondsPerTick, ) = PoolMath.updatePoolMarket(
      self.formula,
      self.slot0.secondsPerTick,
      liquidity,
      self.slot0.coveredCapital,
      liquidity,
      self.slot0.coveredCapital - coverAmount
    );

    self.slot0.coveredCapital -= coverAmount;

    // @dev We remove 1 since the covers expire at the end of the tick
    self.covers[coverId_].lastTick = self.slot0.tick - 1;
  }

  // ======= INTERNAL POOL HELPERS ======= //

  /**
   * @notice Purges expired covers from the pool and updates the pool's slot0 up to the latest timestamp
   *
   * @param poolId_ The pool ID
   *
   * @dev function _purgeExpiredCoversUpTo
   */
  function _purgeExpiredCovers(uint64 poolId_) external {
    _purgeExpiredCoversUpTo(poolId_, block.timestamp);
  }

  /**
   * @notice Removes expired covers from the pool and updates the pool's slot0.
   * Required before any operation that requires the slot0 to be up to date.
   * This includes all position and cover operations.
   *
   * @param poolId_ The pool ID
   */
  function _purgeExpiredCoversUpTo(
    uint64 poolId_,
    uint256 timestamp_
  ) public {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);
    self.slot0 = _refreshSlot0(poolId_, timestamp_);
  }

  // ======= VIEW HELPERS ======= //

  /**
   * @notice Checks if a cover is active or if it has expired or been closed
   * @dev The user is protected during lastTick but the cover cannot be updated
   *
   * @param poolId_ The pool ID
   * @param coverId_ The cover ID
   *
   * @return Whether the cover is active
   */
  function _isCoverActive(
    uint64 poolId_,
    uint256 coverId_
  ) external view returns (bool) {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    return self.slot0.tick < self.covers[coverId_].lastTick;
  }

  /**
   * @notice Computes the cover and strategy rewards for an LP position.
   *
   * @param self The pool
   * @param info The updated position information
   * @param coverRewards The current rewards earned from cover premiums
   * @param strategyRewards The current rewards earned by the strategy
   * @param strategyId The strategy ID
   * @param itCompounds Whether the strategy compounds
   * @param endliquidityIndex The end liquidity index
   * @param startStrategyRewardIndex The start strategy reward index
   * @param endStrategyRewardIndex The end strategy reward index
   *
   * @return coverRewards The aggregated rewards earned from cover premiums
   * @return strategyRewards The aggregated rewards earned by the strategy
   */
  function computePositionRewards(
    DataTypes.VPool storage self,
    UpdatedPositionInfo memory info,
    uint256 coverRewards,
    uint256 strategyRewards,
    uint256 strategyId,
    bool itCompounds,
    uint256 endliquidityIndex,
    uint256 startStrategyRewardIndex,
    uint256 endStrategyRewardIndex
  )
    internal
    view
    returns (
      uint256 /* coverRewards */,
      uint256 /* strategyRewards */
    )
  {
    coverRewards += PoolMath.getCoverRewards(
      info.newUserCapital,
      info.newLpInfo.beginLiquidityIndex,
      endliquidityIndex
    );

    strategyRewards += self.strategyManager.computeReward(
      strategyId,
      // If strategy compounds then add to capital to compute next new rewards
      itCompounds
        ? info.newUserCapital + info.strategyRewards
        : info.newUserCapital,
      startStrategyRewardIndex,
      endStrategyRewardIndex
    );

    return (coverRewards, strategyRewards);
  }

  /**
   * @notice Computes the state changes of an LP position,
   * it aggregates the fees earned by the position and
   * computes the losses incurred by the claims in this pool.
   *
   * @param poolId_ The pool ID
   * @param poolIds_ The pool IDs of the position
   * @param params The update position parameters
   * - currentLiquidityIndex_ The current liquidity index
   * - tokenId_ The LP position token ID
   * - userCapital_ The user's capital
   * - strategyRewardIndex_ The strategy reward index
   * - latestStrategyRewardIndex_ The latest strategy reward index
   *
   * @return info Updated information about the position:
   * - newUserCapital The user's capital after claims
   * - coverRewards The rewards earned from cover premiums
   * - strategyRewards The rewards earned by the strategy
   * - newLpInfo The updated LpInfo of the position
   *
   * @dev Used for takeInterest, withdrawLiquidity and rewardsOf
   */
  function _getUpdatedPositionInfo(
    uint64 poolId_,
    uint64[] storage poolIds_,
    UpdatePositionParams memory params
  ) public view returns (UpdatedPositionInfo memory info) {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    // Make copy of current LP info state for position
    info.newLpInfo = self.lpInfos[params.tokenId];
    info.newUserCapital = params.userCapital;

    // This index is not bubbled up in info because it is updated by the LiquidityManager
    // @dev Left unitilized because _processCompensationsForPosition will update it event with no compensations
    uint256 upToStrategyRewardIndex;

    (
      info,
      upToStrategyRewardIndex
    ) = _processCompensationsForPosition(poolId_, poolIds_, params);

    /**
     * Finally add the rewards from the last claim or update to the current block
     * & register latest reward & claim indexes
     */
    (info.coverRewards, info.strategyRewards) = self
      .computePositionRewards(
        info,
        info.coverRewards,
        info.strategyRewards,
        params.strategyId,
        params.itCompounds,
        params.currentLiquidityIndex,
        upToStrategyRewardIndex,
        params.latestStrategyRewardIndex
      );

    // Register up to where the position has been updated
    // @dev
    info.newLpInfo.beginLiquidityIndex = params.currentLiquidityIndex;
    info.newLpInfo.beginClaimIndex = params.endCompensationId;
  }

  /**
   * @notice Updates the capital in an LP position post compensation payouts.
   *
   * @param poolId_ The pool ID
   * @param poolIds_ The pool IDs of the position
   * @param params The update position parameters
   *
   * @return info Updated information about the position:
   * @return upToStrategyRewardIndex The latest strategy reward index
   */
  function _processCompensationsForPosition(
    uint64 poolId_,
    uint64[] storage poolIds_,
    UpdatePositionParams memory params
  )
    public
    view
    returns (
      UpdatedPositionInfo memory info,
      uint256 upToStrategyRewardIndex
    )
  {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    info.newLpInfo = self.lpInfos[params.tokenId];
    info.newUserCapital = params.userCapital;

    // This index is not bubbled up in info because it is updated by the LiquidityManager
    upToStrategyRewardIndex = params.strategyRewardIndex;
    uint256 compensationId = info.newLpInfo.beginClaimIndex;

    /**
     * Parse each claim that may affect capital due to overlap in order to
     * compute rewards on post compensation capital
     */
    for (
      compensationId;
      compensationId < params.endCompensationId;
      compensationId++
    ) {
      DataTypes.Compensation storage comp = getCompensation(
        compensationId
      );

      // For each pool in the position
      for (uint256 j; j < params.nbPools; j++) {
        // Skip if the comp is not incoming from one of the pools in the position
        if (poolIds_[j] != comp.fromPoolId) continue;

        // We want the liquidity index of this pool at the time of the claim
        uint256 liquidityIndexBeforeClaim = comp
          .liquidityIndexBeforeClaim[self.poolId];

        // Compute the rewards accumulated up to the claim
        (info.coverRewards, info.strategyRewards) = self
          .computePositionRewards(
            info,
            info.coverRewards,
            info.strategyRewards,
            params.strategyId,
            params.itCompounds,
            liquidityIndexBeforeClaim,
            upToStrategyRewardIndex,
            comp.strategyRewardIndexBeforeClaim
          );

        info
          .newLpInfo
          .beginLiquidityIndex = liquidityIndexBeforeClaim;
        // Reduce capital after the comp
        info.newUserCapital -= info.newUserCapital.rayMul(comp.ratio);

        // Register up to where the rewards have been accumulated
        upToStrategyRewardIndex = comp.strategyRewardIndexBeforeClaim;

        break;
      }
    }

    // Register up to where the position has been updated
    info.newLpInfo.beginClaimIndex = params.endCompensationId;
  }

  /**
   * @notice Computes the updated state of a cover.
   *
   * @param poolId_ The pool ID
   * @param coverId_ The cover ID
   *
   * @return info The cover data
   */
  function _computeRefreshedCoverInfo(
    uint64 poolId_,
    uint256 coverId_
  ) external view returns (CoverInfo memory info) {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    return
      self._computeCoverInfo(
        coverId_,
        // For reads we sync the slot0 to the current timestamp to have latests data
        _refreshSlot0(poolId_, block.timestamp)
      );
  }

  /**
   * @notice Returns the current state of a cover.
   *
   * @param poolId_ The pool ID
   * @param coverId_ The cover ID
   *
   * @return info The cover data
   */
  function _computeCurrentCoverInfo(
    uint64 poolId_,
    uint256 coverId_
  ) external view returns (CoverInfo memory info) {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    return self._computeCoverInfo(coverId_, self.slot0);
  }

  /**
   * @notice Computes the premium rate & daily cost of a cover,
   * this parses the pool's ticks to compute how much premiums are left and
   * what is the daily cost of keeping the cover openened.
   *
   * @param self The pool
   * @param coverId_ The cover ID
   *
   * @return info A struct containing the cover's premium rate & the cover's daily cost
   */
  function _computeCoverInfo(
    DataTypes.VPool storage self,
    uint256 coverId_,
    DataTypes.Slot0 memory slot0_
  ) internal view returns (CoverInfo memory info) {
    DataTypes.Cover storage cover = self.covers[coverId_];

    /**
     * If the cover's last tick is overtaken then it's expired & no premiums are left.
     * Return default 0 / false values in the returned struct.
     */
    if (cover.lastTick < slot0_.tick) return info;

    info.isActive = true;

    info.premiumRate = PoolMath.getPremiumRate(
      self.formula,
      PoolMath._utilization(
        slot0_.coveredCapital,
        totalLiquidity(self.poolId)
      )
    );

    /// @dev Skip division by premium rate PERCENTAGE_BASE for precision
    uint256 beginDailyCost = cover
      .coverAmount
      .rayMul(cover.beginPremiumRate)
      .rayDiv(365);
    info.dailyCost = PoolMath.getDailyCost(
      beginDailyCost,
      cover.beginPremiumRate,
      info.premiumRate
    );

    uint256 nbTicksLeft = cover.lastTick - slot0_.tick;
    // Duration in seconds between currentTick & minNextTick
    uint256 duration = nbTicksLeft * slot0_.secondsPerTick;

    /// @dev Unscale amount by PERCENTAGE_BASE & RAY
    info.premiumsLeft =
      (duration * info.dailyCost) /
      (1 days * PERCENTAGE_BASE * RAY);
    /// @dev Unscale amount by PERCENTAGE_BASE & RAY
    info.dailyCost = info.dailyCost / (PERCENTAGE_BASE * RAY);
  }

  /**
   * @notice Mutates a slot0 to reflect states changes upon crossing an initialized tick.
   * The covers crossed tick are expired and the pool's liquidity is updated.
   *
   * @dev It must be mutative so it can be used by read & write fns.
   *
   * @param self The pool
   * @param slot0_ The slot0 to mutate
   * @param tick_ The tick to cross
   *
   * @return The mutated slot0
   */
  function _crossingInitializedTick(
    DataTypes.VPool storage self,
    DataTypes.Slot0 memory slot0_,
    uint32 tick_
  )
    internal
    view
    returns (
      DataTypes.Slot0 memory /* slot0_ */,
      uint256 utilization,
      uint256 premiumRate
    )
  {
    uint256 liquidity = totalLiquidity(self.poolId);
    // Remove expired cover amount from the pool's covered capital
    uint256 newCoveredCapital = slot0_.coveredCapital -
      self.ticks[tick_];

    (premiumRate, slot0_.secondsPerTick, utilization) = PoolMath
      .updatePoolMarket(
        self.formula,
        self.slot0.secondsPerTick,
        liquidity,
        self.slot0.coveredCapital,
        liquidity,
        newCoveredCapital
      );

    // Remove expired cover amount from the pool's covered capital
    slot0_.coveredCapital = newCoveredCapital;

    return (slot0_, utilization, premiumRate);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

// contracts
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// libraries
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { RayMath } from "../libs/RayMath.sol";

// interfaces
import { IStrategyManager } from "../interfaces/IStrategyManager.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ILiquidityManager } from "../interfaces/ILiquidityManager.sol";
import { IEcclesiaDao } from "../interfaces/IEcclesiaDao.sol";
import { IAaveLendingPoolV3 } from "../interfaces/IAaveLendingPoolV3.sol";
import { IAaveRewardsController } from "../interfaces/IAaveRewardsController.sol";

//======== ERRORS ========//

error NotAValidStrategy();
error NotLiquidityManager();
error OnlyWhitelistCanDepositLiquidity();
error RateAboveMax();
error ArgumentLengthMismatch();
error TransferCallFailed();

/**
 * @title Athena Strategy Manager
 * @author vblackwhale
 *
 * This contract manages the assets deposited in Athena pools as liquidity.
 * It is responsible for depositing and withdrawing assets from various DeFi protocols.
 * It also computes the rewards and performance fees for the DAO.
 *
 * @dev For the v0 of the strategy manager, the only supported protocol is Aave v3 USDC.
 *
 */
contract StrategyManager is IStrategyManager, Ownable {
  using SafeERC20 for IERC20;
  using RayMath for uint256;

  uint256 constant PERCENTAGE_BASE = 100;
  uint256 constant HUNDRED_PERCENT = PERCENTAGE_BASE * RayMath.RAY;
  uint256 constant FIFTHY_PERCENT = HUNDRED_PERCENT / 2;

  //======== STORAGE ========//
  ILiquidityManager public liquidityManager;
  IEcclesiaDao public ecclesiaDao;
  // Address of the buyback & burn wallet
  address public buybackWallet;

  // Amount of underlying to be deducted from payout in RAY
  uint256 public payoutDeductibleRate;
  // Amount of performance fee to be paid to ecclesiaDao in RAY
  uint256 public performanceFeeRate;

  IAaveLendingPoolV3 public aaveLendingPool;
  address public USDC; // underlyingAsset
  address public aUSDC; // wrappedAsset

  bool public isWhitelistEnabled;
  mapping(address account_ => bool isWhiteListed_)
    public whiteListedLiquidityProviders;

  //======== CONSTRCUTOR ========//

  constructor(
    ILiquidityManager liquidityManager_,
    IEcclesiaDao ecclesiaDao_,
    IAaveLendingPoolV3 aaveLendingPool_,
    address reserveAsset_, // USDC for Strategy Manager v0
    address buybackWallet_,
    uint256 payoutDeductibleRate_, // in rays
    uint256 performanceFee_ // in rays
  ) Ownable(msg.sender) {
    liquidityManager = liquidityManager_;
    ecclesiaDao = ecclesiaDao_;
    aaveLendingPool = aaveLendingPool_;

    USDC = reserveAsset_;
    buybackWallet = buybackWallet_;

    if (
      FIFTHY_PERCENT < payoutDeductibleRate_ ||
      FIFTHY_PERCENT < performanceFee_
    ) revert RateAboveMax();

    payoutDeductibleRate = payoutDeductibleRate_;
    performanceFeeRate = performanceFee_;

    aUSDC = aaveLendingPool.getReserveData(USDC).aTokenAddress;
  }

  //======== MODIFIERS ========//

  modifier onlyLiquidityManager() {
    if (msg.sender != address(liquidityManager))
      revert NotLiquidityManager();
    _;
  }

  modifier onlyWhiteListedLiquidityProviders() {
    if (
      // @dev using tx origin since the contract is called by the liquidity manager
      isWhitelistEnabled && !whiteListedLiquidityProviders[tx.origin]
    ) revert OnlyWhitelistCanDepositLiquidity();
    _;
  }

  modifier checkId(uint256 strategyId_) {
    if (strategyId_ != 0) revert NotAValidStrategy();
    _;
  }

  //======== VIEWS ========//

  /**
   * @notice Returns true if a strategy compounds yield
   * @param strategyId_ The ID of the strategy
   * @return True if the strategy compounds
   */
  function itCompounds(
    uint256 strategyId_
  ) external pure checkId(strategyId_) returns (bool) {
    return true;
  }

  /**
   * @notice Returns the current index between aToken and underlying token
   * @return uint256 The current reward index in rays
   *
   * @dev A reward index of 1e27 means 1 aToken = 1 underlying token
   */
  function getRewardIndex(
    uint256 strategyId_
  ) public view checkId(strategyId_) returns (uint256) {
    return aaveLendingPool.getReserveNormalizedIncome(USDC);
  }

  /**
   * @notice Returns the current reward rate for the strategy
   * @param strategyId_ The ID of the strategy
   * @return uint256 The reward rate in RAY
   *
   * @dev A reward rate of 1e28 means 100% APR
   */
  function getRewardRate(
    uint256 strategyId_
  ) public view checkId(strategyId_) returns (uint256) {
    return aaveLendingPool.getReserveData(USDC).currentLiquidityRate;
  }

  /**
   * @notice Computes rewards given their amount of underlying & start and end reward indexes
   * @param strategyId_ The ID of the strategy
   * @param amount_ The amount of underlying tokens
   * @param startRewardIndex_ The reward index at the time of deposit
   * @param endRewardIndex_ The reward index at the time of withdrawal
   * @return uint256 The amount of rewards in underlying tokens
   */
  function computeReward(
    uint256 strategyId_,
    uint256 amount_,
    uint256 startRewardIndex_,
    uint256 endRewardIndex_
  ) external pure checkId(strategyId_) returns (uint256) {
    return
      amount_.rayMul(endRewardIndex_).rayDiv(startRewardIndex_) -
      amount_;
  }

  /**
   * @notice Returns the underlying asset token address for a strategy
   * @param strategyId_ The ID of the strategy
   * @return The address of the underlying asset
   */
  function underlyingAsset(
    uint256 strategyId_
  ) external view checkId(strategyId_) returns (address) {
    return USDC;
  }

  /**
   * @notice Returns the wrapped asset token address for a strategy
   * @param strategyId_ The ID of the strategy
   * @return The address of the wrapped asset
   */
  function wrappedAsset(
    uint256 strategyId_
  ) external view checkId(strategyId_) returns (address) {
    return aUSDC;
  }

  /**
   * @notice Returns the underlying and wrapped asset token addresses for a strategy
   * @param strategyId_ The ID of the strategy
   * @return underlying The address of the underlying asset
   * @return wrapped The address of the wrapped asset
   */
  function assets(
    uint256 strategyId_
  )
    external
    view
    checkId(strategyId_)
    returns (address underlying, address wrapped)
  {
    underlying = USDC;
    wrapped = aUSDC;
  }

  /**
   * @notice Returns the amount of underlying tokens for a given amount of wrapped tokens
   * @param strategyId_ The ID of the strategy
   * @param amountWrapped_ The amount of wrapped tokens
   * @return The amount of underlying tokens
   */
  function wrappedToUnderlying(
    uint256 strategyId_,
    uint256 amountWrapped_
  ) public pure checkId(strategyId_) returns (uint256) {
    // Underlying === wrapped for aave as the aToken balance is increased as interests sum up
    return amountWrapped_;
  }

  /**
   * @notice Returns the amount of wrapped tokens for a given amount of underlying tokens
   * @param strategyId_ The ID of the strategy
   * @param amountUnderlying_ The amount of underlying tokens
   * @return The amount of wrapped tokens
   */
  function underlyingToWrapped(
    uint256 strategyId_,
    uint256 amountUnderlying_
  ) public pure checkId(strategyId_) returns (uint256) {
    // Underlying === wrapped for aave as the aToken balance is increased as interests sum up
    return amountUnderlying_;
  }

  //======== HELPERS ========//

  /**
   * @notice Withdraws DAO revenue from the strategy and accrues it in the DAO
   * @param token_ The address of the token
   * @param amount_ The amount of tokens to accrue
   */
  function _accrueToDao(address token_, uint256 amount_) private {
    // Since we remove 1 for rounding errors
    if (amount_ <= 1) return;

    // Withdraw the revenue from the strategy to the DAO contract
    aaveLendingPool.withdraw(
      token_,
      amount_ - 1,
      address(ecclesiaDao)
    );

    // This will register the revenue in the DAO for distribution
    ecclesiaDao.accrueRevenue(token_, amount_, 0);
  }

  //======== UNDERLYING I/O ========//

  /**
   * @notice Deposits underlying tokens into the strategy
   * @param strategyId_ The ID of the strategy
   * @param amountUnderlying_ The amount of underlying tokens to deposit
   */
  function depositToStrategy(
    uint256 strategyId_,
    uint256 amountUnderlying_
  )
    external
    checkId(strategyId_)
    onlyLiquidityManager
    onlyWhiteListedLiquidityProviders
  {
    IERC20(USDC).forceApprove(
      address(aaveLendingPool),
      amountUnderlying_
    );

    aaveLendingPool.deposit(
      USDC,
      amountUnderlying_,
      address(this),
      0
    );
  }

  /**
   * @notice Withdraws underlying tokens from the strategy
   * @param strategyId_ The ID of the strategy
   * @param amountCapitalUnderlying_ The amount of capital underlying tokens to withdraw
   * @param amountRewardsUnderlying_ The amount of rewards underlying tokens to withdraw
   * @param account_ The address to send the underlying tokens to
   * @param yieldBonus_ The yield bonus in RAY
   */
  function withdrawFromStrategy(
    uint256 strategyId_,
    uint256 amountCapitalUnderlying_,
    uint256 amountRewardsUnderlying_,
    address account_,
    uint256 yieldBonus_
  )
    external
    checkId(strategyId_)
    onlyLiquidityManager
    onlyWhiteListedLiquidityProviders
  {
    uint256 amountToWithdraw = amountCapitalUnderlying_ +
      amountRewardsUnderlying_;

    // If the strategy has performance fees then compute the DAO share
    // @dev the bonus is subtracted from the performance fee
    if (
      performanceFeeRate != 0 &&
      amountRewardsUnderlying_ != 0 &&
      yieldBonus_ < performanceFeeRate
    ) {
      uint256 daoShare = ((amountRewardsUnderlying_ *
        performanceFeeRate) -
        (amountRewardsUnderlying_ * yieldBonus_)) / HUNDRED_PERCENT;

      if (daoShare != 0) {
        // Deduct the daoShare from the amount to withdraw
        amountToWithdraw -= daoShare;
        _accrueToDao(USDC, daoShare);
      }
    }

    // Since we remove 1 for rounding errors
    if (amountToWithdraw <= 1) return;

    // @dev No need to approve aToken since they are burned in pool
    // @dev Remove 1 for rounding errors
    aaveLendingPool.withdraw(USDC, amountToWithdraw - 1, account_);
  }

  //======== WRAPPED I/O ========//

  /**
   * @notice Deposits wrapped tokens into the strategy
   * @param strategyId_ The ID of the strategy
   */
  function depositWrappedToStrategy(
    uint256 strategyId_
  )
    external
    checkId(strategyId_)
    onlyLiquidityManager
    onlyWhiteListedLiquidityProviders
  {
    // No need to deposit wrapped asset into strategy as they already compound by holding
  }

  /**
   * @notice Withdraws wrapped tokens from the strategy
   * @param strategyId_ The ID of the strategy
   * @param amountCapitalUnderlying_ The amount of capital underlying tokens to withdraw
   * @param amountRewardsUnderlying_ The amount of rewards underlying tokens to withdraw
   * @param account_ The address to send the underlying tokens to
   * @param yieldBonus_ The yield bonus in RAY
   */
  function withdrawWrappedFromStrategy(
    uint256 strategyId_,
    uint256 amountCapitalUnderlying_,
    uint256 amountRewardsUnderlying_,
    address account_,
    uint256 yieldBonus_
  )
    external
    checkId(strategyId_)
    onlyLiquidityManager
    onlyWhiteListedLiquidityProviders
  {
    // Compute amount of wrapped to send to account
    uint256 amountToWithdraw = underlyingToWrapped(
      strategyId_,
      amountCapitalUnderlying_
    ) + underlyingToWrapped(strategyId_, amountRewardsUnderlying_);

    // If the strategy has performance fees then compute the DAO share
    if (performanceFeeRate != 0 && amountRewardsUnderlying_ != 0) {
      uint256 daoShare = (amountRewardsUnderlying_ *
        (performanceFeeRate - yieldBonus_)) / RayMath.RAY;

      if (daoShare != 0) {
        // Deduct the daoShare from the amount to withdraw
        amountToWithdraw -= daoShare;
        _accrueToDao(USDC, daoShare);
      }
    }

    // Since we remove 1 for rounding errors
    if (amountToWithdraw <= 1) return;

    // @dev Remove 1 for rounding errors
    IERC20(aUSDC).safeTransfer(account_, amountToWithdraw - 1);
  }

  //======== CLAIMS ========//

  /**
   * @notice Pay a valid claim compensation from the strategy
   * @param strategyId_ The ID of the strategy
   * @param amountUnderlying_ The amount of underlying tokens to payout
   * @param account_ The address to send the underlying tokens to
   */
  function payoutFromStrategy(
    uint256 strategyId_,
    uint256 amountUnderlying_,
    address account_
  ) external checkId(strategyId_) onlyLiquidityManager {
    uint256 deductible = (amountUnderlying_ * payoutDeductibleRate) /
      HUNDRED_PERCENT;

    // If there is a deductible, withdraw it from the pool to buy back & burn wallet
    if (0 < deductible)
      aaveLendingPool.withdraw(USDC, deductible, buybackWallet);

    // @dev No need to approve aToken since they are burned in pool
    // @dev Remove 1 for rounding errors
    uint256 amountToPayout = (amountUnderlying_ - deductible);

    // Since we remove 1 for rounding errors
    if (amountToPayout <= 1) return;

    aaveLendingPool.withdraw(USDC, amountToPayout - 1, account_);
  }

  //======== ADMIN ========//

  /**
   * @notice Updates the addresses of the liquidity manager, ecclesiaDao, and buyback wallet
   * @param liquidityManager_ The address of the liquidity manager
   * @param ecclesiaDao_ The address of the ecclesiaDao
   * @param buybackWallet_ The address of the buyback & burn wallet
   */
  function updateAddressList(
    ILiquidityManager liquidityManager_,
    IEcclesiaDao ecclesiaDao_,
    address buybackWallet_
  ) external onlyOwner {
    if (address(liquidityManager_) != address(0))
      liquidityManager = liquidityManager_;
    if (address(ecclesiaDao_) != address(0))
      ecclesiaDao = ecclesiaDao_;
    if (address(buybackWallet_) != address(0))
      buybackWallet = buybackWallet_;
  }

  /**
   * @notice Updates the performance fee for the strategy
   * @param rate_ The new performance fee rate in RAY
   */
  function updatePerformanceFeeRate(
    uint256 rate_ // in rays
  ) external onlyOwner {
    if (FIFTHY_PERCENT < rate_) revert RateAboveMax();
    performanceFeeRate = rate_;
  }

  /**
   * @notice Updates the deductible rate for compensations
   * @param rate_ The new deductible rate in RAY
   */
  function updatePayoutDeductibleRate(
    uint256 rate_ // in rays
  ) external onlyOwner {
    if (FIFTHY_PERCENT < rate_) revert RateAboveMax();
    payoutDeductibleRate = rate_;
  }

  /**
   * @notice Turns the whitelist on or off
   * @param isEnabled_ The new whitelist status
   */
  function setWhitelistStatus(bool isEnabled_) external onlyOwner {
    isWhitelistEnabled = isEnabled_;
  }

  /**
   * @notice Adds or removes addresses from the whitelist
   * @param address_ The addresses to add or remove
   * @param status_ The status of the addresses
   */
  function editWhitelistAddresses(
    address[] calldata address_,
    bool[] calldata status_
  ) external onlyOwner {
    uint256 length = address_.length;

    if (length != status_.length) revert ArgumentLengthMismatch();

    for (uint256 i; i < length; i++) {
      whiteListedLiquidityProviders[address_[i]] = status_[i];
    }
  }

  /**
   * @notice Claims extra AAVE rewards
   * @param rewardsController The address of the rewards controller
   * @param rewardableAssets The list of assets to check eligible distributions
   * @param amount The amount of rewards to claim
   * @param reward The address of the reward token
   */
  function claimAaveRewards(
    address rewardsController,
    address[] calldata rewardableAssets,
    uint256 amount,
    address reward
  ) external onlyOwner {
    IAaveRewardsController(rewardsController).claimRewards(
      rewardableAssets,
      amount,
      msg.sender,
      reward
    );
  }

  /**
   * @notice Claims all extra AAVE rewards
   * @param rewardsController The address of the rewards controller
   * @param rewardableAssets The list of assets to check eligible distributions
   */
  function claimAllAaveRewards(
    address rewardsController,
    address[] calldata rewardableAssets
  ) external onlyOwner {
    IAaveRewardsController(rewardsController).claimAllRewards(
      rewardableAssets,
      msg.sender
    );
  }

  /**
   * @notice Rescue and transfer tokens locked in this contract
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount of token to transfer
   *
   * @dev This function is for emergency use only in case of a critical bug in
   * the v0 strategy manager
   */
  function rescueTokens(
    address token,
    address to,
    uint256 amount
  ) external onlyOwner {
    if (token == address(0)) {
      (bool success, ) = payable(to).call{ value: amount }("");
      if (!success) revert TransferCallFailed();
    } else {
      IERC20(token).safeTransfer(to, amount);
    }
  }
}