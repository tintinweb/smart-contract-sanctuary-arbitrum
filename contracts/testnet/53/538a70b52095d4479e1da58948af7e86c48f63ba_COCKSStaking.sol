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

// SPDX-License-Identifier: UNLICENSED
pragma solidity = 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title COCKS Staking contract
 * @dev Deposit COCKS token and partake in reward distributions paid in USDC per epoch.
 * Reward payouts are based on not only the amount a user stakes but also the duration that they were staked for during
 * each epoch. Each stake for a given user is treated as independent from one another
 */
contract COCKSStaking is ReentrancyGuard, Ownable {

    using SafeERC20 for IERC20;

    struct Stake {
        uint amount;
        uint epoch;
        uint epochRewardFactor;
        /// @dev claimedUpTill means the rewards have been claimed up to but not including the epoch
        uint claimedUpTill;
        uint withdrawalInitiatedAt;
        bool isWithdrawn;
    }

    struct Epoch {
        uint reward;
        /// @dev epoch starts at
        uint startedAt;
        uint finishedAt;
        uint firstDepositAt;
        uint lastDepositAt;
        uint totalDeposited;
        uint rewardFactor;
        uint fullEpochRewardFactor;
    }

    IERC20 public immutable cocks;
    IERC20 public immutable usdc;
    uint private constant MIN_EPOCH_TIME = 6.5 days;
    uint private constant WITHDRAWAL_LOCK_PERIOD = 7 days;
    uint private constant MAX_ITERATIONS = 25;
    uint private constant REWARD_PRECISION = 1000 ether;
    uint public currentEpoch;
    uint public totalDistributed;
    uint public totalClaimed;
    bool public isDepositingEnabled = true;
    address private _distributor;
    mapping(address => Stake[]) private _stakes;
    mapping(uint => Epoch) private _epochs;

    modifier onlyIfDepositingIsEnabled() {
        require(isDepositingEnabled, "COCKSStaking: Depositing is not enabled");
        _;
    }

    modifier onlyDistributor() {
        require(_msgSender() == _distributor, "COCKSStaking: caller is not the distributor");
        _;
    }

    event Deposit(address indexed staker, uint amount);
    event Withdraw(address indexed staker, uint totalLocked, uint totalWithdrawn, uint totalReward);
    event Distributed(uint indexed epoch, uint reward);
    event ClaimedReward(address indexed staker, uint reward);
    event DistributorUpdated(address indexed newDistributor, address prevDistributor);

    /**
     * @param cocks_ $COCKs token address
     * @param usdc_ USDC token address
     * @param distributor_ Distributor address
     */
    constructor(IERC20 cocks_, IERC20 usdc_, address distributor_) Ownable(_msgSender()) {
        require(address(cocks_) != address(0), "COCKSStaking: cocks_ is the zero address");
        require(address(usdc_) != address(0), "COCKSStaking: usdc_ is the zero address");
        require(distributor_ != address(0), "COCKSStaking: distributor_ is the zero address");
        cocks = cocks_;
        usdc = usdc_;
        _distributor = distributor_;
    }

    /// @notice Toggle depositing (only Owner)
    function toggleDepositing() external onlyOwner {
        isDepositingEnabled = !isDepositingEnabled;
    }

    /**
     * @notice Set distributor (only Owner)
     * @param distributor_ New distributor
     */
    function setDistributor(address distributor_) external onlyOwner {
        address prevDistributor = _distributor;
        _setDistributor(distributor_);
        emit DistributorUpdated(distributor_, prevDistributor);
    }

    /**
     * @notice Deposit $COCKs to earn rewards from USDC distributions
     * @param _amount Amount to deposit
     */
    function deposit(uint _amount) external nonReentrant onlyIfDepositingIsEnabled {
        require(cocks.allowance(_msgSender(), address(this)) >= _amount, "COCKSStaking: Insufficient allowance");
        require(cocks.balanceOf(_msgSender()) >= _amount, "COCKSStaking: Insufficient balance");
        Epoch storage current = _epochs[currentEpoch];
        if (current.firstDepositAt > 0) {
            _updateRewardFactor();
        } else {
            current.firstDepositAt = block.timestamp;
        }
        current.totalDeposited += _amount;
        current.lastDepositAt = block.timestamp;
        _stakes[_msgSender()].push(
            Stake(
                _amount,
                currentEpoch,
                current.rewardFactor,
                0,
                0,
                false
            )
        );
        cocks.safeTransferFrom(_msgSender(), address(this), _amount);
        emit Deposit(_msgSender(), _amount);
    }

    /**
     * @notice Initiates withdrawals (and claims rewards) and payouts withdrawals if 7 days have elapsed since a withdrawal was initiated
     * @param _indexes A list of indexes corresponding to a user's stakes
     */
    function withdraw(uint[] calldata _indexes) external nonReentrant {
        Epoch storage current = _epochs[currentEpoch];
        uint totalStakes = getTotalStakesByUser(_msgSender());
        uint totalLocked;
        uint totalWithdrawn;
        uint totalReward;
        for (uint i; i < _indexes.length; i++) {
            require(_indexes[i] < totalStakes, "COCKStaking: Invalid index");
            Stake storage stake = _stakes[_msgSender()][_indexes[i]];
            require(!stake.isWithdrawn, "COCKStaking: Already withdrawn");
            require(stake.withdrawalInitiatedAt == 0 || stake.withdrawalInitiatedAt + WITHDRAWAL_LOCK_PERIOD <= block.timestamp, "COCKStaking: Cannot withdraw before the unlock period");
            if (stake.withdrawalInitiatedAt == 0) {
                totalReward += _claimReward(_indexes[i]);
                totalLocked += stake.amount;
                stake.withdrawalInitiatedAt = block.timestamp;
            } else {
                totalWithdrawn += stake.amount;
                stake.isWithdrawn = true;
            }
        }
        if (totalLocked > 0) {
            current.totalDeposited -= totalLocked;
            _updateRewardFactor();
            current.lastDepositAt = block.timestamp;
        }
        if (totalWithdrawn > 0) {
            cocks.safeTransfer(_msgSender(), totalWithdrawn);
        }
        if (totalReward > 0) {
            totalClaimed += totalReward;
            usdc.safeTransfer(_msgSender(), totalReward);
        }
        emit Withdraw(_msgSender(), totalLocked, totalWithdrawn, totalReward);
    }

    /**
     * @notice Claim USDC rewards
     * @param _indexes A list of indexes corresponding to a user's stakes
     */
    function claimRewards(uint[] calldata _indexes) external nonReentrant {
        uint totalStakes = getTotalStakesByUser(_msgSender());
        uint totalReward;
        for (uint i; i < _indexes.length; i++) {
            require(_indexes[i] < totalStakes, "COCKStaking: Invalid index");
            uint reward = _claimReward(_indexes[i]);
            require(reward > 0, "COCKStaking: Nothing to claim for a specific stake");
            totalReward += reward;
        }
        usdc.safeTransfer(_msgSender(), totalReward);
        totalClaimed += totalReward;
        emit ClaimedReward(_msgSender(), totalReward);
    }

    /// @notice Distribute USDC and start the next epoch
    function distribute() external nonReentrant onlyDistributor {
        uint distributeInEpoch = currentEpoch;
        Epoch storage current = _epochs[distributeInEpoch];
        Epoch storage next = _epochs[distributeInEpoch + 1];
        require(current.startedAt + MIN_EPOCH_TIME <= block.timestamp, "COCKSStaking: A minimum of 6.5 days must elapse before distributing");
        uint reward = availableToDistribute();
        current.finishedAt = block.timestamp;
        if (current.totalDeposited > 0) {
            current.reward = reward;
            _updateRewardFactor();
            uint prevRewardFactor = distributeInEpoch > 0 ? _epochs[distributeInEpoch - 1].rewardFactor : 0;
            current.fullEpochRewardFactor += reward * (current.rewardFactor - prevRewardFactor) / (block.timestamp - current.firstDepositAt);
            totalDistributed += reward;

            /// @dev initialise next epoch based on current epoch
            next.firstDepositAt = block.timestamp;
            next.lastDepositAt = block.timestamp;
            next.totalDeposited = current.totalDeposited;
        }
        next.startedAt = block.timestamp;
        next.rewardFactor = current.rewardFactor;
        next.fullEpochRewardFactor += current.fullEpochRewardFactor;
        currentEpoch++;
        emit Distributed(distributeInEpoch, reward);
    }

    /**
     * @notice Calculate the amount available for distribution
     * @return uint Amount available to distribute
     */
    function availableToDistribute() public view returns (uint) {
        uint balance = usdc.balanceOf(address(this));
        uint unclaimedRewards = totalDistributed - totalClaimed;
        return balance - unclaimedRewards;
    }

    /**
     * @notice Get information about an epoch
     * @param _epoch Epoch
     * @return Epoch Epoch information
     */
    function getEpoch(uint _epoch) external view returns (Epoch memory) {
        require(_epoch <= currentEpoch, "COCKSStaking: _epoch does not exist");
        return _epochs[_epoch];
    }

    /**
     * @notice Get the address of the distributor
     * @return address Distributor
     */
    function getDistributor() external view returns (address) {
        return _distributor;
    }

    /**
     * @notice Get the total number of stakes made by a user (includes withdrawals)
     * @param _user User address
     * @return uint Total number of stakes made by _user
     */
    function getTotalStakesByUser(address _user) public view returns (uint) {
        require(_user != address(0), "COCKSStaking: _user is the zero address");
        return _stakes[_user].length;
    }

    /**
     * @notice Get a stake made by a user
     * @param _user User address
     * @param _index Index corresponding to a stake made by _user
     * @return Stake Staking information made by _user at index _index
     */
    function getStake(address _user, uint _index) public view returns (Stake memory) {
        uint total = getTotalStakesByUser(_user);
        require(_index < total, "COCKSStaking: _index does not exist for _user");
        return _stakes[_user][_index];
    }

    /**
     * @notice Get a list of stakes made by a user using a range of indexes
     * @param _user User address
     * @param _startIndex Start index corresponding to a stake
     * @param _endIndex End index corresponding to a stake
     * @return list A list of stakes for _user within the range of _startIndex to _endIndex
     */
    function getStakesByRange(address _user, uint _startIndex, uint _endIndex) public view returns (Stake[] memory list) {
        uint total = getTotalStakesByUser(_user);
        require(_startIndex <= _endIndex, "COCKSStaking: Start index must be less than or equal to end index");
        require(_endIndex - _startIndex + 1 <= MAX_ITERATIONS, "COCKSStaking: Range exceeds max iterations");
        require(_startIndex < total, "COCKSStaking: Invalid start index");
        require(_endIndex < total, "COCKSStaking: Invalid end index");
        list = new Stake[](_endIndex - _startIndex + 1);
        uint listIndex;
        for (uint i = _startIndex; i <= _endIndex; i++) {
            list[listIndex++] = _stakes[_user][i];
        }
        return list;
    }

    /**
     * @notice Get a list of stakes made by a user using a list of indexes
     * @param _user User address
     * @param _indexes A list of indexes
     * @return list A list of stakes made by _user based on _indexes
     */
    function getStakesByIndexes(address _user, uint[] calldata _indexes) public view returns (Stake[] memory list) {
        uint totalIterations = _indexes.length;
        uint total = getTotalStakesByUser(_user);
        require(totalIterations <= total && totalIterations <= MAX_ITERATIONS, "COCKSStaking: Invalid _indexes length");
        list = new Stake[](totalIterations);
        for (uint i; i < totalIterations; i++) {
            require(_indexes[i] < total, "COCKSStaking: _index does not exist for _user");
            list[i] = _stakes[_user][_indexes[i]];
        }
        return list;
    }

    /**
     * @notice Calculate the rewards earned by a user for a specific stake
     * @param _user User address
     * @param _index Index corresponding to a stake made by _user
     * @return uint Amount of rewards earned by _user at index _index
     */
    function calculateReward(address _user, uint _index) external view returns (uint) {
        uint total = getTotalStakesByUser(_user);
        require(_index < total, "COCKSStaking: _index does not exist for _user");
        return _calculateReward(_user, _index);
    }

    /**
     * @notice Calculate the rewards earned by a user for a range of stakes
     * @param _user User address
     * @param _startIndex Start index corresponding to a stake
     * @param _endIndex End index corresponding to a stake
     * @return totalRewards Total rewards earned by _user between _startIndex and _endIndex
     */
    function calculateRewardsByRange(address _user, uint _startIndex, uint _endIndex) external view returns (uint totalRewards) {
        uint total = getTotalStakesByUser(_user);
        require(_startIndex <= _endIndex, "COCKSStaking: Start index must be less than or equal to end index");
        require(_endIndex - _startIndex + 1 <= MAX_ITERATIONS, "COCKSStaking: Range exceeds max iterations");
        require(_startIndex < total, "COCKSStaking: Invalid start index");
        require(_endIndex < total, "COCKSStaking: Invalid end index");
        for (uint i = _startIndex; i <= _endIndex; i++) {
            totalRewards += _calculateReward(_user, i);
        }
        return totalRewards;
    }

    /**
     * @notice Calculate the rewards earned by a user for a list of stakes
     * @param _user User address
     * @param _indexes A list of indexes
     * @return totalRewards Total rewards earned by _user for _indexes
     */
    function calculateRewardsByIndexes(address _user, uint[] calldata _indexes) external view returns (uint totalRewards) {
        uint totalIterations = _indexes.length;
        uint total = getTotalStakesByUser(_user);
        require(totalIterations <= total && totalIterations <= MAX_ITERATIONS, "COCKSStaking: Invalid _indexes length");
        for (uint i; i < totalIterations; i++) {
            require(_indexes[i] < total, "COCKSStaking: _index does not exist for _user");
            totalRewards += _calculateReward(_user, _indexes[i]);
        }
        return totalRewards;
    }

    /// @param distributor_ Distributor address
    function _setDistributor(address distributor_) private {
        require(distributor_ != address(0), "COCKSStaking: distributor_ is the zero address");
        _distributor = distributor_;
    }

    function _updateRewardFactor() private {
        Epoch storage current = _epochs[currentEpoch];
        if (current.totalDeposited == 0) {
            current.rewardFactor = 0;
            current.firstDepositAt = 0;
        } else {
            current.rewardFactor += REWARD_PRECISION * (block.timestamp - current.lastDepositAt) / current.totalDeposited;
        }
    }

    /**
     * @param _index Index of stake to claim reward for
     * @return reward Reward earned for _index
     */
    function _claimReward(uint _index) private returns (uint reward) {
        Stake memory stake = _stakes[_msgSender()][_index];
        require(stake.withdrawalInitiatedAt == 0, "Already withdrawn or a withdrawal has been initiated");
        reward = _calculateReward(_msgSender(), _index);
        _stakes[_msgSender()][_index].claimedUpTill = currentEpoch;
        return reward;
    }

    /**
     * @param _user User address
     * @param _index Index of stake to calculate reward for
     * @return reward Reward earned for _user at stake index _index
     */
    function _calculateReward(address _user, uint _index) private view returns (uint reward) {
        Stake memory stake = _stakes[_user][_index];
        if (stake.withdrawalInitiatedAt == 0) {
            if (stake.claimedUpTill < currentEpoch) {
                if (stake.claimedUpTill == 0) {
                    reward += _calculateRewardsFromInitialEpoch(_user, _index);
                }
                return reward + _calculateRewardsFromSubsequentEpochs(_user, _index);
            }
        }
        return 0;
    }

    /**
     * @param _user User address
     * @param _index Index of stake to calculate initial epoch reward for
     * @return reward Reward earned for _user at stake index _index for their first epoch
     */
    function _calculateRewardsFromInitialEpoch(address _user, uint _index) private view returns (uint) {
        Stake memory stake = _stakes[_user][_index];
        /// @dev epoch has to have finished
        if (currentEpoch > stake.epoch) {
            Epoch memory epoch = _epochs[stake.epoch];
            uint rewardFactorDifference = epoch.rewardFactor - stake.epochRewardFactor;
            return epoch.reward * rewardFactorDifference * stake.amount / (epoch.finishedAt - epoch.firstDepositAt) / REWARD_PRECISION;
        }
        return 0;
    }

    /**
     * @param _user User address
     * @param _index Index of stake to calculate subsequent epoch rewards for
     * @return reward Reward earned for _user at stake index _index for epochs (excluding their first epoch for this stake)
     */
    function _calculateRewardsFromSubsequentEpochs(address _user, uint _index) private view returns (uint) {
        Stake memory stake = _stakes[_user][_index];
        if (currentEpoch > stake.epoch + 1) {
            /// @dev we take 1 from stake.claimedUpTill because we need the full epoch reward factor from the previous epoch
            Epoch memory start = stake.claimedUpTill > 0 ? _epochs[stake.claimedUpTill - 1] : _epochs[stake.epoch];
            /// @dev we look at the previous epoch because the current epoch won't have rewards
            Epoch memory prev = _epochs[currentEpoch - 1];
            uint rewardFactorDifference = prev.fullEpochRewardFactor - start.fullEpochRewardFactor;
            return stake.amount * rewardFactorDifference / REWARD_PRECISION;
        }
        return 0;
    }
}