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

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/core/IVaultAccessControlRegistry.sol";

pragma solidity 0.8.19;

contract AccessControlBase is Context {
    IVaultAccessControlRegistry public immutable registry;
    address public immutable timelockAddressImmutable;

    constructor(address _vaultRegistry, address _timelock) {
        registry = IVaultAccessControlRegistry(_vaultRegistry);
        timelockAddressImmutable = _timelock;
    }

    /*==================== Managed in VaultAccessControlRegistry *====================*/

    modifier onlyGovernance() {
        require(
            registry.isCallerGovernance(_msgSender()),
            "Forbidden: Only Governance"
        );
        _;
    }

    modifier onlyEmergency() {
        require(
            registry.isCallerEmergency(_msgSender()),
            "Forbidden: Only Emergency"
        );
        _;
    }

    modifier onlySupport() {
        require(
            registry.isCallerSupport(_msgSender()),
            "Forbidden: Only Support"
        );
        _;
    }

    modifier onlyTeam() {
        require(registry.isCallerTeam(_msgSender()), "Forbidden: Only Team");
        _;
    }

    modifier onlyProtocol() {
        require(
            registry.isCallerProtocol(_msgSender()),
            "Forbidden: Only Protocol"
        );
        _;
    }

    modifier protocolNotPaused() {
        require(!registry.isProtocolPaused(), "Forbidden: Protocol Paused");
        _;
    }

    /*==================== Managed in PRYTimelock *====================*/

    modifier onlyTimelockGovernance() {
        address timelockActive_;
        if (!registry.timelockActivated()) {
            // the flip is not switched yet, so this means that the governance address can still pass the onlyTimelockGoverance modifier
            timelockActive_ = registry.governanceAddress();
        } else {
            // the flip is switched, the immutable timelock is now locked in as the only adddress that can pass this modifier (and nothing can undo that)
            timelockActive_ = timelockAddressImmutable;
        }
        require(
            _msgSender() == timelockActive_,
            "Forbidden: Only TimelockGovernance"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "solmate/src/utils/ReentrancyGuard.sol";
import "../interfaces/core/ITokenManager.sol";
import "../interfaces/tokens/IPRY.sol";
import "./AccessControlBase.sol";
import "../interfaces/stakings/IPRYStaking.sol";

contract TokenManager is AccessControlBase, ReentrancyGuard {
    using SafeERC20 for IPRY;
    using SafeERC20 for IERC20;
    event Converted(address indexed account, uint256 amount);
    event TokensSet(IPRY indexed PRY, IPRY indexed vPRYAddress);
    event PRYStakingSet(IPRYStaking indexed PRYStakingAddress);
    /*==================================================== State Variables =============================================================*/
    /// @notice PRY address
    IPRY public immutable PRY;
    /// @notice vPRY address
    IPRY public immutable vPRY;
    /// @notice USDC address
    address public immutable USDC;
    /// @notice PRY staking address
    IPRYStaking public PRYStaking;
    /// @notice total coverted amount (PRY => vPRY)
    uint256 public totalConverted;
    /// @notice stores transferable PRY amount
    uint256 public sendableAmount;
    /// @notice accumulative Vested PRY fee amount
    uint256 public accumFee;

    /// @notice divider for minting vested PRY fee
    // uint256 public mintDivider;

    /// @notice referral Basis points
    uint256 private constant BASIS_POINTS = 10000;

    /*==================================================== Constructor =============================================================*/
    constructor(
        IPRY _PRY,
        IPRY _vPRY,
        address _vaultRegistry,
        address _timelock,
        address _USDC
    ) AccessControlBase(_vaultRegistry, _timelock) {
        PRY = _PRY;
        vPRY = _vPRY;
        USDC = _USDC;
    }

    /*==================================================== Functions =============================================================*/
    /**
     *
     * @param _PRYStaking PRY staking address
     * @notice function to set PRY Staking address
     * @notice grants PRY_STAKING_ROLE to the address
     */
    function setPRYStaking(IPRYStaking _PRYStaking) external onlyGovernance {
        require(address(_PRYStaking) != address(0), "address can not be zero");
        PRYStaking = _PRYStaking;
        emit PRYStakingSet(PRYStaking);
    }

    /*==================================================== PRY Staking Functions =============================================================*/
    /**
     *
     * @param _from adress of the sender
     * @param _amount amount of Vested PRY to take
     * @notice function to transfer Vested PRY from sender to Token Manager
     */
    function takeVestedPRY(
        address _from,
        uint256 _amount
    ) external nonReentrant onlyProtocol {
        vPRY.safeTransferFrom(_from, address(this), _amount);
    }

    /**
     *
     * @param _from adress of the sender
     * @param _amount amount of PRY to take
     * @notice function to transfer PRY from sender to Token Manager
     */
    function takePRY(
        address _from,
        uint256 _amount
    ) external nonReentrant onlyProtocol {
        PRY.safeTransferFrom(_from, address(this), _amount);
    }

    /**
     *
     * @param _to adress of the receiver
     * @param _amount amount of Vested PRY to send
     * @notice function to transfer Vested PRY from Token Manager to receiver
     */
    function sendVestedPRY(
        address _to,
        uint256 _amount
    ) external nonReentrant onlyProtocol {
        vPRY.safeTransfer(_to, _amount);
    }

    /**
     *
     * @param _to adress of the receiver
     * @param _amount amount of PRY to send
     * @notice function to transfer PRY from Token Manager to receiver
     */
    function sendPRY(
        address _to,
        uint256 _amount
    ) external nonReentrant onlyProtocol {
        _sendPRY(_to, _amount);
    }

    /**
     *
     * @param _amount amount of Vested PRY to burn
     * @notice function to burn Vested PRY from Token Manager
     */
    function burnVestedPRY(uint256 _amount) external nonReentrant onlyProtocol {
        vPRY.burn(_amount);
    }

    /**
     *
     * @param _amount amount of PRY to burn
     * @notice function to burn PRY from Token Manager
     */
    function burnPRY(uint256 _amount) external nonReentrant onlyProtocol {
        PRY.burn(_amount);
    }

    /**
     *
     * @param _to USDC receiver address (claim on PRY Staking)
     * @param _amount amount of USDC
     * @notice funtion to transfer USDC from Token Manager to receiver
     */
    function sendUSDC(
        address _to,
        uint256 _amount
    ) external nonReentrant onlyProtocol {
        IERC20(USDC).safeTransfer(_to, _amount);
    }

    /**
     *
     * @param _to address of receiver
     * @param _amount amount of PRY
     * @notice internal function to transfer PRY
     */
    function _sendPRY(address _to, uint256 _amount) internal {
        PRY.safeTransfer(_to, _amount);
    }

    /*==================================================== Conversion =============================================================*/
    /**
     *
     * @param _amount amount of PRY to convert
     * @notice function to convert PRY to Vested PRY
     * @notice takes PRY, mints equivalent amount of Vested PRY
     */
    function convertToken(uint256 _amount) external nonReentrant {
        // Transfer PRY from sender to Token Manager
        PRY.safeTransferFrom(msg.sender, address(this), _amount);
        // Mint equivalent amount of Vested PRY
        vPRY.mint(msg.sender, _amount);
        // Update total converted amount
        totalConverted += _amount;
        // Update sendable amount
        sendableAmount += _amount;

        emit Converted(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITokenManager {
    function takeVestedPRY(address _from, uint256 _amount) external;

    function takePRY(address _from, uint256 _amount) external;

    function sendVestedPRY(address _to, uint256 _amount) external;

    function sendPRY(address _to, uint256 _amount) external;

    function burnVestedPRY(uint256 _amount) external;

    function burnPRY(uint256 _amount) external;

    function sendUSDC(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/IAccessControl.sol";

pragma solidity >=0.6.0 <0.9.0;

interface IVaultAccessControlRegistry is IAccessControl {
	function timelockActivated() external view returns (bool);

	function governanceAddress() external view returns (address);

	function pauseProtocol() external;

	function unpauseProtocol() external;

	function isCallerGovernance(address _account) external view returns (bool);

	function isCallerEmergency(address _account) external view returns (bool);

	function isCallerProtocol(address _account) external view returns (bool);

	function isCallerTeam(address _account) external view returns (bool);

	function isCallerSupport(address _account) external view returns (bool);

	function isProtocolPaused() external view returns (bool);

	function changeGovernanceAddress(address _governanceAddress) external;

	/*==================== Events *====================*/

	event DeadmanSwitchFlipped();
	event GovernanceChange(address newGovernanceAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPRYStaking {
    function share(uint256 amount) external;

    function totalWeight() external view returns (uint256);

    struct StakeDividend {
        uint256 amount;
        uint256 profitDebt;
        uint256 weight;
        uint128 depositTime;
    }

    struct StakeVesting {
        uint256 amount; // The amount of tokens being staked
        uint256 weight; // The weight of the stake, used for calculating rewards
        uint256 vestingDuration; // The duration of the vesting period in seconds
        uint256 profitDebt; // The amount of profit earned by the stake, used for calculating rewards
        uint256 startTime; // The timestamp at which the stake was created
        bool withdrawn; // Indicates whether the stake has been withdrawn or not
        bool cancelled; // Indicates whether the stake has been cancelled or not
    }

    struct Period {
        uint256 duration;
        uint256 minDuration;
        uint256 claimDuration;
        uint256 minPercent;
    }

    struct WeightMultipliers {
        uint256 pry;
        uint256 vPry;
        uint256 vPryVesting;
    }

    /*==================================================== Events =============================================================*/

    event Donation(address indexed player, uint amount);
    event Share(
        uint256 amount,
        uint256 totalWeight,
        uint256 totalStakedVPRY,
        uint256 totalStakedPRY
    );
    event DepositVesting(
        address indexed user,
        uint256 index,
        uint256 startTime,
        uint256 endTime,
        uint256 amount,
        uint256 profitDebt,
        bool isVested,
        bool isVesting
    );

    event DepositDividend(
        address indexed user,
        uint256 amount,
        uint256 profitDebt,
        bool isVested
    );
    event Withdraw(
        address indexed user,
        uint256 withdrawTime,
        uint256 index,
        uint256 amount,
        uint256 redeem,
        uint256 vestedBurn
    );
    event WithdrawBatch(
        address indexed user,
        uint256 withdrawTime,
        uint256[] indexes,
        uint256 amount,
        uint256 redeem,
        uint256 vestedBurn
    );

    event Unstake(
        address indexed user,
        uint256 unstakeTime,
        uint256 amount,
        uint256 burnedAmount,
        bool isVested
    );
    event Cancel(
        address indexed user,
        uint256 cancelTime,
        uint256 index,
        uint256 burnedAmount,
        uint256 sentAmount
    );
    event ClaimVesting(address indexed user, uint256 reward, uint256 index);
    event ClaimVestingBatch(
        address indexed user,
        uint256 reward,
        uint256[] indexes
    );
    event ClaimDividend(address indexed user, uint256 reward, bool isVested);
    event ClaimDividendBatch(address indexed user, uint256 reward);
    event WeightMultipliersUpdate(WeightMultipliers _weightMultipliers);
    event UnstakeBurnPercentageUpdate(uint256 _unstakeBurnPercentage);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPRY is IERC20 {
    function mint(
        address account,
        uint256 amount
    ) external returns (uint256, uint256);

    function burn(uint256 amount) external;

    function MAX_SUPPLY() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}