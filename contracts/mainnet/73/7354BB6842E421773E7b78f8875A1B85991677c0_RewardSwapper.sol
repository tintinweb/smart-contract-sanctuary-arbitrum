// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
pragma solidity 0.8.12;

import {Common} from "../libraries/Common.sol";

interface IRewardDistributor {
    /**
        @notice Update rewards metadata
        @param  distributions  Distribution[] List of reward distribution details
     */
    function updateRewardsMetadata(
        Common.Distribution[] calldata distributions
    ) external;

    /** 
        @notice Set the contract's pause state (ie. before taking snapshot for the harvester)
        @param  state  bool  Pause state
    */
    function setPauseState(bool state) external;

    /**
        @notice Claim rewards based on the specified metadata
        @param  _claims  Claim[] List of claim metadata
     */
    function claim(Common.Claim[] calldata _claims) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IRewardHarvester {
    /**
        @notice Return the default token address
     */
    function defaultToken() external view returns (address);

    /**
        @notice Deposit `defaultToken` to this contract
        @param  _amount  uint256  Amount of `defaultToken` to deposit
     */
    function depositReward(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

library Common {
    /**
     * @param identifier  bytes32  Identifier of the distribution
     * @param token       address  Address of the token to distribute
     * @param merkleRoot  bytes32  Merkle root of the distribution
     * @param proof       bytes32  Proof of the distribution
     */
    struct Distribution {
        bytes32 identifier;
        address token;
        bytes32 merkleRoot;
        bytes32 proof;
    }

    /**
     * @param proposal          bytes32  Proposal to bribe
     * @param token             address  Token to bribe with
     * @param briber            address  Address of the briber
     * @param amount            uint256  Amount of tokens to bribe with
     * @param maxTokensPerVote  uint256  Maximum amount of tokens to use per vote
     * @param periods           uint256  Number of periods to bribe for
     * @param periodDuration    uint256  Duration of each period
     * @param proposalDeadline  uint256  Deadline for the proposal
     * @param permitDeadline    uint256  Deadline for the permit2 signature
     * @param signature         bytes    Permit2 signature
     */
    struct DepositBribeParams {
        bytes32 proposal;
        address token;
        address briber;
        uint256 amount;
        uint256 maxTokensPerVote;
        uint256 periods;
        uint256 periodDuration;
        uint256 proposalDeadline;
        uint256 permitDeadline;
        bytes signature;
    }

    /**
     * @param rwIdentifier      bytes32    Identifier for claiming reward
     * @param fromToken         address    Address of token to swap from
     * @param toToken           address    Address of token to swap to
     * @param fromAmount        uint256    Amount of fromToken to swap
     * @param toAmount          uint256    Amount of toToken to receive
     * @param deadline          uint256    Timestamp until which swap may be fulfilled
     * @param callees           address[]  Array of addresses to call (DEX addresses)
     * @param callLengths       uint256[]  Index of the beginning of each call in exchangeData
     * @param values            uint256[]  Array of encoded values for each call in exchangeData
     * @param exchangeData      bytes      Calldata to execute on callees
     * @param rwMerkleProof     bytes32[]  Merkle proof for the reward claim
     */
    struct ClaimAndSwapData {
        bytes32 rwIdentifier;
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 deadline;
        address[] callees;
        uint256[] callLengths;
        uint256[] values;
        bytes exchangeData;
        bytes32[] rwMerkleProof;
    }

    /**
     * @param identifier   bytes32    Identifier for claiming reward
     * @param account      address    Address of the account to claim for
     * @param amount       uint256    Amount of tokens to claim
     * @param merkleProof  bytes32[]  Merkle proof for the reward claim
     */
    struct Claim {
        bytes32 identifier;
        address account;
        uint256 amount;
        bytes32[] merkleProof;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

library Errors {
    /**
     * @notice max period 0 or greater than MAX_PERIODS
     */
    error InvalidMaxPeriod();

    /**
     * @notice period duration 0 or greater than MAX_PERIOD_DURATION
     */
    error InvalidPeriodDuration();

    /**
     * @notice address provided is not a contract
     */
    error NotAContract();

    /**
     * @notice not authorized
     */
    error NotAuthorized();

    /**
     * @notice contract already initialized
     */
    error AlreadyInitialized();

    /**
     * @notice address(0)
     */
    error InvalidAddress();

    /**
     * @notice empty bytes identifier
     */
    error InvalidIdentifier();

    /**
     * @notice invalid protocol name
     */
    error InvalidProtocol();

    /**
     * @notice invalid number of choices
     */
    error InvalidChoiceCount();

    /**
     * @notice invalid input amount
     */
    error InvalidAmount();

    /**
     * @notice not team member
     */
    error NotTeamMember();

    /**
     * @notice cannot whitelist BRIBE_VAULT
     */
    error NoWhitelistBribeVault();

    /**
     * @notice token already whitelisted
     */
    error TokenWhitelisted();

    /**
     * @notice token not whitelisted
     */
    error TokenNotWhitelisted();

    /**
     * @notice voter already blacklisted
     */
    error VoterBlacklisted();

    /**
     * @notice voter not blacklisted
     */
    error VoterNotBlacklisted();

    /**
     * @notice deadline has passed
     */
    error DeadlinePassed();

    /**
     * @notice invalid period
     */
    error InvalidPeriod();

    /**
     * @notice invalid deadline
     */
    error InvalidDeadline();

    /**
     * @notice invalid max fee
     */
    error InvalidMaxFee();

    /**
     * @notice invalid fee
     */
    error InvalidFee();

    /**
     * @notice invalid fee recipient
     */
    error InvalidFeeRecipient();

    /**
     * @notice invalid distributor
     */
    error InvalidDistributor();

    /**
     * @notice invalid briber
     */
    error InvalidBriber();

    /**
     * @notice address does not have DEPOSITOR_ROLE
     */
    error NotDepositor();

    /**
     * @notice no array given
     */
    error InvalidArray();

    /**
     * @notice invalid reward identifier
     */
    error InvalidRewardIdentifier();

    /**
     * @notice bribe has already been transferred
     */
    error BribeAlreadyTransferred();

    /**
     * @notice distribution does not exist
     */
    error InvalidDistribution();

    /**
     * @notice invalid merkle root
     */
    error InvalidMerkleRoot();

    /**
     * @notice token is address(0)
     */
    error InvalidToken();

    /**
     * @notice claim does not exist
     */
    error InvalidClaim();

    /**
     * @notice reward is not yet active for claiming
     */
    error RewardInactive();

    /**
     * @notice timer duration is invalid
     */
    error InvalidTimerDuration();

    /**
     * @notice merkle proof is invalid
     */
    error InvalidProof();

    /**
     * @notice ETH transfer failed
     */
    error ETHTransferFailed();

    /**
     * @notice Invalid operator address
     */
    error InvalidOperator();

    /**
     * @notice call to TokenTransferProxy contract
     */
    error TokenTransferProxyCall();

    /**
     * @notice calling TransferFrom
     */
    error TransferFromCall();

    /**
     * @notice external call failed
     */
    error ExternalCallFailure();

    /**
     * @notice returned tokens too few
     */
    error InsufficientReturn();

    /**
     * @notice swapDeadline expired
     */
    error DeadlineBreach();

    /**
     * @notice expected tokens returned are 0
     */
    error ZeroExpectedReturns();

    /**
     * @notice arrays in SwapData.exchangeData have wrong lengths
     */
    error ExchangeDataArrayMismatch();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IRewardDistributor} from "./interfaces/IRewardDistributor.sol";
import {IRewardHarvester} from "./interfaces/IRewardHarvester.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Errors} from "./libraries/Errors.sol";
import {Common} from "./libraries/Common.sol";

contract RewardSwapper is Ownable2Step {
    using SafeERC20 for IERC20;

    IRewardDistributor public rewardDistributor;
    IRewardHarvester public rewardHarvester;

    // Operator address
    address public operator;

    //-----------------------//
    //        Events         //
    //-----------------------//
    event SetOperator(address indexed operator);
    event SetRewardHarvester(address indexed rewardHarvester);
    event SetRewardDistributor(address indexed rewardDistributor);
    event BribeTransferred(address indexed token, uint256 totalAmount);

    /**
     * @notice Modifier to check caller is operator
     */
    modifier onlyOperator() {
        if (msg.sender != operator) revert Errors.NotAuthorized();
        _;
    }

    //-----------------------//
    //       Constructor     //
    //-----------------------//
    constructor(
        address _rewardDistributor,
        address _rewardHarvester,
        address _operator
    ) {
        _setRewardDistributor(_rewardDistributor);
        _setRewardHarvester(_rewardHarvester);
        _setOperator(_operator);
    }

    //-----------------------//
    //   External Functions  //
    //-----------------------//

    /**
     * @notice Executes swaps via DEX
     * @param  _claimSwapData  Common.ClaimAndSwapData[]  The data for the claims+swaps
     */
    function claimSwapAndDepositReward(
        Common.ClaimAndSwapData[] calldata _claimSwapData
    ) external onlyOperator {
        uint256 cLen = _claimSwapData.length;

        if (cLen == 0) revert Errors.InvalidArray();

        IERC20 defaultToken = IERC20(rewardHarvester.defaultToken());

        uint256 initalAmount = defaultToken.balanceOf(address(this));

        Common.Claim[] memory claimData = new Common.Claim[](
            _claimSwapData.length
        );

        // Claim rewards
        for (uint256 i; i < cLen; ) {
            claimData[i].identifier = _claimSwapData[i].rwIdentifier;
            claimData[i].account = address(this);
            claimData[i].amount = _claimSwapData[i].fromAmount;
            claimData[i].merkleProof = _claimSwapData[i].rwMerkleProof;

            unchecked {
                ++i;
            }
        }

        rewardDistributor.claim(claimData);

        // Swap reward tokens to default token
        for (uint256 i; i < cLen; ) {
            _swap(_claimSwapData[i]);

            unchecked {
                ++i;
            }
        }

        uint256 amountClaimed = defaultToken.balanceOf(address(this)) -
            initalAmount;

        // Approve reward harvester if needed
        if (
            defaultToken.allowance(address(this), address(rewardHarvester)) <
            amountClaimed
        ) {
            defaultToken.safeApprove(
                address(rewardHarvester),
                type(uint256).max
            );
        }

        // Deposit reward
        rewardHarvester.depositReward(amountClaimed);

        emit BribeTransferred(address(defaultToken), amountClaimed);
    }

    /**
        @notice Change the operator
        @param  _operator  address  New operator address
     */
    function changeOperator(address _operator) external onlyOwner {
        _setOperator(_operator);
    }

    /**
        @notice Change the reward harvester address
        @param  _harvester  address  New harvester address
     */
    function changeRewardHarvester(address _harvester) external onlyOwner {
        _setRewardHarvester(_harvester);
    }

    /**
        @notice Change the reward distributor address
        @param  _distributor  address  New distributor address
     */
    function changeRewardDistributor(address _distributor) external onlyOwner {
        _setRewardDistributor(_distributor);
    }

    //-----------------------//
    //   Internal Functions  //
    //-----------------------//

    /**
        @dev    Internal to set the operator
        @param  _operator  address  Operator address
     */
    function _setOperator(address _operator) internal {
        if (_operator == address(0)) revert Errors.InvalidAddress();

        operator = _operator;

        emit SetOperator(_operator);
    }

    /**
        @dev    Internal to set the reward harvester
        @param  _harvester  address  Reward Harvester address
     */
    function _setRewardHarvester(address _harvester) internal {
        if (_harvester == address(0)) revert Errors.InvalidAddress();

        rewardHarvester = IRewardHarvester(_harvester);

        emit SetRewardHarvester(_harvester);
    }

    /**
        @dev    Internal to set the reward distributor
        @param  _distributor  address  Distributor address
     */
    function _setRewardDistributor(address _distributor) internal {
        if (_distributor == address(0)) revert Errors.InvalidAddress();

        rewardDistributor = IRewardDistributor(_distributor);

        emit SetRewardDistributor(_distributor);
    }

    /**
     * @notice Executes a sequence of swaps via DEX
     * @param  _swapData       Common.SwapData  The data for the swaps
     * @return receivedAmount  uint256          The final amount of the toToken received
     */
    function _swap(
        Common.ClaimAndSwapData memory _swapData
    ) internal returns (uint256 receivedAmount) {
        if (
            !(_swapData.callees.length == _swapData.callLengths.length &&
                _swapData.callees.length == _swapData.values.length)
        ) {
            revert Errors.ExchangeDataArrayMismatch();
        }

        if (_swapData.deadline < block.timestamp) {
            revert Errors.DeadlineBreach();
        }

        if (_swapData.toAmount == 0) {
            revert Errors.ZeroExpectedReturns();
        }

        bytes memory exchangeData = _swapData.exchangeData;
        uint256 calleesLength = _swapData.callees.length;

        if (calleesLength == 0) revert Errors.InvalidArray();

        bytes4 transferFromSelector = IERC20.transferFrom.selector;
        uint256 initialAmount = IERC20(_swapData.toToken).balanceOf(
            address(this)
        );

        uint256 currentDataStartIndex = 0;
        for (uint256 i; i < calleesLength; ) {
            // Check if the call is a transferFrom call
            // protect caller from transferring more than `fromAmount`
            {
                bytes32 selector;
                assembly {
                    selector := mload(add(exchangeData, add(currentDataStartIndex, 32)))
                }
                if (bytes4(selector) == transferFromSelector) {
                    revert Errors.TransferFromCall();
                }
            }
            bool result = _externalCall(
                _swapData.callees[i], //destination
                _swapData.values[i], //value to send
                currentDataStartIndex, // start index of call data
                _swapData.callLengths[i], // length of calldata
                exchangeData // total calldata
            );
            if (!result) {
                revert Errors.ExternalCallFailure();
            }
            currentDataStartIndex += _swapData.callLengths[i];
            unchecked {
                ++i;
            }
        }

        receivedAmount = IERC20(_swapData.toToken).balanceOf(address(this));

        if ((receivedAmount - initialAmount) < _swapData.toAmount) {
            revert Errors.InsufficientReturn();
        }
    }

    /**
     * @dev Source take from GNOSIS MultiSigWallet
     * @dev https://github.com/gnosis/MultiSigWallet/blob/master/contracts/MultiSigWallet.sol
     */
    function _externalCall(
        address _destination,
        uint256 _value,
        uint256 _dataOffset,
        uint256 _dataLength,
        bytes memory _data
    ) internal returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40) // "Allocate" memory for output
            // (0x40 is where "free memory" pointer is stored by convention)

            let d := add(_data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                gas(),
                _destination,
                _value,
                add(d, _dataOffset),
                _dataLength, // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0 // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }
}