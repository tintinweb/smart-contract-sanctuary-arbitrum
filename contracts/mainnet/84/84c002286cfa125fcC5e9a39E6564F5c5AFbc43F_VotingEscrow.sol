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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.16;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IVotingEscrow } from "./interfaces/IVotingEscrow.sol";
import { IBlocklist } from "./interfaces/IBlocklist.sol";

/// @dev forked from  https://github.com/fiatdao/veToken/blob/main/contracts/VotingEscrow.sol
/// Changes:
///  - add lockerWhitelist storage for a contracts that can call lockFor on behalf of a user
///	 - add updateLockerWhitelist method - only owner can update lockerWhitelist
///  - add lockFor that allow a smart contract to lock tokens on behalf of a user
///  - _lockFor logic requirement relaxed to allow update non-empty, non-delegated locks
///  - and increaseAmountFor method anyone can call to add more tokens to a lock

/// @title  Delegated Voting Escrow
/// @notice An ERC20 token that allocates users a virtual balance depending
/// on the amount of tokens locked and their remaining lock duration. The
/// virtual balance decreases linearly with the remaining lock duration.
/// This is the locking mechanism known from veCRV with additional features:
/// - Delegation of lock and voting power
/// - Quit an existing lock and pay a penalty
/// - Optimistic approval of SmartWallets through Blocklist
/// - Reduced pointHistory array size and, as a result, lifetime of the contract
/// - Removed public deposit_for and Aragon compatibility (no use case)
/// @dev Builds on Curve Finance's original VotingEscrow implementation
/// (see https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy)
/// and mStable's Solidity translation thereof
/// (see https://github.com/mstable/mStable-contracts/blob/master/contracts/governance/IncentivisedVotingLockup.sol)
/// Usage of this contract is not safe with all tokens, specifically:
/// - Contract does not support tokens with maxSupply>2^128-10^[decimals]
/// - Contract does not support fee-on-transfer tokens
/// - Contract may be unsafe for tokens with decimals<6
contract VotingEscrow is IVotingEscrow, ReentrancyGuard {
	using SafeERC20 for IERC20;
	// Shared Events
	event Deposit(
		address indexed provider,
		uint256 value,
		uint256 locktime,
		LockAction indexed action,
		uint256 ts
	);
	event Withdraw(address indexed provider, uint256 value, LockAction indexed action, uint256 ts);
	event TransferOwnership(address indexed owner);
	event UpdateBlocklist(address indexed blocklist);
	event UpdatePenaltyRecipient(address indexed recipient);
	event CollectPenalty(uint256 amount, address indexed recipient);
	event Unlock();
	event QuitEnabled(bool quitEnabled);
	event UpdateLockerWhitelist(address indexed addr, bool allowed);

	// Shared global state
	IERC20 public immutable token;
	uint256 public constant WEEK = 7 days;
	uint256 public constant MAXTIME = 730 days;
	uint256 public constant MULTIPLIER = 1e18;
	address public owner;
	address public penaltyRecipient; // receives collected penalty payments
	uint256 public maxPenalty = 1e18; // penalty for quitters with MAXTIME remaining lock
	uint256 public penaltyAccumulated; // accumulated and unwithdrawn penalty payments
	address public blocklist;
	uint256 public supply;
	// a list of contracts that are allowed to lock tokens on behalf of a users
	mapping(address => bool) public lockerWhitelist;

	// Lock state
	uint256 public globalEpoch;
	Point[1000000000000000000] public pointHistory; // 1e9 * userPointHistory-length, so sufficient for 1e9 users
	mapping(address => Point[1000000000]) public userPointHistory;
	mapping(address => uint256) public userPointEpoch;
	mapping(uint256 => int128) public slopeChanges;
	mapping(address => LockedBalance) public locked;
	bool public quitEnabled = false; // false by default (quit disabled)

	// Voting token
	string public name;
	string public symbol;
	uint256 public immutable decimals;

	// Structs
	struct Point {
		int128 bias;
		int128 slope;
		uint256 ts;
		uint256 blk;
	}
	struct LockedBalance {
		int128 amount;
		int128 delegated;
		uint96 end;
		address delegatee;
	}

	// Miscellaneous
	enum LockAction {
		CREATE,
		INCREASE_AMOUNT,
		INCREASE_AMOUNT_AND_DELEGATION,
		INCREASE_TIME,
		WITHDRAW,
		QUIT,
		DELEGATE,
		UNDELEGATE
	}

	/// @notice Initializes state
	/// @param _owner Is assumed to be a timelock contract
	/// @param _penaltyRecipient The recipient of penalty paid by lock quitters
	/// @param _token The token locked in order to obtain voting power
	/// @param _name The name of the voting token
	/// @param _symbol The symbol of the voting token
	constructor(
		address _owner,
		address _penaltyRecipient,
		address _token,
		string memory _name,
		string memory _symbol
	) {
		token = IERC20(_token);
		pointHistory[0] = Point({
			bias: int128(0),
			slope: int128(0),
			ts: block.timestamp,
			blk: block.number
		});

		decimals = IERC20Metadata(_token).decimals();
		require(decimals <= 18, "Exceeds max decimals");

		name = _name;
		symbol = _symbol;
		owner = _owner;
		penaltyRecipient = _penaltyRecipient;
	}

	modifier checkBlocklist() {
		if (blocklist != address(0))
			require(!IBlocklist(blocklist).isBlocked(msg.sender), "Blocked contract");
		_;
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "Only owner");
		_;
	}

	modifier onlyLocker() {
		require(lockerWhitelist[msg.sender], "Only Whitelisted Locker");
		_;
	}

	modifier canQuit() {
		require(quitEnabled, "Quit disabled");
		_;
	}

	/// ~~~~~~~~~~~~~~~~~~~~~~~~~~~ ///
	///       Owner Functions       ///
	/// ~~~~~~~~~~~~~~~~~~~~~~~~~~~ ///

	/// @notice Transfers ownership to a new owner
	/// @param _addr The new owner
	/// @dev Owner is assumed to be a timelock contract
	function transferOwnership(address _addr) external onlyOwner {
		owner = _addr;
		emit TransferOwnership(_addr);
	}

	/// @notice Updates the blocklist contract
	function updateBlocklist(address _addr) external onlyOwner {
		blocklist = _addr;
		emit UpdateBlocklist(_addr);
	}

	/// @notice Updates the recipient of the accumulated penalty paid by quitters
	function updatePenaltyRecipient(address _addr) external onlyOwner {
		penaltyRecipient = _addr;
		emit UpdatePenaltyRecipient(_addr);
	}

	/// @notice add or remove ability of users to quit lock prepaturely
	function setQuitEnabled(bool _quitEnabled) external onlyOwner {
		quitEnabled = _quitEnabled;
		emit QuitEnabled(_quitEnabled);
	}

	/// @notice Removes quitlock penalty by setting it to zero
	/// @dev This is an irreversible action and is assumed to be used in
	/// a migration to a new VotingEscrow contract only
	function unlock() external onlyOwner {
		maxPenalty = 0;
		emit Unlock();
	}

	/// @notice Remove delegation for blocked contract
	/// @param _addr user to which voting power is delegated
	/// @dev Only callable by the blocklist contract
	function forceUndelegate(address _addr) external override {
		require(msg.sender == blocklist, "Only Blocklist");
		LockedBalance memory locked_ = locked[_addr];
		address delegatee = locked_.delegatee;
		int128 value = locked_.amount;

		if (delegatee != _addr && value > 0) {
			LockedBalance memory fromLocked;
			locked_.delegatee = _addr;
			fromLocked = locked[delegatee];
			locked_.end = fromLocked.end;
			_delegate(delegatee, fromLocked, value, LockAction.UNDELEGATE);
			_delegate(_addr, locked_, value, LockAction.DELEGATE);
		}
	}

	/// @notice Updates the locker whitelist
	function updateLockerWhitelist(address _addr, bool allowed) external onlyOwner {
		lockerWhitelist[_addr] = allowed;
		emit UpdateLockerWhitelist(_addr, true);
	}

	/// ~~~~~~~~~~~~~~~~~~~~~~~~~~~ ///
	///       LOCK MANAGEMENT       ///
	/// ~~~~~~~~~~~~~~~~~~~~~~~~~~~ ///

	/// @notice Returns a lock's expiration
	/// @param _addr The address of the lock owner
	/// @return Expiration of the lock
	function lockEnd(address _addr) external view returns (uint256) {
		return locked[_addr].end;
	}

	/// @notice Returns a lock's last available user point
	/// @param _addr The address of the lock owner
	/// @return bias The last recorded virtual balance
	/// @return slope The last recorded linear decay
	/// @return ts The last recorded timestamp
	function getLastUserPoint(address _addr)
		external
		view
		returns (
			int128 bias,
			int128 slope,
			uint256 ts
		)
	{
		uint256 uepoch = userPointEpoch[_addr];
		if (uepoch == 0) {
			return (0, 0, 0);
		}
		Point memory point = userPointHistory[_addr][uepoch];
		return (point.bias, point.slope, point.ts);
	}

	/// @notice Records a checkpoint of both individual and global slope
	/// @param _addr The address of the lock owner, or address(0) for only global
	/// @param _oldLocked Old amount that user had locked, or null for global
	/// @param _newLocked New amount that user has locked, or null for global
	function _checkpoint(
		address _addr,
		LockedBalance memory _oldLocked,
		LockedBalance memory _newLocked
	) internal {
		Point memory userOldPoint;
		Point memory userNewPoint;
		int128 oldSlopeDelta = 0;
		int128 newSlopeDelta = 0;
		uint256 epoch = globalEpoch;

		if (_addr != address(0)) {
			// Calculate slopes and biases
			// Kept at zero when they have to
			// Casting in the next blocks is safe given that MAXTIME is a small
			// positive number and we check for _oldLocked.end>block.timestamp
			// and _newLocked.end>block.timestamp
			if (_oldLocked.end > block.timestamp && _oldLocked.delegated > 0) {
				userOldPoint.slope = _oldLocked.delegated / int128(int256(MAXTIME));
				userOldPoint.bias =
					userOldPoint.slope *
					int128(int256(_oldLocked.end - block.timestamp));
			}
			if (_newLocked.end > block.timestamp && _newLocked.delegated > 0) {
				userNewPoint.slope = _newLocked.delegated / int128(int256(MAXTIME));
				userNewPoint.bias =
					userNewPoint.slope *
					int128(int256(_newLocked.end - block.timestamp));
			}

			// Moved from bottom final if statement to resolve stack too deep err
			// start {
			// Now handle user history
			uint256 uEpoch = userPointEpoch[_addr];

			userPointEpoch[_addr] = uEpoch + 1;
			userNewPoint.ts = block.timestamp;
			userNewPoint.blk = block.number;
			userPointHistory[_addr][uEpoch + 1] = userNewPoint;

			// } end

			// Read values of scheduled changes in the slope
			// oldLocked.end can be in the past and in the future
			// newLocked.end can ONLY by in the FUTURE unless everything expired: than zeros
			oldSlopeDelta = slopeChanges[_oldLocked.end];
			if (_newLocked.end != 0) {
				if (_newLocked.end == _oldLocked.end) {
					newSlopeDelta = oldSlopeDelta;
				} else {
					newSlopeDelta = slopeChanges[_newLocked.end];
				}
			}
		}

		Point memory lastPoint = Point({
			bias: 0,
			slope: 0,
			ts: block.timestamp,
			blk: block.number
		});
		if (epoch > 0) {
			lastPoint = pointHistory[epoch];
		}
		uint256 lastCheckpoint = lastPoint.ts;

		// initialLastPoint is used for extrapolation to calculate block number
		// (approximately, for *At methods) and save them
		// as we cannot figure that out exactly from inside the contract
		Point memory initialLastPoint = Point({
			bias: 0,
			slope: 0,
			ts: lastPoint.ts,
			blk: lastPoint.blk
		});
		uint256 blockSlope = 0; // dblock/dt
		if (block.timestamp > lastPoint.ts) {
			blockSlope =
				(MULTIPLIER * (block.number - lastPoint.blk)) /
				(block.timestamp - lastPoint.ts);
		}
		// If last point is already recorded in this block, slope=0
		// But that's ok b/c we know the block in such case

		// Go over weeks to fill history and calculate what the current point is
		uint256 iterativeTime = _floorToWeek(lastCheckpoint);
		for (uint256 i; i < 255; ) {
			// Hopefully it won't happen that this won't get used in 5 years!
			// If it does, users will be able to withdraw but vote weight will be broken
			iterativeTime = iterativeTime + WEEK;
			int128 dSlope = 0;
			if (iterativeTime > block.timestamp) {
				iterativeTime = block.timestamp;
			} else {
				dSlope = slopeChanges[iterativeTime];
			}
			int128 biasDelta = lastPoint.slope * int128(int256((iterativeTime - lastCheckpoint)));
			lastPoint.bias = lastPoint.bias - biasDelta;
			lastPoint.slope = lastPoint.slope + dSlope;
			// This can happen
			if (lastPoint.bias < 0) {
				lastPoint.bias = 0;
			}
			// This cannot happen - just in case
			if (lastPoint.slope < 0) {
				lastPoint.slope = 0;
			}
			lastCheckpoint = iterativeTime;
			lastPoint.ts = iterativeTime;
			lastPoint.blk =
				initialLastPoint.blk +
				(blockSlope * (iterativeTime - initialLastPoint.ts)) /
				MULTIPLIER;

			// when epoch is incremented, we either push here or after slopes updated below
			epoch = epoch + 1;
			if (iterativeTime == block.timestamp) {
				lastPoint.blk = block.number;
				break;
			} else {
				pointHistory[epoch] = lastPoint;
			}
			unchecked {
				++i;
			}
		}

		globalEpoch = epoch;
		// Now pointHistory is filled until t=now

		if (_addr != address(0)) {
			// If last point was in this block, the slope change has been applied already
			// But in such case we have 0 slope(s)
			lastPoint.slope = lastPoint.slope + userNewPoint.slope - userOldPoint.slope;
			lastPoint.bias = lastPoint.bias + userNewPoint.bias - userOldPoint.bias;
			if (lastPoint.slope < 0) {
				lastPoint.slope = 0;
			}
			if (lastPoint.bias < 0) {
				lastPoint.bias = 0;
			}
		}

		// Record the changed point into history
		pointHistory[epoch] = lastPoint;

		if (_addr != address(0)) {
			// Schedule the slope changes (slope is going down)
			// We subtract new_user_slope from [new_locked.end]
			// and add old_user_slope to [old_locked.end]
			if (_oldLocked.end > block.timestamp) {
				// oldSlopeDelta was <something> - userOldPoint.slope, so we cancel that
				oldSlopeDelta = oldSlopeDelta + userOldPoint.slope;
				if (_newLocked.end == _oldLocked.end) {
					oldSlopeDelta = oldSlopeDelta - userNewPoint.slope; // It was a new deposit, not extension
				}
				slopeChanges[_oldLocked.end] = oldSlopeDelta;
			}
			if (_newLocked.end > block.timestamp) {
				if (_newLocked.end > _oldLocked.end) {
					newSlopeDelta = newSlopeDelta - userNewPoint.slope; // old slope disappeared at this point
					slopeChanges[_newLocked.end] = newSlopeDelta;
				}
				// else: we recorded it already in oldSlopeDelta
			}
		}
	}

	/// @notice Records a new global checkpoint
	function checkpoint() external {
		LockedBalance memory empty;
		_checkpoint(address(0), empty, empty);
	}

	/// @notice Creates a new lock
	/// @param _value Amount of token to lock
	/// @param _unlockTime Expiration time of the lock
	/// @dev `_value` is (unsafely) downcasted from `uint256` to `int128`
	/// and `_unlockTime` is (unsafely) downcasted from `uint256` to `uint96`
	/// assuming that the values never reach the respective max values
	function createLock(uint256 _value, uint256 _unlockTime)
		external
		override
		nonReentrant
		checkBlocklist
	{
		_lockFor(msg.sender, _value, _unlockTime);
	}

	/// @notice lveSECT can create (or update) a lock for a user
	/// @param _account Address of the user
	/// @param _value Amount of token to lock
	/// @param _unlockTime Expiration time of the lock
	/// @dev `_value` is (unsafely) downcasted from `uint256` to `int128`
	/// and `_unlockTime` is (unsafely) downcasted from `uint256` to `uint96`
	/// assuming that the values never reach the respective max values
	function lockFor(
		address _account,
		uint256 _value,
		uint256 _unlockTime
	) external override nonReentrant checkBlocklist onlyLocker {
		_lockFor(_account, _value, _unlockTime);
	}

	function _lockFor(
		address account,
		uint256 _value,
		uint256 _unlockTime
	) internal {
		uint256 unlock_time = _floorToWeek(_unlockTime); // Locktime is rounded down to weeks
		LockedBalance memory locked_ = locked[account];
		LockedBalance memory oldLock = _copyLock(locked_);
		// Validate inputs
		require(_value != 0, "Only non zero amount");
		// require(locked_.amount == 0, "Lock exists");
		// we can relax the above condition for non-delegated accounts
		require(locked_.delegatee == account || locked_.amount == 0, "Delegated lock");
		require(unlock_time >= locked_.end, "Only increase lock end"); // from using quitLock, user should increaseAmount instead
		require(unlock_time > block.timestamp, "Only future lock end");
		require(unlock_time <= block.timestamp + MAXTIME, "Exceeds maxtime");
		// Update total supply of token deposited
		supply = supply + _value;
		// Update lock and voting power (checkpoint)
		// Casting in the next block is safe given that we check for _value>0 and the
		// totalSupply of tokens is generally significantly lower than the int128.max
		// value (considering the max precision of 18 decimals enforced in the constructor)
		locked_.amount = locked_.amount + int128(int256(_value));
		locked_.end = uint96(unlock_time);
		locked_.delegated = locked_.delegated + int128(int256(_value));
		locked_.delegatee = account;
		locked[account] = locked_;
		_checkpoint(account, oldLock, locked_);
		// Deposit locked tokens
		token.safeTransferFrom(msg.sender, address(this), _value);
		emit Deposit(account, _value, unlock_time, LockAction.CREATE, block.timestamp);
	}

	/// @notice Locks more tokens on behalf of an account
	/// @param account Account to lock tokens for
	/// @param _value Amount of tokens to add to the lock
	/// @dev Does not update the lock's expiration
	/// Does record a new checkpoint for the lock
	/// `_value` is (unsafely) downcasted from `uint256` to `int128` assuming
	/// that the max value is never reached in practice
	function increaseAmountFor(address account, uint256 _value)
		external
		override
		nonReentrant
		checkBlocklist
	{
		_increaseAmount(account, _value);
	}

	/// @notice Locks more tokens in an existing lock
	/// @param _value Amount of tokens to add to the lock
	/// @dev Does not update the lock's expiration
	/// Does record a new checkpoint for the lock
	/// `_value` is (unsafely) downcasted from `uint256` to `int128` assuming
	/// that the max value is never reached in practice
	function increaseAmount(uint256 _value) external override nonReentrant checkBlocklist {
		_increaseAmount(msg.sender, _value);
	}

	function _increaseAmount(address account, uint256 _value) internal {
		LockedBalance memory locked_ = locked[account];
		// Validate inputs
		require(_value != 0, "Only non zero amount");
		require(locked_.amount > 0, "No lock");
		require(locked_.end > block.timestamp, "Lock expired");
		// Update total supply of token deposited
		supply = supply + _value;
		// Update lock
		address delegatee = locked_.delegatee;
		uint256 unlockTime = locked_.end;
		LockAction action = LockAction.INCREASE_AMOUNT;
		LockedBalance memory newLocked;
		// Casting in the next block is safe given that we check for _value>0 and the
		// totalSupply of tokens is generally significantly lower than the int128.max
		// value (considering the max precision of 18 decimals enforced in the constructor)
		if (delegatee == account) {
			// Undelegated lock
			action = LockAction.INCREASE_AMOUNT_AND_DELEGATION;
			newLocked = _copyLock(locked_);
			newLocked.amount = newLocked.amount + int128(int256(_value));
			newLocked.delegated = newLocked.delegated + int128(int256(_value));
			locked[account] = newLocked;
		} else {
			// Delegated lock, update sender's lock first
			locked_.amount = locked_.amount + int128(int256(_value));
			locked[account] = locked_;
			// Then, update delegatee's lock and voting power (checkpoint)
			locked_ = locked[delegatee];
			require(locked_.amount > 0, "Delegatee has no lock");
			require(locked_.end > block.timestamp, "Delegatee lock expired");
			newLocked = _copyLock(locked_);
			newLocked.delegated = newLocked.delegated + int128(int256(_value));
			locked[delegatee] = newLocked;
			emit Deposit(delegatee, _value, newLocked.end, LockAction.DELEGATE, block.timestamp);
		}
		// Checkpoint only for delegatee
		_checkpoint(delegatee, locked_, newLocked);
		// Deposit locked tokens
		token.safeTransferFrom(msg.sender, address(this), _value);
		emit Deposit(account, _value, unlockTime, action, block.timestamp);
	}

	/// @notice Extends the expiration of an existing lock
	/// @param _unlockTime New lock expiration time
	/// @dev Does not update the amount of tokens locked
	/// Does record a new checkpoint for the lock
	/// `_unlockTime` is (unsafely) downcasted from `uint256` to `uint96`
	/// assuming that the max value is never reached in practice
	function increaseUnlockTime(uint256 _unlockTime) external override nonReentrant checkBlocklist {
		LockedBalance memory locked_ = locked[msg.sender];
		uint256 unlock_time = _floorToWeek(_unlockTime); // Locktime is rounded down to weeks
		// Validate inputs
		require(locked_.amount > 0, "No lock");
		require(locked_.end > block.timestamp, "Lock expired");
		require(unlock_time > locked_.end, "Only increase lock end");
		require(unlock_time <= block.timestamp + MAXTIME, "Exceeds maxtime");
		// Update lock
		uint256 oldUnlockTime = locked_.end;
		locked_.end = uint96(unlock_time);
		locked[msg.sender] = locked_;
		if (locked_.delegated > 0) {
			// Lock with non-zero virtual balance
			LockedBalance memory oldLocked = _copyLock(locked_);
			oldLocked.end = uint96(oldUnlockTime);
			_checkpoint(msg.sender, oldLocked, locked_);
		}
		emit Deposit(msg.sender, 0, unlock_time, LockAction.INCREASE_TIME, block.timestamp);
	}

	/// @notice Withdraws the tokens of an expired lock
	/// Delegated locks need to be undelegated first
	function withdraw() external override nonReentrant {
		LockedBalance memory locked_ = locked[msg.sender];
		// Validate inputs
		require(locked_.amount > 0, "No lock");
		require(locked_.end <= block.timestamp, "Lock not expired");
		require(locked_.delegatee == msg.sender, "Lock delegated");
		// Update total supply of token deposited
		uint256 value = uint256(uint128(locked_.amount));
		supply = supply - value;
		// Update lock
		LockedBalance memory newLocked = _copyLock(locked_);
		newLocked.amount = 0;
		newLocked.end = 0;
		newLocked.delegated = newLocked.delegated - locked_.amount;
		newLocked.delegatee = address(0);
		locked[msg.sender] = newLocked;
		newLocked.delegated = 0;
		// oldLocked can have either expired <= timestamp or zero end
		// currentLock has only 0 end
		// Both can have >= 0 amount
		_checkpoint(msg.sender, locked_, newLocked);
		// Send back deposited tokens
		token.safeTransfer(msg.sender, value);
		emit Withdraw(msg.sender, value, LockAction.WITHDRAW, block.timestamp);
	}

	/// ~~~~~~~~~~~~~~~~~~~~~~~~~~ ///
	///         DELEGATION         ///
	/// ~~~~~~~~~~~~~~~~~~~~~~~~~~ ///

	/// @notice Delegate lock and voting power to another lock
	/// The receiving lock needs to have a longer lock duration
	/// The delegated lock will inherit the receiving lock's expiration
	/// @param _addr The address of the lock owner to which to delegate
	function delegate(address _addr) external override nonReentrant checkBlocklist {
		// Different restrictions apply to undelegation
		if (_addr == msg.sender) {
			_undelegate();
			return;
		}
		LockedBalance memory locked_ = locked[msg.sender];
		// Validate inputs
		if (blocklist != address(0))
			require(!IBlocklist(blocklist).isBlocked(_addr), "Blocked contract");
		require(locked_.amount > 0, "No lock");
		require(locked_.end > block.timestamp, "Lock expired");
		require(locked_.delegatee != _addr, "Already delegated");
		// Update locks
		int128 value = locked_.amount;
		address delegatee = locked_.delegatee;
		LockedBalance memory toLocked = locked[_addr];
		locked_.delegatee = _addr;
		if (delegatee != msg.sender) {
			locked[msg.sender] = locked_;
			locked_ = locked[delegatee];
		}
		require(toLocked.amount > 0, "Delegatee has no lock");
		require(toLocked.end > block.timestamp, "Delegatee lock expired");
		require(toLocked.end >= locked_.end, "Only delegate to longer lock");
		_delegate(delegatee, locked_, value, LockAction.UNDELEGATE);
		_delegate(_addr, toLocked, value, LockAction.DELEGATE);
	}

	// Undelegates sender's lock
	// Can be executed on expired locks too
	// Owner inherits delegatee's unlockTime if it exceeds owner's
	function _undelegate() internal {
		LockedBalance memory locked_ = locked[msg.sender];
		// Validate inputs
		require(locked_.amount > 0, "No lock");
		require(locked_.delegatee != msg.sender, "Already undelegated");
		// Update locks
		int128 value = locked_.amount;
		address delegatee = locked_.delegatee;
		LockedBalance memory fromLocked = locked[delegatee];
		locked_.delegatee = msg.sender;
		if (locked_.end < fromLocked.end) {
			locked_.end = fromLocked.end;
		}
		_delegate(delegatee, fromLocked, value, LockAction.UNDELEGATE);
		_delegate(msg.sender, locked_, value, LockAction.DELEGATE);
	}

	// Delegates from/to lock and voting power
	function _delegate(
		address addr,
		LockedBalance memory _locked,
		int128 value,
		LockAction action
	) internal {
		LockedBalance memory newLocked = _copyLock(_locked);
		if (action == LockAction.DELEGATE) {
			newLocked.delegated = newLocked.delegated + value;
			emit Deposit(addr, uint256(int256(value)), newLocked.end, action, block.timestamp);
		} else {
			newLocked.delegated = newLocked.delegated - value;
			emit Withdraw(addr, uint256(int256(value)), action, block.timestamp);
		}
		locked[addr] = newLocked;
		if (newLocked.amount > 0) {
			// Only if lock (from lock) hasn't been withdrawn/quitted
			_checkpoint(addr, _locked, newLocked);
		}
	}

	/// ~~~~~~~~~~~~~~~~~~~~~~~~~~ ///
	///         QUIT LOCK          ///
	/// ~~~~~~~~~~~~~~~~~~~~~~~~~~ ///

	/// @notice Quit an existing lock by withdrawing all tokens less a penalty
	/// Use `withdraw` for expired locks
	/// @dev Quitters lock expiration remains in place because it might be delegated to
	function quitLock() external override nonReentrant canQuit {
		LockedBalance memory locked_ = locked[msg.sender];
		// Validate inputs
		require(locked_.amount > 0, "No lock");
		require(locked_.end > block.timestamp, "Lock expired");
		require(locked_.delegatee == msg.sender, "Lock delegated");
		// Update total supply of token deposited
		uint256 value = uint256(uint128(locked_.amount));
		supply = supply - value;
		// Update lock
		LockedBalance memory newLocked = _copyLock(locked_);
		newLocked.amount = 0;
		newLocked.delegated = newLocked.delegated - locked_.amount;
		newLocked.delegatee = address(0);
		locked[msg.sender] = newLocked;
		newLocked.end = 0;
		newLocked.delegated = 0;
		// oldLocked can have either expired <= timestamp or zero end
		// currentLock has only 0 end
		// Both can have >= 0 amount
		_checkpoint(msg.sender, locked_, newLocked);
		// apply penalty
		uint256 penaltyRate = _calculatePenaltyRate(locked_.end);
		uint256 penaltyAmount = (value * penaltyRate) / 1e18; // quitlock_penalty is in 18 decimals precision
		penaltyAccumulated = penaltyAccumulated + penaltyAmount;
		uint256 remainingAmount = value - penaltyAmount;
		// Send back remaining tokens
		token.safeTransfer(msg.sender, remainingAmount);
		emit Withdraw(msg.sender, value, LockAction.QUIT, block.timestamp);
	}

	/// @notice Returns the penalty rate for a given lock expiration
	/// @param end The lock's expiration
	/// @return The penalty rate applicable to the lock
	/// @dev The penalty rate decreases linearly at the same rate as a lock's voting power
	/// in order to compensate for votes unlocked without committing to the lock expiration
	function getPenaltyRate(uint256 end) external view returns (uint256) {
		return _calculatePenaltyRate(end);
	}

	// Calculate penalty rate
	// Penalty rate decreases linearly at the same rate as a lock's voting power
	// in order to compensate for votes used
	function _calculatePenaltyRate(uint256 end) internal view returns (uint256) {
		// We know that end > block.timestamp because expired locks cannot be quitted
		return ((end - block.timestamp) * maxPenalty) / MAXTIME;
	}

	/// @notice Collect accumulated penalty from lock quitters
	/// Everyone can collect but penalty is sent to `penaltyRecipient`
	function collectPenalty() external {
		uint256 amount = penaltyAccumulated;
		penaltyAccumulated = 0;
		address recipient = penaltyRecipient;
		token.safeTransfer(recipient, amount);
		emit CollectPenalty(amount, recipient);
	}

	/// ~~~~~~~~~~~~~~~~~~~~~~~~~~ ///
	///            GETTERS         ///
	/// ~~~~~~~~~~~~~~~~~~~~~~~~~~ ///

	// Creates a copy of a lock
	function _copyLock(LockedBalance memory _locked) internal pure returns (LockedBalance memory) {
		return
			LockedBalance({
				amount: _locked.amount,
				end: _locked.end,
				delegatee: _locked.delegatee,
				delegated: _locked.delegated
			});
	}

	// Floors a timestamp to the nearest weekly increment
	function _floorToWeek(uint256 _t) internal pure returns (uint256) {
		return (_t / WEEK) * WEEK;
	}

	// Uses binarysearch to find the most recent point history preceeding block
	// Find the most recent point history before _block
	// Do not search pointHistories past _maxEpoch
	function _findBlockEpoch(uint256 _block, uint256 _maxEpoch) internal view returns (uint256) {
		// Binary search
		uint256 min = 0;
		uint256 max = _maxEpoch;
		// Will be always enough for 128-bit numbers
		for (uint256 i; i < 128; ) {
			if (min >= max) break;
			uint256 mid = (min + max + 1) / 2;
			if (pointHistory[mid].blk <= _block) {
				min = mid;
			} else {
				max = mid - 1;
			}
			unchecked {
				++i;
			}
		}
		return min;
	}

	// Uses binarysearch to find the most recent user point history preceeding block
	// _addr is the lock owner for which to search
	// Find the most recent point history before _block
	function _findUserBlockEpoch(address _addr, uint256 _block) internal view returns (uint256) {
		uint256 min = 0;
		uint256 max = userPointEpoch[_addr];
		for (uint256 i; i < 128; ) {
			if (min >= max) {
				break;
			}
			uint256 mid = (min + max + 1) / 2;
			if (userPointHistory[_addr][mid].blk <= _block) {
				min = mid;
			} else {
				max = mid - 1;
			}
			unchecked {
				++i;
			}
		}
		return min;
	}

	/// @notice Get a lock's current voting power
	/// @param _owner The address of the lock owner for which to return voting power
	/// @return Voting power of the lock
	function balanceOf(address _owner) public view override returns (uint256) {
		uint256 epoch = userPointEpoch[_owner];
		if (epoch == 0) {
			return 0;
		}
		// Casting is safe given that checkpoints are recorded in the past
		// and are more frequent than every int128.max seconds
		Point memory lastPoint = userPointHistory[_owner][epoch];
		lastPoint.bias =
			lastPoint.bias -
			(lastPoint.slope * int128(int256(block.timestamp - lastPoint.ts)));
		if (lastPoint.bias < 0) {
			lastPoint.bias = 0;
		}
		return uint256(uint128(lastPoint.bias));
	}

	/// @notice Get a lock's voting power at a given block number
	/// @param _owner The address of the lock owner for which to return voting power
	/// @param _blockNumber The block at which to calculate the lock's voting power
	/// @return uint256 Voting power of the lock
	function balanceOfAt(address _owner, uint256 _blockNumber)
		public
		view
		override
		returns (uint256)
	{
		require(_blockNumber <= block.number, "Only past block number");

		// Get most recent user Point to block
		uint256 userEpoch = _findUserBlockEpoch(_owner, _blockNumber);
		if (userEpoch == 0) {
			return 0;
		}
		Point memory upoint = userPointHistory[_owner][userEpoch];

		// Get most recent global Point to block
		uint256 maxEpoch = globalEpoch;
		uint256 epoch = _findBlockEpoch(_blockNumber, maxEpoch);
		Point memory point0 = pointHistory[epoch];

		// Calculate delta (block & time) between user Point and target block
		// Allowing us to calculate the average seconds per block between
		// the two points
		uint256 dBlock = 0;
		uint256 dTime = 0;
		if (epoch < maxEpoch) {
			Point memory point1 = pointHistory[epoch + 1];
			dBlock = point1.blk - point0.blk;
			dTime = point1.ts - point0.ts;
		} else {
			dBlock = block.number - point0.blk;
			dTime = block.timestamp - point0.ts;
		}
		// (Deterministically) Estimate the time at which block _blockNumber was mined
		uint256 blockTime = point0.ts;
		if (dBlock != 0) {
			blockTime = blockTime + ((dTime * (_blockNumber - point0.blk)) / dBlock);
		}
		// Current Bias = most recent bias - (slope * time since update)
		// Casting is safe given that checkpoints are recorded in the past
		// and are more frequent than every int128.max seconds
		upoint.bias = upoint.bias - (upoint.slope * int128(int256(blockTime - upoint.ts)));
		if (upoint.bias >= 0) {
			return uint256(uint128(upoint.bias));
		} else {
			return 0;
		}
	}

	// Calculate total supply of voting power at a given time _t
	// _point is the most recent point before time _t
	// _t is the time at which to calculate supply
	function _supplyAt(Point memory _point, uint256 _t) internal view returns (uint256) {
		Point memory lastPoint = _point;
		// Floor the timestamp to weekly interval
		uint256 iterativeTime = _floorToWeek(lastPoint.ts);
		// Iterate through all weeks between _point & _t to account for slope changes
		for (uint256 i; i < 255; ) {
			iterativeTime = iterativeTime + WEEK;
			int128 dSlope = 0;
			// If week end is after timestamp, then truncate & leave dSlope to 0
			if (iterativeTime > _t) {
				iterativeTime = _t;
			}
			// else get most recent slope change
			else {
				dSlope = slopeChanges[iterativeTime];
			}

			// Casting is safe given that lastPoint.ts < iterativeTime and
			// iteration goes over 255 weeks max
			lastPoint.bias =
				lastPoint.bias -
				(lastPoint.slope * int128(int256(iterativeTime - lastPoint.ts)));
			if (iterativeTime == _t) {
				break;
			}
			lastPoint.slope = lastPoint.slope + dSlope;
			lastPoint.ts = iterativeTime;

			unchecked {
				++i;
			}
		}

		if (lastPoint.bias < 0) {
			lastPoint.bias = 0;
		}
		return uint256(uint128(lastPoint.bias));
	}

	/// @notice Calculate current total supply of voting power
	/// @return Current totalSupply
	function totalSupply() public view override returns (uint256) {
		uint256 epoch_ = globalEpoch;
		Point memory lastPoint = pointHistory[epoch_];
		return _supplyAt(lastPoint, block.timestamp);
	}

	/// @notice Calculate total supply of voting power at a given block number
	/// @param _blockNumber The block number at which to calculate total supply
	/// @return totalSupply of voting power at the given block number
	function totalSupplyAt(uint256 _blockNumber) public view override returns (uint256) {
		require(_blockNumber <= block.number, "Only past block number");

		uint256 epoch = globalEpoch;
		uint256 targetEpoch = _findBlockEpoch(_blockNumber, epoch);

		Point memory point = pointHistory[targetEpoch];

		// If point.blk > _blockNumber that means we got the initial epoch & contract did not yet exist
		if (point.blk > _blockNumber) {
			return 0;
		}

		uint256 dTime = 0;
		if (targetEpoch < epoch) {
			Point memory pointNext = pointHistory[targetEpoch + 1];
			if (point.blk != pointNext.blk) {
				dTime =
					((_blockNumber - point.blk) * (pointNext.ts - point.ts)) /
					(pointNext.blk - point.blk);
			}
		} else if (point.blk != block.number) {
			dTime =
				((_blockNumber - point.blk) * (block.timestamp - point.ts)) /
				(block.number - point.blk);
		}
		// Now dTime contains info on how far are we beyond point
		return _supplyAt(point, point.ts + dTime);
	}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

/// @title Blocklist Checker interface
/// @notice Basic blocklist checker interface for VotingEscrow
interface IBlocklist {
	function isBlocked(address addr) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

interface IVotingEscrow {
	/// @notice Creates a new lock
	/// @param _value Total units of token to lock
	/// @param _unlockTime Time at which the lock expires
	function createLock(uint256 _value, uint256 _unlockTime) external;

	/// @notice Lock tokens into the voting escrow for an account
	/// @param account_ Address of account to lock tokens for
	/// @param value_ Amount of tokens to lock
	/// @param unlockTime_ Unix timestamp when tokens will unlock
	function lockFor(address account_, uint256 value_, uint256 unlockTime_) external;

	/// @notice Locks more tokens in an existing lock
	/// @param _value Additional units of `token` to add to the lock
	/// @dev Does not update the lock's expiration.
	/// @dev Does increase the user's voting power, or the delegatee's voting power.
	function increaseAmount(uint256 _value) external;

	/// @notice Locks more tokens in an existing lock
	/// @param account Address of account to lock tokens for
	/// @param _value Additional units of `token` to add to the lock
	/// @dev Does not update the lock's expiration.
	/// @dev Does increase the user's voting power, or the delegatee's voting power.
	function increaseAmountFor(address account, uint256 _value) external;

	/// @notice Extends the expiration of an existing lock
	/// @param _unlockTime New lock expiration time
	/// @dev Does not update the amount of tokens locked.
	/// @dev Does increase the user's voting power, unless lock is delegated.
	function increaseUnlockTime(uint256 _unlockTime) external;

	/// @notice Withdraws all the senders tokens, providing lockup is over
	/// @dev Delegated locks need to be undelegated first.
	function withdraw() external;

	/// @notice Delegate voting power to another address
	/// @param _addr user to which voting power is delegated
	/// @dev Can only undelegate to longer lock duration
	/// @dev Delegator inherits updates of delegatee lock
	function delegate(address _addr) external;

	/// @notice Quit an existing lock by withdrawing all tokens less a penalty
	/// @dev Quitters lock expiration remains in place because it might be delegated to
	function quitLock() external;

	/// @notice Get current user voting power
	/// @param _owner User for which to return the voting power
	/// @return Voting power of user
	function balanceOf(address _owner) external view returns (uint256);

	/// @notice Get users voting power at a given blockNumber
	/// @param _owner User for which to return the voting power
	/// @param _blockNumber Block at which to calculate voting power
	/// @return uint256 Voting power of user
	function balanceOfAt(address _owner, uint256 _blockNumber) external view returns (uint256);

	/// @notice Calculate current total supply of voting power
	/// @return Current totalSupply
	function totalSupply() external view returns (uint256);

	/// @notice Calculate total supply of voting power at a given blockNumber
	/// @param _blockNumber Block number at which to calculate total supply
	/// @return totalSupply of voting power at the given blockNumber
	function totalSupplyAt(uint256 _blockNumber) external view returns (uint256);

	/// @notice Remove delegation for blocked contract.
	/// @param _addr user to which voting power is delegated
	/// @dev Only callable by the blocklist contract
	function forceUndelegate(address _addr) external;

	/// @notice Returns a lock's expiration
	/// @param _addr The address of the lock owner
	/// @return Expiration of the lock
	function lockEnd(address _addr) external view returns (uint256);
}