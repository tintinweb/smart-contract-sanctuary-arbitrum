// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
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

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0


interface IL2Gateway {
    /// @notice Estimate the fee to call send withdraw message
    function estimateWithdrawETHFee(address _owner, uint128 _amount, uint32 _accountIdOfNonce, uint8 _subAccountIdOfNonce, uint32 _nonce, uint16 _fastWithdrawFeeRate) external view returns (uint256 nativeFee);

    /// @notice Withdraw ETH to L1 for owner
    /// @param _owner The address received eth on L1
    /// @param _amount The eth amount received
    /// @param _accountIdOfNonce Account that supply nonce, may be different from accountId
    /// @param _subAccountIdOfNonce SubAccount that supply nonce
    /// @param _nonce SubAccount nonce, used to produce unique accept info
    /// @param _fastWithdrawFeeRate Fast withdraw fee rate taken by acceptor
    function withdrawETH(address _owner, uint128 _amount, uint32 _accountIdOfNonce, uint8 _subAccountIdOfNonce, uint32 _nonce, uint16 _fastWithdrawFeeRate) external payable;

    /// @notice Estimate the fee to call send withdraw message
    function estimateWithdrawERC20Fee(address _owner, address _token, uint128 _amount, uint32 _accountIdOfNonce, uint8 _subAccountIdOfNonce, uint32 _nonce, uint16 _fastWithdrawFeeRate) external view returns (uint256 nativeFee);

    /// @notice Withdraw ERC20 token to L1 for owner
    /// @dev gateway need to pay fee to message service
    /// @param _owner The address received token on L1
    /// @param _token The token address on L2
    /// @param _amount The token amount received
    /// @param _accountIdOfNonce Account that supply nonce, may be different from accountId
    /// @param _subAccountIdOfNonce SubAccount that supply nonce
    /// @param _nonce SubAccount nonce, used to produce unique accept info
    /// @param _fastWithdrawFeeRate Fast withdraw fee rate taken by acceptor
    function withdrawERC20(address _owner, address _token, uint128 _amount, uint32 _accountIdOfNonce, uint8 _subAccountIdOfNonce, uint32 _nonce, uint16 _fastWithdrawFeeRate) external payable;

    /// @notice Return the fee of sending sync hash to ethereum
    /// @param syncHash the sync hash
    function estimateSendSlaverSyncHashFee(bytes32 syncHash) external view returns (uint nativeFee);

    /// @notice Send sync hash message to ethereum
    /// @param syncHash the sync hash
    function sendSlaverSyncHash(bytes32 syncHash) external payable;

    /// @notice Return the fee of sending sync hash to ethereum
    /// @param blockNumber the block number
    /// @param syncHash the sync hash
    function estimateSendMasterSyncHashFee(uint32 blockNumber, bytes32 syncHash) external view returns (uint nativeFee);

    /// @notice Send sync hash message to ethereum
    /// @param blockNumber the block number
    /// @param syncHash the sync hash
    function sendMasterSyncHash(uint32 blockNumber, bytes32 syncHash) external payable;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Sync service for sending cross chain message
/// @author zk.link
interface ISyncService {
    /// @notice Return the fee of sending sync hash to master chain
    /// @param syncHash the sync hash
    function estimateSendSyncHashFee(bytes32 syncHash) external view returns (uint nativeFee);

    /// @notice Send sync hash message to master chain
    /// @param syncHash the sync hash
    function sendSyncHash(bytes32 syncHash) external payable;

    /// @notice Estimate the fee of sending confirm block message to slaver chain
    /// @param destZkLinkChainId the destination chain id defined by zkLink
    /// @param blockNumber the height of stored block
    function estimateConfirmBlockFee(uint8 destZkLinkChainId, uint32 blockNumber) external view returns (uint nativeFee);

    /// @notice Send block confirmation message to slaver chains
    /// @param destZkLinkChainId the destination chain id defined by zkLink
    /// @param blockNumber the block height
    function confirmBlock(uint8 destZkLinkChainId, uint32 blockNumber) external payable;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Verifier interface contract
/// @author zk.link
interface IVerifier {
    function verifyAggregatedBlockProof(uint256[] memory _recursiveInput, uint256[] memory _proof, uint8[] memory _vkIndexes, uint256[] memory _individualVksInputs, uint256[16] memory _subProofsLimbs) external returns (bool);

    function verifyExitProof(bytes32 _rootHash, uint8 _chainId, uint32 _accountId, uint8 _subAccountId, bytes32 _owner, uint16 _tokenId, uint16 _srcTokenId, uint128 _amount, uint256[] calldata _proof) external returns (bool);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./zksync/Operations.sol";
import "./zksync/Config.sol";
import "./interfaces/IVerifier.sol";
import "./interfaces/ISyncService.sol";
import "./interfaces/IL2Gateway.sol";
import "./zksync/SafeCast.sol";
import "./ZkLinkAcceptor.sol";

/// @title ZkLink storage contract
/// @dev Be carefully to change the order of variables
/// @author zk.link
contract Storage is ZkLinkAcceptor, Config {
    /// @dev Used to safely call `delegatecall`, immutable state variables don't occupy storage slot
    address internal immutable self = address(this);

    // verifier(20 bytes) + totalBlocksExecuted(4 bytes) + firstPriorityRequestId(8 bytes) stored in the same slot

    /// @notice Verifier contract. Used to verify block proof and exit proof
    IVerifier public verifier;

    /// @notice Total number of executed blocks i.e. blocks[totalBlocksExecuted] points at the latest executed block (block 0 is genesis)
    uint32 public totalBlocksExecuted;

    /// @notice First open priority request id
    uint64 public firstPriorityRequestId;

    // networkGovernor(20 bytes) + totalBlocksCommitted(4 bytes) + totalOpenPriorityRequests(8 bytes) stored in the same slot

    /// @notice The the owner of whole system
    address public networkGovernor;

    /// @notice Total number of committed blocks i.e. blocks[totalBlocksCommitted] points at the latest committed block
    uint32 public totalBlocksCommitted;

    /// @notice Total number of requests
    uint64 public totalOpenPriorityRequests;

    // gateway(20 bytes) + totalBlocksProven(4 bytes) + totalCommittedPriorityRequests(8 bytes) stored in the same slot

    /// @notice The gateway is used for communicating with L1
    /// @dev The gateway will not be set if local chain is a L1
    IL2Gateway public gateway;

    /// @notice Total blocks proven.
    uint32 public totalBlocksProven;

    /// @notice Total number of committed requests.
    /// @dev Used in checks: if the request matches the operation on Rollup contract and if provided number of requests is not too big
    uint64 public totalCommittedPriorityRequests;

    // totalBlocksSynchronized(4 bytes) + exodusMode(1 bytes) stored in the same slot

    /// @dev Latest synchronized block height
    uint32 public totalBlocksSynchronized;

    /// @notice Flag indicates that exodus (mass exit) mode is triggered
    /// @notice Once it was raised, it can not be cleared again, and all users must exit
    bool public exodusMode;

    /// @dev Root-chain balances (per owner and token id) to withdraw
    /// @dev the amount of pending balance need to recovery decimals when withdraw
    /// @dev The struct of this map is (owner => tokenId => balance)
    /// @dev The type of owner is bytes32, when storing evm address, 12 bytes of prefix zero will be appended
    /// @dev for example: 0x000000000000000000000000A1a547358A9Ca8E7b320d7742729e3334Ad96546
    mapping(bytes32 => mapping(uint16 => uint128)) internal pendingBalances;

    /// @dev Store withdraw data hash that need to be relayed to L1 by gateway
    /// @dev The key is the withdraw data hash
    /// @dev The value is a flag to indicating whether withdraw exists
    mapping(bytes32 => bool) public pendingL1Withdraws;

    /// @notice Flag indicates that a user has exited a certain token balance in the exodus mode
    /// @dev The struct of this map is (accountId => subAccountId => withdrawTokenId => deductTokenId => performed)
    /// @dev withdrawTokenId is the token that withdraw to user in L1
    /// @dev deductTokenId is the token that deducted from user in L2
    mapping(uint32 => mapping(uint8 => mapping(uint16 => mapping(uint16 => bool)))) public performedExodus;

    /// @dev Priority Requests mapping (request id - operation)
    /// Contains op type, pubdata and expiration block of unsatisfied requests.
    /// Numbers are in order of requests receiving
    mapping(uint64 => Operations.PriorityOperation) public priorityRequests;

    /// @notice User authenticated fact hashes for some nonce.
    mapping(address => mapping(uint32 => bytes32)) public authFacts;

    /// @dev Timer for authFacts entry reset (address, nonce -> timer).
    /// Used when user wants to reset `authFacts` for some nonce.
    mapping(address => mapping(uint32 => uint256)) public authFactsResetTimer;

    /// @dev Stored hashed StoredBlockInfo for some block number
    mapping(uint32 => bytes32) public storedBlockHashes;

    /// @dev Store sync hash for slaver chains
    /// chainId => syncHash
    mapping(uint8 => bytes32) public synchronizedChains;

    /// @notice A set of permitted validators
    mapping(address => bool) public validators;

    struct RegisteredToken {
        bool registered; // whether token registered to ZkLink or not, default is false
        bool paused; // whether token can deposit to ZkLink or not, default is false
        address tokenAddress; // the token address
        uint8 decimals; // the token decimals of layer one
    }

    /// @notice A map of registered token infos
    mapping(uint16 => RegisteredToken) public tokens;

    /// @notice A map of token address to id, 0 is invalid token id
    mapping(address => uint16) public tokenIds;

    /// @dev Support multiple sync services, for example:
    /// <Linea, zkSync Era> - LayerZero
    /// <Linea, Scroll> - zkBridge
    /// chainId => sync service
    mapping(uint8 => ISyncService) public chainSyncServiceMap;
    mapping(address => bool) public syncServiceMap;

    /// @dev Store withdraw data hash that need to be called
    /// @dev The key is the withdraw data hash
    /// @dev The value is a flag to indicating whether withdraw exists
    mapping(bytes32 => bool) public pendingWithdrawWithCalls;

    /// @notice block stored data
    /// @dev `blockNumber`,`timestamp`,`stateHash`,`commitment` are the same on all chains
    /// `priorityOperations`,`pendingOnchainOperationsHash` is different for each chain
    struct StoredBlockInfo {
        uint32 blockNumber; // Rollup block number
        uint64 priorityOperations; // Number of priority operations processed
        bytes32 pendingOnchainOperationsHash; // Hash of all operations that must be processed after verify
        uint256 timestamp; // Rollup block timestamp, have the same format as Ethereum block constant
        bytes32 stateHash; // Root hash of the rollup state
        bytes32 commitment; // Verified input for the ZkLink circuit
        SyncHash[] syncHashs; // Used for cross chain block verify
    }
    struct SyncHash {
        uint8 chainId;
        bytes32 syncHash;
    }


    /// @notice Checks that current state not is exodus mode
    modifier active() {
        require(!exodusMode, "0");
        _;
    }

    /// @notice Checks that current state is exodus mode
    modifier notActive() {
        require(exodusMode, "1");
        _;
    }

    /// @notice Set logic contract must be called through proxy
    modifier onlyDelegateCall() {
        require(address(this) != self, "2");
        _;
    }

    modifier onlyGovernor {
        require(msg.sender == networkGovernor, "3");
        _;
    }

    /// @notice Check if msg sender is a validator
    modifier onlyValidator() {
        require(validators[msg.sender], "4");
        _;
    }

    /// @notice Check if msg sender is sync service
    modifier onlySyncService() {
        require(syncServiceMap[msg.sender], "6");
        _;
    }

    /// @notice Check if msg sender is gateway
    modifier onlyGateway() {
        require(msg.sender == address(gateway), "7");
        _;
    }

    /// @notice Returns the keccak hash of the ABI-encoded StoredBlockInfo
    function hashStoredBlockInfo(StoredBlockInfo memory _storedBlockInfo) internal pure returns (bytes32) {
        return keccak256(abi.encode(_storedBlockInfo));
    }

    /// @notice Increase pending balance to withdraw
    /// @param _address the pending balance owner
    /// @param _tokenId token id
    /// @param _amount pending amount that need to recovery decimals when withdraw
    function increaseBalanceToWithdraw(bytes32 _address, uint16 _tokenId, uint128 _amount) internal {
        uint128 balance = pendingBalances[_address][_tokenId];
        // overflow should not happen here
        // (2^128 / 10^18 = 3.4 * 10^20) is enough to meet the really token balance of L2 account
        pendingBalances[_address][_tokenId] = balance + _amount;
    }

    /// @notice Extend address to bytes32
    /// @dev for example: extend 0xA1a547358A9Ca8E7b320d7742729e3334Ad96546 and the result is 0x000000000000000000000000a1a547358a9ca8e7b320d7742729e3334ad96546
    function extendAddress(address _address) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }

    /// @dev improve decimals when deposit, for example, user deposit 2 USDC in ui, and the decimals of USDC is 6
    /// the `_amount` params when call contract will be 2 * 10^6
    /// because all token decimals defined in layer two is 18
    /// so the `_amount` in deposit pubdata should be 2 * 10^6 * 10^(18 - 6) = 2 * 10^18
    function improveDecimals(uint128 _amount, uint8 _decimals) internal pure returns (uint128) {
        // overflow is impossible,  `_decimals` has been checked when register token
        return _amount * SafeCast.toUint128(10**(TOKEN_DECIMALS_OF_LAYER2 - _decimals));
    }

    /// @dev recover decimals when withdraw, this is the opposite of improve decimals
    function recoveryDecimals(uint128 _amount, uint8 _decimals) internal pure returns (uint128) {
        // overflow is impossible,  `_decimals` has been checked when register token
        return _amount / SafeCast.toUint128(10**(TOKEN_DECIMALS_OF_LAYER2 - _decimals));
    }

    /// @dev Return withdraw hash with call data
    /// @dev (_accountIdOfNonce, _subAccountIdOfNonce, _nonce) ensures the uniqueness of withdraw hash
    function getWithdrawWithDataHash(address _owner, address _tokenAddress, uint128 _amount, bytes32 _dataHash, uint32 _accountIdOfNonce, uint8 _subAccountIdOfNonce, uint32 _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_owner, _tokenAddress, _amount, _dataHash, _accountIdOfNonce, _subAccountIdOfNonce, _nonce));
    }

    /// @notice Performs a delegatecall to the contract implementation
    /// @dev Fallback function allowing to perform a delegatecall to the given implementation
    /// This function will return whatever the implementation call returns
    function _fallback(address _target) internal {
        require(_target != address(0), "5");
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _target, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title ZkLink acceptor contract
/// @author zk.link
abstract contract ZkLinkAcceptor {
    using SafeERC20 for IERC20;

    /// @dev Address represent eth when deposit or withdraw
    address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev When set fee = 100, it means 1%
    uint16 internal constant MAX_ACCEPT_FEE_RATE = 10000;

    /// @dev Accept infos of withdraw
    /// @dev key is keccak256(abi.encodePacked(accountIdOfNonce, subAccountIdOfNonce, nonce, owner, token, amount, fastWithdrawFeeRate))
    /// @dev value is the acceptor
    mapping(bytes32 => address) public accepts;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    /// @notice Event emitted when acceptor accept a fast withdraw
    event Accept(address acceptor, address receiver, address token, uint128 amount, uint16 withdrawFeeRate, uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce, uint128 amountReceive);

    /// @notice Acceptor accept a eth fast withdraw, acceptor will get a fee for profit
    /// @param receiver User receive token from acceptor (the owner of withdraw operation)
    /// @param amount The amount of withdraw operation
    /// @param fastWithdrawFeeRate Fast withdraw fee rate taken by acceptor
    /// @param accountIdOfNonce Account that supply nonce
    /// @param subAccountIdOfNonce SubAccount that supply nonce
    /// @param nonce SubAccount nonce, used to produce unique accept info
    function acceptETH(address payable receiver, uint128 amount, uint16 fastWithdrawFeeRate, uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce) external payable {
        // ===Checks===
        uint128 amountReceive = _checkAccept(msg.sender, receiver, ETH_ADDRESS, amount, fastWithdrawFeeRate, accountIdOfNonce, subAccountIdOfNonce, nonce);

        // ===Interactions===
        // make sure msg value >= amountReceive
        uint256 amountReturn = msg.value - amountReceive;
        // msg.sender should set a reasonable gas limit when call this function
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = receiver.call{value: amountReceive}("");
        require(success, "E0");
        // if send too more eth then return back to msg sender
        if (amountReturn > 0) {
            // it's safe to use call to msg.sender and can send all gas left to it
            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = msg.sender.call{value: amountReturn}("");
            require(success, "E1");
        }
        emit Accept(msg.sender, receiver, ETH_ADDRESS, amount, fastWithdrawFeeRate, accountIdOfNonce, subAccountIdOfNonce, nonce, amountReceive);
    }

    /// @notice Acceptor accept a erc20 token fast withdraw, acceptor will get a fee for profit
    /// @param receiver User receive token from acceptor (the owner of withdraw operation)
    /// @param token Token address
    /// @param amount The amount of withdraw operation
    /// @param fastWithdrawFeeRate Fast withdraw fee rate taken by acceptor
    /// @param accountIdOfNonce Account that supply nonce
    /// @param subAccountIdOfNonce SubAccount that supply nonce
    /// @param nonce SubAccount nonce, used to produce unique accept info
    function acceptERC20(address receiver, address token, uint128 amount, uint16 fastWithdrawFeeRate, uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce) external {
        // ===Checks===
        uint128 amountReceive = _checkAccept(msg.sender, receiver, token, amount, fastWithdrawFeeRate, accountIdOfNonce, subAccountIdOfNonce, nonce);

        // ===Interactions===
        IERC20(token).safeTransferFrom(msg.sender, receiver, amountReceive);
        emit Accept(msg.sender, receiver, token, amount, fastWithdrawFeeRate, accountIdOfNonce, subAccountIdOfNonce, nonce, amountReceive);
    }

    function _checkAccept(address acceptor, address receiver, address token, uint128 amount, uint16 fastWithdrawFeeRate, uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce) internal returns (uint128 amountReceive) {
        // acceptor and receiver MUST be set and MUST not be the same
        require(receiver != address(0), "H1");
        require(receiver != acceptor, "H2");
        // feeRate MUST be valid and MUST not be 100%
        require(fastWithdrawFeeRate < MAX_ACCEPT_FEE_RATE, "H3");
        amountReceive = amount * (MAX_ACCEPT_FEE_RATE - fastWithdrawFeeRate) / MAX_ACCEPT_FEE_RATE;

        // accept tx may be later than block exec tx(with user withdraw op)
        bytes32 hash = getWithdrawHash(accountIdOfNonce, subAccountIdOfNonce, nonce, receiver, token, amount, fastWithdrawFeeRate);
        require(accepts[hash] == address(0), "H4");

        // ===Effects===
        accepts[hash] = acceptor;
    }

    /// @dev Return accept record hash for withdraw
    /// @dev (accountIdOfNonce, subAccountIdOfNonce, nonce) ensures the uniqueness of withdraw hash
    function getWithdrawHash(uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce, address owner, address token, uint128 amount, uint16 fastWithdrawFeeRate) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(accountIdOfNonce, subAccountIdOfNonce, nonce, owner, token, amount, fastWithdrawFeeRate));
    }

    /// @dev Update the receiver of withdraw claim
    /// @dev If acceptor accepted this withdraw then return acceptor or return owner
    function updateAcceptReceiver(address _owner, address _token, uint128 _amount, uint32 _accountIdOfNonce, uint8 _subAccountIdOfNonce, uint32 _nonce, uint16 _fastWithdrawFeeRate) internal returns (address) {
        bytes32 withdrawHash = getWithdrawHash(_accountIdOfNonce, _subAccountIdOfNonce, _nonce, _owner, _token, _amount, _fastWithdrawFeeRate);
        address acceptor = accepts[withdrawHash];
        address receiver = acceptor;
        if (acceptor == address(0)) {
            // receiver act as a acceptor
            receiver = _owner;
            accepts[withdrawHash] = _owner;
        }
        return receiver;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./zksync/ReentrancyGuard.sol";
import "./zksync/Events.sol";
import "./Storage.sol";
import "./zksync/Bytes.sol";
import "./zksync/Utils.sol";

/// @title ZkLink periphery contract
/// @author zk.link
contract ZkLinkPeriphery is ReentrancyGuard, Storage, Events {
    using SafeERC20 for IERC20;
    // =================User interface=================

    /// @notice Checks if Exodus mode must be entered. If true - enters exodus mode and emits ExodusMode event.
    /// @dev Exodus mode must be entered in case of current ethereum block number is higher than the oldest
    /// of existed priority requests expiration block number.
    function activateExodusMode() external active nonReentrant {
        bool trigger = block.number >= priorityRequests[firstPriorityRequestId].expirationBlock &&
        priorityRequests[firstPriorityRequestId].expirationBlock != 0;

        if (trigger) {
            exodusMode = true;
            emit ExodusMode();
        }
    }

    /// @notice Withdraws token from ZkLink to root chain in case of exodus mode. User must provide proof that he owns funds
    /// @param _storedBlockInfo Last verified block
    /// @param _owner Owner of the account
    /// @param _accountId Id of the account in the tree
    /// @param _subAccountId Id of the subAccount in the tree
    /// @param _proof Proof
    /// @param _withdrawTokenId The token want to withdraw in L1
    /// @param _deductTokenId The token deducted in L2
    /// @param _amount Amount for owner (must be total amount, not part of it) in L2
    function performExodus(StoredBlockInfo calldata _storedBlockInfo, bytes32 _owner, uint32 _accountId, uint8 _subAccountId, uint16 _withdrawTokenId, uint16 _deductTokenId, uint128 _amount, uint256[] calldata _proof) external notActive nonReentrant {
        // ===Checks===
        // performed exodus MUST not be already exited
        require(!performedExodus[_accountId][_subAccountId][_withdrawTokenId][_deductTokenId], "y0");
        // incorrect stored block info
        require(storedBlockHashes[totalBlocksExecuted] == hashStoredBlockInfo(_storedBlockInfo), "y1");
        // exit proof MUST be correct
        bool proofCorrect = verifier.verifyExitProof(_storedBlockInfo.stateHash, CHAIN_ID, _accountId, _subAccountId, _owner, _withdrawTokenId, _deductTokenId, _amount, _proof);
        require(proofCorrect, "y2");

        // ===Effects===
        performedExodus[_accountId][_subAccountId][_withdrawTokenId][_deductTokenId] = true;
        increaseBalanceToWithdraw(_owner, _withdrawTokenId, _amount);
        emit WithdrawalPending(_withdrawTokenId, _owner, _amount);
    }

    /// @notice Accrues users balances from deposit priority requests in Exodus mode
    /// @dev WARNING: Only for Exodus mode
    /// Canceling may take several separate transactions to be completed
    /// @param _n number of requests to process
    /// @param _depositsPubdata deposit details
    function cancelOutstandingDepositsForExodusMode(uint64 _n, bytes[] calldata _depositsPubdata) external notActive nonReentrant {
        // ===Checks===
        uint64 toProcess = Utils.minU64(totalOpenPriorityRequests, _n);
        require(toProcess > 0, "A0");

        // ===Effects===
        uint64 currentDepositIdx = 0;
        // overflow is impossible, firstPriorityRequestId >= 0 and toProcess > 0
        uint64 lastPriorityRequestId = firstPriorityRequestId + toProcess - 1;
        for (uint64 id = firstPriorityRequestId; id <= lastPriorityRequestId; ++id) {
            Operations.PriorityOperation memory pr = priorityRequests[id];
            if (pr.opType == Operations.OpType.Deposit) {
                bytes memory depositPubdata = _depositsPubdata[currentDepositIdx];
                require(Utils.hashBytesWithSizeToBytes20(depositPubdata, Operations.DEPOSIT_CHECK_BYTES) == pr.hashedPubData, "A1");
                ++currentDepositIdx;

                Operations.Deposit memory op = Operations.readDepositPubdata(depositPubdata);
                // amount of Deposit has already improve decimals
                increaseBalanceToWithdraw(op.owner, op.tokenId, op.amount);
            }
            // after return back deposited token to user, delete the priorityRequest to avoid redundant cancel
            // other priority requests(ie. FullExit) are also be deleted because they are no used anymore
            // and we can get gas reward for free these slots
            delete priorityRequests[id];
        }
        // overflow is impossible
        firstPriorityRequestId += toProcess;
        totalOpenPriorityRequests -= toProcess;
    }

    /// @notice Set data for changing pubkey hash using onchain authorization.
    ///         Transaction author (msg.sender) should be L2 account address
    /// New pubkey hash can be reset, to do that user should send two transactions:
    ///         1) First `setAuthPubkeyHash` transaction for already used `_nonce` will set timer.
    ///         2) After `AUTH_FACT_RESET_TIMELOCK` time is passed second `setAuthPubkeyHash` transaction will reset pubkey hash for `_nonce`.
    /// @param _pubkeyHash New pubkey hash
    /// @param _nonce Nonce of the change pubkey L2 transaction
    function setAuthPubkeyHash(bytes calldata _pubkeyHash, uint32 _nonce) external active nonReentrant {
        require(_pubkeyHash.length == PUBKEY_HASH_BYTES, "B0"); // PubKeyHash should be 20 bytes.
        if (authFacts[msg.sender][_nonce] == bytes32(0)) {
            authFacts[msg.sender][_nonce] = keccak256(_pubkeyHash);
            emit FactAuth(msg.sender, _nonce, _pubkeyHash);
        } else {
            uint256 currentResetTimer = authFactsResetTimer[msg.sender][_nonce];
            if (currentResetTimer == 0) {
                authFactsResetTimer[msg.sender][_nonce] = block.timestamp;
                emit FactAuthResetTime(msg.sender, _nonce, block.timestamp);
            } else {
                require(block.timestamp - currentResetTimer >= AUTH_FACT_RESET_TIMELOCK, "B1"); // too early to reset auth
                authFactsResetTimer[msg.sender][_nonce] = 0;
                authFacts[msg.sender][_nonce] = keccak256(_pubkeyHash);
                emit FactAuth(msg.sender, _nonce, _pubkeyHash);
            }
        }
    }

    /// @notice  Withdraws tokens from zkLink contract to the owner
    /// @param _owner Address of the tokens owner
    /// @param _tokenId Token id
    /// @param _amount The actual withdrawn amount
    function withdrawPendingBalance(address payable _owner, uint16 _tokenId, uint128 _amount) external nonReentrant {
        // ===Checks===
        // token MUST be registered to ZkLink
        RegisteredToken storage rt = tokens[_tokenId];
        require(rt.registered, "b0");

        // ===Effects===
        // Set the available amount to withdraw
        // balance need to be recovery decimals
        bytes32 l2Owner = extendAddress(_owner);
        uint128 l2Balance = pendingBalances[l2Owner][_tokenId];
        uint128 l2Amount = improveDecimals(_amount, rt.decimals);
        pendingBalances[l2Owner][_tokenId] = l2Balance - l2Amount;

        // ===Interactions===
        _withdrawTo(_owner, rt.tokenAddress, _amount, new bytes(0));
        emit Withdrawal(_tokenId, _amount);
    }

    /// @notice  Withdraws tokens from zkLink contract to the target contract
    /// @param _owner Address of the tokens owner
    /// @param _tokenAddress Token address
    /// @param _amount The actual withdrawn amount
    /// @param _data The target contract address and call data
    /// @param _accountIdOfNonce Account that supply nonce
    /// @param _subAccountIdOfNonce SubAccount that supply nonce
    /// @param _nonce SubAccount nonce
    /// @param _callTarget True when call target or withdraw pending balance to owner
    function withdrawPendingBalanceWithCall(address payable _owner, address _tokenAddress, uint128 _amount, bytes memory _data, uint32 _accountIdOfNonce, uint8 _subAccountIdOfNonce, uint32 _nonce, bool _callTarget) external nonReentrant {
        // ===Checks===
        // pending withdraw record MUST be exist
        bytes32 dataHash = keccak256(_data);
        bytes32 withdrawWithDataHash = getWithdrawWithDataHash(_owner, _tokenAddress, _amount, dataHash, _accountIdOfNonce, _subAccountIdOfNonce, _nonce);
        require(pendingWithdrawWithCalls[withdrawWithDataHash], "z0");

        // ===Effects===
        pendingWithdrawWithCalls[withdrawWithDataHash] = false;

        if (_callTarget) {
            // decode data
            (address targetContract, bytes memory callData) = abi.decode(_data, (address, bytes));
            _withdrawTo(payable(targetContract), _tokenAddress, _amount, callData);
        } else {
            _withdrawTo(_owner, _tokenAddress, _amount, new bytes(0));
        }
        emit WithdrawalCall(withdrawWithDataHash);
    }

    function _withdrawTo(address payable _to,  address _tokenAddress, uint128 _amount, bytes memory _callData) internal {
        // ===Interactions===
        if (_tokenAddress == ETH_ADDRESS) {
            // solhint-disable-next-line  avoid-low-level-calls
            (bool success, ) = _to.call{value: _amount}(_callData);
            require(success, "b1");
        } else {
            IERC20(_tokenAddress).safeTransfer(_to, _amount);
            if (_callData.length > 0) {
                // solhint-disable-next-line  avoid-low-level-calls
                (bool success, ) = _to.call(_callData);
                require(success, "b2");
            }
        }
    }

    /// @notice Returns amount of tokens that can be withdrawn by `address` from zkLink contract
    /// @param _address Address of the tokens owner
    /// @param _tokenId Token id
    /// @return The pending balance(without recovery decimals) can be withdrawn
    function getPendingBalance(bytes32 _address, uint16 _tokenId) external view returns (uint128) {
        return pendingBalances[_address][_tokenId];
    }
    // =======================Governance interface======================

    /// @notice Change current governor
    /// @param _newGovernor Address of the new governor
    function changeGovernor(address _newGovernor) external onlyGovernor {
        require(_newGovernor != address(0), "H");
        if (networkGovernor != _newGovernor) {
            networkGovernor = _newGovernor;
            emit NewGovernor(_newGovernor);
        }
    }

    /// @notice Add token to the list of networks tokens
    /// @param _tokenId Token id
    /// @param _tokenAddress Token address
    /// @param _decimals Token decimals of layer one
    function addToken(uint16 _tokenId, address _tokenAddress, uint8 _decimals) external onlyGovernor {
        // token id MUST be in a valid range
        require(_tokenId > 0 && _tokenId <= MAX_AMOUNT_OF_REGISTERED_TOKENS, "I0");
        // token MUST be not zero address
        require(_tokenAddress != address(0), "I1");
        // token decimals of layer one MUST not be larger than decimals defined in layer two
        require(_decimals <= TOKEN_DECIMALS_OF_LAYER2, "I2");

        RegisteredToken memory rt = tokens[_tokenId];
        rt.registered = true;
        rt.tokenAddress = _tokenAddress;
        rt.decimals = _decimals;
        tokens[_tokenId] = rt;
        tokenIds[_tokenAddress] = _tokenId;
        emit NewToken(_tokenId, _tokenAddress, _decimals);
    }

    /// @notice Pause token deposits for the given token
    /// @param _tokenId Token id
    /// @param _tokenPaused Token paused status
    function setTokenPaused(uint16 _tokenId, bool _tokenPaused) external onlyGovernor {
        RegisteredToken storage rt = tokens[_tokenId];
        require(rt.registered, "K");

        if (rt.paused != _tokenPaused) {
            rt.paused = _tokenPaused;
            emit TokenPausedUpdate(_tokenId, _tokenPaused);
        }
    }

    /// @notice Change validator status (active or not active)
    /// @param _validator Validator address
    /// @param _active Active flag
    function setValidator(address _validator, bool _active) external onlyGovernor {
        if (validators[_validator] != _active) {
            validators[_validator] = _active;
            emit ValidatorStatusUpdate(_validator, _active);
        }
    }

    /// @notice Set sync service address
    /// @param _chainId zkLink chain id
    /// @param _syncService new sync service address
    function setSyncService(uint8 _chainId, ISyncService _syncService) external onlyGovernor {
        ISyncService oldSyncService = chainSyncServiceMap[_chainId];
        if (address(oldSyncService) != address(0)) {
            syncServiceMap[address(oldSyncService)] = false;
        }
        chainSyncServiceMap[_chainId] = _syncService;
        syncServiceMap[address(_syncService)] = true;
        emit SetSyncService(_chainId, address(_syncService));
    }

    /// @notice Set gateway address
    /// @param _gateway gateway address
    function setGateway(IL2Gateway _gateway) external onlyGovernor {
        gateway = _gateway;
        emit SetGateway(address(_gateway));
    }

    // =======================Block interface======================

    /// @notice Recursive proof input data (individual commitments are constructed onchain)
    struct ProofInput {
        uint256[] recursiveInput;
        uint256[] proof;
        uint256[] commitments;
        uint8[] vkIndexes;
        uint256[16] subproofsLimbs;
    }

    /// @notice Blocks commitment verification.
    /// @dev Only verifies block commitments without any other processing
    function proveBlocks(StoredBlockInfo[] memory _committedBlocks, ProofInput memory _proof) external nonReentrant {
        // ===Checks===
        uint32 currentTotalBlocksProven = totalBlocksProven;
        for (uint256 i = 0; i < _committedBlocks.length; ++i) {
            currentTotalBlocksProven = currentTotalBlocksProven + 1;
            require(hashStoredBlockInfo(_committedBlocks[i]) == storedBlockHashes[currentTotalBlocksProven], "x0");

            // commitment of proof produced by zk has only 253 significant bits
            // 'commitment & INPUT_MASK' is used to set the highest 3 bits to 0 and leave the rest unchanged
            require(_proof.commitments[i] <= MAX_PROOF_COMMITMENT
                && _proof.commitments[i] == uint256(_committedBlocks[i].commitment) & INPUT_MASK, "x1");
        }

        // ===Effects===
        require(currentTotalBlocksProven <= totalBlocksCommitted, "x2");
        totalBlocksProven = currentTotalBlocksProven;

        // ===Interactions===
        bool success = verifier.verifyAggregatedBlockProof(
            _proof.recursiveInput,
            _proof.proof,
            _proof.vkIndexes,
            _proof.commitments,
            _proof.subproofsLimbs
        );
        require(success, "x3");

        emit BlockProven(currentTotalBlocksProven);

    }

    /// @notice Reverts unExecuted blocks
    function revertBlocks(StoredBlockInfo[] memory _blocksToRevert) external onlyValidator nonReentrant {
        uint32 blocksCommitted = totalBlocksCommitted;
        uint32 blocksToRevert = Utils.minU32(SafeCast.toUint32(_blocksToRevert.length), blocksCommitted - totalBlocksExecuted);
        uint64 revertedPriorityRequests = 0;

        for (uint32 i = 0; i < blocksToRevert; ++i) {
            StoredBlockInfo memory storedBlockInfo = _blocksToRevert[i];
            require(storedBlockHashes[blocksCommitted] == hashStoredBlockInfo(storedBlockInfo), "c"); // incorrect stored block info

            delete storedBlockHashes[blocksCommitted];

            --blocksCommitted;
            revertedPriorityRequests = revertedPriorityRequests + storedBlockInfo.priorityOperations;
        }

        totalBlocksCommitted = blocksCommitted;
        totalCommittedPriorityRequests = totalCommittedPriorityRequests - revertedPriorityRequests;
        if (totalBlocksCommitted < totalBlocksProven) {
            totalBlocksProven = totalBlocksCommitted;
        }
        if (totalBlocksProven < totalBlocksSynchronized) {
            totalBlocksSynchronized = totalBlocksProven;
        }

        emit BlocksRevert(totalBlocksExecuted, blocksCommitted);
    }


    // =======================Cross chain block synchronization======================
    function receiveSyncHash(uint8 chainId, bytes32 syncHash) external onlySyncService {
        synchronizedChains[chainId] = syncHash;
        emit ReceiveSlaverSyncHash(chainId, syncHash);
    }

    /// @notice Check if received all syncHash from other chains at the block height
    function isBlockConfirmable(StoredBlockInfo memory _block) public view returns (bool) {
        uint32 blockNumber = _block.blockNumber;
        if (!(blockNumber > totalBlocksSynchronized && blockNumber <= totalBlocksProven)) {
            return false;
        }
        if (hashStoredBlockInfo(_block) != storedBlockHashes[blockNumber]) {
            return false;
        }
        for (uint8 i = 0; i < _block.syncHashs.length; ++i) {
            SyncHash memory sync = _block.syncHashs[i];
            bytes32 remoteSyncHash = synchronizedChains[sync.chainId];
            if (remoteSyncHash == bytes32(0)) {
                remoteSyncHash = EMPTY_STRING_KECCAK;
            }
            if (remoteSyncHash != sync.syncHash) {
                return false;
            }
        }
        return true;
    }

    function estimateConfirmBlockFee(uint32 blockNumber) external view returns (uint totalNativeFee) {
        totalNativeFee = 0;
        for (uint8 chainId = MIN_CHAIN_ID; chainId <= MAX_CHAIN_ID; ++chainId) {
            uint256 chainIndex = 1 << chainId - 1;
            if (chainIndex & ALL_CHAINS == chainIndex) {
                if (chainId == MASTER_CHAIN_ID) {
                    continue;
                }
                ISyncService syncService = chainSyncServiceMap[chainId];
                uint nativeFee = syncService.estimateConfirmBlockFee(chainId, blockNumber);
                totalNativeFee += nativeFee;
            }
        }
    }

    /// @notice Send block confirmation message to all other slaver chains at the block height
    function confirmBlock(StoredBlockInfo memory _block) external onlyValidator payable {
        require(isBlockConfirmable(_block), "n0");

        // send confirm message to slaver chains
        uint32 blockNumber = _block.blockNumber;
        uint256 leftMsgValue = msg.value;
        for (uint8 chainId = MIN_CHAIN_ID; chainId <= MAX_CHAIN_ID; ++chainId) {
            uint256 chainIndex = 1 << chainId - 1;
            if (chainIndex & ALL_CHAINS == chainIndex) {
                if (chainId == MASTER_CHAIN_ID) {
                    continue;
                }
                ISyncService syncService = chainSyncServiceMap[chainId];
                uint nativeFee = syncService.estimateConfirmBlockFee(chainId, blockNumber);
                require(leftMsgValue >= nativeFee, "n1");
                syncService.confirmBlock{value:nativeFee}(chainId, blockNumber);
                leftMsgValue -= nativeFee;
            }
        }
        if (leftMsgValue > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = msg.sender.call{value: leftMsgValue}("");
            require(success, "n2");
        }

        totalBlocksSynchronized = blockNumber;
        emit BlockSynced(blockNumber);
    }



    // =======================Withdraw to L1======================
    /// @notice Estimate the fee to withdraw token to L1 for user by gateway
    function estimateWithdrawToL1Fee(address owner, address token, uint128 amount, uint16 fastWithdrawFeeRate, uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce) public view returns (uint256 nativeFee) {
        if (token == ETH_ADDRESS) {
            nativeFee = gateway.estimateWithdrawETHFee(owner, amount, accountIdOfNonce, subAccountIdOfNonce, nonce, fastWithdrawFeeRate);
        } else {
            nativeFee = gateway.estimateWithdrawERC20Fee(owner, token, amount, accountIdOfNonce, subAccountIdOfNonce, nonce, fastWithdrawFeeRate);
        }
    }

    /// @notice Withdraw token to L1 for user by gateway
    /// @param owner User receive token on L1
    /// @param token Token address
    /// @param amount The amount(recovered decimals) of withdraw operation
    /// @param fastWithdrawFeeRate Fast withdraw fee rate taken by acceptor
    /// @param accountIdOfNonce Account that supply nonce, may be different from accountId
    /// @param subAccountIdOfNonce SubAccount that supply nonce
    /// @param nonce SubAccount nonce, used to produce unique accept info
    function withdrawToL1(address owner, address token, uint128 amount, uint16 fastWithdrawFeeRate, uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce) external payable nonReentrant {
        // ===Checks===
        // ensure withdraw data is not executed
        bytes32 withdrawHash = getWithdrawHash(accountIdOfNonce, subAccountIdOfNonce, nonce, owner, token, amount, fastWithdrawFeeRate);
        require(pendingL1Withdraws[withdrawHash] == true, "M0");

        // ensure supply fee
        uint256 fee = estimateWithdrawToL1Fee(owner, token, amount, fastWithdrawFeeRate, accountIdOfNonce, subAccountIdOfNonce, nonce);
        require(msg.value >= fee, "M1");

        // ===Effects===
        pendingL1Withdraws[withdrawHash] = false;

        // ===Interactions===
        // transfer token to gateway
        // send msg.value as bridge fee to gateway
        if (token == ETH_ADDRESS) {
            gateway.withdrawETH{value: fee + amount}(owner, amount, accountIdOfNonce, subAccountIdOfNonce, nonce, fastWithdrawFeeRate);
        } else {
            IERC20(token).safeApprove(address(gateway), amount);
            gateway.withdrawERC20{value: fee}(owner, token, amount, accountIdOfNonce, subAccountIdOfNonce, nonce, fastWithdrawFeeRate);
        }

        uint256 leftMsgValue = msg.value - fee;
        if (leftMsgValue > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = msg.sender.call{value: leftMsgValue}("");
            require(success, "M2");
        }

        emit WithdrawalL1(withdrawHash);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



// Functions named bytesToX, except bytesToBytes20, where X is some type of size N < 32 (size of one word)
// implements the following algorithm:
// f(bytes memory input, uint offset) -> X out
// where byte representation of out is N bytes from input at the given offset
// 1) We compute memory location of the word W such that last N bytes of W is input[offset..offset+N]
// W_address = input + 32 (skip stored length of bytes) + offset - (32 - N) == input + offset + N
// 2) We load W from memory into out, last N bytes of W are placed into out

library Bytes {
    function toBytesFromUInt16(uint16 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 2);
    }

    function toBytesFromUInt24(uint24 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 3);
    }

    function toBytesFromUInt32(uint32 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 4);
    }

    function toBytesFromUInt128(uint128 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 16);
    }

    // Copies 'len' lower bytes from 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length 'len'.
    function toBytesFromUIntTruncated(uint256 self, uint8 byteLength) private pure returns (bytes memory bts) {
        require(byteLength <= 32, "Q");
        bts = new bytes(byteLength);
        // Even though the bytes will allocate a full word, we don't want
        // any potential garbage bytes in there.
        uint256 data = self << ((32 - byteLength) * 8);
        assembly {
            mstore(
            add(bts, 32), // BYTES_HEADER_SIZE
            data
            )
        }
    }

    // Copies 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length '20'.
    function toBytesFromAddress(address self) internal pure returns (bytes memory bts) {
        bts = toBytesFromUIntTruncated(uint256(uint160(self)), 20);
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToAddress(bytes memory self, uint256 _start) internal pure returns (address addr) {
        uint256 offset = _start + 20;
        require(self.length >= offset, "R");
        assembly {
            addr := mload(add(self, offset))
        }
    }

    // Reasoning about why this function works is similar to that of other similar functions, except NOTE below.
    // NOTE: that bytes1..32 is stored in the beginning of the word unlike other primitive types
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToBytes20(bytes memory self, uint256 _start) internal pure returns (bytes20 r) {
        require(self.length >= (_start + 20), "S");
        assembly {
            r := mload(add(add(self, 0x20), _start))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x2)
    function bytesToUInt16(bytes memory _bytes, uint256 _start) internal pure returns (uint16 r) {
        uint256 offset = _start + 0x2;
        require(_bytes.length >= offset, "T");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x3)
    function bytesToUInt24(bytes memory _bytes, uint256 _start) internal pure returns (uint24 r) {
        uint256 offset = _start + 0x3;
        require(_bytes.length >= offset, "U");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x4)
    function bytesToUInt32(bytes memory _bytes, uint256 _start) internal pure returns (uint32 r) {
        uint256 offset = _start + 0x4;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x10)
    function bytesToUInt128(bytes memory _bytes, uint256 _start) internal pure returns (uint128 r) {
        uint256 offset = _start + 0x10;
        require(_bytes.length >= offset, "W");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x14)
    function bytesToUInt160(bytes memory _bytes, uint256 _start) internal pure returns (uint160 r) {
        uint256 offset = _start + 0x14;
        require(_bytes.length >= offset, "X");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x20)
    function bytesToBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32 r) {
        uint256 offset = _start + 0x20;
        require(_bytes.length >= offset, "Y");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // Original source code: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol#L228
    // Get slice from bytes arrays
    // Returns the newly created 'bytes memory'
    // NOTE: theoretically possible overflow of (_start + _length)
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_bytes.length >= (_start + _length), "Z"); // bytes length is less then start byte + length bytes

        bytes memory tempBytes = new bytes(_length);

        if (_length != 0) {
            assembly {
                let slice_curr := add(tempBytes, 0x20)
                let slice_end := add(slice_curr, _length)

                for {
                    let array_current := add(_bytes, add(_start, 0x20))
                } lt(slice_curr, slice_end) {
                    slice_curr := add(slice_curr, 0x20)
                    array_current := add(array_current, 0x20)
                } {
                    mstore(slice_curr, mload(array_current))
                }
            }
        }

        return tempBytes;
    }

    /// Reads byte stream
    /// @return newOffset - offset + amount of bytes read
    /// @return data - actually read data
    // NOTE: theoretically possible overflow of (_offset + _length)
    function read(
        bytes memory _data,
        uint256 _offset,
        uint256 _length
    ) internal pure returns (uint256 newOffset, bytes memory data) {
        data = slice(_data, _offset, _length);
        newOffset = _offset + _length;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readBool(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, bool r) {
        newOffset = _offset + 1;
        r = uint8(_data[_offset]) != 0;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readUint8(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint8 r) {
        newOffset = _offset + 1;
        r = uint8(_data[_offset]);
    }

    // NOTE: theoretically possible overflow of (_offset + 2)
    function readUInt16(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint16 r) {
        newOffset = _offset + 2;
        r = bytesToUInt16(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 3)
    function readUInt24(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint24 r) {
        newOffset = _offset + 3;
        r = bytesToUInt24(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 4)
    function readUInt32(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint32 r) {
        newOffset = _offset + 4;
        r = bytesToUInt32(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 16)
    function readUInt128(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint128 r) {
        newOffset = _offset + 16;
        r = bytesToUInt128(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readUInt160(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint160 r) {
        newOffset = _offset + 20;
        r = bytesToUInt160(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readAddress(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, address r) {
        newOffset = _offset + 20;
        r = bytesToAddress(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readBytes20(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, bytes20 r) {
        newOffset = _offset + 20;
        r = bytesToBytes20(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 32)
    function readBytes32(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, bytes32 r) {
        newOffset = _offset + 32;
        r = bytesToBytes32(_data, _offset);
    }

    /// Trim bytes into single word
    function trim(bytes memory _data, uint256 _newLength) internal pure returns (uint256 r) {
        require(_newLength <= 0x20, "10"); // new_length is longer than word
        require(_data.length >= _newLength, "11"); // data is to short

        uint256 a;
        assembly {
            a := mload(add(_data, 0x20)) // load bytes into uint256
        }

        return a >> ((0x20 - _newLength) * 8);
    }

    // Helper function for hex conversion.
    function halfByteToHex(bytes1 _byte) internal pure returns (bytes1 _hexByte) {
        require(uint8(_byte) < 0x10, "hbh11"); // half byte's value is out of 0..15 range.

        // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
        return bytes1(uint8(0x66656463626139383736353433323130 >> (uint8(_byte) * 8)));
    }

    // Convert bytes to ASCII hex representation
    function bytesToHexASCIIBytes(bytes memory _input) internal pure returns (bytes memory _output) {
        bytes memory outStringBytes = new bytes(_input.length * 2);

        // code in `assembly` construction is equivalent of the next code:
        // for (uint i = 0; i < _input.length; ++i) {
        //     outStringBytes[i*2] = halfByteToHex(_input[i] >> 4);
        //     outStringBytes[i*2+1] = halfByteToHex(_input[i] & 0x0f);
        // }
        assembly {
            let input_curr := add(_input, 0x20)
            let input_end := add(input_curr, mload(_input))

            for {
                let out_curr := add(outStringBytes, 0x20)
            } lt(input_curr, input_end) {
                input_curr := add(input_curr, 0x01)
                out_curr := add(out_curr, 0x02)
            } {
                let curr_input_byte := shr(0xf8, mload(input_curr))
            // here outStringByte from each half of input byte calculates by the next:
            //
            // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
            // outStringByte = byte (uint8 (0x66656463626139383736353433323130 >> (uint8 (_byteHalf) * 8)))
                mstore(
                out_curr,
                shl(0xf8, shr(mul(shr(0x04, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
                mstore(
                add(out_curr, 0x01),
                shl(0xf8, shr(mul(and(0x0f, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
            }
        }
        return outStringBytes;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title zkSync configuration constants
/// @author Matter Labs
contract Config {
    /// @dev Default fee address in state
    address public constant DEFAULT_FEE_ADDRESS = 0x374632e7D48B7872d904524FdC5Dd4516F42cDFF;

    bytes32 internal constant EMPTY_STRING_KECCAK = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    /// @dev Bytes in one chunk
    uint8 internal constant CHUNK_BYTES = 23;

    /// @dev Bytes of L2 PubKey hash
    uint8 internal constant PUBKEY_HASH_BYTES = 20;

    /// @dev Max amount of tokens registered in the network
    uint16 internal constant MAX_AMOUNT_OF_REGISTERED_TOKENS = 65535;

    /// @dev Max account id that could be registered in the network
    uint32 internal constant MAX_ACCOUNT_ID = 16777215;

    /// @dev Max sub account id that could be bound to account id
    uint8 internal constant MAX_SUB_ACCOUNT_ID = 31;

    /// @dev Expected average period of block creation
    uint256 internal constant BLOCK_PERIOD = 12 seconds;

    /// @dev Operation chunks
    uint256 internal constant DEPOSIT_BYTES = 3 * CHUNK_BYTES;
    uint256 internal constant FULL_EXIT_BYTES = 3 * CHUNK_BYTES;
    uint256 internal constant WITHDRAW_BYTES = 5 * CHUNK_BYTES;
    uint256 internal constant FORCED_EXIT_BYTES = 3 * CHUNK_BYTES;
    uint256 internal constant CHANGE_PUBKEY_BYTES = 3 * CHUNK_BYTES;

    /// @dev Expiration delta for priority request to be satisfied (in seconds)
    /// @dev NOTE: Priority expiration should be > (EXPECT_VERIFICATION_IN * BLOCK_PERIOD)
    /// @dev otherwise incorrect block with priority op could not be reverted.
    uint256 internal constant PRIORITY_EXPIRATION_PERIOD = 14 days;

    /// @dev Expiration delta for priority request to be satisfied (in ETH blocks)
    uint256 internal constant PRIORITY_EXPIRATION =
        2592000;

    /// @dev Reserved time for users to send full exit priority operation in case of an upgrade (in seconds)
    uint256 internal constant MASS_FULL_EXIT_PERIOD = 5 days;

    /// @dev Reserved time for users to withdraw funds from full exit priority operation in case of an upgrade (in seconds)
    uint256 internal constant TIME_TO_WITHDRAW_FUNDS_FROM_FULL_EXIT = 2 days;

    /// @dev Notice period before activation preparation status of upgrade mode (in seconds)
    /// @dev NOTE: we must reserve for users enough time to send full exit operation, wait maximum time for processing this operation and withdraw funds from it.
    uint256 internal constant UPGRADE_NOTICE_PERIOD =
        0;

    /// @dev Max commitment produced in zk proof where highest 3 bits is 0
    uint256 internal constant MAX_PROOF_COMMITMENT = 0x1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @dev Bit mask to apply for verifier public input before verifying.
    uint256 internal constant INPUT_MASK = 14474011154664524427946373126085988481658748083205070504932198000989141204991;

    /// @dev Auth fact reset timelock
    uint256 internal constant AUTH_FACT_RESET_TIMELOCK = 1 days;

    /// @dev Max deposit of ERC20 token that is possible to deposit
    uint128 internal constant MAX_DEPOSIT_AMOUNT = 20282409603651670423947251286015;

    /// @dev Chain id defined by ZkLink
    uint8 public constant CHAIN_ID = 9;

    /// @dev Min chain id defined by ZkLink
    uint8 public constant MIN_CHAIN_ID = 1;

    /// @dev Max chain id defined by ZkLink
    uint8 public constant MAX_CHAIN_ID = 9;

    /// @dev All chain index, for example [1, 2, 3, 4] => 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 = 15
    uint256 public constant ALL_CHAINS = 268;

    /// @dev Master chain id defined by ZkLink
    uint8 public constant MASTER_CHAIN_ID = 9;

    /// @dev NONE, ORIGIN, NEXUS
    uint8 internal constant SYNC_TYPE = 1;
    uint8 internal constant SYNC_NONE = 0;
    uint8 internal constant SYNC_ORIGIN = 1;
    uint8 internal constant SYNC_NEXUS = 2;

    /// @dev Token decimals is a fixed value at layer two in ZkLink
    uint8 internal constant TOKEN_DECIMALS_OF_LAYER2 = 18;

    /// @dev The default fee account id
    uint32 internal constant DEFAULT_FEE_ACCOUNT_ID = 0;

    /// @dev Global asset account in the network
    /// @dev Can not deposit to or full exit this account
    uint32 internal constant GLOBAL_ASSET_ACCOUNT_ID = 1;
    bytes32 internal constant GLOBAL_ASSET_ACCOUNT_ADDRESS = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @dev USD and USD stable tokens defined by zkLink
    /// @dev User can deposit USD stable token(eg. USDC, BUSD) to get USD in layer two
    /// @dev And user also can full exit USD in layer two and get back USD stable tokens
    uint16 internal constant USD_TOKEN_ID = 1;
    uint16 internal constant MIN_USD_STABLE_TOKEN_ID = 17;
    uint16 internal constant MAX_USD_STABLE_TOKEN_ID = 31;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Upgradeable.sol";
import "./Operations.sol";

/// @title zkSync events
/// @author Matter Labs
interface Events {
    /// @notice Event emitted when a block is committed
    event BlockCommit(uint32 indexed blockNumber);

    /// @notice Event emitted when a block is proven
    event BlockProven(uint32 indexed blockNumber);

    /// @notice Event emitted when a block is synced
    event BlockSynced(uint32 indexed blockNumber);

    /// @notice Event emitted when a block is executed
    event BlockExecuted(uint32 indexed blockNumber);

    /// @notice Event emitted when user funds are withdrawn from the zkLink state and contract
    event Withdrawal(uint16 indexed tokenId, uint128 amount);

    /// @notice Event emitted when user funds are withdrawn from the zkLink state but not from contract
    event WithdrawalPending(uint16 indexed tokenId, bytes32 indexed recepient, uint128 amount);

    /// @notice Event emitted when user funds are withdrawn from the zkLink state to a target contract
    event WithdrawalCall(bytes32 indexed withdrawHash);

    /// @notice Event emitted when user funds are withdrawn from the zkLink state to L1 and contract
    event WithdrawalL1(bytes32 indexed withdrawHash);

    /// @notice Event emitted when user funds are withdrawn from the zkLink state to L1 but not from contract
    event WithdrawalPendingL1(bytes32 indexed withdrawHash);

    /// @notice Event emitted when user sends a authentication fact (e.g. pub-key hash)
    event FactAuth(address indexed sender, uint32 nonce, bytes fact);

    /// @notice Event emitted when authentication fact reset clock start
    event FactAuthResetTime(address indexed sender, uint32 nonce, uint256 time);

    /// @notice Event emitted when blocks are reverted
    event BlocksRevert(uint32 totalBlocksVerified, uint32 totalBlocksCommitted);

    /// @notice Exodus mode entered event
    event ExodusMode();

    /// @notice New priority request event. Emitted when a request is placed into mapping
    event NewPriorityRequest(
        address sender,
        uint64 serialId,
        Operations.OpType opType,
        bytes pubData,
        uint256 expirationBlock
    );

    /// @notice Token added to ZkLink net
    /// @dev log token decimals on this chain to let L2 know(token decimals maybe different on different chains)
    event NewToken(uint16 indexed tokenId, address indexed token, uint8 decimals);

    /// @notice Governor changed
    event NewGovernor(address newGovernor);

    /// @notice Validator's status changed
    event ValidatorStatusUpdate(address indexed validatorAddress, bool isActive);

    /// @notice Token pause status update
    event TokenPausedUpdate(uint16 indexed token, bool paused);

    /// @notice Sync service changed
    event SetSyncService(uint8 chainId, address newSyncService);

    /// @notice Gateway address changed
    event SetGateway(address indexed newGateway);

    /// @notice Event emitted when send sync hash to master chain
    event SendSlaverSyncHash(bytes32 syncHash);

    /// @notice Event emitted when send sync hash to arbitration
    event SendMasterSyncHash(uint32 blockNumber, bytes32 syncHash);

    /// @notice Event emitted when receive sync hash from a slaver chain
    event ReceiveSlaverSyncHash(uint8 slaverChainId, bytes32 syncHash);
}

/// @title Upgrade events
/// @author Matter Labs
interface UpgradeEvents {
    /// @notice Event emitted when new upgradeable contract is added to upgrade gatekeeper's list of managed contracts
    event NewUpgradable(uint256 indexed versionId, address indexed upgradeable);

    /// @notice Upgrade mode enter event
    event NoticePeriodStart(
        uint256 indexed versionId,
        address[] newTargets,
        uint256 noticePeriod // notice period (in seconds)
    );

    /// @notice Upgrade mode cancel event
    event UpgradeCancel(uint256 indexed versionId);

    /// @notice Upgrade mode complete event
    event UpgradeComplete(uint256 indexed versionId, address[] newTargets);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Bytes.sol";
import "./Utils.sol";

/// @title zkSync operations tools
/// @dev Circuit ops and their pubdata (chunks * bytes)
library Operations {
    /// @dev zkSync circuit operation type
    enum OpType {
        Noop, // 0
        Deposit, // 1 L1 Op
        TransferToNew, // 2 L2 Op
        Withdraw, // 3 L2 Op
        Transfer, // 4 L2 Op
        FullExit, // 5 L1 Op
        ChangePubKey, // 6 L2 Op
        ForcedExit, // 7 L2 Op
        OrderMatching, // 8 L2 Op
        ContractMatching, // 9 L2 Op
        Liquidation, // 10 L2 Op
        AutoDeleveraging, // 11 L2 Op
        UpdateGlobalVar, // 12 L2 Op
        Funding // 13 L2 Op
    }

    // Byte lengths

    /// @dev op is uint8
    uint8 internal constant OP_TYPE_BYTES = 1;

    /// @dev chainId is uint8
    uint8 internal constant CHAIN_BYTES = 1;

    /// @dev token is uint16
    uint8 internal constant TOKEN_BYTES = 2;

    /// @dev nonce is uint32
    uint8 internal constant NONCE_BYTES = 4;

    /// @dev address is 20 bytes length
    uint8 internal constant ADDRESS_BYTES = 20;

    /// @dev address prefix zero bytes length
    uint8 internal constant ADDRESS_PREFIX_ZERO_BYTES = 12;

    /// @dev fee is uint16
    uint8 internal constant FEE_BYTES = 2;

    /// @dev accountId is uint32
    uint8 internal constant ACCOUNT_ID_BYTES = 4;

    /// @dev subAccountId is uint8
    uint8 internal constant SUB_ACCOUNT_ID_BYTES = 1;

    /// @dev amount is uint128
    uint8 internal constant AMOUNT_BYTES = 16;

    /// @dev Priority hash bytes length
    uint256 internal constant DEPOSIT_CHECK_BYTES = 55;
    uint256 internal constant FULL_EXIT_CHECK_BYTES = 43;

    // Priority operations: Deposit, FullExit
    struct PriorityOperation {
        bytes20 hashedPubData; // hashed priority operation public data
        uint64 expirationBlock; // expiration block number (ETH block) for this request (must be satisfied before)
        OpType opType; // priority operation type
    }

    struct Deposit {
        // uint8 opType
        uint8 chainId; // deposit from which chain that identified by L2 chain id
        uint8 subAccountId; // the sub account is bound to account, default value is 0(the global public sub account)
        uint16 tokenId; // the token that registered to L2
        uint16 targetTokenId; // the token that user increased in L2
        uint128 amount; // the token amount deposited to L2
        bytes32 owner; // the address that receive deposited token at L2
        uint32 accountId; // the account id bound to the owner address, ignored at serialization and will be set when the block is submitted
    } // 59 bytes

    /// @dev Deserialize deposit pubdata
    function readDepositPubdata(bytes memory _data) internal pure returns (Deposit memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.subAccountId) = Bytes.readUint8(_data, offset);
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);
        (offset, parsed.targetTokenId) = Bytes.readUInt16(_data, offset);
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);
        (offset, parsed.owner) = Bytes.readBytes32(_data, offset);
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);
    }

    /// @dev Serialize deposit pubdata
    function writeDepositPubdataForPriorityQueue(Deposit memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            uint8(OpType.Deposit),
            op.chainId,
            op.subAccountId,
            op.tokenId,
            op.targetTokenId,
            op.amount,
            op.owner,
            uint32(0) // accountId (ignored during hash calculation)
        );
    }

    /// @dev Checks that op pubdata is same as operation in priority queue
    function checkDepositOperation(bytes memory _opPubData, bytes20 hashedPubData) internal pure {
        require(Utils.hashBytesWithSizeToBytes20(_opPubData, DEPOSIT_CHECK_BYTES) == hashedPubData, "OP: invalid deposit hash");
    }

    struct FullExit {
        // uint8 opType
        uint8 chainId; // withdraw to which chain that identified by L2 chain id
        uint32 accountId; // the account id to withdraw from
        uint8 subAccountId; // the sub account is bound to account, default value is 0(the global public sub account)
        //bytes12 addressPrefixZero; -- address bytes length in L2 is 32
        address owner; // the address that own the account at L2
        uint16 tokenId; // the token that withdraw to L1
        uint16 srcTokenId; // the token that deducted in L2
        uint128 amount; // the token amount that fully withdrawn to owner, ignored at serialization and will be set when the block is submitted
    } // 59 bytes

    /// @dev Deserialize fullExit pubdata
    function readFullExitPubdata(bytes memory _data) internal pure returns (FullExit memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);
        (offset, parsed.subAccountId) = Bytes.readUint8(_data, offset);
        offset += ADDRESS_PREFIX_ZERO_BYTES;
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);
        (offset, parsed.srcTokenId) = Bytes.readUInt16(_data, offset);
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);
    }

    /// @dev Serialize fullExit pubdata
    function writeFullExitPubdataForPriorityQueue(FullExit memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            uint8(OpType.FullExit),
            op.chainId,
            op.accountId,
            op.subAccountId,
            bytes12(0), // append 12 zero bytes
            op.owner,
            op.tokenId,
            op.srcTokenId,
            uint128(0) // amount(ignored during hash calculation)
        );
    }

    /// @dev Checks that op pubdata is same as operation in priority queue
    function checkFullExitOperation(bytes memory _opPubData, bytes20 hashedPubData) internal pure {
        require(Utils.hashBytesWithSizeToBytes20(_opPubData, FULL_EXIT_CHECK_BYTES) == hashedPubData, "OP: invalid fullExit hash");
    }

    struct Withdraw {
        //uint8 opType; -- present in pubdata, ignored at serialization
        uint8 chainId; // which chain the withdraw happened
        uint32 accountId; // the account id to withdraw from
        uint8 subAccountId; // the sub account id to withdraw from
        uint16 tokenId; // the token that to withdraw
        //uint16 srcTokenId; -- the token that decreased in L2, present in pubdata, ignored at serialization
        uint128 amount; // the token amount to withdraw
        //uint16 fee; -- present in pubdata, ignored at serialization
        //bytes12 addressPrefixZero; -- address bytes length in L2 is 32
        address owner; // the address to receive token
        uint32 nonce; // the sub account nonce
        uint16 fastWithdrawFeeRate; // fast withdraw fee rate taken by acceptor
        uint8 withdrawToL1; // when this flag is 1, it means withdraw token to L1
        bytes32 dataHash; // the call data for withdraw
    } // 100 bytes

    function readWithdrawPubdata(bytes memory _data) internal pure returns (Withdraw memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);
        (offset, parsed.subAccountId) = Bytes.readUint8(_data, offset);
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);
        offset += TOKEN_BYTES;
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);
        offset += FEE_BYTES;
        offset += ADDRESS_PREFIX_ZERO_BYTES;
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);
        (offset, parsed.nonce) = Bytes.readUInt32(_data, offset);
        (offset, parsed.fastWithdrawFeeRate) = Bytes.readUInt16(_data, offset);
        (offset, parsed.withdrawToL1) = Bytes.readUint8(_data, offset);
        (offset, parsed.dataHash) = Bytes.readBytes32(_data, offset);
    }

    struct ForcedExit {
        //uint8 opType; -- present in pubdata, ignored at serialization
        uint8 chainId; // which chain the force exit happened
        uint32 initiatorAccountId; // the account id of initiator
        uint8 initiatorSubAccountId; // the sub account id of initiator
        uint32 initiatorNonce; // the sub account nonce of initiator
        uint32 targetAccountId; // the account id of target
        //uint8 targetSubAccountId; -- present in pubdata, ignored at serialization
        uint16 tokenId; // the token that to withdraw
        //uint16 srcTokenId; -- the token that decreased in L2, present in pubdata, ignored at serialization
        uint128 amount; // the token amount to withdraw
        uint8 withdrawToL1; // when this flag is 1, it means withdraw token to L1
        //bytes12 addressPrefixZero; -- address bytes length in L2 is 32
        address target; // the address to receive token
    } // 69 bytes

    function readForcedExitPubdata(bytes memory _data) internal pure returns (ForcedExit memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.initiatorAccountId) = Bytes.readUInt32(_data, offset);
        (offset, parsed.initiatorSubAccountId) = Bytes.readUint8(_data, offset);
        (offset, parsed.initiatorNonce) = Bytes.readUInt32(_data, offset);
        (offset, parsed.targetAccountId) = Bytes.readUInt32(_data, offset);
        offset += SUB_ACCOUNT_ID_BYTES;
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);
        offset += TOKEN_BYTES;
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);
        (offset, parsed.withdrawToL1) = Bytes.readUint8(_data, offset);
        offset += ADDRESS_PREFIX_ZERO_BYTES;
        (offset, parsed.target) = Bytes.readAddress(_data, offset);
    }

    // ChangePubKey
    struct ChangePubKey {
        // uint8 opType; -- present in pubdata, ignored at serialization
        uint8 chainId; // which chain to verify(only one chain need to verify for gas saving)
        uint32 accountId; // the account that to change pubkey
        //uint8 subAccountId; -- present in pubdata, ignored at serialization
        bytes20 pubKeyHash; // hash of the new rollup pubkey
        //bytes12 addressPrefixZero; -- address bytes length in L2 is 32
        address owner; // the owner that own this account
        uint32 nonce; // the account nonce
        //uint16 tokenId; -- present in pubdata, ignored at serialization
        //uint16 fee; -- present in pubdata, ignored at serialization
    } // 67 bytes

    function readChangePubKeyPubdata(bytes memory _data) internal pure returns (ChangePubKey memory parsed) {
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);
        offset += SUB_ACCOUNT_ID_BYTES;
        (offset, parsed.pubKeyHash) = Bytes.readBytes20(_data, offset);
        offset += ADDRESS_PREFIX_ZERO_BYTES;
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);
        (offset, parsed.nonce) = Bytes.readUInt32(_data, offset);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    /// @dev Address of lock flag variable.
    /// @dev Flag is placed at random memory location to not interfere with Storage contract.
    uint256 private constant LOCK_FLAG_ADDRESS = 0x8e94fed44239eb2314ab7a406345e6c5a8f0ccedf3b600de3d004e672c33abf4; // keccak256("ReentrancyGuard") - 1;

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/566a774222707e424896c0c390a84dc3c13bdcb2/contracts/security/ReentrancyGuard.sol
    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    function initializeReentrancyGuard() internal {
        uint256 lockSlotOldValue;

        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange every call to nonReentrant
        // will be cheaper.
        assembly {
            lockSlotOldValue := sload(LOCK_FLAG_ADDRESS)
            sstore(LOCK_FLAG_ADDRESS, _NOT_ENTERED)
        }

        // Check that storage slot for reentrancy guard is empty to rule out possibility of double initialization
        require(lockSlotOldValue == 0, "1B");
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        uint256 _status;
        assembly {
            _status := sload(LOCK_FLAG_ADDRESS)
        }

        // On the first call to nonReentrant, _notEntered will be true
        require(_status == _NOT_ENTERED);

        // Any calls to nonReentrant after this point will fail
        assembly {
            sstore(LOCK_FLAG_ADDRESS, _ENTERED)
        }

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        assembly {
            sstore(LOCK_FLAG_ADDRESS, _NOT_ENTERED)
        }
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and then downcasting.
 *
 * _Available since v2.5.0._
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "16");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "17");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "18");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "19");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "1a");
        return uint8(value);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Interface of the upgradeable contract
/// @author Matter Labs
interface Upgradeable {
    /// @notice Upgrades target of upgradeable contract
    /// @param newTarget New target
    function upgradeTarget(address newTarget) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Bytes.sol";

library Utils {
    /// @notice Returns lesser of two values
    function minU32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a < b ? a : b;
    }

    /// @notice Returns lesser of two values
    function minU64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    /// @notice Returns lesser of two values
    function minU128(uint128 a, uint128 b) internal pure returns (uint128) {
        return a < b ? a : b;
    }

    /// @notice Recovers signer's address from ethereum signature for given message
    /// @param _signature 65 bytes concatenated. R (32) + S (32) + V (1)
    /// @param _messageHash signed message hash.
    /// @return address of the signer
    function recoverAddressFromEthSignature(bytes memory _signature, bytes32 _messageHash)
        internal
        pure
        returns (address)
    {
        require(_signature.length == 65, "ut0"); // incorrect signature length

        bytes32 signR;
        bytes32 signS;
        uint8 signV;
        assembly {
            signR := mload(add(_signature, 32))
            signS := mload(add(_signature, 64))
            signV := byte(0, mload(add(_signature, 96)))
        }

        return ecrecover(_messageHash, signV, signR, signS);
    }

    /// @notice Returns new_hash = hash(old_hash + bytes)
    function concatHash(bytes32 _hash, bytes memory _bytes) internal pure returns (bytes32) {
        bytes32 result;
        assembly {
            let bytesLen := add(mload(_bytes), 32)
            mstore(_bytes, _hash)
            result := keccak256(_bytes, bytesLen)
        }
        return result;
    }

    /// @notice Returns new_hash = hash(a + b)
    function concatTwoHash(bytes32 a, bytes32 b) internal pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

    function hashBytesWithSizeToBytes20(bytes memory _bytes, uint256 _size) internal pure returns (bytes20) {
        bytes32 result;
        assembly {
            result := keccak256(add(_bytes, 32), _size)
        }
        return bytes20(uint160(uint256(result)));
    }
}