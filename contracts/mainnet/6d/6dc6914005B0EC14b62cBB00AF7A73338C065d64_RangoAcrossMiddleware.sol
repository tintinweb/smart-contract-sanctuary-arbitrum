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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.25;

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibInterchain.sol";
import "../../interfaces/IRangoMiddlewareWhitelists.sol";

// @title The base contract to be used as a parent of middleware classes
// @author George
// @dev Note that this is not a facet and should be extended and deployed separately.
contract RangoBaseInterchainMiddleware {
    /// @dev keccak256("exchange.rango.middleware.base")
    bytes32 internal constant BASE_MIDDLEWARE_CONTRACT_NAMESPACE = hex"ad914d4300c64e1902ca499875cd8a76ae717047bcfaa9e806ff7ea4f6911268";

    struct BaseInterchainMiddlewareStorage {
        address owner;
    }

    /// Events
    /// @notice Emits when the owner is updated
    /// @param previousOwner The previous owner
    /// @param newOwner The new owner
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /// @notice Notifies that admin manually refunded some money
    /// @param _token The address of refunded token, 0x000..00 address for native token
    /// @param _amount The amount that is refunded
    event Refunded(address _token, uint _amount);

    constructor(){updateOwnerInternal(tx.origin);}

    function initBaseMiddleware(
        address _owner,
        address _whitelistsContract
    ) public onlyOwner {
        require(_owner != address(0));
        updateOwnerInternal(_owner);
        LibInterchain.updateWhitelistsContractAddress(_whitelistsContract);
    }

    /// @notice used to limit access only to owner
    modifier onlyOwner() {
        require(msg.sender == getBaseInterchainMiddlewareStorage().owner, "should be called only by owner");
        _;
    }

    /// @notice used to limit access only to rango diamond
    modifier onlyDiamond() {
        // only used by CBridge for now
        {
            address s = LibInterchain.getLibInterchainStorage().whitelistsStorageContract;
            address rangoDiamond = IRangoMiddlewareWhitelists(s).getRangoDiamond();
            require(msg.sender == rangoDiamond, "should be called only from diamond");
        }
        _;
    }

    /// @notice Enables the contract to receive native ETH token from other contracts including WETH contract
    receive() external payable {}

    /// @notice returns owner of the contract
    /// @return owner address
    function getOwner() external view returns (address) {
        BaseInterchainMiddlewareStorage storage s = getBaseInterchainMiddlewareStorage();
        return s.owner;
    }

    /// @notice returns address of whitelists storage saved in LibInterchain
    /// @return whitelistsStorageContract address
    function getWhitelistsStorageContractAddress() external view returns (address) {
        return LibInterchain.getLibInterchainStorage().whitelistsStorageContract;
    }

    /// Administration & Control
    /// @notice Updates the address of owner
    /// @param newAddress The new address of owner
    function updateOwner(address newAddress) external onlyOwner {
        updateOwnerInternal(newAddress);
    }

    /// @notice updates the address of whitelists storage contract address
    /// @param newAddress the new address for whitelists storage
    function updateWhitelistsContractAddress(address newAddress) external onlyOwner {
        LibInterchain.updateWhitelistsContractAddress(newAddress);
    }

    /// @notice Transfers an ERC20 token from this contract to msg.sender
    /// @dev This endpoint is to return money to a user if we didn't handle failure correctly and the money is still in the contract
    /// @dev Currently the money goes to admin and they should manually transfer it to a wallet later
    /// @param _tokenAddress The address of ERC20 token to be transferred
    /// @param _amount The amount of money that should be transfered
    function refund(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 ercToken = IERC20(_tokenAddress);
        uint balance = ercToken.balanceOf(address(this));
        require(balance >= _amount, 'Insufficient balance');

        SafeERC20.safeTransfer(IERC20(_tokenAddress), msg.sender, _amount);
        emit Refunded(_tokenAddress, _amount);
    }

    /// @notice Transfers the native token from this contract to msg.sender
    /// @dev This endpoint is to return money to a user if we didn't handle failure correctly and the money is still in the contract
    /// @dev Currently the money goes to admin and they should manually transfer it to a wallet later
    /// @param _amount The amount of native token that should be transferred
    function refundNative(uint256 _amount) external onlyOwner {
        uint balance = address(this).balance;
        require(balance >= _amount, 'Insufficient balance');

        (bool sent,) = msg.sender.call{value : _amount}("");
        require(sent, "failed to send native");

        emit Refunded(LibSwapper.ETH, _amount);
    }

    /// Internal and Private functions
    function updateOwnerInternal(address newAddress) private {
        BaseInterchainMiddlewareStorage storage s = getBaseInterchainMiddlewareStorage();
        address oldAddress = s.owner;
        s.owner = newAddress;
        emit OwnershipTransferred(oldAddress, newAddress);
    }

    /// @dev fetch local storage
    function getBaseInterchainMiddlewareStorage() private pure returns (BaseInterchainMiddlewareStorage storage s) {
        bytes32 namespace = BASE_MIDDLEWARE_CONTRACT_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.25;

import "../../libraries/LibInterchain.sol";
import "../../utils/ReentrancyGuard.sol";
import "../base/RangoBaseInterchainMiddleware.sol";
import "../../interfaces/IAcrossMessageHandler.sol";

/// @title The middleware contract that handles Rango's receive messages from across.
/// @author George
/// @dev Note that this is not a facet and should be deployed separately.
contract RangoAcrossMiddleware is IRango, ReentrancyGuard, RangoBaseInterchainMiddleware, AcrossMessageHandler {

    /// @dev keccak256("exchange.rango.middleware.across")
    bytes32 internal constant ACROSS_MIDDLEWARE_NAMESPACE = hex"dce24b54ba6ac621127abf10d5895b3a9a9c566b24eddc36b2163fc15747e32b";

    struct RangoAcrossMiddlewareStorage {
        /// @notice Addresses that can call exec on this contract
        mapping(address => bool) whitelistedCallers;
    }

    function initAcrossMiddleware(
        address _owner,
        address[] memory _whitelistedCallers,
        address whitelistsContract
    ) external onlyOwner {
        initBaseMiddleware(_owner, whitelistsContract);
        if (_whitelistedCallers.length > 0)
            addWhitelistedCallersInternal(_whitelistedCallers);
    }

    /// Events
    /// @notice Notifies that some new caller addresses are whitelisted
    /// @param _addresses The newly whitelisted addresses
    event AcrossWhitelistedCallersAdded(address[] _addresses);

    /// @notice Notifies that some caller addresses are blacklisted
    /// @param _addresses The addresses that are removed
    event AcrossWhitelistedCallersRemoved(address[] _addresses);

    /// Only permit allowed executors
    modifier onlyWhitelistedCallers(){
        require(getRangoAcrossMiddlewareStorage().whitelistedCallers[msg.sender] == true, "not allowed");
        _;
    }

    /// External Functions
    /// @notice Adds a list of new addresses to the whitelisted across callers
    /// @param _addresses The list of callers to be whitelisted
    function addAcrossWhitelistedCallers(address[] memory _addresses) public onlyOwner {
        addWhitelistedCallersInternal(_addresses);
    }

    /// @notice Removes a list of addresses from whitelist
    /// @param _addresses The list of addresses that should be deprecated
    function removeAcrossWhitelistedCallers(address[] calldata _addresses) external onlyOwner {
        removeWhitelistedCallersInternal(_addresses);
    }

    /// @notice This function will be deprecated later and will no longer be used. TODO: Should be removed later.
    function handleAcrossMessage(
        address tokenSent,
        uint256 amount,
        bool fillCompleted,
        address relayer,
        bytes memory message
    ) external onlyWhitelistedCallers {
        if (fillCompleted == false) {
            return;
        }
        // Note: When this function is called, the caller have already sent erc20 token.
        //       This function is not called with native token, and only receives erc20 tokens (including WETH)
        Interchain.RangoInterChainMessage memory m = abi.decode((message), (Interchain.RangoInterChainMessage));
        (address receivedToken, uint dstAmount, IRango.CrossChainOperationStatus status) = LibInterchain.handleDestinationMessage(tokenSent, amount, m);

        emit RangoBridgeCompleted(
            m.requestId,
            receivedToken,
            m.originalSender,
            m.recipient,
            dstAmount,
            status,
            m.dAppTag
        );
    }

    function handleV3AcrossMessage(
        address tokenSent,
        uint256 amount,
        address relayer,
        bytes memory message
    ) external onlyWhitelistedCallers {
        // Note: When this function is called, the caller have already sent erc20 token.
        //       This function is not called with native token, and only receives erc20 tokens (including WETH)
        Interchain.RangoInterChainMessage memory m = abi.decode((message), (Interchain.RangoInterChainMessage));
        (address receivedToken, uint dstAmount, IRango.CrossChainOperationStatus status) = LibInterchain.handleDestinationMessage(tokenSent, amount, m);

        emit RangoBridgeCompleted(
            m.requestId,
            receivedToken,
            m.originalSender,
            m.recipient,
            dstAmount,
            status,
            m.dAppTag
        );
    }

    /// Private and Internal
    function addWhitelistedCallersInternal(address[] memory _executors) private {
        RangoAcrossMiddlewareStorage storage s = getRangoAcrossMiddlewareStorage();

        address tmpAddr;
        for (uint i = 0; i < _executors.length; i++) {
            tmpAddr = _executors[i];
            require(tmpAddr != address(0), "Invalid Executor Address");
            s.whitelistedCallers[tmpAddr] = true;
        }
        emit AcrossWhitelistedCallersAdded(_executors);
    }

    function removeWhitelistedCallersInternal(address[] calldata _executors) private {
        RangoAcrossMiddlewareStorage storage s = getRangoAcrossMiddlewareStorage();
        for (uint i = 0; i < _executors.length; i++) {
            delete s.whitelistedCallers[_executors[i]];
        }
        emit AcrossWhitelistedCallersRemoved(_executors);
    }

    /// @dev fetch local storage
    function getRangoAcrossMiddlewareStorage() private pure returns (RangoAcrossMiddlewareStorage storage s) {
        bytes32 namespace = ACROSS_MIDDLEWARE_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.25;

// This interface is expected to be implemented by any contract that expects to recieve messages from the SpokePool.
interface AcrossMessageHandler {
    function handleV3AcrossMessage(
        address tokenSent,
        uint256 amount,
        address relayer,
        bytes memory message
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.25;

/// @dev based on Curve router contract https://github.com/curvefi/curve-router-ng/blob/master/contracts/Router.vy

interface ICurve {
    function exchange(
        address [11] calldata _route,
        uint256 [5][5] calldata _swap_params,
        uint256 _amount,
        uint256 _expected,
        address [5] calldata _pools,
        address _receiver
    ) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.25;

/// @title An interface to interchain message types
/// @author Uchiha Sasuke
interface Interchain {
    enum ActionType { NO_ACTION, UNI_V2, UNI_V3, CALL, CURVE }
    enum CallSubActionType { WRAP, UNWRAP, NO_ACTION }

    struct RangoInterChainMessage {
        address requestId;
        uint64 dstChainId;
        // @dev bridgeRealOutput is only used to disambiguate receipt of WETH and ETH and SHOULD NOT be used anywhere else!
        address bridgeRealOutput;
        address toToken;
        address originalSender;
        address recipient;
        ActionType actionType;
        bytes action;
        CallSubActionType postAction;
        uint16 dAppTag;

        // Extra message
        bytes dAppMessage;
        address dAppSourceContract;
        address dAppDestContract;
    }

    struct UniswapV2Action {
        address dexAddress;
        uint amountOutMin;
        address[] path;
        uint deadline;
    }

    struct UniswapV3ActionExactInputSingleParams {
        address dexAddress;
        address tokenIn;
        address tokenOut;
        uint24 fee;
        uint256 deadline;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct UniswapV3ActionExactInputParams {
        address dexAddress;
        address tokenIn;
        address tokenOut;
        bytes encodedPath;
        uint256 deadline;
        uint256 amountOutMinimum;
    }

    /// @notice The requested call data which is computed off-chain and passed to the contract
    /// @param target The dex contract address that should be called
    /// @param overwriteAmount if true, by using startIndexForAmount actual value will be used for swap
    /// @param startIndexForAmount if overwriteAmount is false, this parameter will be ignored. must be byte number
    /// @param callData The required data field that should be give to the dex contract to perform swap
    struct CallAction {
        address tokenIn;
        address spender;
        CallSubActionType preAction;
        address payable target;
        bool overwriteAmount;
        uint256 startIndexForAmount;
        bytes callData;
    }

    /// @notice the data needed to call `exchange` method for swap via Curve
    struct CurveAction {
        address routerContractAddress;
        address [11] routes;
        uint256 [5][5] swap_params;
        uint256 expected;
        address [5] pools;
        address toToken;
    }

}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.25;

interface IRango {
    struct RangoBridgeRequest {
        address requestId;
        address token;
        uint amount;
        uint platformFee;
        uint affiliateFee;
        address payable affiliatorAddress;
        uint destinationExecutorFee;
        uint16 dAppTag;
    }

    enum BridgeType {Across, CBridge, Hop, Hyphen, Multichain, Stargate, Synapse, Thorchain, Symbiosis, Axelar, Voyager, Poly, OptimismBridge, ArbitrumBridge, Wormhole, AllBridge, Connext, NitroAssetForwarder}

    /// @notice Status of cross-chain swap
    /// @param Succeeded The whole process is success and end-user received the desired token in the destination
    /// @param RefundInSource Bridge was out of liquidity and middle asset (ex: USDC) is returned to user on source chain
    /// @param RefundInDestination Our handler on dest chain this.executeMessageWithTransfer failed and we send middle asset (ex: USDC) to user on destination chain
    /// @param SwapFailedInDestination Everything was ok, but the final DEX on destination failed (ex: Market price change and slippage)
    enum CrossChainOperationStatus {
        Succeeded,
        RefundInSource,
        RefundInDestination,
        SwapFailedInDestination
    }

    event RangoBridgeInitiated(
        address indexed requestId,
        address bridgeToken,
        uint256 bridgeAmount,
        address receiver,
        uint destinationChainId,
        bool hasInterchainMessage,
        bool hasDestinationSwap,
        uint8 indexed bridgeId,
        uint16 indexed dAppTag
    );

    event RangoBridgeCompleted(
        address indexed requestId,
        address indexed token,
        address indexed originalSender,
        address receiver,
        uint amount,
        CrossChainOperationStatus status,
        uint16 dAppTag
    );

}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.25;

interface IRangoMessageReceiver {
    enum ProcessStatus { SUCCESS, REFUND_IN_SOURCE, REFUND_IN_DESTINATION }

    function handleRangoMessage(
        address token,
        uint amount,
        ProcessStatus status,
        bytes memory message
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.25;

interface IRangoMiddlewareWhitelists {

    function addWhitelist(address contractAddress) external;
    function removeWhitelist(address contractAddress) external;

    function isContractWhitelisted(address _contractAddress) external view returns (bool);
    function isMessagingContractWhitelisted(address _messagingContract) external view returns (bool);

    function updateWeth(address _weth) external;
    function getWeth() external view returns (address);
    function getRangoDiamond() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.25;

/// @dev based on swap router of uniswap v2 https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-02#swapexactethfortokens
interface IUniswapV2 {
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    // For pangolin and trader joe
    function swapExactAVAXForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.25;
/// @dev based on IswapRouter of UniswapV3 https://docs.uniswap.org/protocol/reference/periphery/interfaces/ISwapRouter
interface IUniswapV3 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.25;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

/// Implementation of EIP-2535 Diamond Standard
/// https://eips.ethereum.org/EIPS/eip-2535
library LibDiamond {
    /// @dev keccak256("diamond.standard.diamond.storage");
    bytes32 internal constant DIAMOND_STORAGE_POSITION = hex"c8fcad8db84d3cc18b4c41d551ea0ee66dd599cde068d998e57d5e09332c131c";

    // Diamond specific errors
    error IncorrectFacetCutAction();
    error NoSelectorsInFacet();
    error FunctionAlreadyExists();
    error FacetAddressIsZero();
    error FacetAddressIsNotZero();
    error FacetContainsNoCode();
    error FunctionDoesNotExist();
    error FunctionIsImmutable();
    error InitZeroButCalldataNotEmpty();
    error CalldataEmptyButInitNotZero();
    error InitReverted();
    // ----------------

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert IncorrectFacetCutAction();
            }
            unchecked {
                ++facetIndex;
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_facetAddress == address(0)) {
            revert FacetAddressIsZero();
        }
        if (_functionSelectors.length == 0) {
            revert NoSelectorsInFacet();
        }
        DiamondStorage storage ds = diamondStorage();
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            if (oldFacetAddress != address(0)) {
                revert FunctionAlreadyExists();
            }
            addFunction(ds, selector, selectorPosition, _facetAddress);
            unchecked {
                ++selectorPosition;
                ++selectorIndex;
            }
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length == 0) {
            revert NoSelectorsInFacet();
        }
        if (_facetAddress == address(0)) {
            revert FacetAddressIsZero();
        }
        DiamondStorage storage ds = diamondStorage();
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            if (oldFacetAddress == _facetAddress) {
                revert FunctionAlreadyExists();
            }
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            unchecked {
                ++selectorPosition;
                ++selectorIndex;
            }
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length == 0) {
            revert NoSelectorsInFacet();
        }
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        if (_facetAddress != address(0)) {
            revert FacetAddressIsNotZero();
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
            unchecked {
                ++selectorIndex;
            }
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress);
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        if (_facetAddress == address(0)) {
            revert FunctionDoesNotExist();
        }
        // an immutable function is a function defined directly in a diamond
        if (_facetAddress == address(this)) {
            revert FunctionIsImmutable();
        }
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            if (_calldata.length != 0) {
                revert InitZeroButCalldataNotEmpty();
            }
        } else {
            if (_calldata.length == 0) {
                revert CalldataEmptyButInitNotZero();
            }
            if (_init != address(this)) {
                enforceHasContractCode(_init);
            }
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert InitReverted();
                }
            }
        }
    }

    function enforceHasContractCode(address _contract) internal view {
        uint256 contractSize;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert FacetContainsNoCode();
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IUniswapV2.sol";
import "../interfaces/IUniswapV3.sol";
import "../interfaces/ICurve.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/Interchain.sol";
import "../interfaces/IRangoMessageReceiver.sol";
import "../interfaces/IRangoMiddlewareWhitelists.sol";
import "./LibSwapper.sol";

library LibInterchain {

    /// @dev keccak256("exchange.rango.library.interchain")
    bytes32 internal constant LIBINTERCHAIN_CONTRACT_NAMESPACE = hex"ff95014231b901d2b22bd69b4e83dacd84ac05e8c2d1e9fba0c7e2f3ed0db0eb";

    struct BaseInterchainStorage {
        address whitelistsStorageContract;
    }

    /// @notice This event indicates that a dApp used Rango messaging (dAppMessage field) and we delivered the message to it
    /// @param _receiverContract The address of dApp's contract that was called
    /// @param _token The address of the token that is sent to the dApp, ETH for native token
    /// @param _amount The amount of the token sent to them
    /// @param _status The status of operation, informing the dApp that the whole process was a success or refund
    /// @param _appMessage The custom message that the dApp asked Rango to deliver
    /// @param success Indicates that the function call to the dApp encountered error or not
    /// @param failReason If success = false, failReason will be the string reason of the failure (aka message of require)
    event CrossChainMessageCalled(
        address _receiverContract,
        address _token,
        uint _amount,
        IRangoMessageReceiver.ProcessStatus _status,
        bytes _appMessage,
        bool success,
        string failReason
    );

    event ActionDone(Interchain.ActionType actionType, address contractAddress, bool success, string reason);
    event SubActionDone(Interchain.CallSubActionType subActionType, address contractAddress, bool success, string reason);
    event WhitelistStorageAddressUpdated(address _oldAddress, address _newAddress);

    /// @notice is used to check if a contract is whitelisted or not
    /// @param _contractAddress the address of the contract to be checked
    /// @return true if contract is whitelisted
    function isContractWhitelisted(address _contractAddress) internal view returns(bool) {
        address whitelistsContractAddress = getLibInterchainStorage().whitelistsStorageContract;
        return IRangoMiddlewareWhitelists(whitelistsContractAddress).isContractWhitelisted(_contractAddress);
    }

    /// @notice is used to check if a DApp is whitelisted or not
    /// @param _messagingContract the address of the DApp to be checked
    /// @return true if DApp is whitelisted
    function isMessagingContractWhitelisted(address _messagingContract) internal view returns(bool) {
        address s = getLibInterchainStorage().whitelistsStorageContract;
        return IRangoMiddlewareWhitelists(s).isMessagingContractWhitelisted(_messagingContract);
    }

    /// @notice updates the address of whitelists storage
    /// @param _storageContract new address
    function updateWhitelistsContractAddress(address _storageContract) internal {
        require(_storageContract != address(0), "Invalid storage contract address");
        BaseInterchainStorage storage baseStorage = getLibInterchainStorage();
        address oldAddress = baseStorage.whitelistsStorageContract;
        baseStorage.whitelistsStorageContract = _storageContract;
        emit WhitelistStorageAddressUpdated(oldAddress, _storageContract);
    }

    function handleDestinationMessage(
        address _token,
        uint _amount,
        Interchain.RangoInterChainMessage memory m
    ) internal returns (address, uint256 dstAmount, IRango.CrossChainOperationStatus status) {
        address sourceToken = m.bridgeRealOutput == LibSwapper.ETH && _token == getWeth() ? LibSwapper.ETH : _token;

        bool ok = true;
        address receivedToken = sourceToken;
        dstAmount = _amount;

        if (m.actionType == Interchain.ActionType.UNI_V2)
            (ok, dstAmount, receivedToken) = _handleUniswapV2(sourceToken, _amount, m);
        else if (m.actionType == Interchain.ActionType.UNI_V3)
            (ok, dstAmount, receivedToken) = _handleUniswapV3(sourceToken, _amount, m);
        else if (m.actionType == Interchain.ActionType.CALL)
            (ok, dstAmount, receivedToken) = _handleCall(sourceToken, _amount, m);
        else if (m.actionType == Interchain.ActionType.CURVE)
            (ok, dstAmount, receivedToken) = _handleCurve(sourceToken, _amount, m);
        else if (m.actionType != Interchain.ActionType.NO_ACTION)
            revert("Unsupported actionType");

        if (ok && m.postAction != Interchain.CallSubActionType.NO_ACTION) {
            (ok, dstAmount, receivedToken) = _handlePostAction(receivedToken, dstAmount, m.postAction);
        }

        status = ok ? IRango.CrossChainOperationStatus.Succeeded : IRango.CrossChainOperationStatus.RefundInDestination;
        IRangoMessageReceiver.ProcessStatus dAppStatus = ok
            ? IRangoMessageReceiver.ProcessStatus.SUCCESS
            : IRangoMessageReceiver.ProcessStatus.REFUND_IN_DESTINATION;

        _sendTokenWithDApp(receivedToken, dstAmount, m.recipient, m.dAppMessage, m.dAppDestContract, dAppStatus);

        return (receivedToken, dstAmount, status);
    }

    /// @notice Performs a uniswap-v2 operation
    /// @param _message The interchain message that contains the swap info
    /// @param _amount The amount of input token
    /// @return ok Indicates that the swap operation was success or fail
    /// @return amountOut If ok = true, amountOut is the output amount of the swap
    function _handleUniswapV2(
        address _token,
        uint _amount,
        Interchain.RangoInterChainMessage memory _message
    ) private returns (bool ok, uint256 amountOut, address outToken) {
        Interchain.UniswapV2Action memory action = abi.decode((_message.action), (Interchain.UniswapV2Action));
        address weth = getWeth();
        if (isContractWhitelisted(action.dexAddress) != true) {
            // "Dex address is not whitelisted"
            return (false, _amount, _token);
        }
        if (action.path.length < 2) {
            // "Invalid uniswap-V2 path"
            return (false, _amount, _token);
        }

        bool shouldDeposit = _token == LibSwapper.ETH && action.path[0] == weth;
        if (!shouldDeposit) {
            if (_token != action.path[0]) {
                // "bridged token must be the same as the first token in destination swap path"
                return (false, _amount, _token);
            }
        } else {
            IWETH(weth).deposit{value : _amount}();
        }

        LibSwapper.approve(action.path[0], action.dexAddress, _amount);

        address toToken = action.path[action.path.length - 1];
        uint toBalanceBefore = LibSwapper.getBalanceOf(toToken);

        try
            IUniswapV2(action.dexAddress).swapExactTokensForTokens(
                _amount,
                action.amountOutMin,
                action.path,
                address(this),
                action.deadline
            )
        returns (uint256[] memory) {
            emit ActionDone(Interchain.ActionType.UNI_V2, action.dexAddress, true, "");
            // Note: instead of using return amounts of swapExactTokensForTokens,
            //       we get the diff balance of before and after. This prevents errors for tokens with transfer fees
            uint toBalanceAfter = LibSwapper.getBalanceOf(toToken);
            SafeERC20.forceApprove(IERC20(action.path[0]), action.dexAddress, 0);
            return (true, toBalanceAfter - toBalanceBefore, toToken);
        } catch {
            emit ActionDone(Interchain.ActionType.UNI_V2, action.dexAddress, true, "Uniswap-V2 call failed");
            SafeERC20.forceApprove(IERC20(action.path[0]), action.dexAddress, 0);
            return (false, _amount, shouldDeposit ? weth : _token);
        }
    }

    /// @notice Performs a uniswap-v3 operation
    /// @param _message The interchain message that contains the swap info
    /// @param _amount The amount of input token
    /// @return ok Indicates that the swap operation was success or fail
    /// @return amountOut If ok = true, amountOut is the output amount of the swap
    function _handleUniswapV3(
        address _token,
        uint _amount,
        Interchain.RangoInterChainMessage memory _message
    ) private returns (bool, uint256, address) {
        Interchain.UniswapV3ActionExactInputParams memory action = abi
            .decode((_message.action), (Interchain.UniswapV3ActionExactInputParams));

        if (isContractWhitelisted(action.dexAddress) != true) {
            // "Dex address is not whitelisted"
            return (false, _amount, _token);
        }

        bool shouldDeposit = _token == LibSwapper.ETH && action.tokenIn == getWeth();
        if (!shouldDeposit) {
            if (_token != action.tokenIn) {
                // "bridged token must be the same as the tokenIn in uniswapV3"
                return (false, _amount, _token);
            }
        } else {
            IWETH(getWeth()).deposit{value : _amount}();
        }

        LibSwapper.approve(action.tokenIn, action.dexAddress, _amount);

        address toToken = action.tokenOut;
        uint toBalanceBefore = LibSwapper.getBalanceOf(toToken);

        try
            IUniswapV3(action.dexAddress).exactInput(IUniswapV3.ExactInputParams({
                path : action.encodedPath,
                recipient : address(this),
                deadline : action.deadline,
                amountIn : _amount,
                amountOutMinimum : action.amountOutMinimum
            }))
        returns (uint) {
            emit ActionDone(Interchain.ActionType.UNI_V3, action.dexAddress, true, "");
            // Note: instead of using return amounts of exactInput,
            //       we get the diff balance of before and after. This prevents errors for tokens with transfer fees.
            uint toBalanceAfter = LibSwapper.getBalanceOf(toToken);
            SafeERC20.forceApprove(IERC20(action.tokenIn), action.dexAddress, 0);
            return (true, toBalanceAfter - toBalanceBefore, toToken);
        } catch {
            emit ActionDone(Interchain.ActionType.UNI_V3, action.dexAddress, false, "Uniswap-V3 call failed");
            SafeERC20.forceApprove(IERC20(action.tokenIn), action.dexAddress, 0);
            return (false, _amount, shouldDeposit ? getWeth() : _token);
        }
    }

    /// @notice Performs a uniswap-v2 operation
    /// @param _message The interchain message that contains the swap info
    /// @param _amount The amount of input token
    /// @return ok Indicates that the swap operation was success or fail
    /// @return amountOut If ok = true, amountOut is the output amount of the swap
    function _handleCall(
        address _token,
        uint _amount,
        Interchain.RangoInterChainMessage memory _message
    ) private returns (bool ok, uint256 amountOut, address outToken) {
        Interchain.CallAction memory action = abi.decode((_message.action), (Interchain.CallAction));

        if (isContractWhitelisted(action.target) != true) {
            // "Action.target is not whitelisted"
            return (false, _amount, _token);
        }
        if (isContractWhitelisted(action.spender) != true) {
            // "Action.spender is not whitelisted"
            return (false, _amount, _token);
        }

        address sourceToken = _token;

        if (action.preAction == Interchain.CallSubActionType.WRAP) {
            if (_token != LibSwapper.ETH) {
                // "Cannot wrap non-native"
                return (false, _amount, _token);
            }
            if (action.tokenIn != getWeth()) {
                // "action.tokenIn must be WETH"
                return (false, _amount, _token);
            }
            (ok, amountOut, sourceToken) = _handleWrap(_token, _amount);
        } else if (action.preAction == Interchain.CallSubActionType.UNWRAP) {
            if (_token != getWeth()) {
                // "Cannot unwrap non-WETH"
                return (false, _amount, _token);
            }
            if (action.tokenIn != LibSwapper.ETH) {
                // "action.tokenIn must be ETH"
                return (false, _amount, _token);
            }
            (ok, amountOut, sourceToken) = _handleUnwrap(_token, _amount);
        } else {
            ok = true;
            if (action.tokenIn != _token) {
                // "_message.tokenIn mismatch in call"
                return (false, _amount, _token);
            }
        }
        if (!ok)
            return (false, _amount, _token);

        if (sourceToken != LibSwapper.ETH)
            LibSwapper.approve(sourceToken, action.spender, _amount);

        uint value = sourceToken == LibSwapper.ETH ? _amount : 0;
        uint toBalanceBefore = LibSwapper.getBalanceOf(_message.toToken);

        if (action.overwriteAmount == true) {
            bytes memory data = action.callData;
            uint256 index = action.startIndexForAmount;
            // Avoid malicious overwriting of function sig or invalid location:
            if (index < 4 || index > (data.length - 32))
                return (false, _amount, _token);
            assembly {
                mstore(add(data, add(index,32)), _amount)
            }
        }

        (bool success, bytes memory ret) = action.target.call{value: value}(action.callData);

        if (sourceToken != LibSwapper.ETH)
            SafeERC20.forceApprove(IERC20(sourceToken), action.spender, 0);

        if (success) {
            emit ActionDone(Interchain.ActionType.CALL, action.target, true, "");
            uint toBalanceAfter = LibSwapper.getBalanceOf(_message.toToken);
            return (true, toBalanceAfter - toBalanceBefore, _message.toToken);
        } else {
            emit ActionDone(Interchain.ActionType.CALL, action.target, false, LibSwapper._getRevertMsg(ret));
            return (false, _amount, sourceToken);
        }
    }

    /// @notice Performs a swap operation using Curve fi
    /// @param _message The interchain message that contains the swap info
    /// @param _amount The amount of input token
    /// @return ok Indicates that the swap operation was success or fail
    /// @return amountOut If ok = true, amountOut is the output amount of the swap
    function _handleCurve(
        address _token,
        uint _amount,
        Interchain.RangoInterChainMessage memory _message
    ) private returns (bool ok, uint256 amountOut, address outToken) {
        Interchain.CurveAction memory action = abi.decode((_message.action), (Interchain.CurveAction));
        if (isContractWhitelisted(action.routerContractAddress) != true) {
            // "Dex address is not whitelisted"
            return (false, _amount, _token);
        }

        uint value = 0;
        if (_token == LibSwapper.ETH) {
            if (action.routes[0] != address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
                return (false, _amount, _token);
            }
            value = _amount;
        } else {
            if (_token != action.routes[0]) {
                return (false, _amount, _token);
            }
            LibSwapper.approve(_token, action.routerContractAddress, _amount);
        }

        address toToken = action.toToken;
        uint toBalanceBefore = LibSwapper.getBalanceOf(toToken);

        try
            ICurve(action.routerContractAddress).exchange{value: value}(
                action.routes,
                action.swap_params,
                _amount,
                action.expected,
                action.pools,
                address(this)
            )
        returns (uint256) {
            emit ActionDone(Interchain.ActionType.CURVE, action.routerContractAddress, true, "");
            uint toBalanceAfter = LibSwapper.getBalanceOf(toToken);
            if (_token != LibSwapper.ETH) {
                SafeERC20.forceApprove(IERC20(_token), action.routerContractAddress, 0);
            }
            return (true, toBalanceAfter - toBalanceBefore, toToken);
        } catch {
            emit ActionDone(Interchain.ActionType.CURVE, action.routerContractAddress, true, "Curve call failed");
            if (_token != LibSwapper.ETH) {
                SafeERC20.forceApprove(IERC20(_token), action.routerContractAddress, 0);
            }
            return (false, _amount, _token);
        }
    }


    /// @notice Performs a uniswap-v2 operation
    /// @param _postAction The type of action to perform such as WRAP, UNWRAP
    /// @param _amount The amount of input token
    /// @return ok Indicates that the swap operation was success or fail
    /// @return amountOut If ok = true, amountOut is the output amount of the swap
    function _handlePostAction(
        address _token,
        uint _amount,
        Interchain.CallSubActionType _postAction
    ) private returns (bool ok, uint256 amountOut, address outToken) {

        if (_postAction == Interchain.CallSubActionType.WRAP) {
            if (_token != LibSwapper.ETH) {
                // "Cannot wrap non-native"
                return (false, _amount, _token);
            }
            (ok, amountOut, outToken) = _handleWrap(_token, _amount);
        } else if (_postAction == Interchain.CallSubActionType.UNWRAP) {
            if (_token != getWeth()) {
                // "Cannot unwrap non-WETH"
                return (false, _amount, _token);
            }
            (ok, amountOut, outToken) = _handleUnwrap(_token, _amount);
        } else {
            // revert("Unsupported post-action");
            return (false, _amount, _token);
        }
        if (!ok)
            return (false, _amount, _token);
        return (ok, amountOut, outToken);
    }

    /// @notice Performs a WETH.deposit operation
    /// @param _amount The amount of input token
    /// @return ok Indicates that the swap operation was success or fail
    /// @return amountOut If ok = true, amountOut is the output amount of the swap
    function _handleWrap(
        address _token,
        uint _amount
    ) private returns (bool ok, uint256 amountOut, address outToken) {
        if (_token != LibSwapper.ETH) {
            // "Cannot wrap non-ETH tokens"
            return (false, _amount, _token);
        }

        IWETH(getWeth()).deposit{value: _amount}();
        emit SubActionDone(Interchain.CallSubActionType.WRAP, getWeth(), true, "");

        return (true, _amount, getWeth());
    }

    /// @notice Performs a WETH.deposit operation
    /// @param _amount The amount of input token
    /// @return ok Indicates that the swap operation was success or fail
    /// @return amountOut If ok = true, amountOut is the output amount of the swap
    function _handleUnwrap(
        address _token,
        uint _amount
    ) private returns (bool ok, uint256 amountOut, address outToken) {
        if (_token != getWeth())
            // revert("Non-WETH tokens unwrapped");
            return (false, _amount, _token);

        IWETH(getWeth()).withdraw(_amount);
        emit SubActionDone(Interchain.CallSubActionType.UNWRAP, getWeth(), true, "");

        return (true, _amount, LibSwapper.ETH);
    }

    /// @notice An internal function to send a token from the current contract to another contract or wallet
    /// @dev This function also can convert WETH to ETH before sending if _withdraw flat is set to true
    /// @dev To send native token _nativeOut param should be set to true, otherwise we assume it's an ERC20 transfer
    /// @dev If there is a message from a dApp it sends the money to the contract instead of the end-user and calls its handleRangoMessage
    /// @param _token The token that is going to be sent to a wallet, ZERO address for native
    /// @param _amount The sent amount
    /// @param _receiver The receiver wallet address or contract
    function _sendTokenWithDApp(
        address _token,
        uint256 _amount,
        address _receiver,
        bytes memory _dAppMessage,
        address _dAppReceiverContract,
        IRangoMessageReceiver.ProcessStatus processStatus
    ) internal {
        bool thereIsAMessage = _dAppReceiverContract != LibSwapper.ETH;
        address immediateReceiver = thereIsAMessage ? _dAppReceiverContract : _receiver;
        emit LibSwapper.SendToken(_token, _amount, immediateReceiver);

        if (_token == LibSwapper.ETH) {
            LibSwapper._sendNative(immediateReceiver, _amount);
        } else {
            SafeERC20.safeTransfer(IERC20(_token), immediateReceiver, _amount);
        }

        if (thereIsAMessage) {
            require(
                isMessagingContractWhitelisted(_dAppReceiverContract),
                "3rd-party contract not whitelisted"
            );

            try IRangoMessageReceiver(_dAppReceiverContract)
                .handleRangoMessage(_token, _amount, processStatus, _dAppMessage)
            {
                emit CrossChainMessageCalled(_dAppReceiverContract, _token, _amount, processStatus, _dAppMessage, true, "");
            } catch Error(string memory reason) {
                emit CrossChainMessageCalled(_dAppReceiverContract, _token, _amount, processStatus, _dAppMessage, false, reason);
            } catch (bytes memory lowLevelData) {
                emit CrossChainMessageCalled(_dAppReceiverContract, _token, _amount, processStatus, _dAppMessage, false, LibSwapper._getRevertMsg(lowLevelData));
            }
        }
    }

    /// @notice used for abi encoding
    /// @param im an instance of RangoInterChainMessage struct
    /// @return encoded format of the struct instance
    function encodeIm(Interchain.RangoInterChainMessage memory im) external pure returns (bytes memory) {
        return abi.encode(im);
    }

    /// @notice get wrapped token address on the current chain from shared storage contract
    /// @return WETH address
    function getWeth() internal view returns(address) {
        address whitelistsContractAddress = getLibInterchainStorage().whitelistsStorageContract;
        return IRangoMiddlewareWhitelists(whitelistsContractAddress).getWeth();
    }

    /// @notice A utility function to fetch storage from a predefined random slot using assembly
    /// @return s The storage object
    function getLibInterchainStorage() internal pure returns (BaseInterchainStorage storage s) {
        bytes32 namespace = LIBINTERCHAIN_CONTRACT_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IRango.sol";

/// @title BaseSwapper
/// @author 0xiden
/// @notice library to provide swap functionality
library LibSwapper {

    /// @dev keccak256("exchange.rango.library.swapper")
    bytes32 internal constant BASE_SWAPPER_NAMESPACE = hex"43da06808a8e54e76a41d6f7b48ddfb23969b1387a8710ef6241423a5aefe64a";

    address payable constant ETH = payable(0x0000000000000000000000000000000000000000);

    struct BaseSwapperStorage {
        address payable feeContractAddress;
        address WETH;
        mapping(address => bool) whitelistContracts;
        mapping(address => mapping(bytes4 => bool)) whitelistMethods;
    }

    /// @notice Emitted if any fee transfer was required
    /// @param token The address of received token, address(0) for native
    /// @param affiliatorAddress The address of affiliate wallet
    /// @param platformFee The amount received as platform fee
    /// @param destinationExecutorFee The amount received to execute transaction on destination (only for cross chain txs)
    /// @param affiliateFee The amount received by affiliate
    /// @param dAppTag Optional identifier to make tracking easier.
    event FeeInfo(
        address token,
        address indexed affiliatorAddress,
        uint platformFee,
        uint destinationExecutorFee,
        uint affiliateFee,
        uint16 indexed dAppTag
    );

    /// @notice A call to another dex or contract done and here is the result
    /// @param target The address of dex or contract that is called
    /// @param success A boolean indicating that the call was success or not
    /// @param returnData The response of function call
    event CallResult(address target, bool success, bytes returnData);

    /// @notice A swap request is done and we also emit the output
    /// @param requestId Optional parameter to make tracking of transaction easier
    /// @param fromToken Input token address to be swapped from
    /// @param toToken Output token address to be swapped to
    /// @param amountIn Input amount of fromToken that is being swapped
    /// @param dAppTag Optional identifier to make tracking easier
    /// @param outputAmount The output amount of the swap, measured by the balance change before and after the swap
    /// @param receiver The address to receive the output of swap. Can be address(0) when swap is before a bridge action
    event RangoSwap(
        address indexed requestId,
        address fromToken,
        address toToken,
        uint amountIn,
        uint minimumAmountExpected,
        uint16 indexed dAppTag,
        uint outputAmount,
        address receiver
    );

    /// @notice Output amount of a dex calls is logged
    /// @param _token The address of output token, ZERO address for native
    /// @param amount The amount of output
    event DexOutput(address _token, uint amount);

    /// @notice The output money (ERC20/Native) is sent to a wallet
    /// @param _token The token that is sent to a wallet, ZERO address for native
    /// @param _amount The sent amount
    /// @param _receiver The receiver wallet address
    event SendToken(address _token, uint256 _amount, address _receiver);


    /// @notice Notifies that Rango's fee receiver address updated
    /// @param _oldAddress The previous fee wallet address
    /// @param _newAddress The new fee wallet address
    event FeeContractAddressUpdated(address _oldAddress, address _newAddress);

    /// @notice Notifies that WETH address is updated
    /// @param _oldAddress The previous weth address
    /// @param _newAddress The new weth address
    event WethContractAddressUpdated(address _oldAddress, address _newAddress);

    /// @notice Notifies that admin manually refunded some money
    /// @param _token The address of refunded token, 0x000..00 address for native token
    /// @param _amount The amount that is refunded
    event Refunded(address _token, uint _amount);

    /// @notice The requested call data which is computed off-chain and passed to the contract
    /// @dev swapFromToken and amount parameters are only helper params and the actual amount and
    /// token are set in callData
    /// @param spender The contract which the approval is given to if swapFromToken is not native.
    /// @param target The dex contract address that should be called
    /// @param swapFromToken Token address of to be used in the swap.
    /// @param amount The amount to be approved or native amount sent.
    /// @param callData The required data field that should be give to the dex contract to perform swap
    struct Call {
        address spender;
        address payable target;
        address swapFromToken;
        address swapToToken;
        bool needsTransferFromUser;
        uint amount;
        bytes callData;
    }

    /// @notice General swap request which is given to us in all relevant functions
    /// @param requestId The request id passed to make tracking transactions easier
    /// @param fromToken The source token that is going to be swapped (in case of simple swap or swap + bridge) or the briding token (in case of solo bridge)
    /// @param toToken The output token of swapping. This is the output of DEX step and is also input of bridging step
    /// @param amountIn The amount of input token to be swapped
    /// @param platformFee The amount of fee charged by platform
    /// @param destinationExecutorFee The amount of fee required for relayer execution on the destination
    /// @param affiliateFee The amount of fee charged by affiliator dApp
    /// @param affiliatorAddress The wallet address that the affiliator fee should be sent to
    /// @param minimumAmountExpected The minimum amount of toToken expected after executing Calls
    /// @param dAppTag An optional parameter
    struct SwapRequest {
        address requestId;
        address fromToken;
        address toToken;
        uint amountIn;
        uint platformFee;
        uint destinationExecutorFee;
        uint affiliateFee;
        address payable affiliatorAddress;
        uint minimumAmountExpected;
        uint16 dAppTag;
    }

    /// @notice initializes the base swapper and sets the init params (such as Wrapped token address)
    /// @param _weth Address of wrapped token (WETH, WBNB, etc.) on the current chain
    function setWeth(address _weth) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();
        address oldAddress = baseStorage.WETH;
        baseStorage.WETH = _weth;
        require(_weth != address(0), "Invalid WETH!");
        emit WethContractAddressUpdated(oldAddress, _weth);
    }

    /// @notice Sets the wallet that receives Rango's fees from now on
    /// @param _address The receiver wallet address
    function updateFeeContractAddress(address payable _address) internal {
        BaseSwapperStorage storage baseSwapperStorage = getBaseSwapperStorage();

        address oldAddress = baseSwapperStorage.feeContractAddress;
        baseSwapperStorage.feeContractAddress = _address;

        emit FeeContractAddressUpdated(oldAddress, _address);
    }

    /// Whitelist ///

    /// @notice Adds a contract to the whitelisted DEXes that can be called
    /// @param contractAddress The address of the DEX
    function addWhitelist(address contractAddress) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();
        baseStorage.whitelistContracts[contractAddress] = true;
    }

    /// @notice Adds a method of contract to the whitelisted DEXes that can be called
    /// @param contractAddress The address of the DEX
    /// @param methodIds The method of the DEX
    function addMethodWhitelists(address contractAddress, bytes4[] calldata methodIds) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();

        baseStorage.whitelistContracts[contractAddress] = true;
        for (uint i = 0; i < methodIds.length; i++)
            baseStorage.whitelistMethods[contractAddress][methodIds[i]] = true;
    }

    /// @notice Adds a method of contract to the whitelisted DEXes that can be called
    /// @param contractAddress The address of the DEX
    /// @param methodId The method of the DEX
    function addMethodWhitelist(address contractAddress, bytes4 methodId) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();

        baseStorage.whitelistContracts[contractAddress] = true;
        baseStorage.whitelistMethods[contractAddress][methodId] = true;
    }

    /// @notice Removes a contract from the whitelisted DEXes
    /// @param contractAddress The address of the DEX or dApp
    function removeWhitelist(address contractAddress) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();

        delete baseStorage.whitelistContracts[contractAddress];
    }

    /// @notice Removes a method of contract from the whitelisted DEXes
    /// @param contractAddress The address of the DEX or dApp
    /// @param methodId The method of the DEX
    function removeMethodWhitelist(address contractAddress, bytes4 methodId) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();

        delete baseStorage.whitelistMethods[contractAddress][methodId];
    }

    function onChainSwapsPreBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        uint extraFee
    ) internal returns (uint out) {

        bool isNative = request.fromToken == ETH;
        uint minimumRequiredValue = (isNative ? request.platformFee + request.affiliateFee + request.amountIn + request.destinationExecutorFee : 0) + extraFee;
        require(msg.value >= minimumRequiredValue, 'Send more ETH to cover input amount + fee');

        (, out) = onChainSwapsInternal(request, calls, extraFee);
        // when there is a bridge after swap, set the receiver in swap event to address(0)
        emitSwapEvent(request, out, ETH);

        return out;
    }

    /// @notice Internal function to compute output amount of DEXes
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls
    /// @param extraNativeFee The amount of native tokens to keep and not return to user as excess amount.
    /// @return The response of all DEX calls and the output amount of the whole process
    function onChainSwapsInternal(
        SwapRequest memory request,
        Call[] calldata calls,
        uint256 extraNativeFee
    ) internal returns (bytes[] memory, uint) {

        uint toBalanceBefore = getBalanceOf(request.toToken);
        uint fromBalanceBefore = getBalanceOf(request.fromToken);
        uint256[] memory initialBalancesList = getInitialBalancesList(calls);

        // transfer tokens from user for SwapRequest and Calls that require transfer from user.
        transferTokensFromUserForSwapRequest(request);
        transferTokensFromUserForCalls(calls);

        bytes[] memory result = callSwapsAndFees(request, calls);

        // check if any extra tokens were taken from contract and return excess tokens if any.
        returnExcessAmounts(request, calls, initialBalancesList);

        // get balance after returning excesses.
        uint fromBalanceAfter = getBalanceOf(request.fromToken);

        // check over-expense of fromToken and return excess if any.
        if (request.fromToken != ETH) {
            require(fromBalanceAfter >= fromBalanceBefore, "Source token balance on contract must not decrease after swap");
            if (fromBalanceAfter > fromBalanceBefore)
                _sendToken(request.fromToken, fromBalanceAfter - fromBalanceBefore, msg.sender);
        }
        else {
            require(fromBalanceAfter >= fromBalanceBefore - msg.value, "Source token balance on contract must not decrease after swap");
            // When we are keeping extraNativeFee for bridgingFee, we should consider it in calculations.
            if (fromBalanceAfter > fromBalanceBefore - msg.value + extraNativeFee)
                _sendToken(request.fromToken, fromBalanceAfter + msg.value - fromBalanceBefore - extraNativeFee, msg.sender);
        }

        uint toBalanceAfter = getBalanceOf(request.toToken);

        uint secondaryBalance = toBalanceAfter - toBalanceBefore;
        require(secondaryBalance >= request.minimumAmountExpected, "Output is less than minimum expected");

        return (result, secondaryBalance);
    }

    /// @notice Private function to handle fetching money from wallet to contract, reduce fee/affiliate, perform DEX calls
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls
    /// @dev It checks the whitelisting of all DEX addresses + having enough msg.value as input
    /// @return The bytes of all DEX calls response
    function callSwapsAndFees(SwapRequest memory request, Call[] calldata calls) private returns (bytes[] memory) {
        bool isSourceNative = request.fromToken == ETH;
        BaseSwapperStorage storage baseSwapperStorage = getBaseSwapperStorage();

        for (uint256 i = 0; i < calls.length; i++) {
            require(baseSwapperStorage.whitelistContracts[calls[i].spender], "Contract spender not whitelisted");
            require(baseSwapperStorage.whitelistContracts[calls[i].target], "Contract target not whitelisted");
            bytes4 sig = bytes4(calls[i].callData[: 4]);
            require(baseSwapperStorage.whitelistMethods[calls[i].target][sig], "Unauthorized call data!");
        }

        // Get Platform fee
        bool hasPlatformFee = request.platformFee > 0;
        bool hasDestExecutorFee = request.destinationExecutorFee > 0;
        bool hasAffiliateFee = request.affiliateFee > 0;
        if (hasPlatformFee || hasDestExecutorFee) {
            require(baseSwapperStorage.feeContractAddress != ETH, "Fee contract address not set");
            _sendToken(request.fromToken, request.platformFee + request.destinationExecutorFee, baseSwapperStorage.feeContractAddress, isSourceNative, false);
        }

        // Get affiliate fee
        if (hasAffiliateFee) {
            require(request.affiliatorAddress != ETH, "Invalid affiliatorAddress");
            _sendToken(request.fromToken, request.affiliateFee, request.affiliatorAddress, isSourceNative, false);
        }

        // emit Fee event
        if (hasPlatformFee || hasDestExecutorFee || hasAffiliateFee) {
            emit FeeInfo(
                request.fromToken,
                request.affiliatorAddress,
                request.platformFee,
                request.destinationExecutorFee,
                request.affiliateFee,
                request.dAppTag
            );
        }

        // Execute swap Calls
        bytes[] memory returnData = new bytes[](calls.length);
        address tmpSwapFromToken;
        for (uint256 i = 0; i < calls.length; i++) {
            tmpSwapFromToken = calls[i].swapFromToken;
            bool isTokenNative = tmpSwapFromToken == ETH;
            if (isTokenNative == false)
                approveMax(tmpSwapFromToken, calls[i].spender, calls[i].amount);

            (bool success, bytes memory ret) = isTokenNative
            ? calls[i].target.call{value : calls[i].amount}(calls[i].callData)
            : calls[i].target.call(calls[i].callData);

            emit CallResult(calls[i].target, success, ret);
            if (!success)
                revert(_getRevertMsg(ret));
            returnData[i] = ret;
        }

        return returnData;
    }

    /// @notice Approves an ERC20 token to a contract to transfer from the current contract
    /// @param token The address of an ERC20 token
    /// @param spender The contract address that should be approved
    /// @param value The amount that should be approved
    function approve(address token, address spender, uint value) internal {
        SafeERC20.forceApprove(IERC20(token), spender, 0);
        SafeERC20.safeIncreaseAllowance(IERC20(token), spender, value);
    }

    /// @notice Approves an ERC20 token to a contract to transfer from the current contract, approves for inf value
    /// @param token The address of an ERC20 token
    /// @param spender The contract address that should be approved
    /// @param value The desired allowance. If current allowance is less than this value, infinite allowance will be given
    function approveMax(address token, address spender, uint value) internal {
        uint256 currentAllowance = IERC20(token).allowance(address(this), spender);
        if (currentAllowance < value) {
            if (currentAllowance != 0) {
                // We set allowance to 0 if not already. tokens such as USDT require zero allowance first.
                SafeERC20.forceApprove(IERC20(token), spender, 0);
            }
            SafeERC20.safeIncreaseAllowance(IERC20(token), spender, type(uint256).max);
        }
    }

    function _sendToken(address _token, uint256 _amount, address _receiver) internal {
        (_token == ETH) ? _sendNative(_receiver, _amount) : SafeERC20.safeTransfer(IERC20(_token), _receiver, _amount);
    }

    function sumFees(IRango.RangoBridgeRequest memory request) internal pure returns (uint256) {
        return request.platformFee + request.affiliateFee + request.destinationExecutorFee;
    }

    function sumFees(SwapRequest memory request) internal pure returns (uint256) {
        return request.platformFee + request.affiliateFee + request.destinationExecutorFee;
    }

    function collectFees(IRango.RangoBridgeRequest memory request) internal {
        // Get Platform fee
        bool hasPlatformFee = request.platformFee > 0;
        bool hasDestExecutorFee = request.destinationExecutorFee > 0;
        bool hasAffiliateFee = request.affiliateFee > 0;
        bool hasAnyFee = hasPlatformFee || hasDestExecutorFee || hasAffiliateFee;
        if (!hasAnyFee) {
            return;
        }
        bool isSourceNative = request.token == ETH;
        BaseSwapperStorage storage baseSwapperStorage = getBaseSwapperStorage();

        if (hasPlatformFee || hasDestExecutorFee) {
            require(baseSwapperStorage.feeContractAddress != ETH, "Fee contract address not set");
            _sendToken(request.token, request.platformFee + request.destinationExecutorFee, baseSwapperStorage.feeContractAddress, isSourceNative, false);
        }

        // Get affiliate fee
        if (hasAffiliateFee) {
            require(request.affiliatorAddress != ETH, "Invalid affiliatorAddress");
            _sendToken(request.token, request.affiliateFee, request.affiliatorAddress, isSourceNative, false);
        }

        // emit Fee event
        emit FeeInfo(
            request.token,
            request.affiliatorAddress,
            request.platformFee,
            request.destinationExecutorFee,
            request.affiliateFee,
            request.dAppTag
        );
    }

    function collectFeesFromSender(IRango.RangoBridgeRequest memory request) internal {
        // Get Platform fee
        bool hasPlatformFee = request.platformFee > 0;
        bool hasDestExecutorFee = request.destinationExecutorFee > 0;
        bool hasAffiliateFee = request.affiliateFee > 0;
        bool hasAnyFee = hasPlatformFee || hasDestExecutorFee || hasAffiliateFee;
        if (!hasAnyFee) {
            return;
        }
        bool isSourceNative = request.token == ETH;
        BaseSwapperStorage storage baseSwapperStorage = getBaseSwapperStorage();

        if (hasPlatformFee || hasDestExecutorFee) {
            require(baseSwapperStorage.feeContractAddress != ETH, "Fee contract address not set");
            if (isSourceNative)
                _sendToken(request.token, request.platformFee + request.destinationExecutorFee, baseSwapperStorage.feeContractAddress, isSourceNative, false);
            else
                SafeERC20.safeTransferFrom(
                    IERC20(request.token),
                    msg.sender,
                    baseSwapperStorage.feeContractAddress,
                    request.platformFee + request.destinationExecutorFee
                );
        }

        // Get affiliate fee
        if (hasAffiliateFee) {
            require(request.affiliatorAddress != ETH, "Invalid affiliatorAddress");
            if (isSourceNative)
                _sendToken(request.token, request.affiliateFee, request.affiliatorAddress, isSourceNative, false);
            else
                SafeERC20.safeTransferFrom(
                    IERC20(request.token),
                    msg.sender,
                    request.affiliatorAddress,
                    request.affiliateFee
                );
        }

        // emit Fee event
        emit FeeInfo(
            request.token,
            request.affiliatorAddress,
            request.platformFee,
            request.destinationExecutorFee,
            request.affiliateFee,
            request.dAppTag
        );
    }

    /// @notice An internal function to send a token from the current contract to another contract or wallet
    /// @dev This function also can convert WETH to ETH before sending if _withdraw flat is set to true
    /// @dev To send native token _nativeOut param should be set to true, otherwise we assume it's an ERC20 transfer
    /// @param _token The token that is going to be sent to a wallet, ZERO address for native
    /// @param _amount The sent amount
    /// @param _receiver The receiver wallet address or contract
    /// @param _nativeOut means the output is native token
    /// @param _withdraw If true, indicates that we should swap WETH to ETH before sending the money and _nativeOut must also be true
    function _sendToken(
        address _token,
        uint256 _amount,
        address _receiver,
        bool _nativeOut,
        bool _withdraw
    ) internal {
        BaseSwapperStorage storage baseStorage = getBaseSwapperStorage();
        emit SendToken(_token, _amount, _receiver);

        if (_nativeOut) {
            if (_withdraw) {
                require(_token == baseStorage.WETH, "token mismatch");
                IWETH(baseStorage.WETH).withdraw(_amount);
            }
            _sendNative(_receiver, _amount);
        } else {
            SafeERC20.safeTransfer(IERC20(_token), _receiver, _amount);
        }
    }

    /// @notice An internal function to send native token to a contract or wallet
    /// @param _receiver The address that will receive the native token
    /// @param _amount The amount of the native token that should be sent
    function _sendNative(address _receiver, uint _amount) internal {
        (bool sent,) = _receiver.call{value : _amount}("");
        require(sent, "failed to send native");
    }


    /// @notice A utility function to fetch storage from a predefined random slot using assembly
    /// @return s The storage object
    function getBaseSwapperStorage() internal pure returns (BaseSwapperStorage storage s) {
        bytes32 namespace = BASE_SWAPPER_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }

    /// @notice To extract revert message from a DEX/contract call to represent to the end-user in the blockchain
    /// @param _returnData The resulting bytes of a failed call to a DEX or contract
    /// @return A string that describes what was the error
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
        // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
        // All that remains is the revert string
    }

    function getBalanceOf(address token) internal view returns (uint) {
        return token == ETH ? address(this).balance : IERC20(token).balanceOf(address(this));
    }

    /// @notice Fetches the balances of swapToTokens.
    /// @dev this fetches the balances for swapToToken of swap Calls. If native eth is received, the balance has already increased so we subtract msg.value.
    function getInitialBalancesList(Call[] calldata calls) internal view returns (uint256[] memory) {
        uint callsLength = calls.length;
        uint256[] memory balancesList = new uint256[](callsLength);
        address token;
        for (uint256 i = 0; i < callsLength; i++) {
            token = calls[i].swapToToken;
            balancesList[i] = getBalanceOf(token);
            if (token == ETH)
                balancesList[i] -= msg.value;
        }
        return balancesList;
    }

    /// This function transfers tokens from users based on the SwapRequest, it transfers amountIn + fees.
    function transferTokensFromUserForSwapRequest(SwapRequest memory request) private {
        uint transferAmount = request.amountIn + sumFees(request);
        if (request.fromToken != ETH)
            SafeERC20.safeTransferFrom(IERC20(request.fromToken), msg.sender, address(this), transferAmount);
        else
            require(msg.value >= transferAmount);
    }

    /// This function iterates on calls and if needsTransferFromUser, transfers tokens from user
    function transferTokensFromUserForCalls(Call[] calldata calls) private {
        uint callsLength = calls.length;
        Call calldata call;
        address token;
        for (uint256 i = 0; i < callsLength; i++) {
            call = calls[i];
            token = call.swapFromToken;
            if (call.needsTransferFromUser && token != ETH)
                SafeERC20.safeTransferFrom(IERC20(call.swapFromToken), msg.sender, address(this), call.amount);
        }
    }

    /// @dev returns any excess token left by the contract.
    /// We iterate over `swapToToken`s because each swapToToken is either the request.toToken or is the output of
    /// another `Call` in the list of swaps which itself either has transferred tokens from user,
    /// or is a middle token that is the output of another `Call`.
    function returnExcessAmounts(
        SwapRequest memory request,
        Call[] calldata calls,
        uint256[] memory initialBalancesList) internal {
        uint excessAmountToToken;
        address tmpSwapToToken;
        uint currentBalanceTo;
        for (uint256 i = 0; i < calls.length; i++) {
            tmpSwapToToken = calls[i].swapToToken;
            currentBalanceTo = getBalanceOf(tmpSwapToToken);
            excessAmountToToken = currentBalanceTo - initialBalancesList[i];
            if (excessAmountToToken > 0 && tmpSwapToToken != request.toToken) {
                _sendToken(tmpSwapToToken, excessAmountToToken, msg.sender);
            }
        }
    }

    function emitSwapEvent(SwapRequest memory request, uint output, address receiver) internal {
        emit RangoSwap(
            request.requestId,
            request.fromToken,
            request.toToken,
            request.amountIn,
            request.minimumAmountExpected,
            request.dAppTag,
            output,
            receiver
        );
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.25;

/// @title Reentrancy Guard
/// @author 
/// @notice Abstract contract to provide protection against reentrancy
abstract contract ReentrancyGuard {
    /// Storage ///

    /// @dev keccak256("exchange.rango.reentrancyguard");
    bytes32 private constant NAMESPACE = hex"4fe94118b1030ac5f570795d403ee5116fd91b8f0b5d11f2487377c2b0ab2559";

    /// Types ///

    struct ReentrancyStorage {
        uint256 status;
    }

    /// Errors ///

    error ReentrancyError();

    /// Constants ///

    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    /// Modifiers ///

    modifier nonReentrant() {
        ReentrancyStorage storage s = reentrancyStorage();
        if (s.status == _ENTERED) revert ReentrancyError();
        s.status = _ENTERED;
        _;
        s.status = _NOT_ENTERED;
    }

    /// Private Methods ///

    /// @dev fetch local storage
    function reentrancyStorage() private pure returns (ReentrancyStorage storage data) {
        bytes32 position = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data.slot := position
        }
    }
}