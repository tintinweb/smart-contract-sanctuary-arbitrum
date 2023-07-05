// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/Types.sol";

interface IChildMarket {

  /// @notice Emitted when placing a bet
  event PlaceBet(
                 address indexed account,
                 uint indexed ticketId,
                 uint8 indexed option,
                 uint estimatedOdds,
                 uint size
                 );
  
  /// @notice Emitted when resolving a `Market`. Note: CLV is the "closing line
  /// value", or the latest odds when the `Market` has closed, included for
  /// reference
  event ResolveMarket(
                      uint8 indexed option,
                      uint payout,
                      uint bookmakingFee,
                      uint optionACLV,
                      uint optionBCLV
                      );

  /// @notice Emitted when user claims a `Ticket`
  event ClaimTicket(
                    address indexed account,
                    uint indexed ticketId,
                    uint ticketSize,
                    uint ticketOdds,
                    uint payout
                    );


  /** ACCESS CONTROLLED FUNCTIONS **/

  
  /// @notice Internal entry point for resolving this `ChildMarket`, which only
  /// `ParentMarket`s may call. The `ChildMarket` can either have a distinct
  /// winning `Option`, or it can be a tie. The `ChildMarket` should contain
  /// exactly enough balance to pay out for worst-case results. If profits are
  /// leftover after accounting for winning payouts, a portion (determined by
  /// `bookmakingFeeBps`) is transferred to the protocol, and the remaining
  /// profits are sent to `ToroPool`.
  /// @param scoreA Raw score of side A, scaled by 1e8
  /// @param scoreB Raw score of side B, scaled by 1e8
  function _resolveMarket(int64 scoreA, int64 scoreB) external;

  /// @notice Internal entry point for placing bets, which only `ParentMarket`s
  /// may call. This function assumes that this `ChildMarket` has already been
  /// pre-funded with user underlying tokens by the `ParentMarket`. The role of
  /// `ChildMarket` is to manage this new currency inflow, including sending and
  /// requesting funds from `ToroPool`. Note: This contract must have the
  /// `CHILD_MARKET_ROLE` before it can request funds from `ToroPool`.
  /// The `option` enum indicates which side the user wants to bet, and the size
  /// is the amount the user wishes to bet (before commission fees).
  /// Commission fees are chard at the time of placing a bet, and the remainder
  /// is the actual size placed for the wager. Hence, the `Ticket` that user
  /// receives when placing a bet will be for a slightly smaller amount than
  /// `size`.
  /// @param account Address of the user
  /// @param option The side which user picks to win
  /// @param size Size which user wishes to bet (before commission fees)
  /// @param cachedCurrentBalance Contract token balance before current bet
  function _placeBet(address account, uint8 option, uint size, uint cachedCurrentBalance) external;

  /// @notice Internal entry point for claiming winning `Ticket`s, which only
  /// `ParentMarket`s may call.  `ChildMarket` should always have enough to pay
  /// every `Ticket` without requesting for fund transfers from `ToroPool`. In
  /// the case of a tie, `Ticket`s will be refunded their initial amount
  /// (minus commission fees). This function must check the validity of the
  /// `Ticket` and if it passes all checks, releases the funds to the winning
  /// account.
  /// @param account Address of the user
  /// @param ticketId ID of the `Ticket`
  function _claimTicket(address account, uint ticketId) external;
  
  
  /** VIEW FUNCTIONS **/

  
  function toroAdmin() external view returns(address);
  
  function toroPool() external view returns(address);

  function parentMarket() external view returns(address);

  function tag() external view returns(bytes32);
  
  function currency() external view returns(IERC20);
  
  function baseOdds() external view returns(uint,uint);
  
  function optionA() external view returns(Types.Option memory);

  function optionB() external view returns(Types.Option memory);

  function labelA() external view returns(string memory);

  function sublabelA() external view returns(string memory);
  
  function labelB() external view returns(string memory);

  function sublabelB() external view returns(string memory);
  
  function deadline() external view returns(uint);

  function sportId() external view returns(uint);
  
  function betType() external view returns(uint8);

  function condition() external view returns(int64);
  
  function maxExposure() external view returns(uint);

  function totalSize() external view returns(uint);

  function totalPayout() external view returns(uint);

  function maxPayout() external view returns(uint);

  function minPayout() external view returns(uint);

  function minLockedBalance() external view returns(uint);

  function exposure() external view returns(uint,uint);
  
  function debits() external view returns(uint);

  function credits() external view returns(uint);

  /// @notice Returns the full `Ticket` struct for a given `Ticket` ID
  /// @param ticketId ID of the ticket
  /// @return Ticket The `Ticket` associated with the ID
  function getTicketById(uint ticketId) external view returns(Types.Ticket memory);

  /// @notice Returns an array of `Ticket` IDs for a given account
  /// @param account Address to query
  /// @return uint[] Array of account `Ticket` IDs
  function accountTicketIds(address account) external view returns(uint[] memory);

  /// @notice Returns an array of full `Ticket` structs for a given account
  /// @param account Address to query
  /// @return Ticket[] Array of account `Ticket`s
  function accountTickets(address account) external view returns(Types.Ticket[] memory);
  
}

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IChildMarket.sol";

interface IParentMarket {

  /// @notice Emitted when adding a `ChildMarket`
  event AddChildMarket(uint betType, address childMarket);

  /// @notice Emitted when `_maxExposure` is updated
  event SetMaxExposure(uint maxExposure);

  
  /** ACCESS CONTROLLED FUNCTIONS **/

  
  /// @notice Internal entry point for resolving this `ParentMarket`, which only
  /// `SportOracle` may call.
  /// NOTE: If a particular `betType` does not exist on this `ParentMarket`, the
  /// resolution for that `betType` will be correctly ignored.
  /// @param scoreA Raw score of side A, scaled by 1e8
  /// @param scoreB Raw score of side B, scaled by 1e8
  function _resolveMarket(int64 scoreA, int64 scoreB) external;
  
  /// @notice Convenience function for adding `ChildMarket` triplet in a single
  /// transaction.
  /// NOTE: To skip adding a `ChildMarket` for any given `betType`, supply the
  /// zero address as a parameter and it will be ignored correctly.
  /// @param market1 Moneyline `ChildMarket`
  /// @param market2 Handicap `ChildMarket`
  /// @param market3 Over/Under `ChildMarket`
  function _addChildren(IChildMarket market1, IChildMarket market2, IChildMarket market3) external;
  
  /// @notice Associate a `ChildMarket` with a particular `betType` to this
  /// `ParentMarket`.
  /// @param betType Enum for bet type (e.g., moneyline, handicap, over/under)
  /// @param cMarket `ChildMarket` to add
  function _addChildMarket(uint betType, IChildMarket cMarket) external;
    
  /// @notice Called by `ToroAdmin` to set the max exposure allowed for every
  /// `ChildMarket` associated with this `ParentMarket`. If a bet size exceeds
  /// `_maxExposure`, it will get rejected. The purpose of `_maxExposure` is to
  /// limit the maximum amount of one-sided risk a `Market` can take on.
  /// @param maxExposure_ New max exposure
  function _setMaxExposure(uint maxExposure_) external;

  
  /** USER INTERFACE **/


  /// @notice External entry point for end users to place bets on any
  /// associated `ChildMarket`. The `betType` will indicate what type of bet
  /// the user wishes to make (i.e., moneyline, handicap, over/under).
  /// The `option` enum indicates which side the user wants to bet, and the size
  /// is the amount the user wishes to bet (before commission fees).
  /// Commission fees are chard at the time of placing a bet, and the remainder
  /// is the actual size placed for the wager. Hence, the `Ticket` that user
  /// receives when placing a bet will be for a slightly smaller amount than
  /// `size`.
  /// `placeBet` transfers the full funds over from user to the `ChildMarket` on
  /// its behalf, so that users only need to call ERC20 `approve` on the
  /// `ParentMarket`. Beyond that, each `ChildMarket` manages its own currency
  /// balances separately when a bet is placed, including sending/requesting
  /// funds to `ToroPool`. The `ChildMarket` must have the `CHILD_MARKET_ROLE`
  /// before it can be approved to request funds from `ToroPool`.
  /// @param betType Enum for bet type (e.g., moneyline, handicap, over/under)
  /// @param option The side which user picks to win
  /// @param size Size which user wishes to bet (before commission fees)
  function placeBet(uint betType, uint8 option, uint size) external;
  
  /// @notice External entry point for end users to claim winning `Ticket`s.
  /// The `betType` will indicate what type of bet the `Ticket` references
  /// (i.e., moneyline, handicap, over/under) and the `ticketId` is the id of
  /// the winning `Ticket`. `ParentMarket` holds no funds - the `ChildMarket`
  /// will transfer funds to winners directly.
  /// @param betType Enum for bet type (e.g., moneyline, handicap, over/under)
  /// @param ticketId ID of the `Ticket`
  function claimTicket(uint betType, uint ticketId) external;

  
  /** VIEW FUNCTIONS **/

  
  function toroAdmin() external view returns(address);
  
  function toroPool() external view returns(address);

  function tag() external view returns(bytes32);
  
  function currency() external view returns(IERC20);

  function resolved() external view returns(bool);
  
  function deadline() external view returns(uint);

  function sportId() external view returns(uint);

  function maxExposure() external view returns(uint);

  function labelA() external view returns(string memory);

  function labelB() external view returns(string memory);

  function childMarket(uint betType) external view returns(IChildMarket);
  
  /// @notice Gets the current state of the `Market`. The states are:
  /// OPEN: Still open for taking new bets
  /// PENDING: No new bets allowed, but no winner/tie declared yet
  /// CLOSED: Result declared, still available for redemptions
  /// EXPIRED: Redemption window expired, `Market` eligible to be deleted
  /// @return uint8 Current state
  function state() external view returns(uint8);
  
}

// SPDX-License-Identifier:NONE
pragma solidity ^0.8.17;

import "./IParentMarket.sol";
import "../libraries/Types.sol";

interface ISportOracle {

  
  /** ACCESS CONTROLLED FUNCTIONS **/

  function _addTagToMarket(bytes32 tag, address pMarketAddr) external;
  
  /// @notice Updates the base odds for an array of matches. This function
  /// accepts an array of bytes data, where each bytes element is encoded as:
  /// b[0:1] => Version Number (uint8)
  /// b[1:33] => Tag (bytes32), Tag of the match
  /// b[j+33:j+34] => BetType (uint8), 
  /// b[j+34:j+42] => oddsA (uint8)
  /// b[j+42:j+50] => oddsB (uint*)
  /// The odds should expressed in DECIMAL ODDS format, scaled by 1e8
  function _updateBaseOdds(uint8 version, bytes[] calldata data) external;

  /// @notice Resolves the market for an array of matches. This function
  /// accepts an array of bytes data, where each bytes element is encoded as:
  /// b[0:32] => Tag (bytes32), Tag of the match
  /// b[32:40] => scoreA (int64), Score of side A, scaled by 1e8
  /// b[40:48] => scoreB (int64), Score of side B, scaled by 1e8
  function _resolveMarket(uint8 version, bytes[] calldata data) external;
  
  
  /** VIEW FUNCTIONS **/

  
  function getParentMarket(bytes32 tag) external view returns(IParentMarket);

  function baseOdds(bytes32 tag, uint8 betType) external view returns(Types.Odds memory);
  
}

//SPDX-License-Identifier: NONE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IToroPool.sol";
import "./IParentMarket.sol";

interface IToroAdmin is IAccessControlUpgradeable {

  /// @notice Emitted when setting `_toroDB`
  event SetToroDB(address toroDBAddr);

  /// @notice Emitted when setting `_sportOracle`
  event SetSportOracle(address sportOracleAddr);
  
  /// @notice Emitted when setting `_priceOracle`
  event SetPriceOracle(address priceOracleAddr);
  
  /// @notice Emitted when setting `_feeEmissionsController`
  event SetFeeEmissionsController(address feeEmissionsControllerAddr);

  /// @notice Emitted when setting `_affiliateERC721`
  event SetAffiliateERC721(address affiliateERC721Addr);

  /// @notice Emitted when setting `_affiliateMintFee`
  event SetAffiliateMintFee(uint affiliateMintFee);

  /// @notice Emitted when adding a new `ParentMarket`
  event AddParentMarket(
                        address indexed currency,
                        uint indexed sportId,
                        string labelA,
                        string labelB,
                        address pMarketAddr
                        );

  /// @notice Emitted when deleting a `ParentMarket`
  event DeleteParentMarket(
                           address indexed currency,
                           uint indexed sportId,
                           string labelA,
                           string labelB,
                           address pMarketAddr
                           );
  
  /// @notice Emitted when adding a new `ToroPool`
  event AddToroPool(address toroPool);

  /// @notice Emitted when setting the bookmaking fee
  event SetBookmakingFeeBps(uint bookmakingFeeBps);

  /// @notice Emitted when setting the commission fee
  event SetCommissionFeeBps(uint commissionFeeBps);

  /// @notice Emitted when setting the affiliate bonus
  event SetAffiliateBonusBps(uint affiliateBonusBps);

  /// @notice Emitted when setting the referent discount
  event SetReferentDiscountBps(uint referentDiscountBps);

  /// @notice Emitted when setting the market expiry deadline
  event SetExpiryDeadline(uint expiryDeadline_);

  /// @notice Emitted when setting the LP cooldown
  event SetCooldownLP(uint redeemLPCooldown_);

  /// @notice Emitted when setting the LP window
  event SetWindowLP(uint windowLP_);
  
  /** ACCESS CONTROLLED FUNCTIONS **/

  /// @notice Called upon initialization after deploying `ToroDB` contract
  /// @param toroDBAddr Address of `ToroDB` deployment
  function _setToroDB(address toroDBAddr) external;

  /// @notice Called upon initialization after deploying `SportOracle` contract
  /// @param sportOracleAddr Address of `SportOracle` deployment
  function _setSportOracle(address sportOracleAddr) external;
  
  /// @notice Called upon initialization after deploying `PriceOracle` contract
  /// @param priceOracleAddr Address of `PriceOracle` deployment
  function _setPriceOracle(address priceOracleAddr) external;
  
  /// @notice Called upon initialization after deploying `FeeEmissionsController` contract
  /// @param feeEmissionsControllerAddr Address of `FeeEmissionsController` deployment
  function _setFeeEmissionsController(address feeEmissionsControllerAddr) external;

  /// @notice Called up initialization after deploying `AffiliateERC721` contract
  /// @param affiliateERC721Addr Address of `AffiliateERC721` deployment
  function _setAffiliateERC721(address affiliateERC721Addr) external;

  /// @notice Adds a new `ToroPool` currency contract
  /// @param toroPool_ New `ToroPool` currency contract
  function _addToroPool(IToroPool toroPool_) external;

  /// @notice Adds a new `ParentMarket`. `ParentMarket`s can only be added if
  /// there is a matching `ToroPool` contract that supports the currency
  /// @param pMarket `ParentMarket` to add
  function _addParentMarket(IParentMarket pMarket) external;

  /// @notice Removes a `ParentMarket` completely from being associated with the
  /// `ToroPool` token completely. This should only done after a minimum period
  /// of time after the `ParentMarket` has closed, or else users won't be able
  /// to redeem from it.
  /// @param pMarketAddr Address of target `ParentMarket` to be deleted
  function _deleteParentMarket(address pMarketAddr) external;
  
  /// @notice Sets the max exposure for a particular `ParentMarket`
  /// @param pMarketAddr Address of the target `ParentMarket`
  /// @param maxExposure_ New max exposure, in local currency
  function _setMaxExposure(address pMarketAddr, uint maxExposure_) external;
    
  /// @notice Sets affiliate mint fee. The fee is in USDC, scaled to 1e6
  /// @param affiliateMintFee_ New mint fee
  function _setAffiliateMintFee(uint affiliateMintFee_) external;

  /// @notice Set the bookmaking fee
  /// param bookmakingFeeBps_ New bookmaking fee, scaled to 1e4  
  function _setBookmakingFeeBps(uint bookmakingFeeBps_) external;
  
  /// @notice Set the protocol fee
  /// param commissionFeeBps_ New protocol fee, scaled to 1e4  
  function _setCommissionFeeBps(uint commissionFeeBps_) external;

  /// @notice Set the affiliate bonus
  /// param affiliateBonusBps_ New affiliate bonus, scaled to 1e4 
  function _setAffiliateBonusBps(uint affiliateBonusBps_) external;

  /// @notice Set the referent discount
  /// @param referentDiscountBps_ New referent discount, scaled to 1e4
  function _setReferentDiscountBps(uint referentDiscountBps_) external;

  /// @notice Set the global `Market` expiry deadline
  /// @param expiryDeadline_ New `Market` expiry deadline (in seconds)
  function _setExpiryDeadline(uint expiryDeadline_) external;

  /// @notice Set the global cooldown timer for LP actions
  /// @param cooldownLP_ New cooldown time (in seconds)
  function _setCooldownLP(uint cooldownLP_) external;

  /// @notice Set the global window for LP actions
  /// @param windowLP_ New window time (in seconds)
  function _setWindowLP(uint windowLP_) external;

  /** VIEW FUNCTIONS **/

  function affiliateERC721() external view returns(address);

  function toroDB() external view returns(address);

  function sportOracle() external view returns(address);
  
  function priceOracle() external view returns(address);
  
  function feeEmissionsController() external view returns(address);

  function toroPool(IERC20 currency) external view returns(IToroPool);

  function parentMarkets(IERC20 currency, uint sportId) external view returns(address[] memory);

  function affiliateMintFee() external view returns(uint);

  function bookmakingFeeBps() external view returns(uint);
  
  function commissionFeeBps() external view returns(uint);

  function affiliateBonusBps() external view returns(uint);

  function referentDiscountBps() external view returns(uint);

  function expiryDeadline() external view returns(uint);

  function cooldownLP() external view returns(uint);

  function windowLP() external view returns(uint);
  
  function ADMIN_ROLE() external view returns(bytes32);

  function BOOKMAKER_ROLE() external view returns(bytes32);
  
  function CHILD_MARKET_ROLE() external view returns(bytes32);
  
  function PARENT_MARKET_ROLE() external view returns(bytes32);
  
  function MANTISSA_BPS() external view returns(uint);
  
  function MANTISSA_ODDS() external view returns(uint);

  function MANTISSA_USD() external pure returns(uint);
  
  function NULL_AFFILIATE() external view returns(uint);

  function OPTION_TIE() external view returns(uint8);
  
  function OPTION_A() external view returns(uint8);

  function OPTION_B() external view returns(uint8);

  function OPTION_UNDEFINED() external view returns(uint8);
  
  function STATE_OPEN() external view returns(uint8);

  function STATE_PENDING() external view returns(uint8);

  function STATE_CLOSED() external view returns(uint8);

  function STATE_EXPIRED() external view returns(uint8);  

  function BET_TYPE_MONEYLINE() external pure returns(uint8);

  function BET_TYPE_HANDICAP() external pure returns(uint8);

  function BET_TYPE_OVER_UNDER() external pure returns(uint8);
  
}

//SPDX-License-Identifier: NONE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IToroPool is IERC20Upgradeable {

  /// @notice Emitted when setting burn request
  event SetLastBurnRequest(address indexed user, uint timestamp);


  /** ACCESS CONTROLLED FUNCTIONS **/


  /// @notice Transfers funds to a `ChildMarket` to ensure it can cover the
  /// maximum payout. This is an access-controlled function - only the
  /// `ChildMarket` contracts may call this function
  function _transferToChildMarket(address cMarket, uint amount) external;

  /// @notice Accounting function to increase the amount credited to `ToroPool`
  /// i.e., How much is owed TO `ToroPool` FROM `ChildMarket`s
  /// @param amount Amount to increase `_credits`
  function _incrementCredits(uint amount) external;

  /// @notice Accounting function to decrease the amount credited to `ToroPool`
  /// i.e., How much is owed TO `ToroPool` FROM `ChildMarket`s
  /// @param amount Amount to decrease `_credits`
  function _decrementCredits(uint amount) external;

  /// @notice Accounting function to increase the amount debited to `ToroPool`
  /// i.e., How much is owed FROM `ToroPool` TO `ChildMarket`s
  /// @param amount Amount to increase `_debits`
  function _incrementDebits(uint amount) external;

  /// @notice Accounting function to decrease the amount debited to `ToroPool`
  /// i.e., How much is owed FROM `ToroPool` TO `ChildMarket`s
  /// @param amount Amount to decrease `_debits`
  function _decrementDebits(uint amount) external;

  
  /** USER INTERFACE **/


  /// @notice Deposit underlying currency and receive LP tokens
  /// NOTE: We need to strip out the amounts locked or amounts transferred by
  /// currently open `ChildMarket`s (i.e. their `netDebt`). Hence, to get a fair
  /// picture of the amount of LP tokens due to minters, we need to use the
  /// `netBalance`, which is the sum of the free balance currently inside the
  /// `ToroPool` contract and the `netDebt` of all open `ChildMarket`s.
  /// @param amount Amount user wishes to deposit, in underlying token
  function mint(uint amount) external;

  /// @notice Burn LP tokens to receive back underlying currency.
  /// NOTE: We need to strip out the amounts locked or amounts transferred by
  /// currently open `ChildMarket`s (i.e. their `netDebt`). Hence, to get a fair
  /// picture of the underlying amount due to LPs, we need to use the
  /// `netBalance`, which is the sum of the free balance currently inside the
  /// `ToroPool` contract and the `netDebt` of all open `ChildMarket`s. Because
  /// of this, it is possible that `ToroPool` potentially may not have enough
  /// balance if enough currency is locked inside open `ChildMarket`s relative
  /// to free balance in the contract. In that case, LPs will have to wait until
  /// the current `ChildMarket`s are closed or for new minters before redeeming.
  /// @param amount Amount of LP tokens user wishes to burn
  function burn(uint amount) external;

  /// @notice Make a request to burn tokens in the future. LPs may not burn
  /// their tokens immediately, but must wait a `cooldownLP` time after making
  /// the request. They are also given a `windowLP` time to burn. If they do not
  /// burn within the window, the current request expires and they will have to
  /// make a new burn request.
  function burnRequest() external;

  
  /** VIEW FUNCTIONS **/
  

  function toroAdmin() external view returns(address);
  
  function currency() external view returns(IERC20);

  /// @notice Conversion from underlying tokens to LP tokens, taking into
  /// account the balance that is currently locked inside open `ChildMarket`s
  /// @param amount Amount of underlying tokens
  /// @return uint Amount of LP tokens
  function underlyingToLP(uint amount) external view returns(uint);

  /// @notice Conversion from LP tokens to underlying tokens, taking into
  /// account the balance that is currently locked inside open `ChildMarket`s
  /// @param amount Amount of LP tokens
  /// @return uint Amount of underlying tokens
  function LPToUnderlying(uint amount) external view returns(uint);

  function credits() external view returns(uint);

  function debits() external view returns(uint);
  
}

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.17;

library Types {

  /// @notice Contains all the details of a betting `Ticket`
  /// @member id Unique identifier for the ticket
  /// @member account Address of the bettor
  /// @member option Enum indicating which `Option` the bettor has selected
  /// @member odds The locked-in odds which the bettor receives on this bet
  /// @member size The total size of the bet
  struct Ticket {
    uint id;
    address account;
    uint8 option;
    uint odds;
    uint size;
  }

  /// @notice Contains all the details of a betting `Option`
  /// @member label String identifier for the name of the betting `Option`
  /// @member size Total action currently placed on this `Option`
  /// @member payout Total amount owed to bettors if this `Option` wins
  struct Option {
    string label;
    uint size;
    uint payout;
  }

  /// @notice Convenience struct for storing odds tuples. Odds should always
  /// be stored in DECIMAL ODDS format, scaled by 1e8
  /// @member oddsA Odds of side A, in decimal odds format, scaled by 1e8
  /// @member oddsB Odds of side B, in decimal odds format, scaled by 1e8
  struct Odds {
    uint oddsA;
    uint oddsB;
  }
    
}

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IChildMarket.sol";
import "./interfaces/IParentMarket.sol";
import "./interfaces/IToroAdmin.sol";
import "./interfaces/ISportOracle.sol";

contract ParentMarket is ReentrancyGuard, IParentMarket {

  using SafeERC20 for IERC20;
  
  /// @notice Address of `ToroAdmin` contract
  IToroAdmin private _toroAdmin;

  /// @notice Address of `ToroPool` contract
  IToroPool private _toroPool;
  
  /// @notice Currency of this market
  IERC20 private _currency;

  /// @notice Unique tag corresponding to this match
  bytes32 private _tag;
  
  /// @notice True if the match result has been resolved, false otherwise
  bool private _resolved;
  
  /// @notice No more bets may be placed after deadline. UNIX timestamp in seconds
  uint private _deadline;

  /// @notice Enum of specific sport league (e.g., NBA, NFL)
  uint private _sportId;

  /// @notice Max exposure of the `ParentMarket` before bet sizes become limited
  uint private _maxExposure;
  
  /// @notice String name of option A (e.g. Los Angeles Lakers)
  string private _labelA;

  /// @notice Sstring name of Option B (e.g. Boston Celtics)
  string private _labelB;
  
  /// @notice Mapping from `betIds` to `ChildMarket`s
  mapping(uint => IChildMarket) private _childMarkets;
  
  constructor(
              address toroAdminAddr_,
              address currencyAddr_,
              bytes32 tag_,
              string memory labelA_,
              string memory labelB_,
              uint8 sportId_,
              uint maxExposure_,
              uint deadline_
              ) {
    
    // `deadline_` sets the deadline for when bets can no longer be placed
    require(deadline_ > block.timestamp, "Deadline must be in the future");

    // Set initial values
    _toroAdmin = IToroAdmin(toroAdminAddr_);
    _currency = IERC20(currencyAddr_);
    _tag = tag_;
    _labelA = labelA_;
    _labelB = labelB_;
    _sportId = sportId_;
    _maxExposure = maxExposure_;
    _deadline = deadline_;
    _resolved = false;
    
    // There must be an associated `ToroPool` token for this currency
    require(
            address(_toroAdmin.toroPool(_currency)) != address(0),
            "Currency not supported"
            );

    // Set the `ToroPool` token associated with this `Market`
    _toroPool = IToroPool(_toroAdmin.toroPool(_currency));
  }

  modifier onlyAdmin() {
    require(_toroAdmin.hasRole(_toroAdmin.ADMIN_ROLE(), msg.sender), "only admin");
    _;
  }
  
  modifier onlyToroAdmin() {
    require(msg.sender == address(_toroAdmin), "only ToroAdmin");
    _;
  }

  modifier onlySportOracle() {
    require(msg.sender == address(_toroAdmin.sportOracle()), "only SportOracle");
    _;
  }

  
  /** ACCESS CONTROLLED FUNCTIONS **/

  
  /// @notice Internal entry point for resolving this `ParentMarket`, which only
  /// `SportOracle` may call.
  /// NOTE: If a particular `betType` does not exist on this `ParentMarket`, the
  /// resolution for that `betType` will be correctly ignored.
  /// @param scoreA Raw score of side A, scaled by 1e8
  /// @param scoreB Raw score of side B, scaled by 1e8
  function _resolveMarket(int64 scoreA, int64 scoreB) external onlySportOracle {

    // Only allow resolving of unresolved `ParentMarket`
    require(!_resolved, "parent market already resolved");
    
    _resolveChildMarket(_toroAdmin.BET_TYPE_MONEYLINE(), scoreA, scoreB);
    _resolveChildMarket(_toroAdmin.BET_TYPE_HANDICAP(), scoreA, scoreB);
    _resolveChildMarket(_toroAdmin.BET_TYPE_OVER_UNDER(), scoreA, scoreB);
    
    // Mark this `ParentMarket` as resolved
    _resolved = true;
  }
  
  /// @notice Convenience function for adding `ChildMarket` triplet in a single
  /// transaction.
  /// NOTE: To skip adding a `ChildMarket` for any given `betType`, supply the
  /// zero address as a parameter and it will be ignored correctly.
  /// @param market1 Moneyline `ChildMarket`
  /// @param market2 Handicap `ChildMarket`
  /// @param market3 Over/Under `ChildMarket`
  function _addChildren(
                        IChildMarket market1,
                        IChildMarket market2,
                        IChildMarket market3
                        ) external onlyAdmin {

    _addChildMarket(_toroAdmin.BET_TYPE_MONEYLINE(), market1);
    _addChildMarket(_toroAdmin.BET_TYPE_HANDICAP(), market2);
    _addChildMarket(_toroAdmin.BET_TYPE_OVER_UNDER(), market3);
    
  }

  /// @notice Associate a `ChildMarket` with a particular `betType` to this
  /// `ParentMarket`.
  /// @param betType Enum for bet type (e.g., moneyline, handicap, over/under)
  /// @param cMarket `ChildMarket` to add
  function _addChildMarket(uint betType, IChildMarket cMarket) public onlyAdmin {

    // Ignore if adding null `ChildMarket`
    if(address(cMarket) == address(0)) {
      return;
    }
        
    // The `ChildMarket` must be associated to a valid `betType`
    require(
            betType == _toroAdmin.BET_TYPE_MONEYLINE() ||
            betType == _toroAdmin.BET_TYPE_HANDICAP() ||
            betType == _toroAdmin.BET_TYPE_OVER_UNDER(),
            "invalid bet type"
            );
    
    // Existing `ChildMarket`s cannot be replaced. Only new ones may be created.
    require(address(_childMarkets[betType]) == address(0), "child market exists");    
    
    // Cannot add a `ChildMarket` that isn't assigned to this parent
    require(cMarket.parentMarket() == address(this), "parent mismatch");

    // Cannot add a `ChildMarket` with the wrong bet type
    require(cMarket.betType() == betType, "bet type mismatch");
    
    // Add the `ChildMarket`
    _childMarkets[betType] = cMarket;

    // `CHILD_MARKET_ROLE` allows `ChildMarket` to request funds from `ToroPool`
    _toroAdmin.grantRole(_toroAdmin.CHILD_MARKET_ROLE(), address(cMarket));
    
    // Emit the event
    emit AddChildMarket(betType, address(cMarket));
  }
  
  /// @notice Called by `ToroAdmin` to set the max exposure allowed for every
  /// `ChildMarket` associated with this `ParentMarket`. If a bet size exceeds
  /// `_maxExposure`, it will get rejected. The purpose of `_maxExposure` is to
  /// limit the maximum amount of one-sided risk a `Market` can take on.
  /// @param maxExposure_ New max exposure
  function _setMaxExposure(uint maxExposure_) external onlyToroAdmin {

    // Set the new max exposure value
    _maxExposure = maxExposure_;

    // Emit the event
    emit SetMaxExposure(maxExposure_);
  }  
  

  /** USER INTERFACE **/

  
  /// @notice External entry point for end users to place bets on any
  /// associated `ChildMarket`. The `betType` will indicate what type of bet
  /// the user wishes to make (i.e., moneyline, handicap, over/under).
  /// The `option` enum indicates which side the user wants to bet, and the size
  /// is the amount the user wishes to bet (before commission fees).
  /// Commission fees are chard at the time of placing a bet, and the remainder
  /// is the actual size placed for the wager. Hence, the `Ticket` that user
  /// receives when placing a bet will be for a slightly smaller amount than
  /// `size`.
  /// `placeBet` transfers the full funds over from user to the `ChildMarket` on
  /// its behalf, so that users only need to call ERC20 `approve` on the
  /// `ParentMarket`. Beyond that, each `ChildMarket` manages its own currency
  /// balances separately when a bet is placed, including sending/requesting
  /// funds to `ToroPool`. The `ChildMarket` must have the `CHILD_MARKET_ROLE`
  /// before it can be approved to request funds from `ToroPool`.
  /// @param betType Enum for bet type (e.g., moneyline, handicap, over/under)
  /// @param option The side which user picks to win
  /// @param size Size which user wishes to bet (before commission fees)
  function placeBet(uint betType, uint8 option, uint size) external nonReentrant {

    // There must be an associated `ChildMarket` for this `betType`
    IChildMarket cMarket = _childMarkets[betType];
    require(address(cMarket) != address(0), "child market not found");

    // Cache the current token balance of the `ChildMarket` because we will be
    // pr-funding it with user tokens so `_currency.balanceOf(address(cMarket))`
    // will be an inaccurate value after the transfer.
    uint cachedCurrentBalance = _currency.balanceOf(address(cMarket));
    
    // Pre-fund the `ChildMarket` on its behalf. Note: This means end users
    // need to call ERC20 `approve` on this `ParentMarket`.
    _currency.safeTransferFrom(msg.sender, address(cMarket), size);
    
    // Place the bet in the `ChildMarket`
    cMarket._placeBet(msg.sender, option, size, cachedCurrentBalance);
    
  }

  /// @notice External entry point for end users to claim winning `Ticket`s.
  /// The `betType` will indicate what type of bet the `Ticket` references
  /// (i.e., moneyline, handicap, over/under) and the `ticketId` is the id of
  /// the winning `Ticket`. `ParentMarket` holds no funds - the `ChildMarket`
  /// will transfer funds to winners directly.
  /// @param betType Enum for bet type (e.g., moneyline, handicap, over/under)
  /// @param ticketId ID of the `Ticket`
  function claimTicket(uint betType, uint ticketId) external nonReentrant {

    // There must be an associated `ChildMarket` for this `betType`
    IChildMarket cMarket = _childMarkets[betType];
    require(address(cMarket) != address(0), "child market not found");

    // Claim the ticket in the `ChildMarket`
    cMarket._claimTicket(msg.sender, ticketId);
    
  }

  
  /** VIEW FUNCTIONS **/

  
  function toroAdmin() external view returns(address) {
    return address(_toroAdmin);
  }
  
  function toroPool() external view returns(address) {
    return address(_toroPool);
  }

  function currency() external view returns(IERC20) {
    return _currency;
  }

  function tag() external view returns(bytes32) {
    return _tag;
  }
  
  function resolved() external view returns(bool) {
    return _resolved;
  }
  
  function deadline() external view returns(uint) {
    return _deadline;
  }

  function sportId() external view returns(uint) {
    return _sportId;
  }

  function maxExposure() external view returns(uint) {
    return _maxExposure;
  }

  function labelA() external view returns(string memory) {
    return _labelA;
  }

  function labelB() external view returns(string memory) {
    return _labelB;
  }

  function childMarket(uint betType) external view returns(IChildMarket) {
    return _childMarkets[betType];
  }
  
  /// @notice Gets the current state of the `Market`. The states are:
  /// OPEN: Still open for taking new bets
  /// PENDING: No new bets allowed, but no winner/tie declared yet
  /// CLOSED: Result declared, still available for redemptions
  /// EXPIRED: Redemption window expired, `Market` eligible to be deleted
  /// @return uint8 Current state
  function state() external view returns(uint8) {
    return _state();
  }  

  /** INTERNAL FUNCTIONS **/

  /// @notice Gets the current state of the `Market`. The states are:
  /// OPEN: Still open for taking new bets
  /// PENDING: No new bets allowed, but no winner/tie declared yet
  /// CLOSED: Result declared, still available for redemptions
  /// EXPIRED: Redemption window expired, `Market` eligible to be deleted
  /// @return uint8 Current state
  function _state() internal view returns(uint8) {
    if(block.timestamp < _deadline) {
      // Before betting `_deadline`, `ParentMarket` is open
      return _toroAdmin.STATE_OPEN();
    } else if(!_resolved) {
      // If deadline passes, but no result declared yet, `ParentMarket` is pending
      return _toroAdmin.STATE_PENDING();
    } else if(block.timestamp < _deadline + _toroAdmin.expiryDeadline()) {
      // If a winner has been declared, allow winners to redeem until the
      // `ParentMarket` is past its expiry deadline
      return _toroAdmin.STATE_CLOSED();
    } else {
      // After expiry deadline, `ParentMarket` is expired and may be subject to
      // deletion
      return _toroAdmin.STATE_EXPIRED();
    }        
  }

  /// @notice Resolves a particular `ChildMarket` of given `betType`
  /// Does nothing if there does not exist a `ChildMarket` for that `betType`.
  /// @param betType Enum for bet type (e.g., moneyline, handicap, over/under)
  /// @param scoreA Raw score of side A, scaled by 1e8
  /// @param scoreB Raw score of side B, scaled by 1e8
  function _resolveChildMarket(uint betType, int64 scoreA, int64 scoreB) internal {

    // Find the particular `ChildMarket`, if it exists
    IChildMarket childMarket_ = _childMarkets[betType];

    // Resolve the particular `ChildMarket`, if it exists
    if(address(childMarket_) != address(0)) {
      childMarket_._resolveMarket(scoreA, scoreB);
    }
    
  }

  
}