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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IAdapterDataProvider} from "./interfaces/IAdapterDataProvider.sol";

/**
 * @title AdapterDataProvider
 * @author Router Protocol
 * @notice This contract serves as the data provider for an intent adapter based on Router
 * Cross-Chain Intent Framework.
 */
contract AdapterDataProvider is IAdapterDataProvider {
    address private _owner;
    mapping(address => bool) private _headRegistry;
    mapping(address => bool) private _tailRegistry;
    mapping(address => bool) private _inboundAssetRegistry;
    mapping(address => bool) private _outboundAssetRegistry;

    constructor(address __owner) {
        _owner = __owner;
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function setOwner(address __owner) external onlyOwner {
        _owner = __owner;
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function isAuthorizedPrecedingContract(
        address precedingContract
    ) external view returns (bool) {
        if (precedingContract == address(0)) return true;
        return _headRegistry[precedingContract];
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function isAuthorizedSucceedingContract(
        address succeedingContract
    ) external view returns (bool) {
        if (succeedingContract == address(0)) return true;
        return _tailRegistry[succeedingContract];
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function isValidInboundAsset(address asset) external view returns (bool) {
        return _inboundAssetRegistry[asset];
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function isValidOutboundAsset(address asset) external view returns (bool) {
        return _outboundAssetRegistry[asset];
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function setPrecedingContract(
        address precedingContract,
        bool isValid
    ) external onlyOwner {
        _headRegistry[precedingContract] = isValid;
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function setSucceedingContract(
        address succeedingContract,
        bool isValid
    ) external onlyOwner {
        _tailRegistry[succeedingContract] = isValid;
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function setInboundAsset(address asset, bool isValid) external onlyOwner {
        _inboundAssetRegistry[asset] = isValid;
    }

    /**
     * @inheritdoc IAdapterDataProvider
     */
    function setOutboundAsset(address asset, bool isValid) external onlyOwner {
        _outboundAssetRegistry[asset] = isValid;
    }

    /**
     * @notice modifier to ensure that only owner can call this function
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == _owner, "Only owner");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Basic} from "./common/Basic.sol";
import {Errors} from "./utils/Errors.sol";
import {ReentrancyGuard} from "./utils/ReentrancyGuard.sol";
import {AdapterDataProvider} from "./AdapterDataProvider.sol";

/**
 * @title BaseAdapter
 * @author Router Protocol
 * @notice This contract is the base implementation of an intent adapter based on Router
 * Cross-Chain Intent Framework.
 */
abstract contract BaseAdapter is Basic, ReentrancyGuard {
    address private immutable _self;
    address private immutable _native;
    address private immutable _wnative;
    AdapterDataProvider private immutable _adapterDataProvider;

    event ExecutionEvent(string indexed adapterName, bytes data);
    event OperationFailedRefundEvent(
        address token,
        address recipient,
        uint256 amount
    );
    event UnsupportedOperation(
        address token,
        address refundAddress,
        uint256 amount
    );

    constructor(
        address __native,
        address __wnative,
        bool __deployDataProvider,
        address __owner
    ) {
        _self = address(this);
        _native = __native;
        _wnative = __wnative;

        AdapterDataProvider dataProvider;

        if (__deployDataProvider)
            dataProvider = new AdapterDataProvider(__owner);
        else dataProvider = AdapterDataProvider(address(0));

        _adapterDataProvider = dataProvider;
    }

    /**
     * @dev function to get the address of weth
     */
    function wnative() public view override returns (address) {
        return _wnative;
    }

    /**
     * @dev function to get the address of native token
     */
    function native() public view override returns (address) {
        return _native;
    }

    /**
     * @dev function to get the AdapterDataProvider instance for this contract
     */
    function adapterDataProvider() public view returns (AdapterDataProvider) {
        return _adapterDataProvider;
    }

    /**
     * @dev Function to check whether the contract is a valid preceding contract registered in
     * the head registry.
     * @dev This registry governs the initiation of the adapter, exclusively listing authorized
     * preceding adapters.
     * @notice Only the adapters documented in this registry can invoke the current adapter,
     * thereby guaranteeing regulated and secure execution sequences.
     * @param precedingContract Address of preceding contract.
     * @return true if valid, false if invalid.
     */
    function isAuthorizedPrecedingContract(
        address precedingContract
    ) public view returns (bool) {
        return
            _adapterDataProvider.isAuthorizedPrecedingContract(
                precedingContract
            );
    }

    /**
     * @dev Function to check whether the contract is a valid succeeding contract registered in
     * the tail registry.
     * @dev This registry dictates the potential succeeding actions by listing adapters that
     * may be invoked following the current one.
     * @notice Only the adapters documented in this registry can be invoked by the current adapter,
     * thereby guaranteeing regulated and secure execution sequences.
     * @param succeedingContract Address of succeeding contract.
     * @return true if valid, false if invalid.
     */
    function isAuthorizedSucceedingContract(
        address succeedingContract
    ) public view returns (bool) {
        return
            _adapterDataProvider.isAuthorizedSucceedingContract(
                succeedingContract
            );
    }

    /**
     * @dev Function to check whether the asset is a valid inbound asset registered in the inbound
     * asset registry.
     * @dev This registry keeps track of all the acceptable incoming assets, ensuring that the
     * adapter only processes predefined asset types.
     * @param asset Address of the asset.
     * @return true if valid, false if invalid.
     */
    function isValidInboundAsset(address asset) public view returns (bool) {
        return _adapterDataProvider.isValidInboundAsset(asset);
    }

    /**
     * @dev Function to check whether the asset is a valid outbound asset registered in the outbound
     * asset registry.
     * @dev It manages the types of assets that the adapter is allowed to output, thus controlling
     * the flow’s output and maintaining consistency.
     * @param asset Address of the asset.
     * @return true if valid, false if invalid.
     */
    function isValidOutboundAsset(address asset) public view returns (bool) {
        return _adapterDataProvider.isValidOutboundAsset(asset);
    }

    /**
     * @dev function to get the name of the adapter
     */
    function name() public view virtual returns (string memory);

    /**
     * @dev function to get the address of the contract
     */
    function self() public view returns (address) {
        return _self;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {TokenInterface} from "./Interfaces.sol";
import {TokenUtilsBase} from "./TokenUtilsBase.sol";

abstract contract Basic is TokenUtilsBase {
    function getTokenBal(address token) internal view returns (uint _amt) {
        _amt = address(token) == native()
            ? address(this).balance
            : TokenInterface(token).balanceOf(address(this));
    }

    function approve(address token, address spender, uint256 amount) internal {
        // solhint-disable-next-line no-empty-blocks
        try TokenInterface(token).approve(spender, amount) {} catch {
            TokenInterface(token).approve(spender, 0);
            TokenInterface(token).approve(spender, amount);
        }
    }

    function convertNativeToWnative(uint amount) internal {
        TokenInterface(wnative()).deposit{value: amount}();
    }

    function convertWnativeToNative(uint amount) internal {
        TokenInterface(wnative()).withdraw(amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface TokenInterface {
    function approve(address, uint256) external;

    function transfer(address, uint) external;

    function transferFrom(address, address, uint) external;

    function deposit() external payable;

    function withdraw(uint) external;

    function balanceOf(address) external view returns (uint);

    function decimals() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IWETH} from "../interfaces/IWETH.sol";
import {SafeERC20, IERC20} from "../utils/SafeERC20.sol";

abstract contract TokenUtilsBase {
    using SafeERC20 for IERC20;

    function wnative() public view virtual returns (address);

    function native() public view virtual returns (address);

    function approveToken(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) internal {
        if (_tokenAddr == native()) return;

        if (IERC20(_tokenAddr).allowance(address(this), _to) < _amount) {
            IERC20(_tokenAddr).safeApprove(_to, _amount);
        }
    }

    function pullTokensIfNeeded(
        address _token,
        address _from,
        uint256 _amount
    ) internal returns (uint256) {
        // handle max uint amount
        if (_amount == type(uint256).max) {
            _amount = getBalance(_token, _from);
        }

        if (
            _from != address(0) &&
            _from != address(this) &&
            _token != native() &&
            _amount != 0
        ) {
            IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        }

        return _amount;
    }

    function withdrawTokens(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (_amount == type(uint256).max) {
            _amount = getBalance(_token, address(this));
        }

        if (_to != address(0) && _to != address(this) && _amount != 0) {
            if (_token != native()) {
                IERC20(_token).safeTransfer(_to, _amount);
            } else {
                (bool success, ) = _to.call{value: _amount}("");
                require(success, "native send fail");
            }
        }

        return _amount;
    }

    function depositWnative(uint256 _amount) internal {
        IWETH(wnative()).deposit{value: _amount}();
    }

    function withdrawWnative(uint256 _amount) internal {
        IWETH(wnative()).withdraw(_amount);
    }

    function getBalance(
        address _tokenAddr,
        address _acc
    ) internal view returns (uint256) {
        if (_tokenAddr == native()) {
            return _acc.balance;
        } else {
            return IERC20(_tokenAddr).balanceOf(_acc);
        }
    }

    function getTokenDecimals(address _token) internal view returns (uint256) {
        if (_token == native()) return 18;

        return IERC20(_token).decimals();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Interface for Adapter Data Provider contract for intent adapter.
 * @author Router Protocol.
 */

interface IAdapterDataProvider {
    /**
     * @dev Function to get the address of owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Function to set the address of owner.
     * @dev This function can only be called by the owner of this contract.
     * @param __owner Address of the new owner
     */
    function setOwner(address __owner) external;

    /**
     * @dev Function to check whether the contract is a valid preceding contract registered in
     * the head registry.
     * @dev This registry governs the initiation of the adapter, exclusively listing authorized
     * preceding adapters.
     * @notice Only the adapters documented in this registry can invoke the current adapter,
     * thereby guaranteeing regulated and secure execution sequences.
     * @param precedingContract Address of preceding contract.
     * @return true if valid, false if invalid.
     */
    function isAuthorizedPrecedingContract(
        address precedingContract
    ) external view returns (bool);

    /**
     * @dev Function to check whether the contract is a valid succeeding contract registered in
     * the tail registry.
     * @dev This registry dictates the potential succeeding actions by listing adapters that
     * may be invoked following the current one.
     * @notice Only the adapters documented in this registry can be invoked by the current adapter,
     * thereby guaranteeing regulated and secure execution sequences.
     * @param succeedingContract Address of succeeding contract.
     * @return true if valid, false if invalid.
     */
    function isAuthorizedSucceedingContract(
        address succeedingContract
    ) external view returns (bool);

    /**
     * @dev Function to check whether the asset is a valid inbound asset registered in the inbound
     * asset registry.
     * @dev This registry keeps track of all the acceptable incoming assets, ensuring that the
     * adapter only processes predefined asset types.
     * @param asset Address of the asset.
     * @return true if valid, false if invalid.
     */
    function isValidInboundAsset(address asset) external view returns (bool);

    /**
     * @dev Function to check whether the asset is a valid outbound asset registered in the outbound
     * asset registry.
     * @dev It manages the types of assets that the adapter is allowed to output, thus controlling
     * the flow’s output and maintaining consistency.
     * @param asset Address of the asset.
     * @return true if valid, false if invalid.
     */
    function isValidOutboundAsset(address asset) external view returns (bool);

    /**
     * @dev Function to set preceding contract (head registry) for the adapter.
     * @dev This registry governs the initiation of the adapter, exclusively listing authorized
     * preceding adapters.
     * @notice Only the adapters documented in this registry can invoke the current adapter,
     * thereby guaranteeing regulated and secure execution sequences.
     * @param precedingContract Address of preceding contract.
     * @param isValid Boolean value suggesting if this is a valid preceding contract.
     */
    function setPrecedingContract(
        address precedingContract,
        bool isValid
    ) external;

    /**
     * @dev Function to set succeeding contract (tail registry) for the adapter.
     * @dev This registry dictates the potential succeeding actions by listing adapters that
     * may be invoked following the current one.
     * @notice Only the adapters documented in this registry can be invoked by the current adapter,
     * thereby guaranteeing regulated and secure execution sequences.
     * @param succeedingContract Address of succeeding contract.
     * @param isValid Boolean value suggesting if this is a valid succeeding contract.
     */
    function setSucceedingContract(
        address succeedingContract,
        bool isValid
    ) external;

    /**
     * @dev Function to set inbound asset registry for the adapter.
     * @dev This registry keeps track of all the acceptable incoming assets, ensuring that the
     * adapter only processes predefined asset types.
     * @param asset Address of the asset.
     * @param isValid Boolean value suggesting if this is a valid inbound asset.
     */
    function setInboundAsset(address asset, bool isValid) external;

    /**
     * @dev Function to set outbound asset registry for the adapter.
     * @dev It manages the types of assets that the adapter is allowed to output, thus controlling
     * the flow’s output and maintaining consistency.
     * @param asset Address of the asset.
     * @param isValid Boolean value suggesting if this is a valid inbound asset.
     */
    function setOutboundAsset(address asset, bool isValid) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "../utils/SafeERC20.sol";

abstract contract IWETH {
    function allowance(address, address) public view virtual returns (uint256);

    function balanceOf(address) public view virtual returns (uint256);

    function approve(address, uint256) public virtual;

    function transfer(address, uint256) public virtual returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) public virtual returns (bool);

    function deposit() public payable virtual;

    function withdraw(uint256) public virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseAdapter} from "./BaseAdapter.sol";
import {EoaExecutorWithDataProvider, EoaExecutorWithoutDataProvider} from "./utils/EoaExecutor.sol";

abstract contract RouterIntentEoaAdapterWithDataProvider is
    BaseAdapter,
    EoaExecutorWithDataProvider
{
    constructor(
        address __native,
        address __wnative,
        address __owner
    )
        BaseAdapter(__native, __wnative, true, __owner)
    // solhint-disable-next-line no-empty-blocks
    {

    }
}

abstract contract RouterIntentEoaAdapterWithoutDataProvider is
    BaseAdapter,
    EoaExecutorWithoutDataProvider
{
    constructor(
        address __native,
        address __wnative
    )
        BaseAdapter(__native, __wnative, false, address(0))
    // solhint-disable-next-line no-empty-blocks
    {

    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library Address {
    //insufficient balance
    error InsufficientBalance(uint256 available, uint256 required);
    //unable to send value, recipient may have reverted
    error SendingValueFail();
    //insufficient balance for call
    error InsufficientBalanceForCall(uint256 available, uint256 required);
    //call to non-contract
    error NonContractCall();

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        uint256 balance = address(this).balance;
        if (balance < amount) {
            revert InsufficientBalance(balance, amount);
        }

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        if (!(success)) {
            revert SendingValueFail();
        }
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        uint256 balance = address(this).balance;
        if (balance < value) {
            revert InsufficientBalanceForCall(balance, value);
        }
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        if (!(isContract(target))) {
            revert NonContractCall();
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract EoaExecutorWithDataProvider {
    /**
     * @dev function to execute an action on an adapter used in an EOA.
     * @param precedingAdapter Address of the preceding adapter.
     * @param succeedingAdapter Address of the succeeding adapter.
     * @param data inputs data.
     * @return tokens to be refunded to user at the end of tx.
     */
    function execute(
        address precedingAdapter,
        address succeedingAdapter,
        bytes calldata data
    ) external payable virtual returns (address[] memory tokens);
}

abstract contract EoaExecutorWithoutDataProvider {
    /**
     * @dev function to execute an action on an adapter used in an EOA.
     * @param data inputs data.
     * @return tokens to be refunded to user at the end of tx.
     */
    function execute(
        bytes calldata data
    ) external payable virtual returns (address[] memory tokens);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/**
 * @title Errors library
 * @author Router Intents Error
 * @notice Defines the error messages emitted by the contracts on Router Intents
 */
library Errors {
    string public constant ARRAY_LENGTH_MISMATCH = "1"; // 'Array lengths mismatch'
    string public constant INSUFFICIENT_NATIVE_FUNDS_PASSED = "2"; // 'Insufficient native tokens passed'
    string public constant WRONG_BATCH_PROVIDED = "3"; // 'The targetLength, valueLength, callTypeLength, funcLength do not match in executeBatch transaction functions in batch transaction contract'
    string public constant INVALID_CALL_TYPE = "4"; // 'The callType value can only be 1 (call)' and 2(delegatecall)'
    string public constant ONLY_NITRO = "5"; // 'Only nitro can call this function'
    string public constant ONLY_SELF = "6"; // 'Only the current contract can call this function'
    string public constant ADAPTER_NOT_WHITELISTED = "7"; // 'Adapter not whitelisted'
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

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

    error ReentrantCall();

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        if (_status == _ENTERED) {
            revert ReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "../interfaces/IERC20.sol";
import {Address} from "./Address.sol";
import {SafeMath} from "./SafeMath.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /// @dev Edited so it always first approves 0 and then the value, because of non standard tokens
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, 0)
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: operation failed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: mul overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library Errors {
    string public constant AMOUNT_CANNOT_BE_ZERO = "1";
    string public constant RECIPIENT_CANNOT_BE_ZERO = "2";
    string public constant AMOUNT_RECEIVED_CANNOT_BE_ZERO = "3";
    string public constant RESTAKED_ETH_RECEIVED_AMOUNT_LESS_THAN_MIN_RETURN =
        "4";
    string public constant ONLY_EMERGENCY_OWNER = "5";
    string public constant EMERGENCY_OWNER_CANNOT_BE_ZERO = "6";
    string public constant WRONG_BATCH_PROVIDED = "7";
    string public constant INSUFFICIENT_NATIVE_FUNDS_PASSED = "8";
    string public constant ONLY_SELF = "9";
    string public constant ARRAY_LENGTH_MISMATCH = "10";
    string public constant INSUFFICIENT_FEE_PASSED = "11";
    string public constant VOLUME_CANNOT_BE_ZERO = "12";
    string public constant ONLY_NATIVE_TOKENS = "13";
    string public constant ONLY_NITRO_BRIDGE = "14";
    string public constant ONLY_WHITELISTED_BRIDGES = "15";
    string public constant BRIDGE_ADAPTER_ADDRESS_CANNOT_BE_ZERO = "16";
    string public constant MULTICALLER_ADDRESS_CANNOT_BE_ZERO = "17";
    string public constant FEE_MANAGER_ADDRESS_CANNOT_BE_ZERO = "18";
    string public constant SWAP_FAILED = "19";
    string public constant ADAPTER_NOT_WHITELISTED = "20";
    string public constant BRIDGE_TX_FAILED_ON_MULTICALL = "21";
    string public constant TOKEN_PASSED_CANNOT_BE_NULL_ADDRESS = "22";
    string public constant ADAPTER_ADDRESS_CANNOT_BE_ZERO = "23";
    string public constant ADAPTER_TYPE_CAN_BE_EITHER_1_OR_2 = "24";
    string public constant FEE_TRANSFER_FAILED = "25";
    string public constant AMOUNT_LESSER_THAN_MIN_DEPOSIT = "26";
    string public constant ARRAY_LENGTH_ZERO = "27";
    string public constant REFUND_AMOUNT_ZERO = "28";
    string public constant INVALID_RESTAKING_PROTOCOL_TYPE = "29";
    string public constant INVALID_PROTOCOL_DATA = "30";
    string public constant BASE_GAS_NOT_IN_RANGE = "31";
    string public constant MARGINAL_GAS_PER_USER_NOT_IN_RANGE = "32";
    string public constant FEE_TOO_LARGE = "33";
    string public constant ZERO_DEPOSIT_FUNDS_FOR_THIS_PROTOCOL_ID = "34";
    string public constant NOT_EXECUTABLE = "35";
    string public constant PROTOCOL_DATA_NOT_SET = "36";
    string public constant CANNOT_EXECUTE_LESSER_THAN_MIN_EXECUTABLE_BATCH =
        "37";
    string public constant MAX_FEE_PERCENTAGE_GREATER_THAN_CEILING = "38";
    string public constant FUSION_TX_BUILDER_CANNOT_BE_ADDRESS_ZERO = "39";
    string public constant PROTOCOL_IS_PAUSED = "40";
    string public constant OPEN_OCEAN_ADDRESS_CANNOT_BE_ZERO = "41";
    string public constant BRIDGE_ADDRESS_CANNOT_BE_ZERO = "42";
    string public constant WNATIVE_ADDRESS_CANNOT_BE_ZERO = "43";
    string public constant CHAIN_LINK_GAS_PRICE_ORACLE_ADDRESS_CANNOT_BE_ZERO =
        "44";
    string public constant STAKE_EASE_FEE_MANAGER_ADDRESS_CANNOT_BE_ZERO = "45";
    string public constant PROTOCOL_GAS_PER_USER_OUT_OF_RANGE = "46";
    string public constant GAS_PRICE_EXCEEDS_FAST_GAS_RANGE = "47";
    string public constant AMOUNT_TO_RESTAKE_CANNOT_BE_ZERO = "48";
    string public constant UNSUPPORTED_OPERATION = "49";
    string public constant CANNOT_SET_ALL_DATA_FOR_PROTOCOL_AGAIN = "50";
    string public constant INVALID_ASSET = "51";
    string public constant CANNOT_SET_NEW_PROTOCOL_DATA_WITH_UPDATE_FUNCTION =
        "52";
    string public constant OFT_ADAPTER_NOT_FOUND = "53";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title IFeeManager
 * @author StakeEase
 * @notice Interface for FeeManager contract for StakeEase.
 */

interface IFeeManager {
    /**
     * @notice Function to fetch the amount of fee.
     * @param txVolume Volume of transaction in ETH.
     * @return fee to be deducted in ETH.
     */
    function getFee(uint256 txVolume) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ILRTDepositPool {
    /**
     * @notice View amount of rsETH to mint for given asset amount
     * @param asset Asset address
     * @param amount Asset amount
     * @return rsethAmountToMint Amount of rseth to mint
     */
    function getRsETHAmountToMint(
        address asset,
        uint256 amount
    ) external view returns (uint256 rsethAmountToMint);

    /**
     * @notice Function to help user stake LST to the protocol.
     * @param asset LST asset address to stake,
     * @param depositAmount LST asset amount to stake.
     * @param minRSETHAmountToReceive Minimum amount of rseth to receive.
     * @param referralId referralId for the referrer.
     */
    function depositAsset(
        address asset,
        uint256 depositAmount,
        uint256 minRSETHAmountToReceive,
        string calldata referralId
    ) external;

    /// @notice Allows user to deposit ETH to the protocol
    /// @param minRSETHAmountExpected Minimum amount of rseth to receive
    /// @param referralId referral id
    function depositETH(
        uint256 minRSETHAmountExpected,
        string calldata referralId
    ) external payable;

    /// @notice gets the current limit of asset deposit
    /// @param asset Asset address
    /// @return currentLimit Current limit of asset deposit
    function getAssetCurrentLimit(
        address asset
    ) external view returns (uint256);
}

interface IKelpPoolArbitrum {
    function swapToRsETH(uint256 wstETHAmount) external payable;

    function viewSwapRsETHAmountAndFee(
        uint256 amount,
        bool isWstETH
    ) external view returns (uint256 rsETHAmount, uint256 fee);
}

interface IKelpPoolL2 {
    function deposit(string memory referralId) external payable;

    function viewSwapRsETHAmountAndFee(
        uint256 amount,
        bool isWstETH
    ) external view returns (uint256 rsETHAmount, uint256 fee);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {EoaExecutorWithoutDataProvider} from "@routerprotocol/intents-core/contracts/RouterIntentEoaAdapter.sol";
import {Errors} from "../../Errors.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IKelpPoolArbitrum} from "../../interfaces/ILRTDepositPool.sol";
import {RestakingAdapterBase} from "../RestakingAdapterBase.sol";

/**
 * @title KelpArbitrumAdapter
 * @author StakeEase
 */
contract KelpArbitrumAdapter is RestakingAdapterBase {
    using SafeERC20 for IERC20;

    IKelpPoolArbitrum public immutable kelpPoolArbitrum;
    IERC20 public immutable rsEth;

    constructor(
        address _native,
        address _wnative,
        address _feeManager,
        address _kelpPoolArbitrum,
        address _rsEth
    ) RestakingAdapterBase(_native, _wnative, _feeManager) {
        kelpPoolArbitrum = IKelpPoolArbitrum(_kelpPoolArbitrum);
        rsEth = IERC20(_rsEth);
    }

    function name() public pure override returns (string memory) {
        return "KelpAdapter";
    }

    /**
     * @inheritdoc EoaExecutorWithoutDataProvider
     */
    function execute(
        bytes calldata data
    ) external payable override returns (address[] memory) {
        (
            address asset,
            address recipient,
            uint256 amount,
            uint256 minReceive
        ) = parseInput(data);

        bool isNativeAsset = asset == native();

        if (address(this) == self()) {
            if (isNativeAsset) amount = msg.value;
            else {
                IERC20(asset).safeTransferFrom(msg.sender, self(), amount);
                amount = IERC20(asset).balanceOf(self());
            }
        } else if (amount == type(uint256).max) {
            if (isNativeAsset) amount = address(this).balance;
            else amount = IERC20(asset).balanceOf(address(this));
        }

        require(amount != 0, Errors.AMOUNT_CANNOT_BE_ZERO);

        uint256 fee = feeManager.getFee(amount);

        if (fee != 0) {
            amount = amount - fee;
            if (isNativeAsset) payable(address(feeManager)).transfer(fee);
            else IERC20(asset).safeTransfer(address(feeManager), fee);
        }

        return
            _restakeOnKelp(
                isNativeAsset,
                asset,
                recipient,
                fee,
                amount,
                minReceive
            );
    }

    function _restakeOnKelp(
        bool isNativeAsset,
        address asset,
        address recipient,
        uint256 fee,
        uint256 amount,
        uint256 minReceive
    ) internal returns (address[] memory) {
        uint256 rsEthBalBefore = rsEth.balanceOf(address(this));

        if (isNativeAsset) kelpPoolArbitrum.swapToRsETH{value: amount}(0);
        else {
            IERC20(asset).safeIncreaseAllowance(
                address(kelpPoolArbitrum),
                amount
            );

            kelpPoolArbitrum.swapToRsETH(amount);
        }

        uint256 rsEthReceived = rsEth.balanceOf(address(this)) - rsEthBalBefore;

        if (rsEthReceived < minReceive)
            revert(Errors.RESTAKED_ETH_RECEIVED_AMOUNT_LESS_THAN_MIN_RETURN);

        if (recipient != address(this))
            rsEth.safeTransfer(recipient, rsEthReceived);

        emit RestakingSuccessful(
            self(),
            recipient,
            asset,
            fee,
            amount,
            rsEthReceived
        );

        address[] memory tokens = new address[](2);
        tokens[0] = address(asset);
        tokens[0] = address(rsEth);

        return tokens;
    }

    function parseInput(
        bytes memory data
    ) internal pure returns (address, address, uint256, uint256) {
        (
            address asset,
            address recipient,
            uint256 amount,
            uint256 minReceive
        ) = abi.decode(data, (address, address, uint256, uint256));

        return (asset, recipient, amount, minReceive);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {RouterIntentEoaAdapterWithoutDataProvider} from "@routerprotocol/intents-core/contracts/RouterIntentEoaAdapter.sol";
import {IFeeManager} from "../interfaces/IFeeManager.sol";

/**
 * @title RestakingAdapterBase
 * @author StakeEase
 */
abstract contract RestakingAdapterBase is
    RouterIntentEoaAdapterWithoutDataProvider
{
    IFeeManager public immutable feeManager;

    event RestakingSuccessful(
        address indexed adapter,
        address indexed recipient,
        address stakingAsset,
        uint256 fee,
        uint256 amount,
        uint256 receivedAmount
    );

    constructor(
        address _native,
        address _wnative,
        address _feeManager
    ) payable RouterIntentEoaAdapterWithoutDataProvider(_native, _wnative) {
        feeManager = IFeeManager(_feeManager);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}