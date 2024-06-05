// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IXeqFeeManager {
    function calculateXEQForBuy(
        address _token,
        uint256 _amountOfTokens
    ) external returns (uint256);

    function calculateXEQForSell(
        address _token,
        uint256 _amountOfTokens
    ) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/// @notice Stores a reference to the registry for this system
interface ISystemComponent {
    /// @notice The system instance this contract is tied to
    function getSystemRegistry() external view returns (address registry);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import {ISystemSecurity} from "./security/ISystemSecurity.sol";
import {IAccessController} from "./security/IAccessController.sol";
import {IRentShare} from "./rent/IRentShare.sol";
import {IRentDistributor} from "./rent/IRentDistributor.sol";
import {IMarketplace} from "./marketplace/IMarketplace.sol";
import {ISecondaryMarket} from "./marketplace/ISecondaryMarket.sol";
import {IWhitelist} from "./whitelist/IWhitelist.sol";
import {ILockNFT} from "./lockNft/ILockNFT.sol";
import {IXeqFeeManager} from "./fees/IXeqFeeManager.sol";
import {IRootPriceOracle} from "./oracles/IRootPriceOracle.sol";
import {IJarvisDex} from "./oclr/IJarvisDex.sol";
import {IDFXRouter} from "./oclr/IDFXRouter.sol";
import {ISanctionsList} from "./sbt/ISanctionsList.sol";
import {ISBT} from "./sbt/ISBT.sol";
import {IPasskeyFactory} from "./wallet/IPasskeyFactory.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Root most registry contract for the system
interface ISystemRegistry {
    /// @notice Get the system security instance for this system
    /// @return security instance of system security for this system
    function systemSecurity() external view returns (ISystemSecurity security);

    /// @notice Get the access Controller for this system
    /// @return controller instance of the access controller for this system
    function accessController()
        external
        view
        returns (IAccessController controller);

    /// @notice Get the RentShare for this system
    /// @return rentShare instance  for this system
    function rentShare() external view returns (IRentShare rentShare);

    /// @notice Get the RentDistributor for this system
    /// @return rentDistributor instance  for this system
    function rentDistributor()
        external
        view
        returns (IRentDistributor rentDistributor);

    /// @notice Get the Marketplace for this system
    /// @return Marketplace instance  for this system
    function marketplace() external view returns (IMarketplace);

    /// @notice Get the TokensWhitelist for this system
    /// @return TokensWhitelist instance  for this system
    function whitelist() external view returns (IWhitelist);

    /// @notice Get the LockNFTMinter.sol for this system
    /// @return LockNFTMinter instance  for this system
    function lockNftMinter() external view returns (ILockNFT);

    /// @notice Get the LockNFT.sol for this system
    /// @return Lock NFT instance  for this system that will be used to mint lock NFTs to users to withdraw funds from system
    function lockNft() external view returns (ILockNFT);

    /// @notice Get the XeqFeeManger.sol for this system
    /// @return XeqFeeManger that will be used to tell how much fees in XEQ should be charged against base currency
    function xeqFeeManager() external view returns (IXeqFeeManager);

    /// @notice Get the XEQ.sol for this system
    /// @return Protocol XEQ token
    function xeq() external view returns (IERC20);

    /// @notice Get the RootPriceOracle.sol for the system
    /// @return RootPriceOracle to provide prices of normal erc20 tokens and Property tokens
    function rootPriceOracle() external view returns (IRootPriceOracle);

    /// @return address of TRY
    function TRY() external view returns (IERC20);

    /// @return address of USDC
    function USDC() external view returns (IERC20);

    /// @return address of xUSDC => 0xequity usdc
    function xUSDC() external view returns (IERC20);

    /// @notice router to support property swaps and some tokens swap for rent
    /// @return address of OCLR
    function oclr() external view returns (address);

    /// @return jarvis dex address
    function jarvisDex() external view returns (IJarvisDex);

    /// @return DFX router address
    function dfxRouter() external view returns (IDFXRouter);

    /// @return address of transfer manager to enforce checks on Property tokens' transfers
    function transferManager() external view returns (address);

    /// @return address of the sacntions list to enforce token transfer with checks
    function sanctionsList() external view returns (ISanctionsList);

    /// @return address of the SBT.sol that issues tokens when a user KYCs
    function sbt() external view returns (ISBT);

    /// @return address of PasskeyWalletFactory.sol
    function passkeyWalletFactory() external view returns (IPasskeyFactory);

    /// @return address of SecondaryMarket.sol
    function secondaryMarket() external view returns (ISecondaryMarket);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface ILock {
    enum LockStatus {
        CANCELLED,
        ACTIVE,
        EXECUTED
    }

    struct UserPositionLock {
        address[] collateralTokens;
        uint[] amounts;
        uint createdAt;
        LockStatus lockStatus;
    }

    struct RentShareLock {
        string[] propertySymbols;
        uint[] amounts;
        uint createdAt;
        LockStatus lockStatus;
    }

    struct OtherLock {
        bytes32[] tokensDetails;
        uint[] amount;
        uint createdAt;
        LockStatus lockStatus;
    }

    enum LockType {
        USER_POSITION_LOCK,
        RENT_SHARE_LOCK,
        OTHER_LOCK
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;
import "./ILock.sol";

interface ILockNFT is ILock {
    function lockNFT() external view returns (address);

    function updateLockNftStatus(
        uint lockNftTokenId,
        LockStatus lockStatus
    ) external;

    function lockNftToStatus(
        uint lockNftTokenId
    ) external view returns (ILock.LockStatus);

    function mintUserPositionLockNft(
        address receiver,
        ILock.UserPositionLock calldata
    ) external returns (uint);

    function mintRentShareLockNft(
        address receiver,
        ILock.RentShareLock calldata
    ) external returns (uint);

    function mintOtherLockNft(
        address receiver,
        ILock.OtherLock calldata
    ) external returns (uint);

    function nftToUserPositionLockDetails(
        uint nftTokenId
    ) external view returns (ILock.UserPositionLock memory);

    function nftToRentShareLockDetails(
        uint nftTokenId
    ) external view returns (ILock.RentShareLock memory);

    function nftToOtherLockDetails(
        uint nftTokenId
    ) external view returns (ILock.OtherLock memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IMarketplace {
    struct MarketplaceStorage {
        /// @notice represents 100%. e.g 1% = 100 // @todo remove this for production
        uint HUNDRED_PERCENT;
        /// @notice Max fees that can be charged when buying property
        uint MAX_BUY_FEES;
        /// @notice Max fees that can be charged when selling property
        uint MAX_SELL_FEES;
        /// @notice maps property symbol to property tokens address
        /// disallows same property symbols
        mapping(string => PropertyDetails) propertySymbolToDetails;
        ///@notice address of Property token implementation
        address propertyTokenImplementation;
        /// @notice keeps track of numbers of properties deployed by this Marketplace
        /// also serves the purpose of Rent Pool id in RentShare.sol
        /// means if 5th property is deployed, deployedProperties.length shows that
        /// this 5th property has rent pool id of 5 in Rentshare.sol
        address[] deployedProperties;
        /// @notice to check if a Property token is deployed by this Marketplace
        mapping(address propertyTokenAddress => bool isPropertyExist) propertyExist;
        /// @notice flag to ACTIVE/PAUSE buying of Properties tokens
        State propertiesBuyState;
        /// @notice flag to ACTIVE/PAUSE selling of Properties tokens
        State propertiesSellState;
    }

    struct SwapArgs {
        address from;
        address to;
        address recipient;
        bool isFeeInXeq;
        address[] vaults;
        uint256[] amounts; // how much tokens to buy/sell in corresponding vault
        bytes arbCallData;
    }
    enum State {
        Active,
        Paused
    }
    struct PropertyDetails {
        address baseCurrency;
        uint totalSupply;
        address propertyOwner;
        address propertyFeesReceiver;
        address propertyTokenAddress;
        uint buyFees;
        uint sellFees;
        State buyState; // by default it is active
        State sellState; // by default it is active
    }

    function isPropertyBuyingPaused(
        address propertyTokenAddress
    ) external view returns (bool);

    function isPropertySellingPaused(
        address propertyTokenAddress
    ) external view returns (bool);

    function getFeesToCharge(
        address propertyToken,
        uint amountToChargeFeesOn,
        bool isBuy
    ) external view returns (uint);

    /// @return returns amount of quote tokens paid in case of buying of property
    ///         or amount of tokens get when selling
    function swap(SwapArgs memory swapArgs) external returns (uint);

    function getPropertyPriceInQuoteCurrency(
        address baseCurrency,
        address quoteCurrency,
        uint amountInBaseCurrency // will be in 18 decimals
    ) external view returns (uint);

    function getPropertyDetails(
        address propertyAddress
    ) external view returns (PropertyDetails memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface ISecondaryMarket {
    /**
     * @notice for Marketplace: takes tokens from MP and send Proeprty tokens to MP
     * @param _propertyToken address of WLegal
     * @param _repayAmount amount of baseCurrency that is being paid to buy Property tokens
     * @param _currentPertokenPrice current price of unit Property token in Quote currency
     * @param _quoteCurrency quote currency (token which is being paid to buy property)
     * @param _recipient Buyer of Property
     * @param _vaults Vault that will hold the property tokens and provide liquidity
     * @param _amounts amount of property tokens to fetch from each vault
     */
    function buyPropertyTokens(
        address _propertyToken,
        uint256 _repayAmount,
        uint256 _currentPertokenPrice,
        address _quoteCurrency,
        address _recipient,
        address[] memory _vaults,
        uint256[] memory _amounts
    ) external;

    function sellPropertyTokens(
        uint256 _tokensToBorrow,
        address _propertyToken,
        address _recipient,
        address[] memory _vaults,
        uint256[] memory _amounts
    ) external returns (uint);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IDFXRouter {
    /// @notice view how much target amount a fixed origin amount will swap for
    /// @param _quoteCurrency the address of the quote currency (usually USDC)
    /// @param _origin the address of the origin
    /// @param _target the address of the target
    /// @param _originAmount the origin amount
    /// @return targetAmount_ the amount of target that will be returned
    function viewOriginSwap(
        address _quoteCurrency,
        address _origin,
        address _target,
        uint256 _originAmount
    ) external view returns (uint256 targetAmount_);

    /// @notice swap a dynamic origin amount for a fixed target amount
    /// @param _quoteCurrency the address of the quote currency (usually USDC)
    /// @param _origin the address of the origin
    /// @param _target the address of the target
    /// @param _originAmount the origin amount
    /// @param _minTargetAmount the minimum target amount
    /// @param _deadline deadline in block number after which the trade will not execute
    /// @return targetAmount_ the amount of target that has been swapped for the origin amount
    function originSwap(
        address _quoteCurrency,
        address _origin,
        address _target,
        uint256 _originAmount,
        uint256 _minTargetAmount,
        uint256 _deadline
    ) external returns (uint256 targetAmount_);

    /// @notice view how much of the origin currency the target currency will take
    /// @param _quoteCurrency the address of the quote currency (usually USDC)
    /// @param _origin the address of the origin
    /// @param _target the address of the target
    /// @param _targetAmount the target amount
    /// @return originAmount_ the amount of target that has been swapped for the origin
    function viewTargetSwap(
        address _quoteCurrency,
        address _origin,
        address _target,
        uint256 _targetAmount
    ) external view returns (uint256 originAmount_);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IJarvisDex {
    /**
     * @notice Mint synthetic tokens using fixed amount of collateral
     * @notice This calculate the price using on chain price feed
     * @notice User must approve collateral transfer for the mint request to succeed
     * @param mintParams Input parameters for minting (see MintParams struct)
     * @return syntheticTokensMinted Amount of synthetic tokens minted by a user
     * @return feePaid Amount of collateral paid by the user as fee
     */
    function mint(
        MintParams calldata mintParams
    ) external returns (uint256 syntheticTokensMinted, uint256 feePaid);

    // For JARVIS_DEX contract
    function mint(
        MintParams calldata mintParams,
        address poolAddress
    ) external returns (uint256 syntheticTokensMinted, uint256 feePaid);

    /**
     * @notice Redeem amount of collateral using fixed number of synthetic token
     * @notice This calculate the price using on chain price feed
     * @notice User must approve synthetic token transfer for the redeem request to succeed
     * @param redeemParams Input parameters for redeeming (see RedeemParams struct)
     * @return collateralRedeemed Amount of collateral redeem by user
     * @return feePaid Amount of collateral paid by user as fee
     */
    function redeem(
        RedeemParams calldata redeemParams
    ) external returns (uint256 collateralRedeemed, uint256 feePaid);

    // For JARVIS_DEX contract
    function redeem(
        RedeemParams calldata redeemParams,
        address poolAddress
    ) external returns (uint256 collateralRedeemed, uint256 feePaid);

    struct MintParams {
        // Minimum amount of synthetic tokens that a user wants to mint using collateral (anti-slippage)
        uint256 minNumTokens;
        // Amount of collateral that a user wants to spend for minting
        uint256 collateralAmount;
        // Expiration time of the transaction
        uint256 expiration;
        // Address to which send synthetic tokens minted
        address recipient;
    }

    struct RedeemParams {
        // Amount of synthetic tokens that user wants to use for redeeming
        uint256 numTokens;
        // Minimium amount of collateral that user wants to redeem (anti-slippage)
        uint256 minCollateral;
        // Expiration time of the transaction
        uint256 expiration;
        // Address to which send collateral tokens redeemed
        address recipient;
    }

    /**
     * @notice Returns the collateral amount will be received and fees will be paid in exchange for an input amount of synthetic tokens
     * @notice This function is only trading-informative, it doesn't check edge case conditions like lending manager dust and undercap of one or more LPs
     * @param  _syntTokensAmount Amount of synthetic tokens to be exchanged
     * @return collateralAmountReceived Collateral amount will be received by the user
     * @return feePaid Collateral fee will be paid
     */
    function getRedeemTradeInfo(
        uint256 _syntTokensAmount
    ) external view returns (uint256 collateralAmountReceived, uint256 feePaid);

    /**
     * @notice Returns the synthetic tokens will be received and fees will be paid in exchange for an input collateral amount
     * @notice This function is only trading-informative, it doesn't check edge case conditions like lending manager dust and reverting due to dust splitting
     * @param _collateralAmount Input collateral amount to be exchanged
     * @return synthTokensReceived Synthetic tokens will be minted
     * @return feePaid Collateral fee will be paid
     */
    function getMintTradeInfo(
        uint256 _collateralAmount
    ) external view returns (uint256 synthTokensReceived, uint256 feePaid);

    /**
     * @return return token that is used as collateral
     */
    function collateralToken() external view returns (address);

    /**
     * @return return token that will be minted agaisnt collateral
     */
    function syntheticToken() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @notice An oracle that can provide prices for single or multiple classes of tokens
interface IRootPriceOracle {
    // struct Property {
    //     uint256 price;
    //     address currency;
    //     address priceFeed;
    // }

    // struct Storage {
    //     mapping(string => Property) propertyDetails;
    //     mapping(address => address) currencyToFeed;
    //     mapping(string => address) nameToFeed;
    // }

    // function feedPriceChainlink(
    //     address _of
    // ) external view returns (uint256 latestPrice);

    // function setPropertyDetails(
    //     string memory _propertySymbol,
    //     Property calldata _propertyDetails
    // ) external;

    // function getPropertyDetail(
    //     string memory _propertySymbol
    // ) external view returns (Property memory property);

    // //---------------------------------------------------------------------

    // // function setCurrencyToFeed(address _currency, address _feed) external;

    // function getCurrencyToFeed(
    //     address _currency
    // ) external view returns (address);

    /// @notice Returns price for the provided token in USD when normal token e.g LINK, ETH
    /// and returns in Property's Base currency when Property Token e.g WXEFR1.
    /// @dev May require additional registration with the provider before being used for a token
    /// returns price in 18 decimals
    /// @param token Token to get the price of
    /// @return price The price of the token in USD
    function getTokenPrice(address token) external view returns (uint256 price);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

interface IRentDistributor {
    /**
     * @notice Allows user to redeem rent
     * @param lockNftTokenId LockNft id to redeem
     * @param recipient receiver of the redeemed amount
     */
    function redeem(
        uint lockNftTokenId,
        address recipient
    ) external returns (uint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRentShare {
    struct RentShareStorage {
        mapping(uint => Pool) pools; // Pool id to Pool details
        uint256 RENT_PRECISION;
        address rentToken; // token in which rent will be distributed, VTRY
        mapping(string propertySymbol => uint poolId) symbolToPoolId; // symbol of Property token -> Pool Id
        mapping(uint256 poolId => mapping(address propertyTokensHolder => PoolStaker propertyHolderDetails)) poolStakers; // Pool Id -> holder/user -> Details
        mapping(uint poolId => bool isRentActive) propertyRentStatus; // pool id => true ? rent is active : rent is paused
        mapping(address propertyTokenHolder => mapping(uint poolId => uint rentMadeSoFar)) userToPoolToRent; // user => Property Pool Id  => property rent made so far
        mapping(uint poolId => mapping(uint epochNumber => uint totalRentAccumulatedRentPerShare)) epochAccumluatedRentPerShare;
        mapping(uint poolId => uint epoch) poolIdToEpoch;
        // uint public epoch;
        mapping(uint poolId => bool isInitialized) isPoolInitialized;
        bool rentWrapperToogle; // true: means harvestRewards should only be called by a wrapper not users, false: means users can call harvestRent directly
        mapping(string propertySymbol => uint rentClaimLockDuration) propertyToRentClaimDuration; // duration in seconds after which rent can be claimed since harvestRent transaction
    }
    // Staking user for a pool
    struct PoolStaker {
        mapping(uint epoch => uint propertyTokenBalance) epochToTokenBalance;
        mapping(uint epoch => uint rentDebt) epochToRentDebt;
        uint lastEpoch;
        // uint256 amount; // Amount of Property tokens a user holds
        // uint256 rentDebt; // The amount relative to accumulatedRentPerShare the user can't get as rent
    }
    struct Pool {
        IERC20 stakeToken; // Property token
        uint256 tokensStaked; // Total tokens staked
        uint256 lastRentedTimestamp; // Last block time the user had their rent calculated
        uint256 accumulatedRentPerShare; // Accumulated rent per share times RENT_PRECISION
        uint256 rentTokensPerSecond; // Number of rent tokens minted per block for this pool
    }

    struct LockNftDetailEvent {
        address caller;
        uint lockNftTokenId;
        string propertySymbol;
        uint amount;
    }

    struct UserEpochsRent {
        uint poolId;
        address user;
        uint fromEpoch;
        uint toEpoch;
    }

    function createPool(
        IERC20 _stakeToken,
        string memory symbol,
        uint256 _poolId
    ) external;

    function deposit(
        string calldata _propertySymbol,
        address _sender,
        uint256 _amount
    ) external;

    function withdraw(
        string calldata _propertySymbol,
        address _sender,
        uint256 _amount
    ) external;

    function isLockNftMature(uint lockNftTokenId) external view returns (bool);

    function harvestRent(
        string[] calldata symbols,
        address receiver
    ) external returns (uint);

    function getSymbolToPropertyAddress(
        string memory symbol
    ) external view returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

interface ISanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

interface ISBT {
    // events

    event CommunityAdded(string indexed name);
    event CommunityRemoved(string indexed name);
    event ApprovedCommunityAdded(
        string indexed wrappedProperty,
        string indexed community
    );
    event ApprovedCommunityRemoved(
        string indexed wrappedProperty,
        string indexed community
    );
    event BulkApprovedCommunities(
        string indexed wrappedProperty,
        string[] communities
    );
    event BulkRemoveCommunities(
        string indexed wrappedProperty,
        string[] communities
    );

    struct SBTStorage {
        //is community approved
        mapping(string => bool) nameExist;
        mapping(string => uint256) communityToId;
        mapping(uint256 => bool) idExist;
        //approved communities against wrapped property token.
        mapping(string => mapping(string => bool)) approvedSBT;
        //approved communities list against wrapped property token.
        mapping(string => string[]) approvedSBTCommunities;
        // communityId => key => encoded data
        mapping(uint => mapping(bytes32 => bytes)) communityToKeyToValue;
        // community id -> key -> does exist or not?
        mapping(uint => mapping(bytes32 => bool)) keyExistsInCommunity;
        // registry of blacklisted address by 0x40C57923924B5c5c5455c48D93317139ADDaC8fb
        address sanctionsList;
    }

    function getApprovedSBTCommunities(
        string memory symbol
    ) external view returns (string[] memory);

    function getBalanceOf(
        address user,
        string memory community
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IAccessControlEnumerable} from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

interface IAccessController is IAccessControlEnumerable {
    error AccessDenied();

    function setupRole(bytes32 role, address account) external;

    function verifyOwner(address account) external view;

    function grantPropertyTokenRole(address propertyToken) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface ISystemSecurity {
    /// @notice Whether or not the system as a whole is paused
    function isSystemPaused() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IMintableBurnableERC20 {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

interface IVault {
    function buyPropertyTokens(
        address _propertyToken,
        uint256 _amountOfTokens,
        address _recipient,
        uint _repayAmount,
        address _propertyBasecurrency
    ) external;

    function borrow(
        address propertyToken,
        uint noOfPropertyToken,
        uint256 amountToBorrow,
        address recipient
    ) external returns (uint);

    function fees() external view returns (uint);

    function notifyProfit(uint256 _amount) external;

    function nofityLoss(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPasskeyFactory {
    function updatePasskeySigner(
        bytes32 emailHash,
        address currentSigner,
        address newSigner // ignore 2 steps ownership transfer
    ) external;

    /// @notice returns true of deplpoyed from factory, false otherwise
    function isDeployedFromHere(
        address passkeyWallet
    ) external view returns (bool);

    function computeAddress(
        bytes32 salt,
        address signerIfAny
    ) external view returns (address);

    function recoveryCoolDownPeriod() external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/**
 * @title An interface to track a whitelist of addresses.
 */
interface IWhitelist {
    /**
     * @notice Adds an address to the whitelist.
     * @param newToken the new address to add.
     */
    function addTokenToWhitelist(address newToken) external;

    /**
     * @notice Removes an address from the whitelist.
     * @param tokenToRemove The existing address to remove.
     */
    function removeTokenFromWhitelist(address tokenToRemove) external;

    /**
     * @notice Checks whether an address is on the whitelist.
     * @param tokenToCheck The address to check.
     * @return True if `tokenToCheck` is on the whitelist, or False.
     */
    function isTokenOnWhitelist(
        address tokenToCheck
    ) external view returns (bool);

    /**
     * @notice Checks whether an address is on the whitelist.
     * @param addressToCheck The address to check.
     * @return True if `addressToCheck` is on the whitelist, or False.
     */
    function isAddressOnAllowList(
        address addressToCheck
    ) external view returns (bool);

    /**
     * @notice Gets all addresses that are currently included in the whitelist.
     * @return The list of addresses on the whitelist.
     */
    function getTokenWhitelist() external view returns (address[] memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

library Roles {
    // --------------------------------------------------------------------
    // Central roles list used by all contracts that call AccessController
    // --------------------------------------------------------------------

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant FREEZE_UNFREEZE_ROLE =
        keccak256("FREEZE_UNFREEZE_ROLE");
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");
    bytes32 public constant EMERGENCY_PAUSER = keccak256("EMERGENCY_PAUSER");
    bytes32 public constant MARKETPLACE_MANAGER =
        keccak256("MARKETPLACE_MANAGER");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant RENT_MANAGER_ROLE = keccak256("RENT_MANAGER_ROLE");
    bytes32 public constant RENT_DELEGATOR_ROLE =
        keccak256("RENT_DELEGATOR_ROLE"); // This role holder can harvestRent() on other user behalf
    bytes32 public constant RENT_POOL_CREATOR_ROLE =
        keccak256("RENT_POOL_CREATOR_ROLE");
    bytes32 public constant PROPERTY_TOKEN_ROLE =
        keccak256("PROPERTY_TOKEN_ROLE");

    // to call to access controller and grant PROPERTY_TOKEN_ROLE to deployed property
    bytes32 public constant MARKETPLACE_ROLE = keccak256("MARKETPLACE_ROLE");
    bytes32 public constant MARKETPLACE_BORROWER_ROLE =
        keccak256("MARKETPLACE_BORROWER_ROLE");
    bytes32 public constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");
    bytes32 public constant LOCKNFT_ADMIN = keccak256("LOCKNFT_ADMIN"); // Role to change and update URI on LockNft.sol
    bytes32 public constant LOCKNFT_MINTER = keccak256("LOCKNFT_MINTER"); // Role a wrapper contract should have to call to LockNft.sol to mint lock NFTs
    bytes32 public constant LOCKNFT_MINTER_CALLER =
        keccak256("LOCKNFT_MINTER_CALLER"); // Role to have to call LockNftMinter.sol. This role will be possed by user positions, Rentshare , rentDistributor etc.
    // only whitelisted contracts can call swap to buy/sell properties
    // user will call those whitelisted contracts to buy/sell
    // This role will be given to OCLRouter.sol for now.
    bytes32 public constant MARKETPLACE_SWAPPER =
        keccak256("MARKETPLACE_SWAPPER");
    // this role will be used to call harvest and redeem rent functions on RentShare and RentDistributor contracts
    // when a flag will be on
    bytes32 public constant RENT_WRAPPER = keccak256("RENT_WRAPPER");
    bytes32 public constant PASSKEY_FACTORY_MANAGER =
        keccak256("PASSKEY_FACTORY_MANAGER");
    // will be responsible for oracle related admin stuff
    bytes32 public constant ORACLE_MANAGER = keccak256("ORACLE_MANAGER");
    bytes32 public constant VAULT_MANAGER = keccak256("VAULT_MANAGER");
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ISecondaryMarket} from "./../interfaces/marketplace/ISecondaryMarket.sol";
import {ISystemRegistry} from "./../interfaces/ISystemRegistry.sol";
import {SecurityBase} from "./../security/SecurityBase.sol";

import "./SecondaryMarketPositionManager.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {SystemComponent} from "./../SystemComponent.sol";
import {Pausable} from "./../security/Pausable.sol";
import {Errors} from "./../utils/Errors.sol";
import {Roles} from "./../libs/Roles.sol";
import {IMintableBurnableERC20} from "./../interfaces/tokens/IMintableBurnableERC20.sol";
import {IVault} from "./../interfaces/vaults/IVault.sol";

/**
 * @title MpBorrower
 * @notice When user wants to sell property, this contract borrows from ERC4626 and give asked currency to marketplace.
 */

// @todo add a whitelist of vaults, only those vaults should be callable
contract SecondaryMarketplace is
    SystemComponent,
    SecurityBase,
    Pausable,
    ISecondaryMarket,
    SecondaryMarketPositionManager
{
    using SafeERC20 for IERC20;
    //----------------------------------------
    // Storage
    //----------------------------------------

    address public allowedMarketplace;
    // events

    event AllowedMarketplaceUpdated(address _marketplace);
    event PoolToBorrowFromUpdated(address _newPool);

    /**
     * @notice creates Initializes the contract.
     * @param _allowedMarketplace address of Marketplace.sol that can call this contract
     * @param _systemRegistry address of SystemRegistry.sol
     */
    constructor(
        address _allowedMarketplace,
        ISystemRegistry _systemRegistry
    )
        SystemComponent(_systemRegistry)
        SecurityBase(address(_systemRegistry.accessController()))
        Pausable(_systemRegistry)
    {
        allowedMarketplace = _allowedMarketplace;
    }

    /**
     * @notice changes the address of Marketplace who can interact with this contract.
     * @param _marketPlace allowed marketplace that can call specific functions in this contract
     */
    function setAllowedMarketPlace(address _marketPlace) external onlyOwner {
        allowedMarketplace = _marketPlace;
        emit AllowedMarketplaceUpdated(_marketPlace);
    }

    /**
     * @notice for Marketplace: This mints X tokens to Marketplace against Property tokens
     * @param _propertyTokensValue vaule of property tokens sold in baseCurrency
     * @param _propertyToken address of WLegal
     * @param _recipient Receiver of tokens
     */
    function sellPropertyTokens(
        uint256 _propertyTokensValue,
        address _propertyToken,
        address _recipient,
        address[] memory _vaults,
        uint256[] memory _amounts
    ) external returns (uint) {
        // @todo apply disciuted rate mecahnism
        _verifyCaller();
        uint noOfTokens = _getArraySum(_amounts);
        uint perTokenPrice = _propertyTokensValue / noOfTokens;
        IERC20(_propertyToken).safeTransferFrom(
            msg.sender,
            address(this),
            noOfTokens
        );
        uint totalAmountPaidToUserAfterFees;
        {
            for (uint i = 0; i < _vaults.length; i++) {
                require(
                    _vaults[0] != address(0) && _amounts[0] > 0,
                    "Invalid Vault or amount"
                );
                uint amountAfterFees; // amount paid to user
                IERC20(_propertyToken).safeIncreaseAllowance(
                    _vaults[i],
                    _amounts[i]
                );
                uint currentValueOfPropertyTokens = _amounts[i] * perTokenPrice; //actual value of _amounts[i], means fees is not deducted yet
                amountAfterFees =
                    currentValueOfPropertyTokens -
                    _calcFees(
                        currentValueOfPropertyTokens,
                        _getVaultFees(_vaults[i])
                    );
                require(
                    IVault(_vaults[i]).borrow(
                        _propertyToken,
                        _amounts[i],
                        currentValueOfPropertyTokens,
                        _recipient
                    ) == amountAfterFees,
                    "Borrow failed"
                );
                addBorrowPosition(
                    _propertyToken,
                    amountAfterFees,
                    _amounts[i],
                    _vaults[i]
                );
                totalAmountPaidToUserAfterFees += amountAfterFees;
            }
        }
        return totalAmountPaidToUserAfterFees;
        // @todo check if vault have enough liquidity, if it have, then just convert the xUSDC to USDC
    }

    /**
     * @notice for Marketplace: this converts baseCurrency to x-Tokens using CustomVault and repays to ERC4626 Vault and buys Property tokens from ERC4626Vault
     * @param _propertyToken address of WLegal
     * @param _repayAmount amount of baseCurrency that is being paid to ERC4626Vault
     * @param _currentPertokenPrice current price of unit Property token
     * @param _quoteCurrency quote currency (token which is being paid to buy property)
     * @param _vaults Vault that will hold the property tokens and provide liquidity
     * @param _amounts amount of property tokens to fetch from each vault
     */

    function buyPropertyTokens(
        address _propertyToken,
        uint256 _repayAmount,
        uint256 _currentPertokenPrice,
        address _quoteCurrency,
        address _recipient,
        address[] memory _vaults,
        uint256[] memory _amounts
    ) external {
        // @todo abstraction with regard to token = > wrapper contract for etc uniswap
        _verifyCaller();
        IERC20(_quoteCurrency).safeTransferFrom(
            msg.sender,
            address(this),
            _repayAmount
        );
        // @todo add a refunding mechanism => if user pays more and gets less tokens

        uint arrLength = _vaults.length;
        uint amountpaidToBuy;
        uint index = _vaults[0] == address(0) ? 1 : 0; // to skip the first index if it is zero address
        for (; index < arrLength; index++) {
            require(
                _vaults[index] != address(0) && _amounts[index] > 0,
                "Invalid Vault or amount"
            );
            amountpaidToBuy = _amounts[index] * _currentPertokenPrice;
            // @todo do the safeApprove stuff from a lib that enforces relavant checks e.g allowance is zero etc
            IERC20(_quoteCurrency).safeIncreaseAllowance(
                _vaults[index],
                amountpaidToBuy
            );
            // sending tokens to buyer directly
            IVault(_vaults[index]).buyPropertyTokens(
                _propertyToken,
                _amounts[index],
                _recipient,
                amountpaidToBuy,
                _quoteCurrency
            );
            // @todo keep track of remaining
            repay(
                _repayAmount,
                _propertyToken,
                _currentPertokenPrice,
                _vaults[index]
            );
        }

        // this step not required
        // _storageParams._repayToCustomVault(_repayAmount, lastProfitSentToGauge);

        // @todo to be done after the repay.
        // _stora geParams._afterRepay(remaining);
    }

    /**
     * @return allowedMarketPlace address of Marketplace who can borrow and buyProperty tokens using this contract.
     */
    function getAllowedMarketplaceAddress() external view returns (address) {
        return allowedMarketplace;
    }

    function _getArraySum(uint[] memory amounts) public pure returns (uint) {
        uint sum = 0;
        uint length = amounts.length;
        for (uint i = 0; i < length; i++) {
            sum += amounts[i];
        }
        return sum;
    }

    // verfies if caller is Marketplace or not
    function _verifyCaller() internal view {
        require(msg.sender == allowedMarketplace, "Caller not marketplace");
    }

    function _getVaultFees(address vault) internal view returns (uint) {
        return IVault(vault).fees();
    }

    function _calcFees(uint amount, uint fees) internal pure returns (uint) {
        return (amount * fees) / 10000; // 10000 => 100%, so, fee = 1000 means 10%
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;
import "./../interfaces/vaults/IVault.sol";
/**
 * @title PositionManager
 * @notice To keep track of borrow positions b/w ERC4626 and Marketplace and Profit and loss.
 */
contract SecondaryMarketPositionManager {
    struct BorrowPosition {
        uint256 borrowedAmount;
        uint256 borrowAmountFilled;
        uint256 profitEarned;
        address wLegalAddress;
        uint256 tokenSold;
        uint256 lossFilled;
        uint256 noOfTokens;
        uint256 actualCost;
    }

    /// @notice maps property to vault to all borrow positions this property has.
    mapping(address => mapping(address => BorrowPosition[]))
        public propertyToVaultToPositions;

    /// @notice maps property to last repaid (not neccassarily full) borrow position index
    mapping(address => mapping(address => uint256))
        public propertyToVaultToBorrowCursor;

    /**
     * @notice _property address of WLegal Token
     * @return total borrow positions this property has so far.
     */
    function getPropertyToVaultTotalPositions(
        address _property,
        address vault
    ) external view returns (uint) {
        return propertyToVaultToPositions[_property][vault].length;
    }

    /**
     * @notice adds borrow position and keeps track how property tokens are bought by ERC4626Vault and sent x-tokens to Marketplace
     * @param wLegalAddress address of WrappedLegal bought bu ERC4626Vault
     * @param  borrowAmount amount of xTokens sent to MarketplaceBorrower in order to buy property tokens
     * @param  noOfTokens number of property tokens bought by ERC4626Vault in this tx.
     */
    function addBorrowPosition(
        address wLegalAddress,
        uint256 borrowAmount,
        uint256 noOfTokens,
        address vaultAddress
    ) internal returns (uint256) {
        BorrowPosition memory p;
        p.borrowedAmount = borrowAmount;
        p.noOfTokens = noOfTokens;
        p.actualCost = borrowAmount / noOfTokens;
        p.wLegalAddress = wLegalAddress;

        propertyToVaultToPositions[wLegalAddress][vaultAddress].push(p);
        return
            propertyToVaultToPositions[wLegalAddress][vaultAddress].length - 1;
    }

    /**
     * @notice updates/closes the positiosn whose borrowed amount has been repaid
     * @param repayAmount amount repaid of  xusdc
     * @param  wLegalAddress address of WLegal token
     * @param  currentPertokenPrice current price of WLegal to calculate profit/loss.
     * @param  poolToBorrowFrom address of ERC4626Vault
     * @return remaining if there remains any amount after repaying all the positions
     */
    function repay(
        uint256 repayAmount,
        address wLegalAddress,
        uint256 currentPertokenPrice,
        address poolToBorrowFrom
    ) internal returns (uint256 remaining) {
        // 4500
        remaining = repayAmount;

        BorrowPosition storage _positions;
        //  15 = 4500 / 300
        uint256 sharesCounter = repayAmount / currentPertokenPrice;
        uint256 priceDiff;
        //uint maxProfitOfPosition;
        //uint maxLossOfPosition;
        uint256 totalProfit;
        uint256 totalLoss;
        uint256 pendingAmount;
        uint256 pendingShares;
        uint256 matched;
        uint256 acutalSale;

        // Loop through positions until the entire repay amount is processed
        while (remaining > 0) {
            _positions = propertyToVaultToPositions[wLegalAddress][
                poolToBorrowFrom
            ][propertyToVaultToBorrowCursor[wLegalAddress][poolToBorrowFrom]];

            // true = 300 >= 175
            // Flag to determine profit or loss based on current vs. borrowed price
            bool flag = currentPertokenPrice >= _positions.actualCost; // true means profit: false means loss

            // 15  === [10,5]
            // 20 == [10,10]
            // 2 = [2]
            // Calculate the number of shares available to sell from this position
            pendingShares = _positions.noOfTokens - _positions.tokenSold;
            // 10

            // Determine the actual number of shares to sell from this position (limited by remaining shares or available shares)
            acutalSale = pendingShares > sharesCounter
                ? sharesCounter
                : pendingShares;
            _positions.tokenSold += acutalSale;
            sharesCounter -= acutalSale;
            // When the flag is true
            // Calculating our profit
            if (flag) {
                priceDiff = currentPertokenPrice - _positions.actualCost;
                totalProfit = priceDiff * acutalSale;
            }
            // when the flag is false
            // Calculating our loss
            else {
                // we will loss when we even dont receive back our invested amount
                priceDiff = _positions.actualCost - currentPertokenPrice;
                totalLoss = acutalSale * priceDiff;
            }

            // is transaction total profit / loss
            //if the flag is true means we are in profit

            if (flag) {
                //  3000 - 110
                // totalIpust - profit

                //Below branch/condition is needed to be cover

                if (totalProfit <= remaining) {
                    _positions.profitEarned += totalProfit;
                    remaining -= totalProfit;
                } else {
                    // If profit is higher than remaining amount, update profit with remaining and set remaining to 0

                    _positions.profitEarned += remaining;
                    remaining -= remaining;
                }
            } else {
                // If there's a loss, update loss filled
                _positions.lossFilled += totalLoss;
            }
            // 2890
            // Calculate remaining amount to be borrowed from this position
            pendingAmount =
                _positions.borrowedAmount -
                _positions.lossFilled -
                _positions.borrowAmountFilled;
            matched = remaining > pendingAmount ? pendingAmount : remaining; // Determine amount to be matched from this position
            _positions.borrowAmountFilled += matched;
            remaining -= matched;

            if (
                // 2890 = 0+  2890
                // Borrowed amount is fully covered by filled loss and filled borrow amount
                // incase of loss: loss amount + filled amount == borrowed amount, means position is settled but in loss
                _positions.borrowedAmount ==
                _positions.lossFilled + _positions.borrowAmountFilled ||
                // _positions.profitEarned == profitEarned ||
                // 10 * 300 = 1250+ 1750

                _positions.noOfTokens * currentPertokenPrice ==
                _positions.profitEarned + _positions.borrowAmountFilled
            ) {
                // **This block executes when either condition is met, indicating full repayment within the current position**
                /// Notifiy reward against filled position
                calculateAndNotifyProfitOrLoss(_positions, poolToBorrowFrom);

                propertyToVaultToBorrowCursor[wLegalAddress][
                    poolToBorrowFrom
                ]++;
            }
            if (checkToBreakLoop(wLegalAddress, poolToBorrowFrom)) {
                break;
            }
        }
        return remaining;
    }

    /**
     * @notice Calculates and notify profit or loss made for the position.
     * @param _position position that is being repayed
     * @param _poolToBorrowFrom address of ERC4626Vault
     */
    function calculateAndNotifyProfitOrLoss(
        BorrowPosition memory _position,
        address _poolToBorrowFrom
    ) internal {
        if (_position.profitEarned == _position.lossFilled) return;

        if (_position.profitEarned > _position.lossFilled) {
            uint256 profitToRealize = _position.profitEarned -
                _position.lossFilled;
            IVault(_poolToBorrowFrom).notifyProfit(profitToRealize);
        } else {
            uint256 lossToRealize = _position.lossFilled -
                _position.profitEarned;
            IVault(_poolToBorrowFrom).nofityLoss(lossToRealize);
        }
    }

    /**
     * @notice checks whether if there are further positions to be repaid
     * @return true: when there are no positions remaining to repay. false: there are still position remaining
     */
    function checkToBreakLoop(
        address wLegalAddress,
        address vault
    ) internal view returns (bool) {
        return
            propertyToVaultToBorrowCursor[wLegalAddress][vault] >
            propertyToVaultToPositions[wLegalAddress][vault].length - 1;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Roles} from "./../libs/Roles.sol";
import {Errors} from "./../utils/Errors.sol";
import {SystemComponent} from "./../SystemComponent.sol";
import {SecurityBase} from "./SecurityBase.sol";
import {ISystemRegistry} from "./../interfaces/ISystemRegistry.sol";
import {IAccessController} from "./../interfaces/security/IAccessController.sol";
import {ISystemSecurity} from "./../interfaces/security/ISystemSecurity.sol";

//ERRORS
error IsPaused();
error IsNotPaused();

/**
 * @notice Contract which allows children to implement an emergency stop mechanism that can be trigger
 * by an account that has been granted the EMERGENCY_PAUSER role.
 * Makes available the `whenNotPaused` and `whenPaused` modifiers.
 * Respects a system level pause from the System Security.
 */
abstract contract Pausable {
    IAccessController private immutable _accessController;
    ISystemSecurity private immutable _systemSecurity;

    /// @dev Emitted when the pause is triggered by `account`.
    event Paused(address account);

    /// @dev Emitted when the pause is lifted by `account`.
    event Unpaused(address account);

    bool private _paused;

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    modifier isPauser() {
        if (!_accessController.hasRole(Roles.EMERGENCY_PAUSER, msg.sender)) {
            revert Errors.AccessDenied();
        }
        _;
    }

    constructor(ISystemRegistry systemRegistry) {
        Errors.verifyNotZero(address(systemRegistry), "systemRegistry");

        // Validate the registry is in a state we can use it
        IAccessController accessController = systemRegistry.accessController();
        if (address(accessController) == address(0)) {
            revert Errors.RegistryItemMissing("accessController");
        }
        ISystemSecurity systemSecurity = systemRegistry.systemSecurity();
        if (address(systemSecurity) == address(0)) {
            revert Errors.RegistryItemMissing("systemSecurity");
        }

        _accessController = accessController;
        _systemSecurity = systemSecurity;
    }

    /// @notice Pauses the contract
    /// @dev Reverts if already paused or not EMERGENCY_PAUSER role
    function pause() external virtual isPauser {
        if (_paused) {
            revert IsPaused();
        }

        _paused = true;

        emit Paused(msg.sender);
    }

    /// @notice Unpauses the contract
    /// @dev Reverts if not paused or not EMERGENCY_PAUSER role
    function unpause() external virtual isPauser {
        if (!_paused) {
            revert IsNotPaused();
        }

        _paused = false;

        emit Unpaused(msg.sender);
    }

    /// @notice Returns true if the contract or system is paused, and false otherwise.
    function paused() public view virtual returns (bool) {
        return _paused || _systemSecurity.isSystemPaused();
    }

    /// @dev Throws if the contract or system is paused.
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert IsPaused();
        }
    }

    /// @dev Throws if the contract or system is not paused.
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert IsNotPaused();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IAccessController} from "./../interfaces/security/IAccessController.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Errors} from "./../utils/Errors.sol";

//ERROR
error UndefinedAddress();

contract SecurityBase {
    IAccessController public immutable accessController;

    constructor(address _accessController) {
        if (_accessController == address(0)) revert UndefinedAddress();

        accessController = IAccessController(_accessController);
    }

    modifier onlyOwner() {
        accessController.verifyOwner(msg.sender);
        _;
    }

    modifier hasRole(bytes32 role) {
        if (!accessController.hasRole(role, msg.sender))
            revert Errors.AccessDenied();
        _;
    }

    ///////////////////////////////////////////////////////////////////
    //
    //  Forward all the regular methods to central security module
    //
    ///////////////////////////////////////////////////////////////////

    function _hasRole(
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return accessController.hasRole(role, account);
    }

    // NOTE: left commented forward methods in here for potential future use
    //     function _getRoleAdmin(bytes32 role) internal view returns (bytes32) {
    //         return accessController.getRoleAdmin(role);
    //     }
    //
    //     function _grantRole(bytes32 role, address account) internal {
    //         accessController.grantRole(role, account);
    //     }
    //
    //     function _revokeRole(bytes32 role, address account) internal {
    //         accessController.revokeRole(role, account);
    //     }
    //
    //     function _renounceRole(bytes32 role, address account) internal {
    //         accessController.renounceRole(role, account);
    //     }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {ISystemComponent} from "./interfaces/ISystemComponent.sol";
import {ISystemRegistry} from "./interfaces/ISystemRegistry.sol";
import {Errors} from "./utils/Errors.sol";

contract SystemComponent is ISystemComponent {
    ISystemRegistry internal immutable systemRegistry;

    constructor(ISystemRegistry _systemRegistry) {
          Errors.verifyNotZero(address(_systemRegistry), "_systemRegistry");
        systemRegistry = _systemRegistry;
    }

    function getSystemRegistry() external view returns (address) {
        return address(systemRegistry);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

library Errors {
    using Address for address;
    ///////////////////////////////////////////////////////////////////
    //                       Set errors
    ///////////////////////////////////////////////////////////////////

    error AccessDenied();
    error ZeroAddress(string paramName);
    error ZeroAmount();
    error InsufficientBalance(address token);
    error AssetNotAllowed(address token);
    error InvalidAddress(address addr);
    error InvalidParam(string paramName);
    error InvalidParams();
    error AlreadySet(string param);
    error ArrayLengthMismatch(uint256 length1, uint256 length2, string details);
    error RegistryItemMissing(string item);
    error SystemMismatch(address source1, address source2);

    error ItemNotFound();
    error ItemExists();
    error MissingRole(bytes32 role, address user);
    error NotRegistered();
    // Used to check storage slot is empty before setting.
    error MustBeZero();
    // Used to check storage slot set before deleting.
    error MustBeSet();

    error ApprovalFailed(address token);

    error InvalidToken(address token);

    function verifyArrayLengths(
        uint256 length1,
        uint256 length2,
        string memory details
    ) external pure {
        if (length1 != length2) {
            revert ArrayLengthMismatch(length1, length2, details);
        }
    }

    function verifyNotZero(
        address addr,
        string memory paramName
    ) internal pure {
        if (addr == address(0)) {
            revert ZeroAddress(paramName);
        }
    }

    function verifyNotEmpty(
        string memory val,
        string memory paramName
    ) internal pure {
        if (bytes(val).length == 0) {
            revert InvalidParam(paramName);
        }
    }

    function verifyNotZero(uint256 num, string memory paramName) internal pure {
        if (num == 0) {
            revert InvalidParam(paramName);
        }
    }

    function verifySystemsMatch(
        address component1,
        address component2
    ) internal view {
        bytes memory call = abi.encodeWithSignature("getSystemRegistry()");

        address registry1 = abi.decode(
            component1.functionStaticCall(call),
            (address)
        );
        address registry2 = abi.decode(
            component2.functionStaticCall(call),
            (address)
        );

        if (registry1 != registry2) {
            revert SystemMismatch(component1, component2);
        }
    }
}