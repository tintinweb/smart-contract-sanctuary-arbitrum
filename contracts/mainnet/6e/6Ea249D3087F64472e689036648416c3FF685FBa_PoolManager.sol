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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import './IUserRegistar.sol';
import './IVRFConsumer.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IPoolManager {
    error InvalidMsgSender();
    error NotRegistered();
    error OverHundredPercent();
    error ZeroAddress();
    error ZeroTicketsExp();
    error ZeroPrize();
    error ZeroRoundDuration();
    error PoolExists();
    error PoolNotFound();
    error InvalidStartTime();
    error NoTicketSpecified();
    error TooManyTickets();
    error RoundNotStart();
    error RoundEnded();
    error NotEnoughTicketsLeft();
    error TicketSold(uint32 ticket);
    error InvalidTicket(uint32 ticket);
    error DifferentArrayLength();
    error ZeroWinNumber();
    error NotWinner();
    error AlreadyClaimed();
    error NotEnded();
    error AlreadyDrawn();

    event ReferralFeeUpdated(uint24 oldReferralFee, uint24 newReferralFee);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event PoolCreated(
        uint128 prize,
        uint128 totalTickets, 
        uint128 pricePerTicket, 
        uint128 roundDuration, 
        uint128 roundGapTime,
        bytes32 poolId
    );
    event NewRoundOpened(
        bytes32 poolId,
        uint256 roundId,
        uint128 startTime,
        uint128 endTime
    );
    event TicketsSold(
        address indexed owner,
        bytes32 poolId,
        uint256 roundId,
        uint32[] tickets
    );
    event PrizeClaimed(
        bytes32 poolId,
        uint256 roundId
    );
    event ReferralRewardCollected(address indexed referrer, uint256 amount);

    struct PoolInfo {
        uint128 prize;
        uint128 totalTickets;
        uint128 pricePerTicket;
        uint128 roundDuration;
        uint128 roundGapTime;
        RoundInfo[] roundInfos;
    }

    struct RoundInfo {
        uint128 startTime;
        uint128 endTime;
        uint128 leftTickets;
        uint256 vrfRequestId;
        uint32 winNumber;
        bool isClaimed;
    }

    struct ParticipationRecord {
        bytes32 poolId;
        uint256 roundId;
        uint256 timestamp;
        uint256 ticketsCount;
        uint32[] tickets;
    }

    struct VRFRequestInfo {
        bytes32 poolId;
        uint256 roundId;
    }

    function HUNDRED_PERCENT() external view returns (uint24);

    function referralFee() external view returns (uint24);

    function usdt() external view returns (IERC20);

    function userRegistar() external view returns (IUserRegistar);

    function vrfConsumer() external view returns (IVRFConsumer);

    function getTicketOwner(bytes32 poolId, uint256 roundId, uint32 ticket) external view returns (address);

    function referralRewardAccured(address referrer) external view returns (uint256);

    function referralRewardAccumulated(address referrer) external view returns (uint256);

    function getAllPoolIds() external view returns (bytes32[] memory poolIds);

    function getPoolInfo(bytes32 poolId) external view returns (
        uint128 prize, 
        uint128 totalTickets, 
        uint128 pricePerTicket, 
        uint128 roundDuration,
        uint128 roundGapTime,
        uint256 currentRound
    );

    function getRoundInfo(bytes32 poolId, uint256 roundId) external view returns (
        uint128 startTime,
        uint128 endTime,
        uint128 leftTickets,
        uint256 vrfRequestId,
        uint32 winNumber,
        bool isClaimed
    );

    function getSoldTickets(bytes32 poolId, uint256 roundId) external view returns (uint32[] memory soldTickets);

    function getAllParticipationRecords(address user) external view returns (ParticipationRecord[] memory);

    function getParticipationRecordsByPoolRound(address user, bytes32 poolId, uint256 roundId) external view returns (ParticipationRecord[] memory);

    function getWonParticipationRecords(address user) external view returns (ParticipationRecord[] memory, uint256 totalPrizes);

    function getUnclaimedPrizes(address user) external view returns (bytes32[] memory poolIds, uint256[] memory roundIds, uint256 totalPrizes);

    function updateReferralFee(uint24 newReferralFee) external;

    function setVRFConsumer(address vrfConsumer_) external;

    function createPool(
        uint8 totalTicketsExp,
        uint128 prize,
        uint128 pricePerTicket,
        uint128 roundDuration,
        uint128 roundGapTime,
        uint128 startTime
    ) external returns (bytes32 poolId);

    function buyTickets(bytes32 poolId, uint256 roundId, uint32[] calldata tickets) external;

    function drawEndedRoundAndOpenNewRound(bytes32 poolId) external;

    function claimPrizes(address to, bytes32[] calldata poolIds, uint256[] calldata roundIds) external;

    function collectReferralReward(address to) external;

    function withdrawUsdt(address to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

interface IUserRegistar {
    error UserAlreadyRegisted(address user);
    error ForbidTransfer();

    event SignedUp(address indexed user, uint256 id, uint256 referrerId);

    function getUserId(address user) external view returns (uint256 id);

    function getReferrer(address user) external view returns (address referrer);

    function signUp(uint256 referrerId) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

interface IVRFConsumer {
    function requestRandomWords() external returns (uint256 requestId);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

interface IVRFConsumerCallback {
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.20;

import './interfaces/IPoolManager.sol';
import './interfaces/IUserRegistar.sol';
import './interfaces/IVRFConsumer.sol';
import './interfaces/IVRFConsumerCallback.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract PoolManager is IPoolManager, IVRFConsumerCallback, Ownable {
    using SafeERC20 for IERC20;

    uint24 public constant HUNDRED_PERCENT = 1000000; // 100%

    uint24 public referralFee;

    IERC20 public immutable usdt;
    IUserRegistar public immutable userRegistar;
    IVRFConsumer public vrfConsumer;

    // if use subgraph, can remove
    mapping(address referrer => uint256) public referralRewardAccumulated;
    mapping(address referrer => uint256) public referralRewardAccured;
    mapping(bytes32 poolId => mapping(uint256 roundId => mapping(uint32 ticket => address owner))) public getTicketOwner;

    // if use subgraph, can remove
    mapping(address user => ParticipationRecord[]) private _userParticipationRecords;

    mapping(bytes32 poolId => mapping(uint256 roundId => uint32[])) private _soldTickets;
    mapping(uint256 vrfRequestId => VRFRequestInfo) private _vrfRequestInfoMap;
    mapping(bytes32 poolId => PoolInfo) private _poolInfoMap;
    bytes32[] private _poolIds;

    constructor(
        uint24 referralFee_,
        address usdt_,
        address userRegistar_
    ) Ownable(msg.sender) {
        referralFee = referralFee_;
        usdt = IERC20(usdt_);
        userRegistar = IUserRegistar(userRegistar_);
    }

    function setVRFConsumer(address vrfConsumer_) external onlyOwner {
        vrfConsumer = IVRFConsumer(vrfConsumer_);
    }

    function updateReferralFee(uint24 newReferralFee) external onlyOwner {
        if (newReferralFee >= HUNDRED_PERCENT) revert OverHundredPercent();
        emit ReferralFeeUpdated(referralFee, newReferralFee);
        referralFee = newReferralFee;
    }

    function getAllPoolIds() external view returns (bytes32[] memory poolIds) {
        return _poolIds;
    }

    function getPoolInfo(bytes32 poolId) external view returns (
        uint128 prize, 
        uint128 totalTickets, 
        uint128 pricePerTicket,
        uint128 roundDuration,
        uint128 roundGapTime,
        uint256 currentRound
    ) {
        PoolInfo memory poolInfo = _poolInfoMap[poolId];
        prize = poolInfo.prize;
        totalTickets = poolInfo.totalTickets;
        pricePerTicket = poolInfo.pricePerTicket;
        roundDuration = poolInfo.roundDuration;
        roundGapTime = poolInfo.roundGapTime;
        currentRound = poolInfo.roundInfos.length;
    }

    function getRoundInfo(bytes32 poolId, uint256 roundId) external view returns (
        uint128 startTime,
        uint128 endTime,
        uint128 leftTickets,
        uint256 vrfRequestId,
        uint32 winNumber,
        bool isClaimed
    ) {
        RoundInfo memory roundInfo = _poolInfoMap[poolId].roundInfos[roundId - 1];
        startTime = roundInfo.startTime;
        endTime = roundInfo.endTime;
        leftTickets = roundInfo.leftTickets;
        vrfRequestId = roundInfo.vrfRequestId;
        winNumber = roundInfo.winNumber;
        isClaimed = roundInfo.isClaimed;
    }

    function getSoldTickets(bytes32 poolId, uint256 roundId) external view returns (uint32[] memory) {
        return _soldTickets[poolId][roundId];
    }

    function getAllParticipationRecords(address user) external view returns (ParticipationRecord[] memory) {
        return _userParticipationRecords[user];
    }

    function getParticipationRecordsByPoolRound(address user, bytes32 poolId, uint256 roundId) external view returns (ParticipationRecord[] memory records) {
        ParticipationRecord[] memory allRecords = _userParticipationRecords[user];
        ParticipationRecord[] memory tempRecords = new ParticipationRecord[](allRecords.length);
        uint256 realLength;
        for (uint256 i = 0; i < allRecords.length; i++) {
            ParticipationRecord memory record = allRecords[i];
            if (poolId == record.poolId && roundId == record.roundId) {
                tempRecords[realLength] = record;
                realLength++;
            }
        }

        records = new ParticipationRecord[](realLength);
        for (uint256 i = 0; i < realLength; i++) {
            records[i] = tempRecords[i];
        }
    }

    function getWonParticipationRecords(address user) public view returns (ParticipationRecord[] memory records, uint256 totalPrizes) {
        ParticipationRecord[] memory allRecords = _userParticipationRecords[user];
        ParticipationRecord[] memory tempRecords = new ParticipationRecord[](allRecords.length);
        uint256 realLength;
        for (uint256 i = 0; i < allRecords.length; i++) {
            ParticipationRecord memory record = allRecords[i];
            bytes32 poolId = record.poolId; 
            uint256 roundId = record.roundId;
            uint32 winNumber = _poolInfoMap[poolId].roundInfos[roundId - 1].winNumber;
            for (uint256 j = 0; j < record.ticketsCount; j++) {
                if (winNumber == record.tickets[j]) {
                    uint32[] memory winningTicket = new uint32[](1);
                    winningTicket[0] = winNumber;
                    tempRecords[realLength] = ParticipationRecord(poolId, roundId, record.timestamp, 1, winningTicket);
                    totalPrizes += _poolInfoMap[poolId].prize;
                    realLength++;
                    break;
                }
            }
            
        }
        records = new ParticipationRecord[](realLength);
        for (uint256 i = 0; i < realLength; i++) {
            records[i] = tempRecords[i];
        }
    }

    function getUnclaimedPrizes(address user) external view returns (bytes32[] memory poolIds, uint256[] memory roundIds, uint256 totalPrizes) {
        (ParticipationRecord[] memory wonRecords, ) = getWonParticipationRecords(user);
        bytes32[] memory tempPoolIds = new bytes32[](wonRecords.length);
        uint256[] memory tempRoundIds = new uint256[](wonRecords.length);
        uint256 resultCount;
        for (uint256 i = 0; i < wonRecords.length; i++) {
            ParticipationRecord memory record = wonRecords[i];
            bytes32 poolId = record.poolId; 
            uint256 roundId = record.roundId;
            if (!_poolInfoMap[poolId].roundInfos[roundId - 1].isClaimed) {
                totalPrizes += _poolInfoMap[poolId].prize;
                tempPoolIds[resultCount] = poolId;
                tempRoundIds[resultCount] = roundId;
                resultCount++;
            }
        }

        poolIds = new bytes32[](resultCount);
        roundIds = new uint256[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            poolIds[i] = tempPoolIds[i];
            roundIds[i] = tempRoundIds[i];
        }
    }

    function createPool(
        uint8 totalTicketsExp,
        uint128 prize,
        uint128 pricePerTicket,
        uint128 roundDuration,
        uint128 roundGapTime,
        uint128 startTime
    ) external onlyOwner returns (bytes32 poolId) {
        if (totalTicketsExp == 0) revert ZeroTicketsExp();
        if (prize == 0) revert ZeroPrize();
        if (roundDuration == 0) revert ZeroRoundDuration();
        if (startTime < block.timestamp) revert InvalidStartTime();

        uint128 totalTickets = uint128(10 ** totalTicketsExp);
        poolId = keccak256(
            abi.encode(
                prize,
                totalTickets,
                pricePerTicket,
                roundDuration,
                roundGapTime
            )
        );
        if (_poolInfoMap[poolId].prize > 0) revert PoolExists();

        _poolInfoMap[poolId].prize = prize;
        _poolInfoMap[poolId].totalTickets = totalTickets;
        _poolInfoMap[poolId].pricePerTicket = pricePerTicket;
        _poolInfoMap[poolId].roundDuration = roundDuration;
        _poolInfoMap[poolId].roundGapTime = roundGapTime;

        RoundInfo memory newRoundInfo = RoundInfo({
            startTime: startTime,
            endTime: startTime + roundDuration,
            leftTickets: totalTickets,
            vrfRequestId: 0,
            winNumber: 0,
            isClaimed: false
        });
        _poolInfoMap[poolId].roundInfos.push(newRoundInfo);
        _poolIds.push(poolId);
        emit PoolCreated(
            prize,
            totalTickets,
            pricePerTicket,
            roundDuration,
            roundGapTime,
            poolId
        );
        emit NewRoundOpened(poolId, 1, startTime, newRoundInfo.endTime);
    }

    function buyTickets(
        bytes32 poolId,
        uint256 roundId,
        uint32[] calldata tickets
    ) external {
        if (tickets.length == 0) revert NoTicketSpecified();

        PoolInfo memory poolInfo = _poolInfoMap[poolId];
        RoundInfo memory roundInfo = poolInfo.roundInfos[roundId - 1];
        if (block.timestamp < roundInfo.startTime) revert RoundNotStart();
        if (block.timestamp >= roundInfo.endTime) revert RoundEnded();
        if (tickets.length > roundInfo.leftTickets) revert NotEnoughTicketsLeft();

        for (uint256 i = 0; i < tickets.length; i++) {
            if (tickets[i] == 0 || tickets[i] > poolInfo.totalTickets)
                revert InvalidTicket(tickets[i]);
            if (getTicketOwner[poolId][roundId][tickets[i]] != address(0))
                revert TicketSold(tickets[i]);
            getTicketOwner[poolId][roundId][tickets[i]] = msg.sender;
            _soldTickets[poolId][roundId].push(tickets[i]);
        }

        _userParticipationRecords[msg.sender].push(ParticipationRecord({
            poolId: poolId,
            roundId: roundId,
            timestamp: block.timestamp,
            ticketsCount: tickets.length,
            tickets: tickets
        }));

        uint128 need2Pay = uint128(tickets.length) * poolInfo.pricePerTicket;
        usdt.safeTransferFrom(msg.sender, address(this), need2Pay);

        address referrer = userRegistar.getReferrer(msg.sender);
        if (referrer != address(0)) {
            uint128 referralReward = (need2Pay * uint128(referralFee)) /
                uint128(HUNDRED_PERCENT);
            referralRewardAccured[referrer] += referralReward;
            referralRewardAccumulated[referrer] += referralReward;
        }

        roundInfo.leftTickets -= uint128(tickets.length);

        emit TicketsSold(msg.sender, poolId, roundId, tickets);

        if (roundInfo.leftTickets == 0) {
            uint256 requestId = vrfConsumer.requestRandomWords();
            _vrfRequestInfoMap[requestId] = VRFRequestInfo(poolId, roundId);
            roundInfo.vrfRequestId = requestId;
            roundInfo.endTime = uint128(block.timestamp);

            uint128 nextStartTime = uint128(block.timestamp) + poolInfo.roundGapTime;
            uint128 nextEndTime = nextStartTime + poolInfo.roundDuration;
            RoundInfo memory nextRoundInfo = RoundInfo({
                startTime: nextStartTime,
                endTime: nextEndTime,
                leftTickets: poolInfo.totalTickets,
                vrfRequestId: 0,
                winNumber: 0,
                isClaimed: false
            });
            _poolInfoMap[poolId].roundInfos.push(nextRoundInfo);
            uint256 newRoundId = _poolInfoMap[poolId].roundInfos.length;

            emit NewRoundOpened(poolId, newRoundId, nextStartTime, nextEndTime);
        }

        _poolInfoMap[poolId].roundInfos[roundId - 1] = roundInfo;
    }

    function drawEndedRoundAndOpenNewRound(bytes32 poolId) external {
        PoolInfo memory poolInfo = _poolInfoMap[poolId];
        uint256 roundId = poolInfo.roundInfos.length;
        if (roundId == 0) revert PoolNotFound();

        RoundInfo memory roundInfo = _poolInfoMap[poolId].roundInfos[roundId - 1];
        if (block.timestamp < roundInfo.endTime) revert NotEnded();
        if (roundInfo.vrfRequestId > 0) revert AlreadyDrawn();

        uint256 requestId = vrfConsumer.requestRandomWords();
        _vrfRequestInfoMap[requestId] = VRFRequestInfo(poolId, roundId);
        roundInfo.vrfRequestId = requestId;
        _poolInfoMap[poolId].roundInfos[roundId - 1] = roundInfo;

        uint128 nextStartTime = uint128(block.timestamp) + poolInfo.roundGapTime;
        uint128 nextEndTime = nextStartTime + poolInfo.roundDuration;
        RoundInfo memory nextRoundInfo = RoundInfo({
            startTime: nextStartTime,
            endTime: nextEndTime,
            leftTickets: poolInfo.totalTickets,
            vrfRequestId: 0,
            winNumber: 0,
            isClaimed: false
        });
        _poolInfoMap[poolId].roundInfos.push(nextRoundInfo);
        uint256 newRoundId = _poolInfoMap[poolId].roundInfos.length;
        emit NewRoundOpened(poolId, newRoundId, nextStartTime, nextEndTime);
    }

    function claimPrizes(
        address to,
        bytes32[] calldata poolIds,
        uint256[] calldata roundIds
    ) external {
        if (poolIds.length != roundIds.length) revert DifferentArrayLength();
        uint256 totalPrize;
        for (uint256 i = 0; i < poolIds.length; i++) {
            uint32 winNumber = _poolInfoMap[poolIds[i]].roundInfos[roundIds[i] - 1].winNumber;
            bool isClaimed = _poolInfoMap[poolIds[i]].roundInfos[roundIds[i] - 1].isClaimed;
            if (winNumber == 0) revert ZeroWinNumber();
            if (isClaimed) revert AlreadyClaimed();
            if (msg.sender != getTicketOwner[poolIds[i]][roundIds[i]][winNumber]) revert NotWinner();
            totalPrize += _poolInfoMap[poolIds[i]].prize;
            _poolInfoMap[poolIds[i]].roundInfos[roundIds[i] - 1].isClaimed = true;
            emit PrizeClaimed(poolIds[i], roundIds[i]);
        }
        usdt.safeTransfer(to, totalPrize);
    }

    function collectReferralReward(address to) external {
        uint256 accured = referralRewardAccured[msg.sender];
        usdt.safeTransfer(to, accured);
        referralRewardAccured[msg.sender] = 0;
        emit ReferralRewardCollected(msg.sender, accured);
    }

    function withdrawUsdt(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        usdt.safeTransfer(to, amount);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        if (msg.sender != address(vrfConsumer)) revert InvalidMsgSender();
        VRFRequestInfo memory requestInfo = _vrfRequestInfoMap[requestId];
        uint256 winNumber = randomWords[0] % _poolInfoMap[requestInfo.poolId].totalTickets + 1;
        _poolInfoMap[requestInfo.poolId].roundInfos[requestInfo.roundId - 1].winNumber = uint32(winNumber);
    }
}