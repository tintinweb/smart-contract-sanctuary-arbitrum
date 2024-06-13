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

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { UintUtils } from '../../utils/UintUtils.sol';
import { IAccessControlInternal } from './IAccessControlInternal.sol';
import { AccessControlStorage } from './AccessControlStorage.sol';

/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract AccessControlInternal is IAccessControlInternal {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UintUtils for uint256;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /*
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function _hasRole(
        bytes32 role,
        address account
    ) internal view virtual returns (bool) {
        return
            AccessControlStorage.layout().roles[role].members.contains(account);
    }

    /**
     * @notice revert if sender does not have given role
     * @param role role to query
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, msg.sender);
    }

    /**
     * @notice revert if given account does not have given role
     * @param role role to query
     * @param account to query
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        'AccessControl: account ',
                        account.toString(),
                        ' is missing role ',
                        uint256(role).toHexString(32)
                    )
                )
            );
        }
    }

    /*
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function _getRoleAdmin(
        bytes32 role
    ) internal view virtual returns (bytes32) {
        return AccessControlStorage.layout().roles[role].adminRole;
    }

    /**
     * @notice set role as admin role
     * @param role role to set
     * @param adminRole admin role to set
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = _getRoleAdmin(role);
        AccessControlStorage.layout().roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /*
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.add(account);
        emit RoleGranted(role, account, msg.sender);
    }

    /*
     * @notice unassign role from given account
     * @param role role to unassign
     * @parm account
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.remove(account);
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function _renounceRole(bytes32 role) internal virtual {
        _revokeRole(role, msg.sender);
    }

    /**
     * @notice query role for member at given index
     * @param role role to query
     * @param index index to query
     */
    function _getRoleMember(
        bytes32 role,
        uint256 index
    ) internal view virtual returns (address) {
        return AccessControlStorage.layout().roles[role].members.at(index);
    }

    /**
     * @notice query role for member count
     * @param role role to query
     */
    function _getRoleMemberCount(
        bytes32 role
    ) internal view virtual returns (uint256) {
        return AccessControlStorage.layout().roles[role].members.length();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';

library AccessControlStorage {
    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.AccessControl');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial AccessControl interface needed by internal functions
 */
interface IAccessControlInternal {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, value);
    }

    function indexOf(
        AddressSet storage set,
        address value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(
        UintSet storage set,
        uint256 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        return set._inner._values;
    }

    function toArray(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] storage values = set._inner._values;
        address[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function toArray(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] storage values = set._inner._values;
        uint256[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _indexOf(
        Set storage set,
        bytes32 value
    ) private view returns (uint256) {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            status = true;
        }
    }

    function _remove(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            status = true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
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
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { AccessControlInternal } from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";
import { AccessControlStorage } from "@solidstate/contracts/access/access_control/AccessControlStorage.sol";
import { IPaymentModule } from "../interfaces/IPaymentModule.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { LibPaymentModuleStorage } from "../libraries/LibPaymentModuleStorage.sol";
import { LibPaymentModuleConsts } from "../libraries/LibPaymentModuleConsts.sol";
import { LibCommonConsts } from "../libraries/LibCommonConsts.sol";
import { IPlatformModule } from "../interfaces/IPlatformModule.sol";
import { IPricingModule } from "../interfaces/IPricingModule.sol";
import { LibSwapTokens } from "../libraries/LibSwapTokens.sol";

contract PaymentModuleFacet is IPaymentModule, AccessControlInternal {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line func-name-mixedcase
    function PAYMENT_PROCESSOR_ROLE() external pure override returns (bytes32) {
        return LibPaymentModuleConsts.PAYMENT_PROCESSOR_ROLE;
    }

    function adminWithdraw(address tokenAddress, uint256 amount, address treasury) external override onlyRole(AccessControlStorage.DEFAULT_ADMIN_ROLE) {
        if (tokenAddress == address(0)) {
            // We specifically ignore this return value.
            (bool success, ) = payable(treasury).call{ value: amount }("");
            require(success, "Failed to transfer ETH to treasury");
        } else {
            IERC20(tokenAddress).safeTransfer(treasury, amount);
        }
    }

    function setUsdToken(address newUsdToken) external override onlyRole(AccessControlStorage.DEFAULT_ADMIN_ROLE) {
        LibPaymentModuleStorage.DiamondStorage storage ds = LibPaymentModuleStorage.diamondStorage();
        ds.usdToken = newUsdToken;
    }

    function setRouterAddress(address newRouter) external override onlyRole(AccessControlStorage.DEFAULT_ADMIN_ROLE) {
        LibPaymentModuleStorage.DiamondStorage storage ds = LibPaymentModuleStorage.diamondStorage();
        ds.router = newRouter;
    }

    function addAcceptedToken(AcceptedToken memory acceptedToken) external override onlyRole(AccessControlStorage.DEFAULT_ADMIN_ROLE) {
        LibPaymentModuleStorage.DiamondStorage storage ds = LibPaymentModuleStorage.diamondStorage();

        require(acceptedToken.router != address(0), "PaymentModule::addAcceptedToken::ZERO: router cannot be zero.");
        require(bytes(acceptedToken.name).length > 0, "PaymentModule::addAcceptedToken::ZERO: name cannot be empty.");
        require(ds.acceptedTokenByAddress[acceptedToken.token].router == address(0), "PaymentModule::addAcceptedToken::ALREADY_EXISTS");

        ds.acceptedTokenByAddress[acceptedToken.token] = acceptedToken;
        ds.acceptedTokens.push(acceptedToken.token);
    }

    function removeAcceptedToken(address tokenAddress) external override onlyRole(AccessControlStorage.DEFAULT_ADMIN_ROLE) {
        LibPaymentModuleStorage.DiamondStorage storage ds = LibPaymentModuleStorage.diamondStorage();
        delete ds.acceptedTokenByAddress[tokenAddress];
        bool found = false;
        for (uint256 index = 0; index < ds.acceptedTokens.length; index++) {
            if (ds.acceptedTokens[index] == tokenAddress) {
                ds.acceptedTokens[index] = ds.acceptedTokens[ds.acceptedTokens.length - 1];
                ds.acceptedTokens.pop();
                found = true;
                break;
            }
        }

        require(found, "PaymentModuleFacet::removeAcceptedToken::TOKEN_NOT_FOUND");
    }

    function updateAcceptedToken(AcceptedToken memory acceptedToken) external override onlyRole(AccessControlStorage.DEFAULT_ADMIN_ROLE) {
        LibPaymentModuleStorage.DiamondStorage storage ds = LibPaymentModuleStorage.diamondStorage();
        address oldAcceptedToken = ds.acceptedTokenByAddress[acceptedToken.token].token;
        ds.acceptedTokenByAddress[acceptedToken.token] = acceptedToken;
        bool found = false;
        for (uint256 index = 0; index < ds.acceptedTokens.length; index++) {
            if (ds.acceptedTokens[index] == oldAcceptedToken) {
                ds.acceptedTokens[index] = acceptedToken.token;
                found = true;
                break;
            }
        }

        require(found, "PaymentModuleFacet::updateAcceptedToken::TOKEN_NOT_FOUND");
    }

    function setV3PoolFeeForTokenNative(address token, uint24 poolFee) external override onlyRole(AccessControlStorage.DEFAULT_ADMIN_ROLE) {
        LibPaymentModuleStorage.DiamondStorage storage ds = LibPaymentModuleStorage.diamondStorage();
        ds.v3PoolFeeForNativeByToken[token] = poolFee;
    }

    function getUsdToken() external view override returns (address) {
        LibPaymentModuleStorage.DiamondStorage storage ds = LibPaymentModuleStorage.diamondStorage();
        return ds.usdToken;
    }

    function getPaymentByIndex(uint256 paymentIndex) external view override returns (ProcessPaymentOutput memory) {
        LibPaymentModuleStorage.DiamondStorage storage ds = LibPaymentModuleStorage.diamondStorage();
        return ds.paymentProcessed[paymentIndex];
    }

    function getV3PoolFeeForTokenWithNative(address token) external view override returns (uint24) {
        LibPaymentModuleStorage.DiamondStorage storage ds = LibPaymentModuleStorage.diamondStorage();
        return ds.v3PoolFeeForNativeByToken[token];
    }

    function isV2Router() external view override returns (bool) {
        LibPaymentModuleStorage.DiamondStorage storage ds = LibPaymentModuleStorage.diamondStorage();
        return ds.isV2Router;
    }

    function getRouterAddress() external view override returns (address) {
        LibPaymentModuleStorage.DiamondStorage storage ds = LibPaymentModuleStorage.diamondStorage();
        return ds.router;
    }

    function getAcceptedTokenByAddress(address tokenAddress) external view override returns (IPaymentModule.AcceptedToken memory) {
        LibPaymentModuleStorage.DiamondStorage storage ds = LibPaymentModuleStorage.diamondStorage();
        return ds.acceptedTokenByAddress[tokenAddress];
    }

    function getAcceptedTokens() external view override returns (address[] memory) {
        LibPaymentModuleStorage.DiamondStorage storage ds = LibPaymentModuleStorage.diamondStorage();
        return ds.acceptedTokens;
    }

    function getQuoteTokenPrice(address token0, address token1) external view override returns (uint256 price) {
        require(token0 != token1, "PaymentModuleFacet::getQuoteTokenPrice::INVALID_TOKENS");

        LibPaymentModuleStorage.DiamondStorage storage ds = LibPaymentModuleStorage.diamondStorage();

        if (ds.isV2Router == true) {
            price = LibSwapTokens._getQuoteTokenPriceV2(token0, token1, ds.router);
        } else {
            price = LibSwapTokens._getQuoteTokenPriceV3(token0, token1, ds.v3PoolFeeForNativeByToken[token0], ds.v3PoolFeeForNativeByToken[token1], ds.router);
        }
    }

    // solhint-disable-next-line function-max-lines
    function processPayment(
        ProcessPaymentInput memory input
    ) external payable override onlyRole(LibPaymentModuleConsts.PAYMENT_PROCESSOR_ROLE) returns (uint256) {
        LibPaymentModuleStorage.DiamondStorage storage ds = LibPaymentModuleStorage.diamondStorage();

        IPaymentModule.AcceptedToken memory acceptedToken = ds.acceptedTokenByAddress[input.tokenAddress];

        uint256 treasuryShare = 0;
        uint256 referrerShare = 0;
        uint256 usdPrice = 0;

        IPlatformModule.Platform memory platform = IPlatformModule(address(this)).getPlatformById(input.platformId);

        if (platform.id != input.platformId) {
            revert ProcessPaymentError("INVALID_PLATFORM_ID");
        }

        for (uint256 index = 0; index < input.services.length; index++) {
            IPlatformModule.Service memory service = platform.services[input.services[index]];
            usdPrice += service.usdPrice * input.serviceAmounts[index];
        }

        // if the payer is the Diamond itself, we don't process the payment
        if (input.user == address(this)) {
            return 0;
        }

        if (platform.isDiscountEnabled == true) {
            uint256 discountBasis = IPricingModule(address(this)).getDiscountPercentageForUser(input.user);
            usdPrice = usdPrice - ((usdPrice * discountBasis) / LibCommonConsts.BASIS_POINTS);
        }

        if (usdPrice == 0) return 0;

        uint256 paymentAmount = usdPrice;
        if (acceptedToken.tokenType == IPaymentModule.PaymentMethod.NATIVE) {
            // if user is paying with native token, we swap it by usdToken
            paymentAmount = _processNativePayment(input.user, msg.value, usdPrice);
        } else if (acceptedToken.tokenType == IPaymentModule.PaymentMethod.USD) {
            IERC20(ds.usdToken).safeTransferFrom(input.user, address(this), usdPrice);
        } else if (acceptedToken.tokenType == IPaymentModule.PaymentMethod.ALTCOIN) {
            paymentAmount = _processTokenPayment(acceptedToken, input.user, usdPrice);
        } else {
            revert ProcessPaymentError("INVALID_PAYMENT_METHOD");
        }

        uint256 tokenBurnedAmount = _burnTokenByUsd(platform.burnToken, (usdPrice * platform.burnBasisPoints) / LibCommonConsts.BASIS_POINTS);

        (treasuryShare, referrerShare) = _processShare(platform, input.referrer, usdPrice);

        ProcessPaymentOutput memory paymentOutput = ProcessPaymentOutput({
            processPaymentInput: input,
            usdPrice: usdPrice,
            paymentAmount: paymentAmount,
            burnedAmount: tokenBurnedAmount,
            treasuryShare: treasuryShare,
            referrerShare: referrerShare
        });

        ds.paymentIndex++;

        emit PaymentProcessed(ds.paymentProcessedLastBlock, ds.paymentIndex);

        ds.paymentProcessedLastBlock = block.number;
        ds.paymentProcessed[ds.paymentIndex] = paymentOutput;

        return ds.paymentIndex;
    }

    /**
        #########################
        #### PRIVATE METHODS ####
        #########################
     */

    function _burnTokenByUsd(address burnToken, uint256 usdBurnAmount) private returns (uint256 tokenBurnedAmount) {
        LibPaymentModuleStorage.DiamondStorage storage ds = LibPaymentModuleStorage.diamondStorage();

        if (usdBurnAmount == 0 || burnToken == address(0)) return 0;

        uint256 initialTokenBurnBalance = IERC20(burnToken).balanceOf(LibCommonConsts.BURN_ADDRESS);

        if (ds.isV2Router == true) {
            LibSwapTokens._swapExactTokensForTokensV2(ds.usdToken, burnToken, usdBurnAmount, LibCommonConsts.BURN_ADDRESS, ds.router);
        } else {
            LibSwapTokens._swapExactTokensForTokensV3(
                ds.usdToken,
                burnToken,
                usdBurnAmount,
                ds.v3PoolFeeForNativeByToken[ds.usdToken],
                ds.v3PoolFeeForNativeByToken[burnToken],
                LibCommonConsts.BURN_ADDRESS,
                ds.router
            );
        }

        tokenBurnedAmount = IERC20(burnToken).balanceOf(LibCommonConsts.BURN_ADDRESS) - initialTokenBurnBalance;

        emit TokenBurned(ds.tokenBurnedLastBlock, burnToken, tokenBurnedAmount);
        ds.tokenBurnedLastBlock = block.number;
    }

    function _processNativePayment(address user, uint256 ethAmount, uint256 usdAmount) private returns (uint256 paidEthAmount) {
        LibPaymentModuleStorage.DiamondStorage storage ds = LibPaymentModuleStorage.diamondStorage();

        uint256 initialUsdBalance = IERC20(ds.usdToken).balanceOf(address(this));
        uint256 oldEthBalance = address(this).balance;

        if (ds.isV2Router == true) {
            LibSwapTokens._swapEthForExactTokensV2(ethAmount, ds.usdToken, usdAmount, ds.router);
        } else {
            LibSwapTokens._swapEthForExactTokensV3(ethAmount, ds.usdToken, usdAmount, ds.router, ds.v3PoolFeeForNativeByToken[ds.usdToken]);
        }

        uint256 newUsdBalance = IERC20(ds.usdToken).balanceOf(address(this));
        uint256 usdExpected = newUsdBalance - initialUsdBalance;
        require(usdExpected == usdAmount, "Not enough msg.value to cover fees");
        // refund any extra ETH sent
        paidEthAmount = oldEthBalance - address(this).balance;
        uint256 toBeRefunded = ethAmount - paidEthAmount;
        (bool success, ) = payable(user).call{ value: toBeRefunded }("");
        require(success, "Failed to refund leftover native tokens");
    }

    function _processTokenPayment(
        IPaymentModule.AcceptedToken memory acceptedToken,
        address user,
        uint256 usdAmount
    ) private returns (uint256 tokenPaymentAmount) {
        LibPaymentModuleStorage.DiamondStorage storage ds = LibPaymentModuleStorage.diamondStorage();

        uint256 initialTokenBalance = IERC20(acceptedToken.token).balanceOf(address(this));
        // uint256 requiredToken = _calculateRequiredTokenForUsdAmount(acceptedToken, usdAmount);
        uint256 requiredToken = IERC20(acceptedToken.token).allowance(user, address(this));
        // e.g. requiredToken / 5000 * 10000 means we want to take enough Token for the expected USD and BURN
        IERC20(acceptedToken.token).safeTransferFrom(user, address(this), requiredToken);
        uint256 receivedTokenAmount = IERC20(acceptedToken.token).balanceOf(address(this)) - initialTokenBalance;

        if (acceptedToken.isV2Router == true) {
            LibSwapTokens._swapTokensForExactTokensV2(acceptedToken.token, receivedTokenAmount, ds.usdToken, usdAmount, address(this), acceptedToken.router);
        } else {
            LibSwapTokens._swapTokensForExactTokensV3(
                acceptedToken.token,
                receivedTokenAmount,
                ds.usdToken,
                usdAmount,
                ds.v3PoolFeeForNativeByToken[acceptedToken.token],
                ds.v3PoolFeeForNativeByToken[ds.usdToken],
                address(this),
                acceptedToken.router
            );
        }

        // refund remaining tokens to the user
        uint256 remainingTokenBalance = IERC20(acceptedToken.token).balanceOf(address(this)) - initialTokenBalance;
        if (remainingTokenBalance > 0) {
            IERC20(acceptedToken.token).safeTransfer(user, remainingTokenBalance);
        }
        tokenPaymentAmount = requiredToken - remainingTokenBalance;
    }

    function _processShare(
        IPlatformModule.Platform memory platform,
        address referrer,
        uint256 paymentAmount
    ) private returns (uint256 treasuryShare, uint256 referrerShare) {
        LibPaymentModuleStorage.DiamondStorage storage ds = LibPaymentModuleStorage.diamondStorage();

        uint256 usdBurnShare = (paymentAmount * platform.burnBasisPoints) / LibCommonConsts.BASIS_POINTS;
        referrerShare = 0;
        if (referrer != address(0) && platform.referrerBasisPoints > 0) {
            referrerShare = (paymentAmount * platform.referrerBasisPoints) / LibCommonConsts.BASIS_POINTS;
            IERC20(ds.usdToken).safeTransfer(referrer, referrerShare);
        }
        treasuryShare = paymentAmount - referrerShare - usdBurnShare;

        IERC20(ds.usdToken).safeTransfer(platform.treasury, treasuryShare);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IPaymentModule {
    enum PaymentMethod {
        NATIVE,
        USD,
        ALTCOIN
    }

    enum PaymentType {
        NATIVE,
        GIFT,
        CROSSCHAIN
    }

    struct AcceptedToken {
        string name;
        PaymentMethod tokenType;
        address token;
        address router;
        bool isV2Router;
        uint256 slippageTolerance;
    }

    struct ProcessPaymentInput {
        bytes32 platformId;
        uint32[] services;
        uint32[] serviceAmounts;
        address referrer;
        address user;
        address tokenAddress;
    }

    struct ProcessPaymentOutput {
        ProcessPaymentInput processPaymentInput;
        uint256 usdPrice;
        uint256 paymentAmount;
        uint256 burnedAmount;
        uint256 treasuryShare;
        uint256 referrerShare;
    }

    struct ProcessCrossPaymentOutput {
        bytes32 platformId;
        uint32[] services;
        uint32[] serviceAmounts;
        address payer;
        address spender;
        uint256 sourceChainId;
        uint256 destinationChainId;
    }

    // solhint-disable-next-line func-name-mixedcase
    function PAYMENT_PROCESSOR_ROLE() external pure returns (bytes32);
    function adminWithdraw(address tokenAddress, uint256 amount, address treasury) external;
    function setUsdToken(address newUsdToken) external;
    function setRouterAddress(address newRouter) external;
    function addAcceptedToken(AcceptedToken memory acceptedToken) external;
    function removeAcceptedToken(address tokenAddress) external;
    function updateAcceptedToken(AcceptedToken memory acceptedToken) external;
    function setV3PoolFeeForTokenNative(address token, uint24 poolFee) external;
    function getUsdToken() external view returns (address);
    function processPayment(ProcessPaymentInput memory params) external payable returns (uint256);
    function getPaymentByIndex(uint256 paymentIndex) external view returns (ProcessPaymentOutput memory);
    function getQuoteTokenPrice(address token0, address token1) external view returns (uint256 price);
    function getV3PoolFeeForTokenWithNative(address token) external view returns (uint24);
    function isV2Router() external view returns (bool);
    function getRouterAddress() external view returns (address);
    function getAcceptedTokenByAddress(address tokenAddress) external view returns (AcceptedToken memory);
    function getAcceptedTokens() external view returns (address[] memory);

    /** EVENTS */
    event TokenBurned(uint256 indexed tokenBurnedLastBlock, address indexed tokenAddress, uint256 amount);
    event PaymentProcessed(uint256 indexed previousBlock, uint256 indexed paymentIndex);
    event TreasuryAddressUpdated(address indexed oldTreasury, address indexed newTreasury);

    /** ERRORS */
    error ProcessPaymentError(string errorMessage);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
interface IPlatformModule {
    struct Service {
        string name;
        uint256 usdPrice;
    }

    struct Platform {
        string name;
        bytes32 id;
        address owner;
        address treasury;
        uint256 referrerBasisPoints;
        address burnToken;
        uint256 burnBasisPoints;
        bool isDiscountEnabled;
        Service[] services;
    }

    // solhint-disable-next-line func-name-mixedcase
    function PLATFORM_MANAGER_ROLE() external pure returns (bytes32);

    function getPlatformCount() external view returns (uint256);

    function getPlatformIds() external view returns (bytes32[] memory);

    function getPlatformIdByIndex(uint256 index) external view returns (bytes32);

    function getPlatformById(bytes32 platformId) external view returns (IPlatformModule.Platform memory);

    function addPlatform(IPlatformModule.Platform memory platform) external;

    function removePlatform(uint256 index) external;

    function updatePlatform(IPlatformModule.Platform memory platform) external;

    function addPlatformService(bytes32 platformId, IPlatformModule.Service memory service) external;

    function removePlatformService(bytes32 platformId, uint256 serviceId) external;

    function updatePlatformService(bytes32 platformId, uint256 serviceId, IPlatformModule.Service memory service) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IPricingModule {
    function addDiscountNfts(address[] memory newDiscountNFTs, uint256[] memory discountBasisPoints) external;

    function removeDiscountNfts(address[] memory discountNFTs) external;

    function setDiscountPercentageForNft(address nft, uint256 discountBasisPoints) external;

    function getDiscountNfts() external view returns (address[] memory);

    function isDiscountNft(address nft) external view returns (bool);

    function getDiscountPercentageForNft(address nft) external view returns (uint256);

    function getDiscountPercentageForUser(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibCommonConsts {
    uint256 internal constant BASIS_POINTS = 10_000;
    address internal constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /**
        INNER_STRUCT is used for storing inner struct in mappings within diamond storage
     */
    bytes32 internal constant INNER_STRUCT = keccak256("floki.common.consts.inner.struct");
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibPaymentModuleConsts {
    bytes32 internal constant PAYMENT_PROCESSOR_ROLE = keccak256("PAYMENT_PROCESSOR_ROLE");
    bytes32 internal constant PLATFORM_MANAGER_ROLE = keccak256("PLATFORM_MANAGER_ROLE");
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { IPaymentModule } from "../interfaces/IPaymentModule.sol";

/// @notice storage for PaymentModule

library LibPaymentModuleStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("floki.payment.diamond.storage");

    struct DiamondStorage {
        mapping(address => IPaymentModule.AcceptedToken) acceptedTokenByAddress;
        mapping(uint256 => IPaymentModule.ProcessPaymentOutput) paymentProcessed;
        address[] acceptedTokens;
        address usdToken;
        address router;
        uint256 paymentProcessedLastBlock;
        uint256 referrerShareLastBlock;
        uint256 tokenBurnedLastBlock;
        bool isV2Router;
        mapping(address => uint24) v3PoolFeeForNativeByToken;
        address priceOracle;
        uint256 paymentIndex;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ISwapRouterV3 } from "../../interfaces/ISwapRouterV3.sol";
import { IUniswapV3Pool } from "../../interfaces/IUniswapV3Pool.sol";

library LibSwapTokens {
    using SafeERC20 for IERC20;

    function _swapEthForExactTokensV2(uint256 ethAmount, address token, uint256 amountOut, address router) internal {
        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(router).WETH();
        path[1] = address(token);
        IUniswapV2Router02(router).swapETHForExactTokens{ value: ethAmount }(amountOut, path, address(this), block.timestamp);
    }

    function _swapEthForExactTokensV3(uint256 ethAmount, address token, uint256 amountOut, address router, uint24 v3PoolFee) internal {
        ISwapRouterV3.ExactOutputSingleParams memory params = ISwapRouterV3.ExactOutputSingleParams({
            tokenIn: ISwapRouterV3(router).WETH9(),
            tokenOut: token,
            fee: v3PoolFee,
            recipient: address(this),
            amountOut: amountOut,
            amountInMaximum: ethAmount,
            sqrtPriceLimitX96: 0
        });
        uint256 amountIn = ISwapRouterV3(router).exactOutputSingle{ value: ethAmount }(params);

        if (amountIn < ethAmount) {
            ISwapRouterV3(router).refundETH();
        }
    }

    function _swapExactTokensForTokensV2(address inputToken, address outputToken, uint256 inputAmount, address treasury, address router) internal {
        address[] memory path = new address[](3);
        path[0] = inputToken;
        path[1] = IUniswapV2Router02(router).WETH();
        path[2] = outputToken;
        if (IERC20(inputToken).allowance(address(this), router) != 0) {
            IERC20(inputToken).safeApprove(router, 0);
        }
        IERC20(inputToken).safeApprove(router, inputAmount);

        IUniswapV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(inputAmount, 0, path, treasury, block.timestamp);
    }

    function _swapTokensForExactTokensV2(
        address inputToken,
        uint256 amountInMax,
        address outputToken,
        uint256 amountOut,
        address treasury,
        address router
    ) internal {
        address[] memory path = new address[](3);
        path[0] = inputToken;
        path[1] = IUniswapV2Router02(router).WETH();
        path[2] = outputToken;
        if (IERC20(inputToken).allowance(address(this), router) != 0) {
            IERC20(inputToken).safeApprove(router, 0);
        }

        IERC20(inputToken).safeApprove(router, amountInMax);

        uint256[] memory requiredAmounts = IUniswapV2Router02(router).getAmountsIn(amountOut, path);
        require(requiredAmounts[0] <= amountInMax, "LibSwapTokens: INSUFFICIENT_INPUT_AMOUNT");

        IUniswapV2Router02(router).swapTokensForExactTokens(amountOut, amountInMax, path, treasury, block.timestamp);
    }

    function _swapExactTokensForTokensV3(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint24 inputTokenPoolFee,
        uint24 outputTokenPoolFee,
        address treasury,
        address router
    ) internal {
        if (IERC20(inputToken).allowance(address(this), router) != 0) {
            IERC20(inputToken).safeApprove(router, 0);
        }
        IERC20(inputToken).safeApprove(router, inputAmount);

        bytes memory path = abi.encodePacked(inputToken, inputTokenPoolFee, ISwapRouterV3(router).WETH9(), outputTokenPoolFee, outputToken);

        ISwapRouterV3.ExactInputParams memory params = ISwapRouterV3.ExactInputParams({
            path: path,
            recipient: treasury,
            amountIn: inputAmount,
            amountOutMinimum: 0
        });

        ISwapRouterV3(router).exactInput(params);
    }

    function _swapTokensForExactTokensV3(
        address inputToken,
        uint256 amountInMax,
        address outputToken,
        uint256 amountOut,
        uint24 inputTokenPoolFee,
        uint24 outputTokenPoolFee,
        address treasury,
        address router
    ) internal {
        if (IERC20(inputToken).allowance(address(this), router) != 0) {
            IERC20(inputToken).safeApprove(router, 0);
        }
        IERC20(inputToken).safeApprove(router, amountInMax);

        bytes memory path = abi.encodePacked(outputToken, outputTokenPoolFee, ISwapRouterV3(router).WETH9(), inputTokenPoolFee, inputToken);

        ISwapRouterV3.ExactOutputParams memory params = ISwapRouterV3.ExactOutputParams({
            path: path,
            recipient: treasury,
            amountOut: amountOut,
            amountInMaximum: amountInMax
        });

        ISwapRouterV3(router).exactOutput(params);
    }

    function _getQuoteTokenPriceV2Weth(address token0, address token1, address router) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token0;
        uint256 token0Unit = 10 ** IERC20Metadata(token0).decimals();
        uint256[] memory amounts = IUniswapV2Router02(router).getAmountsIn(token0Unit, path);

        return amounts[0];
    }
    function _getQuoteTokenPriceV2(address token0, address token1, address router) internal view returns (uint256) {
        address weth = IUniswapV2Router02(router).WETH();
        if (token0 == address(0)) {
            return _getQuoteTokenPriceV2Weth(weth, token1, router);
        } else if (token1 == address(0)) {
            return _getQuoteTokenPriceV2Weth(token0, weth, router);
        }

        address[] memory path = new address[](3);
        path[0] = token1;
        path[1] = IUniswapV2Router02(router).WETH();
        path[2] = token0;

        uint256 token0Unit = 10 ** IERC20Metadata(token0).decimals();
        uint256[] memory amounts = IUniswapV2Router02(router).getAmountsIn(token0Unit, path);

        return amounts[0];
    }

    function _shiftRightBits(uint256 value) internal pure returns (uint256 result, uint256 bits) {
        uint256 maxNumber = 1 << 128;
        result = value;
        if (result >= maxNumber) {
            for (bits = 1; bits <= 96; bits++) {
                result = (value >> bits);
                if (result < maxNumber) {
                    return (result, bits);
                }
            }
        }
    }

    function _getTokenPriceFromSqrtX96(uint256 sqrtPrice) internal pure returns (uint256 price) {
        (uint256 bitResult, uint256 bits) = _shiftRightBits(sqrtPrice);
        uint256 leftBits = (96 - bits) * 2;
        price = (bitResult * bitResult);
        (price, bits) = _shiftRightBits(price);
        leftBits -= bits;
        price = (price * 1e18) >> leftBits;
    }

    function _getQuoteTokenPriceV3Weth(address token, uint24 poolFee, address router) internal view returns (uint256, uint256) {
        address weth = ISwapRouterV3(router).WETH9();
        address factory = ISwapRouterV3(router).factory();
        address pool = ISwapRouterV3(factory).getPool(weth, token, poolFee);
        uint256 tokenDecimals = IERC20Metadata(token).decimals();

        address poolToken0 = IUniswapV3Pool(pool).token0();
        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(pool).slot0();

        uint256 tokenPerWeth = _getTokenPriceFromSqrtX96(sqrtPriceX96);
        uint256 wethPerToken = (10 ** (18 + tokenDecimals)) / tokenPerWeth;

        if (poolToken0 == weth) {
            return (tokenPerWeth, wethPerToken);
        } else {
            return (wethPerToken, tokenPerWeth);
        }
    }

    function _getQuoteTokenPriceV3(address token0, address token1, uint24 token0PoolFee, uint24 token1PoolFee, address router) internal view returns (uint256) {
        uint256 wethPerToken;
        uint256 tokenPerWeth;
        if (token0 == address(0)) {
            (tokenPerWeth, ) = _getQuoteTokenPriceV3Weth(token1, token1PoolFee, router);
            return tokenPerWeth;
        } else if (token1 == address(0)) {
            (, wethPerToken) = _getQuoteTokenPriceV3Weth(token0, token0PoolFee, router);
            return wethPerToken;
        }

        (, wethPerToken) = _getQuoteTokenPriceV3Weth(token0, token0PoolFee, router);
        (tokenPerWeth, ) = _getQuoteTokenPriceV3Weth(token1, token1PoolFee, router);

        return (wethPerToken * tokenPerWeth) / 1e18;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ISwapRouterV3 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    // solhint-disable-next-line func-name-mixedcase
    function WETH9() external pure returns (address);

    function factory() external pure returns (address);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);

    function refundETH() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IUniswapV3Pool {
    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}