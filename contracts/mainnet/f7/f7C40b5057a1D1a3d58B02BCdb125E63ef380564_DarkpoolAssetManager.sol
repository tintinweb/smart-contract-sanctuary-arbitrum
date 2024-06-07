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

pragma solidity >=0.8.20;

import {BaseAssetManager} from "./base/BaseAssetManager.sol";
import {DarkpoolInputBuilder} from "./DarkpoolInputBuilder.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title DarkpoolAssetManager
 * @dev Asset manager for deposit/withdrawal/transfer/join/split/join-split.
 */
contract DarkpoolAssetManager is BaseAssetManager, DarkpoolInputBuilder {
    using SafeERC20 for IERC20;

    event Deposit(
        address depositor,
        bytes32 noteOut, 
        uint256 amount, 
        address asset
    );

    event Withdraw(
        bytes32 nullifierIn,
        uint256 amount,
        address asset,
        address recipient
    );

    event Transfer(
        bytes32 nullifierIn, 
        uint256 amount,
        address asset,
        bytes32 noteOut,
        bytes32 noteFooter
    );

    event Split(
        bytes32 nullifierIn,
        bytes32 noteOut1,
        bytes32 noteOut2
    );

    event JoinSplit(
        bytes32 nullifierIn1,
        bytes32 nullifierIn2,
        bytes32 noteOut1,
        bytes32 noteOut2
    );

    event Join(
        bytes32 nullifierIn1,
        bytes32 nullifierIn2,
        bytes32 noteOut1
    );

    constructor(
        address assetPoolERC20,
        address assetPoolERC721,
        address assetPoolETH,
        address verifierHub,
        address relayerHub,
        address feeManager,
        address comlianceManager,
        address merkleTreeOperator,
        address mimc254,
        address initialOwner
    )
        BaseAssetManager(
            assetPoolERC20,
            assetPoolERC721,
            assetPoolETH,
            verifierHub,
            relayerHub,
            feeManager,
            comlianceManager,
            merkleTreeOperator,
            mimc254,
            initialOwner
        )
        DarkpoolInputBuilder(P)
    {}

    /**
     * @dev Function to deposit ERC20 tokens, guarded by the compliance manager.
     * @param _asset Address of the ERC20 token.
     * @param _amount Amount of ERC20 tokens to be deposited.
     * @param _noteCommitment Deposit note for commiting to the merkle tree.
     * @param _proof Deposit proof.
     */
    function depositERC20(
        address _asset,
        uint256 _amount,
        bytes32 _noteCommitment,
        bytes32 _noteFooter,
        bytes calldata _proof
    ) public {
        require(
            _complianceManager.isAuthorized(address(this), msg.sender),
            "BaseAssetManager: invalid credential"
        );
        _validateNoteIsNotCreated(_noteCommitment);
        _validateNoteFooterIsNotUsed(_noteFooter);

        DepositRawInputs memory inputs = DepositRawInputs(
            msg.sender,
            _noteCommitment,
            _asset,
            _amount,
            _noteFooter
        );

        _verifyProof(_proof, _buildDepositInputs(inputs), "deposit");
        _registerNoteFooter(_noteFooter);

        IERC20(_asset).safeTransferFrom(
            msg.sender,
            address(_assetPoolERC20),
            _amount
        );

        _postDeposit(_noteCommitment);

        emit Deposit(msg.sender, _noteCommitment, _amount, _asset);
    }

    /**
     * @dev Function to deposit ETH, guarded by the compliance manager.
     * @param _noteCommitment Deposit note for commiting to the merkle tree.
     * @param _proof Deposit proof.
     */
    function depositETH(
        bytes32 _noteCommitment,
        bytes32 _noteFooter,
        bytes calldata _proof
    ) public payable {
        require(
            _complianceManager.isAuthorized(address(this), msg.sender),
            "BaseAssetManager: invalid credential"
        );
        _validateNoteIsNotCreated(_noteCommitment);
        _validateNoteFooterIsNotUsed(_noteFooter);

        DepositRawInputs memory inputs = DepositRawInputs(
            msg.sender,
            _noteCommitment,
            ETH_ADDRESS,
            msg.value,
            _noteFooter
        );

        _verifyProof(_proof, _buildDepositInputs(inputs), "deposit");
        _registerNoteFooter(_noteFooter);

        (bool success, ) = address(_assetPoolETH).call{value: msg.value}("");
        require(success, "depositETH: transfer failed");

        _postDeposit(_noteCommitment);

        emit Deposit(msg.sender, _noteCommitment, msg.value, ETH_ADDRESS);
    }

    /**
     * @dev Function to withdraw ERC20 tokens, guarded by the compliance manager.
     * @param _asset Address of the ERC20 token.
     * @param _proof Withdraw proof.
     * @param _merkleRoot Merkle root of the merkle tree.
     * @param _nullifier Nullifier of the note to be withdrawn.
     * @param _recipient Address of the recipient.
     * @param _relayer Address of the relayer.
     * @param _amount Amount of ERC20 tokens to be withdrawn.
     * @param _relayerGasFee Gas fee to refund to the relayer.
     */
    function withdrawERC20(
        address _asset,
        bytes calldata _proof,
        bytes32 _merkleRoot,
        bytes32 _nullifier,
        address _recipient,
        address _relayer,
        uint256 _amount,
        uint256 _relayerGasFee
    ) public {
        require(
            _complianceManager.isAuthorized(address(this), _recipient),
            "BaseAssetManager: invalid credential"
        );

        _validateMerkleRootIsAllowed(_merkleRoot);
        _validateNullifierIsNotUsed(_nullifier);
        _validateNullifierIsNotLocked(_nullifier);
        _validateRelayerIsRegistered(_relayer);
        if(msg.sender != _relayer) {
            revert RelayerMismatch();
        }

        WithdrawRawInputs memory inputs = WithdrawRawInputs(
            _recipient,
            _merkleRoot,
            _asset,
            _amount,
            _nullifier,
            _relayer
        );

        _verifyProof(_proof, _buildWithdrawInputs(inputs), "withdraw");

        _postWithdraw(_nullifier);

        _releaseERC20WithFee(
            _asset,
            _recipient,
            _relayer,
            _relayerGasFee,
            _amount
        );

        emit Withdraw(_nullifier, _amount, _asset, _recipient);
    }

    /**
     * @dev Function to withdraw ETH from darkpool, guarded by the compliance manager.
     * @param _proof Withdraw proof.
     * @param _merkleRoot Merkle root of the merkle tree.
     * @param _nullifier Nullifier of the note to be withdrawn.
     * @param _recipient Address of the recipient.
     * @param _relayer Address of the relayer.
     * @param _relayerGasFee Gas fee to refund to the relayer.
     * @param _amount Amount of ETH to be withdrawn.
     */
    function withdrawETH(
        bytes calldata _proof,
        bytes32 _merkleRoot,
        bytes32 _nullifier,
        address payable _recipient,
        address payable _relayer,
        uint256 _relayerGasFee,
        uint256 _amount
    ) public {
        require(
            _complianceManager.isAuthorized(address(this), _recipient),
            "BaseAssetManager: invalid credential"
        );

        _validateMerkleRootIsAllowed(_merkleRoot);
        _validateNullifierIsNotUsed(_nullifier);
        _validateNullifierIsNotLocked(_nullifier);
        _validateRelayerIsRegistered(_relayer);
        if(msg.sender != _relayer) {
            revert RelayerMismatch();
        }

        WithdrawRawInputs memory inputs = WithdrawRawInputs(
            _recipient,
            _merkleRoot,
            ETH_ADDRESS,
            _amount,
            _nullifier,
            _relayer
        );

        _verifyProof(_proof, _buildWithdrawInputs(inputs), "withdraw");
        
        _postWithdraw(_nullifier);

        _releaseETHWithFee(_recipient, _relayer, _relayerGasFee, _amount);

        emit Withdraw(_nullifier, _amount, ETH_ADDRESS, _recipient);
    }

    /**
     * @dev Function to transfer assets within the darkpool.
     * @param _merkleRoot Merkle root of the merkle tree.
     * @param _nullifierIn Nullifier of the input note.
     * @param _noteOut note of the transfee.
     * @param _proof Transfer proof.
     */
    function transfer(
        bytes32 _merkleRoot,
        bytes32 _nullifierIn,
        address _asset,
        uint256 _amount,
        bytes32 _noteOut,
        bytes32 _noteFooter,
        bytes calldata _proof
    ) public {
        _validateMerkleRootIsAllowed(_merkleRoot);
        _validateNullifierIsNotUsed(_nullifierIn);
        _validateNullifierIsNotLocked(_nullifierIn);
        _validateNoteIsNotCreated(_noteOut);
        _validateNoteFooterIsNotUsed(_noteFooter);

        TransferRawInputs memory inputs = TransferRawInputs(
            _merkleRoot,
            _asset,
            _amount,
            _nullifierIn,
            _noteOut,
            _noteFooter
        );

        _verifyProof(_proof, _buildTransferInputs(inputs), "transfer");
        _registerNoteFooter(_noteFooter);
        _postWithdraw(_nullifierIn);
        _postDeposit(_noteOut);

        emit Transfer(
            _nullifierIn,
            _amount,
            _asset,
            _noteOut,
            _noteFooter
        );
    }

    /**
     * @dev Function to split a note into two.
     * @param _merkleRoot Merkle root of the merkle tree.
     * @param _nullifierIn1 Nullifier of the input note.
     * @param _noteOut1 note of the first output note.
     * @param _noteOut2 note of the second output note.
     * @param _proof Split proof.
     */
    function split(
        bytes32 _merkleRoot,
        bytes32 _nullifierIn1,
        bytes32 _noteOut1,
        bytes32 _noteOut2,
        bytes32 _noteFooter1,
        bytes32 _noteFooter2,
        bytes calldata _proof
    ) public payable {
        _validateMerkleRootIsAllowed(_merkleRoot);
        _validateNullifierIsNotUsed(_nullifierIn1);
        _validateNullifierIsNotLocked(_nullifierIn1);
        _validateNoteIsNotCreated(_noteOut1);
        _validateNoteIsNotCreated(_noteOut2);
        _validateNoteFooterIsNotUsed(_noteFooter1);
        _validateNoteFooterIsNotUsed(_noteFooter2);

        if(_noteFooter1 == _noteFooter2) {
            revert NoteFooterDuplicated();
        }

        SplitRawInputs memory inputs = SplitRawInputs(
            _merkleRoot,
            _nullifierIn1,
            _noteOut1,
            _noteOut2,
            _noteFooter1,
            _noteFooter2
        );

        _verifyProof(_proof, _buildSplitInputs(inputs), "split");
        _registerNoteFooter(_noteFooter1);
        _registerNoteFooter(_noteFooter2);
        _postWithdraw(_nullifierIn1);
        _postDeposit(_noteOut1);
        _postDeposit(_noteOut2);

        emit Split(_nullifierIn1, _noteOut1, _noteOut2);
    }

    /**
     * @dev Function to reassemble two notes' assets.
     * @param _merkleRoot Merkle root of the merkle tree.
     * @param _nullifierIn1 Nullifier of the first input note.
     * @param _nullifierIn2 Nullifier of the second input note.
     * @param _noteOut1 note of the first output note.
     * @param _noteOut2 note of the second output note.
     * @param _proof Join proof.
     */
    function joinSplit(
        bytes32 _merkleRoot,
        bytes32 _nullifierIn1,
        bytes32 _nullifierIn2,
        bytes32 _noteOut1,
        bytes32 _noteOut2,
        bytes32 _noteFooter1,
        bytes32 _noteFooter2,
        bytes calldata _proof
    ) public payable {
        _validateMerkleRootIsAllowed(_merkleRoot);
        _validateNullifierIsNotUsed(_nullifierIn1);
        _validateNullifierIsNotUsed(_nullifierIn2);
        _validateNullifierIsNotLocked(_nullifierIn1);
        _validateNullifierIsNotLocked(_nullifierIn2);
        _validateNoteIsNotCreated(_noteOut1);
        _validateNoteIsNotCreated(_noteOut2);
        _validateNoteFooterIsNotUsed(_noteFooter1);
        _validateNoteFooterIsNotUsed(_noteFooter2);

        if (_noteFooter1 == _noteFooter2) {
            revert NoteFooterDuplicated();
        }

        JoinSplitRawInputs memory inputs = JoinSplitRawInputs(
            _merkleRoot,
            _nullifierIn1,
            _nullifierIn2,
            _noteOut1,
            _noteOut2,
            _noteFooter1,
            _noteFooter2
        );

        _verifyProof(_proof, _buildJoinSplitInputs(inputs), "joinSplit");
        _registerNoteFooter(_noteFooter1);
        _registerNoteFooter(_noteFooter2);
        _postWithdraw(_nullifierIn1);
        _postWithdraw(_nullifierIn2);
        _postDeposit(_noteOut1);
        _postDeposit(_noteOut2);

        emit JoinSplit(_nullifierIn1, _nullifierIn2, _noteOut1, _noteOut2);
    }

    /**
     * @dev Function to join two notes into one.
     * @param _merkleRoot Merkle root of the merkle tree.
     * @param _nullifierIn1 Nullifier of the first input note.
     * @param _nullifierIn2 Nullifier of the second input note.
     * @param _noteOut note of the output note.
     * @param _proof Join proof.
     */
    function join(
        bytes32 _merkleRoot,
        bytes32 _nullifierIn1,
        bytes32 _nullifierIn2,
        bytes32 _noteOut,
        bytes32 _noteFooter,
        bytes calldata _proof
    ) public payable {
        _validateMerkleRootIsAllowed(_merkleRoot);
        _validateNullifierIsNotUsed(_nullifierIn1);
        _validateNullifierIsNotUsed(_nullifierIn2);
        _validateNullifierIsNotLocked(_nullifierIn1);
        _validateNullifierIsNotLocked(_nullifierIn2);
        _validateNoteIsNotCreated(_noteOut);
        _validateNoteFooterIsNotUsed(_noteFooter);

        JoinRawInputs memory inputs = JoinRawInputs(
            _merkleRoot,
            _nullifierIn1,
            _nullifierIn2,
            _noteOut,
            _noteFooter
        );

        _verifyProof(_proof, _buildJoinInputs(inputs), "join");

        _registerNoteFooter(_noteFooter);
        _postWithdraw(_nullifierIn1);
        _postWithdraw(_nullifierIn2);
        _postDeposit(_noteOut);

        emit Join(_nullifierIn1, _nullifierIn2, _noteOut);
    }

    /**
     * @dev Function for ORC swapping within the darkpool.
     * @param _merkleRoot Merkle root of the merkle tree.
     * @param _aliceNullifier Nullifier of Alice's note for swapping out.
     * @param _aliceOut note of the assets to be swapped in by Alice.
     * @param _bobNullifier Nullifier of Bob's note for swapping out.
     * @param _bobOut note of the assets to be swapped in by Bob.
     * @param _proof Swap proof.
     
    function swap(
        bytes32 _merkleRoot,
        bytes32 _aliceNullifier,
        bytes32 _aliceOut,
        bytes32 _aliceOutFooter,

        bytes32 _bobNullifier,
        bytes32 _bobOut,
        bytes32 _bobOutFooter,
        bytes calldata _proof
    ) public payable {
        _validateMerkleRootIsAllowed(_merkleRoot);
        _validateNullifierIsNotUsed(_aliceNullifier);
        _validateNullifierIsNotUsed(_bobNullifier);
        _validateNoteIsNotCreated(_aliceOut);
        _validateNoteIsNotCreated(_bobOut);
        _validateNoteFooterIsNotUsed(_aliceOutFooter);
        _validateNoteFooterIsNotUsed(_bobOutFooter);

        SwapRawInputs memory inputs = SwapRawInputs(
            _merkleRoot,
            _aliceNullifier,
            _aliceOut,
            _aliceOutFooter,
            _bobNullifier,
            _bobOut,
            _bobOutFooter
        );

        _verifyProof(_proof, _buildSwapInputs(inputs), "swap");

        _registerNoteFooter(_aliceOutFooter);
        _registerNoteFooter(_bobOutFooter);
        _postWithdraw(_aliceNullifier);
        _postWithdraw(_bobNullifier);
        _postDeposit(_aliceOut);
        _postDeposit(_bobOut);
    }*/
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {BaseInputBuilder} from "./base/BaseInputBuilder.sol";

contract DarkpoolInputBuilder is BaseInputBuilder {
    struct DepositRawInputs {
        address owner;
        bytes32 noteCommitment;
        address asset;
        uint256 amount;
        bytes32 noteFooter;
    }

    struct WithdrawRawInputs {
        address recipient;
        bytes32 merkleRoot;
        address asset;
        uint256 amount;
        bytes32 nullifier;
        address relayer;
    }

    struct TransferRawInputs {
        bytes32 merkleRoot;
        address asset;
        uint256 amount;
        bytes32 nullifierIn;
        bytes32 noteOut;
        bytes32 noteFooter;
    }

    struct SplitRawInputs {
        bytes32 merkleRoot;
        bytes32 nullifierIn1;
        bytes32 noteOut1;
        bytes32 noteOut2;
        bytes32 noteFooter1;
        bytes32 noteFooter2;
    }

    struct JoinSplitRawInputs {
        bytes32 merkleRoot;
        bytes32 nullifierIn1;
        bytes32 nullifierIn2;
        bytes32 noteOut1;
        bytes32 noteOut2;
        bytes32 noteFooter1;
        bytes32 noteFooter2;
    }

    struct JoinRawInputs {
        bytes32 merkleRoot;
        bytes32 nullifierIn1;
        bytes32 nullifierIn2;
        bytes32 noteOut1;
        bytes32 noteFooter1;
    }

    struct SwapRawInputs {
        bytes32 merkleRoot;
        bytes32 aliceNullifier;
        bytes32 aliceOut;
        bytes32 bobNullifier;
        bytes32 bobOut;
        bytes32 aliceNoteFooter;
        bytes32 bobNoteFooter;
    }

    constructor(uint256 primeField) BaseInputBuilder(primeField) {}

    function _buildDepositInputs(
        DepositRawInputs memory _rawInputs
    ) internal pure returns (bytes32[] memory) {
        bytes32[] memory inputs = new bytes32[](5);
        inputs[0] = _bytifyToNoir(_rawInputs.owner);
        inputs[1] = bytes32(_rawInputs.noteCommitment);
        inputs[2] = _bytifyToNoir(_rawInputs.asset);
        inputs[3] = bytes32(_rawInputs.amount);
        inputs[4] = _rawInputs.noteFooter;

        return inputs;
    }

    function _buildWithdrawInputs(
        WithdrawRawInputs memory _rawInputs
    ) internal pure returns (bytes32[] memory) {
        bytes32[] memory inputs = new bytes32[](6);
        inputs[0] = _bytifyToNoir(_rawInputs.recipient);
        inputs[1] = _rawInputs.merkleRoot;
        inputs[2] = _bytifyToNoir(_rawInputs.asset);
        inputs[3] = bytes32(_rawInputs.amount);
        inputs[4] = _rawInputs.nullifier;
        inputs[5] = _bytifyToNoir(_rawInputs.relayer);

        return inputs;
    }

    function _buildTransferInputs(
        TransferRawInputs memory _rawInputs
    ) internal pure returns (bytes32[] memory) {
        bytes32[] memory inputs = new bytes32[](6);
        inputs[0] = _rawInputs.merkleRoot;
        inputs[1] = _bytifyToNoir(_rawInputs.asset);
        inputs[2] = bytes32(_rawInputs.amount);
        inputs[3] = _rawInputs.nullifierIn;
        inputs[4] = _rawInputs.noteOut;
        inputs[5] = _rawInputs.noteFooter;

        return inputs;
    }

    function _buildSplitInputs(
        SplitRawInputs memory _rawInputs
    ) internal pure returns (bytes32[] memory) {
        bytes32[] memory inputs = new bytes32[](6);
        inputs[0] = _rawInputs.merkleRoot;
        inputs[1] = _rawInputs.nullifierIn1;
        inputs[2] = _rawInputs.noteOut1;
        inputs[3] = _rawInputs.noteOut2;
        inputs[4] = _rawInputs.noteFooter1;
        inputs[5] = _rawInputs.noteFooter2;

        return inputs;
    }

    function _buildJoinSplitInputs(
        JoinSplitRawInputs memory _rawInputs
    ) internal pure returns (bytes32[] memory) {
        bytes32[] memory inputs = new bytes32[](7);
        inputs[0] = _rawInputs.merkleRoot;
        inputs[1] = _rawInputs.nullifierIn1;
        inputs[2] = _rawInputs.nullifierIn2;
        inputs[3] = _rawInputs.noteOut1;
        inputs[4] = _rawInputs.noteOut2;
        inputs[5] = _rawInputs.noteFooter1;
        inputs[6] = _rawInputs.noteFooter2;

        return inputs;
    }

    function _buildJoinInputs(
        JoinRawInputs memory _rawInputs
    ) internal pure returns (bytes32[] memory) {
        bytes32[] memory inputs = new bytes32[](5);
        inputs[0] = _rawInputs.merkleRoot;
        inputs[1] = _rawInputs.nullifierIn1;
        inputs[2] = _rawInputs.nullifierIn2;
        inputs[3] = _rawInputs.noteOut1;
        inputs[4] = _rawInputs.noteFooter1;

        return inputs;
    }

    function _buildSwapInputs(
        SwapRawInputs memory _rawInputs
    ) internal pure returns (bytes32[] memory) {
        bytes32[] memory inputs = new bytes32[](7);
        inputs[0] = _rawInputs.merkleRoot;
        inputs[1] = _rawInputs.aliceNullifier;
        inputs[2] = _rawInputs.aliceOut;
        inputs[3] = _rawInputs.aliceNoteFooter;
        inputs[4] = _rawInputs.bobNullifier;
        inputs[5] = _rawInputs.bobOut;
        inputs[6] = _rawInputs.bobNoteFooter;

        return inputs;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAssetPool} from "../interfaces/IAssetPool.sol";
import {IVerifier} from "../interfaces/IVerifier.sol";
import {IVerifierHub} from "../interfaces/IVerifierHub.sol";
import {IRelayerHub} from "../interfaces/IRelayerHub.sol";
import {IFeeManager} from "../interfaces/IFeeManager.sol";
import {IComplianceManager} from "../interfaces/IComplianceManager.sol";
import {IMerkleTreeOperator} from "../interfaces/IMerkleTreeOperator.sol";
import {IMimc254} from "../interfaces/IMimc254.sol";
import {BaseInputBuilder} from "./BaseInputBuilder.sol";

/**
 * @title BaseAssetManager
 * @dev Base contract for asset managers.
 */
abstract contract BaseAssetManager is Ownable, BaseInputBuilder {
    using SafeERC20 for IERC20;

    struct FundReleaseDetails {
        address assetAddress;
        address payable recipient;
        address payable relayer;
        uint256 relayerGasFee;
        uint256 amount;
    }

    IVerifierHub internal _verifierHub;
    IAssetPool internal _assetPoolERC20;
    IAssetPool internal _assetPoolERC721;
    IAssetPool internal _assetPoolETH;
    IRelayerHub internal _relayerHub;
    IFeeManager internal _feeManager;
    IComplianceManager internal _complianceManager;
    IMerkleTreeOperator internal immutable _merkleTreeOperator;
    IMimc254 internal immutable _mimc254;

    address public constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    bytes32 public constant ASSET_ETH = keccak256(abi.encode(ETH_ADDRESS));

    uint256 public constant P =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    error RelayerNotRegistered();
    error NullifierUsed();
    error NullifierLocked();
    error MerkleRootNotAllowed();
    error NoteFooterUsed();
    error NoteAlreadyCreated();
    error InvalidNoteParameters();
    error ZeroAddress();
    error NoteFooterDuplicated();
    error RelayerMismatch();

    // we dont use it for now
    modifier onlyETHAssetPool() {
        require(
            msg.sender == address(_assetPoolETH),
            "BaseAssetManager: Only ETH Asset Pool"
        );
        _;
    }

    constructor(
        address assetPoolERC20,
        address assetPoolERC721,
        address assetPoolETH,
        address verifierHub,
        address relayerHub,
        address feeManager,
        address complianceManager,
        address merkleTreeOperator,
        address mimc254,
        address initialOwner
    ) Ownable(initialOwner) {
        if (assetPoolERC20 == address(0) || 
            assetPoolERC721 == address(0) ||
            assetPoolETH == address(0) ||
            verifierHub == address(0) ||
            relayerHub == address(0) ||
            feeManager == address(0) ||
            complianceManager == address(0) ||
            merkleTreeOperator == address(0) ||
            mimc254 == address(0) ||
            initialOwner == address(0)
            ) {
                revert ZeroAddress();
        }
        _assetPoolERC20 = IAssetPool(assetPoolERC20);
        _assetPoolERC721 = IAssetPool(assetPoolERC721);
        _assetPoolETH = IAssetPool(assetPoolETH);
        _verifierHub = IVerifierHub(verifierHub);
        _relayerHub = IRelayerHub(relayerHub);
        _feeManager = IFeeManager(feeManager);
        _complianceManager = IComplianceManager(complianceManager);
        _merkleTreeOperator = IMerkleTreeOperator(merkleTreeOperator);
        _mimc254 = IMimc254(mimc254);
    }

    receive() external payable {}

    /**
     * @dev Transfers the asset to the asset pool if there are
     *      any remaining assets due to network failures.
     */
    function releaseToAsssetPool(
        address asset,
        uint256 amount
    ) external onlyOwner {
        require(amount > 0, "BaseAssetManager: amount must be greater than 0");
        if (asset == address(0) || asset == ETH_ADDRESS) {
            (bool success, ) = address(_assetPoolETH).call{value: amount}("");
            require(success, "BaseAssetManager: Failed to send Ether");
        } else {
            IERC20(asset).safeTransfer(address(_assetPoolERC20), amount);
        }
    }

    function setAssetPoolERC20(address assetPoolERC20) public onlyOwner {
        if (assetPoolERC20 != address(0)) {
            _assetPoolERC20 = IAssetPool(assetPoolERC20);
        }
    }

    function setAssetPoolERC721(address assetPoolERC721) public onlyOwner {
        if (assetPoolERC721 != address(0)) {
            _assetPoolERC721 = IAssetPool(assetPoolERC721);
        }
    }

    function setAssetPoolETH(address assetPoolETH) public onlyOwner {
        if (assetPoolETH != address(0)) {
            _assetPoolETH = IAssetPool(assetPoolETH);
        }
    }

    function setVerifierHub(address verifierHub) public onlyOwner {
        if (verifierHub != address(0)) {
            _verifierHub = IVerifierHub(verifierHub);
        }
    }

    function setRelayerHub(address relayerHub) public onlyOwner {
        if (relayerHub != address(0)) {
            _relayerHub = IRelayerHub(relayerHub);
        }
    }

    function setFeeManager(address feeManager) public onlyOwner {
        if (feeManager != address(0)) {
            _feeManager = IFeeManager(feeManager);
        }
    }

    function setComplianceManager(address complianceManager) public onlyOwner {
        if (complianceManager != address(0)) {
            _complianceManager = IComplianceManager(complianceManager);
        }
    }

    function getAssetPoolERC20() public view returns (address) {
        return address(_assetPoolERC20);
    }

    function getAssetPoolERC721() public view returns (address) {
        return address(_assetPoolERC721);
    }

    function getAssetPoolETH() public view returns (address) {
        return address(_assetPoolETH);
    }

    function getVerifierHub() public view returns (address) {
        return address(_verifierHub);
    }

    function getRelayerHub() public view returns (address) {
        return address(_relayerHub);
    }

    function getFeeManager() public view returns (address) {
        return address(_feeManager);
    }
    
    function getComplianceManager() public view returns (address) {
        return address(_complianceManager);
    }

    function getMerkleTreeOperator() public view returns (address) {
        return address(_merkleTreeOperator);
    }

    function getMimc254() public view returns (address) {
        return address(_mimc254);
    }

    function _postDeposit(bytes32 _noteCommitment) internal {
        _merkleTreeOperator.setNoteCommitmentCreated(_noteCommitment);
        _merkleTreeOperator.appendMerkleLeaf(bytes32(_noteCommitment));
    }

    function _postWithdraw(bytes32 _nullifier) internal {
        _merkleTreeOperator.setNullifierUsed(_nullifier);
    }

    function _setNullifierLock(bytes32 _nullifier, bool _locked) internal {
        _merkleTreeOperator.setNullifierLocked(_nullifier, _locked);
    } 
    
    function _registerNoteFooter(bytes32 _noteFooter) internal {
        _merkleTreeOperator.setNoteFooterUsed(_noteFooter);
    }

    function _releaseERC20WithFee(
        address _asset,
        address _to,
        address _relayer,
        uint256 _relayerGasFee,
        uint256 _amount
    ) internal returns (uint256, uint256, uint256) {
        (
            uint256 actualAmount,
            uint256 serviceFee,
            uint256 relayerRefund
        ) = _feeManager.calculateFee(_amount, _relayerGasFee);

        _assetPoolERC20.release(_asset, _to, actualAmount);

        if (relayerRefund > 0) {
            _assetPoolERC20.release(_asset, _relayer, relayerRefund);
        }
        if (serviceFee > 0) {
            _assetPoolERC20.release(_asset, address(_feeManager), serviceFee);
        }

        return (actualAmount, serviceFee, relayerRefund);
    }

    function _releaseETHWithFee(
        address payable _to,
        address payable _relayer,
        uint256 _relayerGasFee,
        uint256 _amount
    ) internal returns (uint256, uint256, uint256) {
        (
            uint256 actualAmount,
            uint256 serviceFee,
            uint256 relayerRefund
        ) = _feeManager.calculateFee(_amount, _relayerGasFee);

        _assetPoolETH.release(_to, actualAmount);

        if (relayerRefund > 0) {
            _assetPoolETH.release(_relayer, relayerRefund);
        }
        if (serviceFee > 0) {
            _assetPoolETH.release(payable(address(_feeManager)), serviceFee);
        }

        return (actualAmount, serviceFee, relayerRefund);
    }

    function _releaseFunds(
        FundReleaseDetails memory details
    ) internal returns (uint256, uint256, uint256) {
        if (
            details.assetAddress == ETH_ADDRESS ||
            details.assetAddress == address(0)
        ) {
            return
                _releaseETHWithFee(
                    details.recipient,
                    details.relayer,
                    details.relayerGasFee,
                    details.amount
                );
        } else {
            return
                _releaseERC20WithFee(
                    details.assetAddress,
                    details.recipient,
                    details.relayer,
                    details.relayerGasFee,
                    details.amount
                );
        }
    }

    function _verifyProof(
        bytes calldata _proof,
        bytes32[] memory _inputs,
        string memory verifierType
    ) internal view {
        IVerifier verifier = _verifierHub.getVerifier(verifierType);
        require(verifier.verify(_proof, _inputs), "invalid proof");
    }


    function _buildNoteForERC20(
        address asset,
        uint256 amount,
        bytes32 noteFooter
    ) internal view returns (bytes32) {
        return _buildNote(
            asset,
            amount,
            noteFooter,
            IMimc254.NoteDomainSeparator.FUNGIBLE
        );
    }

    function _buildNoteForERC721(
        address asset,
        uint256 tokenId,
        bytes32 noteFooter
    ) internal view returns (bytes32) {
        return _buildNote(
            asset,
            tokenId,
            noteFooter,
            IMimc254.NoteDomainSeparator.NON_FUNGIBLE
        );
    }

    function _validateRelayerIsRegistered(address relayer) internal view {
        if (!_relayerHub.isRelayerRegistered(relayer)) {
            revert RelayerNotRegistered();
        }
    }

    function _validateNullifierIsNotUsed(bytes32 nullifier) internal view {
        if (!_merkleTreeOperator.nullifierIsNotUsed(nullifier)) {
            revert NullifierUsed();
        }
    }
    
    function _validateNullifierIsNotLocked(bytes32 nullifier) internal view {
        if (!_merkleTreeOperator.nullifierIsNotLocked(nullifier)) {
            revert NullifierLocked();
        }
    }

    function _validateMerkleRootIsAllowed(bytes32 merkleRoot) internal view {
        if (!_merkleTreeOperator.merkleRootIsAllowed(merkleRoot)) {
            revert MerkleRootNotAllowed();
        }
    }

    function _validateNoteFooterIsNotUsed(bytes32 noteFooter) internal view {
        if (!_merkleTreeOperator.noteFooterIsNotUsed(noteFooter)) {
            revert NoteFooterUsed();
        }
    }

    function _validateNoteIsNotCreated(bytes32 noteCommitment) internal view {
        if (!_merkleTreeOperator.noteIsNotCreated(noteCommitment)) {
            revert NoteAlreadyCreated();
        }
    }

    function _buildNote(
        address asset,
        uint256 amount,
        bytes32 noteFooter,
        IMimc254.NoteDomainSeparator domainSeparator
    ) private view returns (bytes32) {
        
        if (asset == address(0) || amount  == 0 || noteFooter == bytes32(0)){
            revert InvalidNoteParameters();
        }
        uint256[] memory array = new uint256[](4);
        array[0] = uint256(domainSeparator);
        array[1] = uint256(_bytifyToNoir(asset));
        array[2] = amount;
        array[3] = uint256(noteFooter);
        return
            bytes32(_mimc254.mimcBn254(array));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title BaseInputBuilder
 * @dev Base contract for ZK verify input builders.
 */
contract BaseInputBuilder {
    uint256 internal _primeField;

    constructor(uint256 primeField) {
        _primeField = primeField;
    }

    function _bytifyToNoir(address value) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(ripemd160(abi.encode(value)))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.20;

interface IAssetPool {
    function setAssetManager(address assetManager,bool registered) external;

    function release(address tokenOrNft, address to, uint256 amountOrNftId) external;

    function release(address payable to, uint256 amount) external;

    function getAssetManagerRegistration( address assetManager) 
        external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.20;


interface IComplianceManager {
    function isAuthorized(address observer, address subject) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.20;

interface IFeeManager {
    function calculateFee(
        uint256 amount,
        uint256 relayerRefund
    ) external view returns (uint256, uint256, uint256);

    function calculateFee(
        uint256[4] calldata amount,
        uint256[4] calldata relayerRefund
    ) external view returns (uint256[4] memory, uint256[4] memory, uint256[4] memory);

    function calculateFeeForFSN(
        uint256[4] calldata amount,
        uint256[4] calldata relayerRefund
    ) external view returns (uint256[] memory, uint256[4] memory, uint256[4] memory);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.20;

interface IMerkleTreeOperator {
    function appendMerkleLeaf(bytes32 leaf) external;
    function setNoteCommitmentCreated(bytes32 commitment) external;
    function setNullifierUsed(bytes32 nullifier) external;
    function setNullifierLocked(bytes32 nullifier, bool locked) external;
    function setNoteFooterUsed(bytes32 noteFooter) external;

    function isRelayerRegistered(address _relayer) external view returns (bool);

    function merkleRootIsAllowed(
        bytes32 _merkleRoot
    ) external view returns (bool);

    function nullifierIsNotUsed(
        bytes32 _nullifier
    ) external view returns (bool);
   
    function nullifierIsNotLocked(
        bytes32 _nullifier
    ) external view returns (bool);

    function noteIsNotCreated(
        bytes32 _noteCommitment
    ) external view returns (bool);

    function noteFooterIsNotUsed(
        bytes32 _noteFooter
    ) external view returns (bool);

    function getMerkleRoot() external view returns (bytes32);

    function getMerklePath(
        bytes32 _noteCommitment
    ) external view returns (bytes32[] memory, bool[] memory, bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.20;


interface IMimc254 {
    enum NoteDomainSeparator {
        FUNGIBLE,
        NON_FUNGIBLE
    }

    function mimcBn254(uint256[] memory array) external view returns (uint256);

    /*function mimcBn254ForNote(
        uint256[3] memory array,
        NoteDomainSeparator domainSeparator
    ) external view returns (uint256);

    function mimcBn254ForTree(
        uint256[3] memory _array
    ) external view returns (uint256);

    function mimcBn254ForRoute(
        uint256[12] memory _array
    ) external view returns (uint256);*/
    
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.20;

interface IRelayerHub {
    function isRelayerRegistered(address _relayer) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.20;

interface IVerifier {
    function verify(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IVerifier} from "./IVerifier.sol";

interface IVerifierHub {
    function setVerifier(string memory verifierName, address addr) external;

    function getVerifierNames() external returns (string[] memory);

    function getVerifier(
        string memory verifierName
    ) external view returns (IVerifier);
}