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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

interface IDepositHandler {
    struct FungibleTokenDeposit {
        address tokenAddress;
        uint256 amount;
        bool isLP;
    }

    struct NonFungibleTokenDeposit {
        address tokenAddress;
        uint256 tokenId;
    }

    struct MultiTokenDeposit {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
    }

    struct V3LPData {
        address tokenAddress;
        address token0;
        address token1;
        uint128 liquidityToRemove;
        uint24 fee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { IDepositHandler } from "./IDepositHandler.sol";

interface IVaultFactory is IDepositHandler {
    function createVault(
        address referrer,
        address beneficiary,
        uint256 unlockTimestamp,
        IDepositHandler.FungibleTokenDeposit[] memory fungibleTokenDeposits,
        IDepositHandler.NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        IDepositHandler.MultiTokenDeposit[] memory multiTokenDeposits,
        bool isVesting
    ) external payable;

    function createVaultWithoutKey(
        address referrer,
        address beneficiary,
        uint256 unlockTimestamp,
        IDepositHandler.FungibleTokenDeposit[] memory fungibleTokenDeposits,
        IDepositHandler.NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        IDepositHandler.MultiTokenDeposit[] memory multiTokenDeposits,
        bool isVesting
    ) external payable;

    function burn(
        address referrer,
        IDepositHandler.FungibleTokenDeposit[] memory fungibleTokenDeposits,
        IDepositHandler.NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        IDepositHandler.MultiTokenDeposit[] memory multiTokenDeposits
    ) external payable;

    function notifyUnlock(bool isCompletelyUnlocked) external;

    function lockExtended(uint256 oldUnlockTimestamp, uint256 newUnlockTimestamp) external;

    function paymentModule() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { AccessControlStorage } from "@solidstate/contracts/access/access_control/AccessControlStorage.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Factory } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import { IVaultFactory } from "../../locker/interfaces/IVaultFactory.sol";
import { IDepositHandler } from "../../locker/interfaces/IDepositHandler.sol";

import { ITokenLauncherLiquidityPoolFactory } from "../interfaces/ITokenLauncherLiquidityPoolFactory.sol";
import { ITokenFiErc20 } from "../interfaces/ITokenFiErc20.sol";
import { ITokenLauncherQuerier } from "../interfaces/ITokenLauncherQuerier.sol";
import { LibTokenLauncherLiquidityPoolFactoryStorage } from "../libraries/LibTokenLauncherLiquidityPoolFactoryStorage.sol";

import { LibCommonConsts } from "../../common/admin/libraries/LibCommonConsts.sol";

contract TokenLauncherLiquidityPoolFactoryFacet is ITokenLauncherLiquidityPoolFactory {
    using SafeERC20 for IERC20;

    function createTokenLauncherV2LiquidityPool(ITokenLauncherLiquidityPoolFactory.CreateV2LpTlInput memory input) external payable override {
        // First check the allowance of the source token
        ITokenFiErc20 token = ITokenFiErc20(input.createV2LpInput.liquidityPoolDetails.sourceToken);

        uint256 allowedAmount = IERC20(input.createV2LpInput.liquidityPoolDetails.sourceToken).allowance(input.createV2LpInput.owner, address(this));
        require(
            allowedAmount >= input.createV2LpInput.liquidityPoolDetails.amountSourceToken,
            "TokenLauncherLiquidityPoolFactoryFacet:createTokenLauncherV2LiquidityPool: Not enough allowance"
        );

        // Create LP
        ITokenLauncherLiquidityPoolFactory.CreateV2Output memory lpOutput = _createV2LiquidityPool(input.createV2LpInput);
        // if the source token is a tokenfi token, we need to add the new LP to the exchange pool
        if (ITokenLauncherQuerier(address(this)).getTokenOwnerByToken(input.createV2LpInput.liquidityPoolDetails.sourceToken) != address(0)) {
            require(
                msg.sender == address(this) ||
                    msg.sender == ITokenLauncherQuerier(address(this)).getTokenOwnerByToken(input.createV2LpInput.liquidityPoolDetails.sourceToken),
                "TokenLauncherLiquidityPoolFactoryV1Facet:createTokenLauncherV2Liquidity: INVALID_SENDER"
            );
            if (!token.isExchangePool(lpOutput.liquidityPoolToken)) {
                token.addExchangePool(lpOutput.liquidityPoolToken);
            }
            if (token.isReflectionToken() && !token.isExcludedFromReflectionRewards(lpOutput.liquidityPoolToken)) {
                token.excludeAccount(lpOutput.liquidityPoolToken);
            }

            token.setBuybackDetails(input.buybackDetails);
        }
    }

    function createV2LiquidityPool(CreateV2LpInput memory input) external payable override {
        _createV2LiquidityPool(input);
    }

    function _createV2LiquidityPool(CreateV2LpInput memory input) private returns (CreateV2Output memory) {
        IUniswapV2Router02 router = IUniswapV2Router02(input.liquidityPoolDetails.routerAddress);
        IERC20 sourceToken = IERC20(input.liquidityPoolDetails.sourceToken);
        uint256 sourceInitialBalance = sourceToken.balanceOf(address(this));
        sourceToken.safeTransferFrom(input.owner, address(this), input.liquidityPoolDetails.amountSourceToken);
        uint256 sourceEarnedAmount = sourceToken.balanceOf(address(this)) - sourceInitialBalance;
        sourceToken.safeApprove(input.liquidityPoolDetails.routerAddress, sourceEarnedAmount);

        uint256 liquidity = _addLiquidity(input, sourceEarnedAmount);
        // Lock Liquidity if applicable
        address pairAddress = IUniswapV2Factory(router.factory()).getPair(input.liquidityPoolDetails.sourceToken, input.liquidityPoolDetails.pairedToken);
        if (input.lockLPDetails.lockLPTokenPercentage > 0) {
            _lockLiquidity(input, pairAddress);
        }

        ITokenLauncherLiquidityPoolFactory.CreateV2Output memory lpOutput = CreateV2Output({ liquidityPoolToken: pairAddress, liquidity: liquidity });

        // Log into store
        RegisterLiquidityPoolInput memory lpInput = RegisterLiquidityPoolInput({
            tokenAddress: input.liquidityPoolDetails.sourceToken,
            liquidityPoolToken: lpOutput.liquidityPoolToken
        });

        _registerLiquidityPool(lpInput);

        emit TokenLiquidityCreated(msg.sender, input.liquidityPoolDetails);

        return lpOutput;
    }

    function registerLiquidityPool(RegisterLiquidityPoolInput memory input) external override onlyAdmin {
        _registerLiquidityPool(input);
    }

    function _registerLiquidityPool(RegisterLiquidityPoolInput memory input) private {
        LibTokenLauncherLiquidityPoolFactoryStorage.DiamondStorage storage ds = LibTokenLauncherLiquidityPoolFactoryStorage.diamondStorage();
        ds.liquidityPoolTokensByToken[input.tokenAddress].push(input.liquidityPoolToken);
        emit LiquidityPoolRegistered(ds.currentBlockLiquidityPoolRegistered, input.liquidityPoolToken, input.tokenAddress);
        ds.currentBlockLiquidityPoolRegistered = block.number;
    }

    function _addLiquidity(CreateV2LpInput memory input, uint256 sourceEarnedAmount) private returns (uint256 liquidity) {
        address lpTokenBeneficiary = (input.lockLPDetails.lockLPTokenPercentage == 0) ? input.treasury : address(this);
        IUniswapV2Router02 router = IUniswapV2Router02(input.liquidityPoolDetails.routerAddress);

        IERC20 pairedToken = IERC20(input.liquidityPoolDetails.pairedToken);
        if (input.liquidityPoolDetails.pairedToken == router.WETH()) {
            require(input.liquidityPoolDetails.amountPairedToken == msg.value, "TokenLauncherLiquidityPoolFactoryFacet: INVALID_ETH_AMOUNT");
            (, , liquidity) = router.addLiquidityETH{ value: msg.value }(
                input.liquidityPoolDetails.sourceToken,
                sourceEarnedAmount,
                0,
                0,
                lpTokenBeneficiary,
                block.timestamp
            );
        } else {
            uint256 initialBalance = pairedToken.balanceOf(address(this));
            pairedToken.safeTransferFrom(input.owner, address(this), input.liquidityPoolDetails.amountPairedToken);
            uint256 earnedAmount = pairedToken.balanceOf(address(this)) - initialBalance;
            pairedToken.safeApprove(input.liquidityPoolDetails.routerAddress, earnedAmount);
            (, , liquidity) = router.addLiquidity(
                input.liquidityPoolDetails.sourceToken,
                input.liquidityPoolDetails.pairedToken,
                sourceEarnedAmount,
                earnedAmount,
                0,
                0,
                lpTokenBeneficiary,
                block.timestamp
            );
        }
    }

    function _lockLiquidity(CreateV2LpInput memory input, address pairAddress) private {
        LibTokenLauncherLiquidityPoolFactoryStorage.DiamondStorage storage ds = LibTokenLauncherLiquidityPoolFactoryStorage.diamondStorage();

        require(input.lockLPDetails.lockLPTokenPercentage <= LibCommonConsts.BASIS_POINTS, "TokenLauncherLiquidityPoolFactoryFacet: INVALID_LOCK_PERCENTAGE");

        uint256 lpBalanceToLock = (IERC20(pairAddress).balanceOf(address(this)) * input.lockLPDetails.lockLPTokenPercentage) / LibCommonConsts.BASIS_POINTS;
        uint256 lpBalanceToTreasury = IERC20(pairAddress).balanceOf(address(this)) - lpBalanceToLock;
        IDepositHandler.FungibleTokenDeposit[] memory fungibleTokenDeposits = new IDepositHandler.FungibleTokenDeposit[](1);
        fungibleTokenDeposits[0] = IDepositHandler.FungibleTokenDeposit({ tokenAddress: pairAddress, amount: lpBalanceToLock, isLP: true });
        IDepositHandler.NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits = new IDepositHandler.NonFungibleTokenDeposit[](0);
        IDepositHandler.MultiTokenDeposit[] memory multiTokenDeposits = new IDepositHandler.MultiTokenDeposit[](0);

        IERC20(pairAddress).safeApprove(IVaultFactory(ds.vaultFactory).paymentModule(), lpBalanceToLock);

        IVaultFactory(ds.vaultFactory).createVault(
            address(0),
            input.lockLPDetails.beneficiary,
            input.lockLPDetails.unlockTimestamp,
            fungibleTokenDeposits,
            nonFungibleTokenDeposits,
            multiTokenDeposits,
            input.lockLPDetails.isVesting
        );
        // Send remaining LP Tokens to treasury (if any)
        if (lpBalanceToTreasury > 0) IERC20(pairAddress).safeTransfer(input.treasury, lpBalanceToTreasury);
    }

    function setVaultFactory(address _vaultFactory) external onlyAdmin {
        LibTokenLauncherLiquidityPoolFactoryStorage.DiamondStorage storage ds = LibTokenLauncherLiquidityPoolFactoryStorage.diamondStorage();

        address oldVaultFactory = ds.vaultFactory;
        ds.vaultFactory = _vaultFactory;
        emit VaultFactoryUpdated(oldVaultFactory, _vaultFactory);
    }

    function getLiquidityPoolTokensByToken(address token) external view override returns (address[] memory) {
        LibTokenLauncherLiquidityPoolFactoryStorage.DiamondStorage storage ds = LibTokenLauncherLiquidityPoolFactoryStorage.diamondStorage();

        return ds.liquidityPoolTokensByToken[token];
    }

    modifier onlyAdmin() {
        require(
            IAccessControl(address(this)).hasRole(AccessControlStorage.DEFAULT_ADMIN_ROLE, msg.sender),
            "TokenLauncherLiquidityPoolFactoryFacet: Only admin can call this function"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ITokenFiErc20 {
    struct FeeDetails {
        uint256 percentage;
        bool onlyOnSwaps;
    }

    struct Fees {
        FeeDetails transferFee;
        FeeDetails burn;
        FeeDetails reflection;
        FeeDetails buyback;
    }

    struct BuybackDetails {
        address pairToken;
        address router;
        uint256 liquidityBasisPoints;
        uint256 priceImpactBasisPoints;
    }

    struct TokenInfo {
        string name;
        string symbol;
        string logo;
        uint8 decimals;
        uint256 initialSupply;
        uint256 maxSupply;
        address treasury;
        address owner;
        Fees fees;
        BuybackDetails buybackDetails;
    }

    struct TotalReflection {
        uint256 tTotal;
        uint256 rTotal;
        uint256 tFeeTotal;
    }

    struct ReflectionInfo {
        TotalReflection totalReflection;
        mapping(address => uint256) rOwned;
        mapping(address => uint256) tOwned;
        mapping(address => bool) isExcludedFromReflectionRewards;
        address[] excluded;
    }

    /** ONLY ROLES */
    function mint(address to, uint256 amount) external;
    function updateTokenLauncher(address _newTokenLauncher) external;
    function updateTreasury(address _newTreasury) external;
    function setName(string memory name) external;
    function setSymbol(string memory symbol) external;
    function setDecimals(uint8 decimals) external;
    function updateFees(Fees memory _fees) external;
    function setBuybackDetails(BuybackDetails memory _buybackDetails) external;
    function setBuybackHandler(address _newBuybackHandler) external;
    function addExchangePool(address pool) external;
    function removeExchangePool(address pool) external;
    function addExemptAddress(address account) external;
    function removeExemptAddress(address account) external;

    /** VIEW */
    function fees() external view returns (Fees memory);
    function tokenInfo() external view returns (TokenInfo memory);
    function buybackHandler() external view returns (address);
    function isExchangePool(address pool) external view returns (bool);
    function isExemptedFromTax(address account) external view returns (bool);
    function isReflectionToken() external view returns (bool);

    /** REFLECTION Implemetation */
    function reflect(uint256 tAmount) external;
    function excludeAccount(address account) external;
    function includeAccount(address account) external;
    function isExcludedFromReflectionRewards(address account) external view returns (bool);
    function totalReflection() external view returns (TotalReflection memory);
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256);
    function tokenFromReflection(uint256 rAmount) external view returns (uint256);
    function totalFees() external view returns (uint256);

    event ExemptedAdded(address indexed account);
    event ExemptedRemoved(address indexed account);
    event ExchangePoolAdded(address indexed pool);
    event ExchangePoolRemoved(address indexed pool);
    event TokenLauncherUpdated(address indexed oldTokenLauncher, address indexed newTokenLauncher);
    event TransferTax(address indexed account, address indexed receiver, uint256 amount, string indexed taxType);
    event BuybackHandlerUpdated(address indexed oldBuybackHandler, address indexed newBuybackHandler);
    event BuybackDetailsUpdated(address indexed router, address indexed pairToken, uint256 liquidityBasisPoints, uint256 priceImpactBasisPoints);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ITokenLauncherCommon {
    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ITokenFiErc20 } from "./ITokenFiErc20.sol";

interface ITokenLauncherLiquidityPoolFactory {
    struct LiquidityPoolDetails {
        address sourceToken;
        address pairedToken;
        uint256 amountSourceToken;
        uint256 amountPairedToken;
        address routerAddress;
    }

    struct LockLPDetails {
        uint256 lockLPTokenPercentage;
        uint256 unlockTimestamp;
        address beneficiary;
        bool isVesting;
    }

    struct CreateV2LpInput {
        address owner;
        address treasury;
        LiquidityPoolDetails liquidityPoolDetails;
        LockLPDetails lockLPDetails;
    }

    struct CreateV2LpTlInput {
        CreateV2LpInput createV2LpInput;
        ITokenFiErc20.BuybackDetails buybackDetails;
    }

    struct CreateV2Output {
        address liquidityPoolToken;
        uint256 liquidity;
    }

    struct RegisterLiquidityPoolInput {
        address tokenAddress;
        address liquidityPoolToken;
    }

    function createTokenLauncherV2LiquidityPool(ITokenLauncherLiquidityPoolFactory.CreateV2LpTlInput memory input) external payable;
    function createV2LiquidityPool(CreateV2LpInput memory input) external payable;
    function registerLiquidityPool(RegisterLiquidityPoolInput memory input) external;
    function getLiquidityPoolTokensByToken(address token) external view returns (address[] memory);

    event TokenLiquidityCreated(address indexed owner, LiquidityPoolDetails liquidityPoolDetails);
    event VaultFactoryUpdated(address indexed oldVaultFactory, address indexed newVaultFactory);
    event LiquidityPoolRegistered(uint256 indexed previousBlock, address indexed lpToken, address indexed sourceToken);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ITokenLauncherCommon } from "./ITokenLauncherCommon.sol";

interface ITokenLauncherQuerier is ITokenLauncherCommon {
    // solhint-disable func-name-mixedcase
    function TOKENLAUNCHER_PRODUCT_ID() external pure returns (bytes32);

    function getTokenOwnerByToken(address tokenAddress) external view returns (address);

    function getTokensPaginated(TokenType tokenType, uint256 quantity, uint256 page) external view returns (address[] memory);

    function getTokensByOwnerPaginated(address owner, TokenType tokenType, uint256 quantity, uint256 page) external view returns (address[] memory);

    function buybackHandler() external view returns (address);

    function currentBlockTokenCreated() external view returns (uint256);

    function currentBlockTokenOwnerUpdated() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibTokenLauncherLiquidityPoolFactoryStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("tokenfi.tokenlauncher.liquiditypool.factory.diamond.storage");

    struct DiamondStorage {
        address vaultFactory;
        uint256 currentBlockLiquidityPoolRegistered;
        mapping(address => address[]) liquidityPoolTokensByToken;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}