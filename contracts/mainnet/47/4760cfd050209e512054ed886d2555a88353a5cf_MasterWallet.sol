// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IMasterWallet.sol";
import "./access/SpoolAccessControllable.sol";

contract MasterWallet is IMasterWallet, SpoolAccessControllable {
    using SafeERC20 for IERC20;

    constructor(ISpoolAccessControl accessControl_) SpoolAccessControllable(accessControl_) {}

    function transfer(IERC20 token, address recipient, uint256 amount)
        external
        onlyRole(ROLE_MASTER_WALLET_MANAGER, msg.sender)
    {
        token.safeTransfer(recipient, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/token/ERC20/IERC20.sol";

interface IMasterWallet {
    /**
     * @notice Transfers amount of token to the recipient.
     * @dev Requirements:
     * - caller must have role ROLE_MASTER_WALLET_MANAGER
     * @param token Token to transfer.
     * @param recipient Target of the transfer.
     * @param amount Amount to transfer.
     */
    function transfer(IERC20 token, address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../interfaces/ISpoolAccessControl.sol";
import "../interfaces/CommonErrors.sol";
import "./Roles.sol";

/**
 * @notice Account access role verification middleware
 */
abstract contract SpoolAccessControllable {
    /* ========== CONSTANTS ========== */

    /**
     * @dev Spool access control manager.
     */
    ISpoolAccessControl internal immutable _accessControl;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @param accessControl_ Spool access control manager.
     */
    constructor(ISpoolAccessControl accessControl_) {
        if (address(accessControl_) == address(0)) revert ConfigurationAddressZero();

        _accessControl = accessControl_;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @dev Reverts if an account is missing a role.\
     * @param role Role to check for.
     * @param account Account to check.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_accessControl.hasRole(role, account)) {
            revert MissingRole(role, account);
        }
    }

    /**
     * @dev Revert if an account is missing a role for a smartVault.
     * @param smartVault Address of the smart vault.
     * @param role Role to check for.
     * @param account Account to check.
     */
    function _checkSmartVaultRole(address smartVault, bytes32 role, address account) internal view {
        if (!_accessControl.hasSmartVaultRole(smartVault, role, account)) {
            revert MissingRole(role, account);
        }
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (_accessControl.paused()) {
            revert SystemPaused();
        }
    }

    function _checkNonReentrant() internal view {
        _accessControl.checkNonReentrant();
    }

    function _nonReentrantBefore() internal {
        _accessControl.nonReentrantBefore();
    }

    function _nonReentrantAfter() internal {
        _accessControl.nonReentrantAfter();
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Only allows accounts with granted role.
     * @dev Reverts when the account fails check.
     * @param role Role to check for.
     * @param account Account to check.
     */
    modifier onlyRole(bytes32 role, address account) {
        _checkRole(role, account);
        _;
    }

    /**
     * @notice Only allows accounts with granted role for a smart vault.
     * @dev Reverts when the account fails check.
     * @param smartVault Address of the smart vault.
     * @param role Role to check for.
     * @param account Account to check.
     */
    modifier onlySmartVaultRole(address smartVault, bytes32 role, address account) {
        _checkSmartVaultRole(smartVault, role, account);
        _;
    }

    /**
     * @notice Only allows accounts that are Spool admins or admins of a smart vault.
     * @dev Reverts when the account fails check.
     * @param smartVault Address of the smart vault.
     * @param account Account to check.
     */
    modifier onlyAdminOrVaultAdmin(address smartVault, address account) {
        _accessControl.checkIsAdminOrVaultAdmin(smartVault, account);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Prevents a contract from calling itself, or other contracts using this modifier.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    /**
     * @dev Check if a system has already entered in the non-reentrant state.
     */
    modifier checkNonReentrant() {
        _checkNonReentrant();
        _;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin-upgradeable/access/IAccessControlUpgradeable.sol";

/**
 * @notice Used when an account is missing a required role.
 * @param role Required role.
 * @param account Account missing the required role.
 */
error MissingRole(bytes32 role, address account);

/**
 * @notice Used when interacting with Spool when the system is paused.
 */
error SystemPaused();

/**
 * @notice Used when setting smart vault owner
 */
error SmartVaultOwnerAlreadySet(address smartVault);

/**
 * @notice Used when a contract tries to enter in a non-reentrant state.
 */
error ReentrantCall();

/**
 * @notice Used when a contract tries to call in a non-reentrant function and doesn't have the correct role.
 */
error NoReentrantRole();

interface ISpoolAccessControl is IAccessControlUpgradeable {
    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Gets owner of a smart vault.
     * @param smartVault Smart vault.
     * @return owner Owner of the smart vault.
     */
    function smartVaultOwner(address smartVault) external view returns (address owner);

    /**
     * @notice Looks if an account has a role for a smart vault.
     * @param smartVault Address of the smart vault.
     * @param role Role to look for.
     * @param account Account to check.
     * @return hasRole True if account has the role for the smart vault, false otherwise.
     */
    function hasSmartVaultRole(address smartVault, bytes32 role, address account)
        external
        view
        returns (bool hasRole);

    /**
     * @notice Checks if an account is either Spool admin or admin for a smart vault.
     * @dev The function reverts if account is neither.
     * @param smartVault Address of the smart vault.
     * @param account to check.
     */
    function checkIsAdminOrVaultAdmin(address smartVault, address account) external view;

    /**
     * @notice Checks if system is paused or not.
     * @return isPaused True if system is paused, false otherwise.
     */
    function paused() external view returns (bool isPaused);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Pauses the whole system.
     * @dev Requirements:
     * - caller must have role ROLE_PAUSER
     */
    function pause() external;

    /**
     * @notice Unpauses the whole system.
     * @dev Requirements:
     * - caller must have role ROLE_UNPAUSER
     */
    function unpause() external;

    /**
     * @notice Grants role to an account for a smart vault.
     * @dev Requirements:
     * - caller must have either role ROLE_SPOOL_ADMIN or role ROLE_SMART_VAULT_ADMIN for the smart vault
     * @param smartVault Address of the smart vault.
     * @param role Role to grant.
     * @param account Account to grant the role to.
     */
    function grantSmartVaultRole(address smartVault, bytes32 role, address account) external;

    /**
     * @notice Revokes role from an account for a smart vault.
     * @dev Requirements:
     * - caller must have either role ROLE_SPOOL_ADMIN or role ROLE_SMART_VAULT_ADMIN for the smart vault
     * @param smartVault Address of the smart vault.
     * @param role Role to revoke.
     * @param account Account to revoke the role from.
     */
    function revokeSmartVaultRole(address smartVault, bytes32 role, address account) external;

    /**
     * @notice Renounce role for a smart vault.
     * @param smartVault Address of the smart vault.
     * @param role Role to renounce.
     */
    function renounceSmartVaultRole(address smartVault, bytes32 role) external;

    /**
     * @notice Grant ownership to smart vault and assigns admin role.
     * @dev Ownership can only be granted once and it should be done at vault creation time.
     * @param smartVault Address of the smart vault.
     * @param owner address to which grant ownership to
     */
    function grantSmartVaultOwnership(address smartVault, address owner) external;

    /**
     * @notice Checks and reverts if a system has already entered in the non-reentrant state.
     */
    function checkNonReentrant() external view;

    /**
     * @notice Sets the entered flag to true when entering for the first time.
     * @dev Reverts if a system has already entered before.
     */
    function nonReentrantBefore() external;

    /**
     * @notice Resets the entered flag after the call is finished.
     */
    function nonReentrantAfter() external;

    /**
     * @notice Emitted when ownership of a smart vault is granted to an address
     * @param smartVault Smart vault address
     * @param address_ Address of the new smart vault owner
     */
    event SmartVaultOwnershipGranted(address indexed smartVault, address indexed address_);

    /**
     * @notice Smart vault specific role was granted
     * @param smartVault Smart vault address
     * @param role Role ID
     * @param account Account to which the role was granted
     */
    event SmartVaultRoleGranted(address indexed smartVault, bytes32 indexed role, address indexed account);

    /**
     * @notice Smart vault specific role was revoked
     * @param smartVault Smart vault address
     * @param role Role ID
     * @param account Account for which the role was revoked
     */
    event SmartVaultRoleRevoked(address indexed smartVault, bytes32 indexed role, address indexed account);

    /**
     * @notice Smart vault specific role was renounced
     * @param smartVault Smart vault address
     * @param role Role ID
     * @param account Account that renounced the role
     */
    event SmartVaultRoleRenounced(address indexed smartVault, bytes32 indexed role, address indexed account);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @notice Used when an array has invalid length.
 */
error InvalidArrayLength();

/**
 * @notice Used when group of smart vaults or strategies do not have same asset group.
 */
error NotSameAssetGroup();

/**
 * @notice Used when configuring an address with a zero address.
 */
error ConfigurationAddressZero();

/**
 * @notice Used when constructor or intializer parameters are invalid.
 */
error InvalidConfiguration();

/**
 * @notice Used when fetched exchange rate is out of slippage range.
 */
error ExchangeRateOutOfSlippages();

/**
 * @notice Used when an invalid strategy is provided.
 * @param address_ Address of the invalid strategy.
 */
error InvalidStrategy(address address_);

/**
 * @notice Used when doing low-level call on an address that is not a contract.
 * @param address_ Address of the contract
 */
error AddressNotContract(address address_);

/**
 * @notice Used when invoking an only view execution and tx.origin is not address zero.
 * @param address_ Address of the tx.origin
 */
error OnlyViewExecution(address address_);

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @dev Grants permission to:
 * - acts as a default admin for other roles,
 * - can whitelist an action with action manager,
 * - can manage asset group registry.
 *
 * Is granted to the deployer of the SpoolAccessControl contract.
 *
 * Equals to the DEFAULT_ADMIN_ROLE of the OpenZeppelin AccessControl.
 */
bytes32 constant ROLE_SPOOL_ADMIN = 0x00;

/**
 * @dev Grants permission to integrate a new smart vault into the Spool ecosystem.
 *
 * Should be granted to smart vault factory contracts.
 */
bytes32 constant ROLE_SMART_VAULT_INTEGRATOR = keccak256("SMART_VAULT_INTEGRATOR");

/**
 * @dev Grants permission to
 * - manage rewards on smart vaults,
 * - manage roles on smart vaults,
 * - redeem for another user of a smart vault.
 */
bytes32 constant ROLE_SMART_VAULT_ADMIN = keccak256("SMART_VAULT_ADMIN");

/**
 * @dev Grants permission to manage allowlists with AllowlistGuard for a smart vault.
 *
 * Should be granted to whoever is in charge of maintaining allowlists with AllowlistGuard for a smart vault.
 */
bytes32 constant ROLE_GUARD_ALLOWLIST_MANAGER = keccak256("GUARD_ALLOWLIST_MANAGER");

/**
 * @dev Grants permission to manage assets on master wallet.
 *
 * Should be granted to:
 * - the SmartVaultManager contract,
 * - the StrategyRegistry contract,
 * - the DepositManager contract,
 * - the WithdrawalManager contract.
 */
bytes32 constant ROLE_MASTER_WALLET_MANAGER = keccak256("MASTER_WALLET_MANAGER");

/**
 * @dev Marks a contract as a smart vault manager.
 *
 * Should be granted to:
 * - the SmartVaultManager contract,
 * - the DepositManager contract.
 */
bytes32 constant ROLE_SMART_VAULT_MANAGER = keccak256("SMART_VAULT_MANAGER");

/**
 * @dev Marks a contract as a strategy registry.
 *
 * Should be granted to the StrategyRegistry contract.
 */
bytes32 constant ROLE_STRATEGY_REGISTRY = keccak256("STRATEGY_REGISTRY");

/**
 * @dev Grants permission to act as a risk provider.
 *
 * Should be granted to whoever is allowed to provide risk scores.
 */
bytes32 constant ROLE_RISK_PROVIDER = keccak256("RISK_PROVIDER");

/**
 * @dev Grants permission to act as an allocation provider.
 *
 * Should be granted to contracts that are allowed to calculate allocations.
 */
bytes32 constant ROLE_ALLOCATION_PROVIDER = keccak256("ALLOCATION_PROVIDER");

/**
 * @dev Grants permission to pause the system.
 */
bytes32 constant ROLE_PAUSER = keccak256("SYSTEM_PAUSER");

/**
 * @dev Grants permission to unpause the system.
 */
bytes32 constant ROLE_UNPAUSER = keccak256("SYSTEM_UNPAUSER");

/**
 * @dev Grants permission to manage rewards payment pool.
 */
bytes32 constant ROLE_REWARD_POOL_ADMIN = keccak256("REWARD_POOL_ADMIN");

/**
 * @dev Grants permission to reallocate smart vaults.
 */
bytes32 constant ROLE_REALLOCATOR = keccak256("REALLOCATOR");

/**
 * @dev Grants permission to be used as a strategy.
 */
bytes32 constant ROLE_STRATEGY = keccak256("STRATEGY");

/**
 * @dev Grants permission to manually set strategy apy.
 */
bytes32 constant ROLE_STRATEGY_APY_SETTER = keccak256("STRATEGY_APY_SETTER");

/**
 * @dev Grants permission to manage role ROLE_STRATEGY.
 */
bytes32 constant ADMIN_ROLE_STRATEGY = keccak256("ADMIN_STRATEGY");

/**
 * @dev Grants permission vault admins to allow redeem on behalf of other users.
 */
bytes32 constant ROLE_SMART_VAULT_ALLOW_REDEEM = keccak256("SMART_VAULT_ALLOW_REDEEM");

/**
 * @dev Grants permission to manage role ROLE_SMART_VAULT_ALLOW_REDEEM.
 */
bytes32 constant ADMIN_ROLE_SMART_VAULT_ALLOW_REDEEM = keccak256("ADMIN_SMART_VAULT_ALLOW_REDEEM");

/**
 * @dev Grants permission to run do hard work.
 */
bytes32 constant ROLE_DO_HARD_WORKER = keccak256("DO_HARD_WORKER");

/**
 * @dev Grants permission to immediately withdraw assets in case of emergency.
 */
bytes32 constant ROLE_EMERGENCY_WITHDRAWAL_EXECUTOR = keccak256("EMERGENCY_WITHDRAWAL_EXECUTOR");

/**
 * @dev Grants permission to swap with swapper.
 *
 * Should be granted to the DepositSwap contract.
 */
bytes32 constant ROLE_SWAPPER = keccak256("SWAPPER");

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