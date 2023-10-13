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

    /*==================== Managed in WINRTimelock *====================*/

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

import "solmate/src/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/core/IVault.sol";
import "../interfaces/core/IWLPManager.sol";
import "../interfaces/core/ITokenManager.sol";
import "../interfaces/stakings/IWINRStaking.sol";
import "../interfaces/core/IFeeCollector.sol";
import "../tokens/wlp/interfaces/IBasicFDT.sol";
import "./AccessControlBase.sol";

contract FeeCollector is ReentrancyGuard, AccessControlBase, IFeeCollector {
    /*==================== Constants *====================*/
    uint256 private constant MAX_INTERVAL = 14 days;
    uint256 private constant BASIS_POINTS_DIVISOR = 1e4;
    uint256 private constant PRICE_PRECISION = 1e30;

    /*==================== State Variabes *====================*/
    IVault public vault;
    IWLPManager public wlpManager;
    IERC20 public wlp;
    IWINRStaking public winrStaking;
    // the fee distribution reward interval
    uint256 public rewardInterval = 1 days;
    // array with addresses of all tokens fees are collected in
    address[] public allWhitelistedTokensFeeCollector;
    mapping(address => bool) private whitelistedDestinations;
    // stores tokens amounts of referral
    mapping(address => uint256) public referralReserve;
    // ratio configuration for receivers of accumulated wagerfees
    WagerDistributionRatio public wagerDistributionConfig;
    // ratio configuration for receivers of accumulated swapfees
    SwapDistributionRatio public swapDistributionConfig;
    // stores wlp amounts of addresses
    Reserve public reserves;
    // distribution addresses
    DistributionAddresses public addresses;
    // last distribution times of destinations
    DistributionTimes public lastDistributionTimes;
    // if true, the contract will revert on time based distribution functions
    bool public failOnTime = false;

    constructor(
        address _vaultRegistry,
        address _vault,
        address _wlpManager,
        address _wlpClaimContract,
        address _tokenManagerContract,
        address _winrStakingContract,
        address _buybackAndBurnContract,
        address _coreDevelopment,
        address _referralContract,
        address _timelock
    ) AccessControlBase(_vaultRegistry, _timelock) {
        _checkNotNull(_vault);
        _checkNotNull(_wlpManager);
        vault = IVault(_vault);
        wlpManager = IWLPManager(_wlpManager);

        addresses = IFeeCollector.DistributionAddresses(
            _wlpClaimContract,
            _tokenManagerContract,
            _buybackAndBurnContract,
            _coreDevelopment,
            _referralContract
        );

        lastDistributionTimes = DistributionTimes(
            block.timestamp,
            block.timestamp,
            block.timestamp,
            block.timestamp,
            block.timestamp
        );

        wlp = IERC20(wlpManager.wlp());
        winrStaking = IWINRStaking(_winrStakingContract);

        whitelistedDestinations[_wlpClaimContract] = true;
        whitelistedDestinations[_tokenManagerContract] = true;
        whitelistedDestinations[_coreDevelopment] = true;
        whitelistedDestinations[_buybackAndBurnContract] = true;
        whitelistedDestinations[_referralContract] = true;
        whitelistedDestinations[_timelock] = true;
    }

    /*==================== Configuration functions (onlyGovernance) *====================*/

    /**
     * @notice function that sets vault address
     */
    function setVault(address vault_) external onlyTimelockGovernance {
        _checkNotNull(vault_);
        vault = IVault(vault_);
        emit VaultUpdated(vault_);
    }

    /**
     * @notice function that changes wlp manager address
     */
    function setWlpManager(address wlpManager_) public onlyTimelockGovernance {
        _checkNotNull(wlpManager_);
        wlpManager = IWLPManager(wlpManager_);
        wlp = IERC20(wlpManager.wlp());
        _checkNotNull(address(wlp));
        emit WLPManagerUpdated(address(wlpManager_));
    }

    /**
     * @param _wlpClaimContract address for the claim destination
     */
    function setWlpClaimContract(
        address _wlpClaimContract
    ) external onlyTimelockGovernance {
        _checkNotNull(_wlpClaimContract);
        // remove previous destination from whitelist
        whitelistedDestinations[addresses.wlpClaim] = false;
        addresses.wlpClaim = _wlpClaimContract;
        whitelistedDestinations[_wlpClaimContract] = true;
        emit SetClaimDestination(_wlpClaimContract);
    }

    /**
     * @param _buybackAndBurnContract address for the buyback and burn destination
     */
    function setBuyBackAndBurnContract(
        address _buybackAndBurnContract
    ) external onlyTimelockGovernance {
        _checkNotNull(_buybackAndBurnContract);
        // remove previous destination from whitelist
        whitelistedDestinations[addresses.buybackAndBurn] = false;
        addresses.buybackAndBurn = _buybackAndBurnContract;
        whitelistedDestinations[_buybackAndBurnContract] = true;
        emit SetBuybackAndBurnDestination(_buybackAndBurnContract);
    }

    /**
     * @param _tokenManagerContract address for the staking destination
     */
    function setWinrStakingContract(
        address _tokenManagerContract
    ) external onlyTimelockGovernance {
        _checkNotNull(_tokenManagerContract);
        // remove previous destination from whitelist
        whitelistedDestinations[addresses.winrStaking] = false;
        addresses.winrStaking = _tokenManagerContract;
        whitelistedDestinations[_tokenManagerContract] = true;
        emit SetStakingDestination(_tokenManagerContract);
    }

    /**
     * @param _coreDevelopment  address for the core destination
     */
    function setCoreDevelopment(
        address _coreDevelopment
    ) external onlyTimelockGovernance {
        _checkNotNull(_coreDevelopment);
        // remove previous destination from whitelist
        whitelistedDestinations[addresses.core] = false;
        addresses.core = _coreDevelopment;
        whitelistedDestinations[_coreDevelopment] = true;
        emit SetCoreDestination(_coreDevelopment);
    }

    /**
     * @param _referralAddress  address for the referral distributor
     */
    function setReferralDistributor(
        address _referralAddress
    ) external onlyTimelockGovernance {
        _checkNotNull(_referralAddress);
        // remove previous destination from whitelist
        whitelistedDestinations[addresses.referral] = false;
        addresses.referral = _referralAddress;
        whitelistedDestinations[_referralAddress] = true;
        emit SetReferralDestination(_referralAddress);
    }

    /**
     * @notice function to add a fee destination address to the whitelist
     * @dev can only be called by the timelock governance contract
     * @param _toWhitelistAddress address to whitelist
     * @param _setting bool to either whitelist or 'unwhitelist' address
     */
    function addToWhitelist(
        address _toWhitelistAddress,
        bool _setting
    ) external onlyTeam {
        _checkNotNull(_toWhitelistAddress);
        whitelistedDestinations[_toWhitelistAddress] = _setting;
        emit WhitelistEdit(_toWhitelistAddress, _setting);
    }

    /**
     * @notice configuration function for reward interval
     * @dev the configured fee collection interval cannot exceed the MAX_INTERVAL
     * @param _timeInterval uint time interval for fee collection
     */
    function setRewardInterval(uint256 _timeInterval) external onlyTeam {
        require(
            _timeInterval <= MAX_INTERVAL,
            "FeeCollector: invalid interval"
        );
        rewardInterval = _timeInterval;
        emit SetRewardInterval(_timeInterval);
    }

    /**
     * @notice function that configures the collected wager fee distribution
     * @dev the ratios together should equal 1e4 (100%)
     * @param _stakingRatio the ratio of the winr stakers
     * @param _buybackAndBurnRatioWager the ratio of the buyback and burning amounts
     * @param _coreRatio  the ratio of the core dev
     */
    function setWagerDistribution(
        uint64 _stakingRatio,
        uint64 _buybackAndBurnRatioWager,
        uint64 _coreRatio
    ) external onlyGovernance {
        // together all the ratios need to sum to 1e4 (100%)
        require(
            (_stakingRatio + _buybackAndBurnRatioWager + _coreRatio) == 1e4,
            "FeeCollector: Wager Ratios together don't sum to 1e4"
        );
        wagerDistributionConfig = WagerDistributionRatio(
            _stakingRatio,
            _buybackAndBurnRatioWager,
            _coreRatio
        );
        emit WagerDistributionSet(
            _stakingRatio,
            _buybackAndBurnRatioWager,
            _coreRatio
        );
    }

    /**
     * @notice function that configures the collected swap fee distribution
     * @dev the ratios together should equal 1e4 (100%)
     * @param _wlpHoldersRatio the ratio of the totalRewards going to WLP holders
     * @param _stakingRatio the ratio of the totalRewards going to WINR stakers
     * @param _buybackAndBurnRatio  the ratio of the buyBack and burn going to buyback and burn address
     * @param _coreRatio  the ratio of the totalRewars going to core dev
     */
    function setSwapDistribution(
        uint64 _wlpHoldersRatio,
        uint64 _stakingRatio,
        uint64 _buybackAndBurnRatio,
        uint64 _coreRatio
    ) external onlyGovernance {
        // together all the ratios need to sum to 1e4 (100%)
        require(
            (_wlpHoldersRatio +
                _stakingRatio +
                _buybackAndBurnRatio +
                _coreRatio) == 1e4,
            "FeeCollector: Ratios together don't sum to 1e4"
        );
        swapDistributionConfig = SwapDistributionRatio(
            _wlpHoldersRatio,
            _stakingRatio,
            _buybackAndBurnRatio,
            _coreRatio
        );
        emit SwapDistributionSet(
            _wlpHoldersRatio,
            _stakingRatio,
            _buybackAndBurnRatio,
            _coreRatio
        );
    }

    /**
     * Context/Explanation of the feecollectors whitelistList:
     * The Vault collects fees of all actions of whitelisted tokens present in the vault (payins, swaps, deposit, withdraw).
     * The FeeCollector contract should be able to claim these tokens always (since the FeeCollectors role is to distribute these tokens to the recipients).
     * It is possible that tokens are removed from the vaults whitelist by WINR governance - while there are still collected wager/swap fee tokens present on the vault (this would be a one-time sitation). If the tokens are removed from the vaults whitelist, the FeeCollector will be unable to collect these tokens (since it iterates over the whitelisted token array of the Vault).
     *
     * To make sure that tokens are still collectable, we added a set of functions in the FeeCollector that can manually add/remove tokens to the feecollectors whitelist. Managers are able to sync this array with the vault and manually add/remove tokens from it.
     */

    /**
     * @notice function that syncs the whitelisted tokens with the vault
     */
    function syncWhitelistedTokens() external onlySupport {
        delete allWhitelistedTokensFeeCollector;
        uint256 count_ = vault.allWhitelistedTokensLength();
        for (uint256 i = 0; i < count_; ++i) {
            address token_ = vault.allWhitelistedTokens(i);
            allWhitelistedTokensFeeCollector.push(token_);
        }
        emit SyncTokens();
    }

    /**
     * @notice manually adds a tokenaddress to the vault
     * @param _tokenToAdd address to manually add to the llWhitelistedTokensFeeCollector array
     */
    function addTokenToWhitelistList(address _tokenToAdd) external onlyTeam {
        allWhitelistedTokensFeeCollector.push(_tokenToAdd);
        emit TokenAddedToWhitelist(_tokenToAdd);
    }

    /**
     * @notice deletes entire whitelist array
     * @dev this function should be used before syncWhitelistedTokens is called!
     */
    function deleteWhitelistTokenList() external onlyTeam {
        delete allWhitelistedTokensFeeCollector;
        emit DeleteAllWhitelistedTokens();
    }

    /*==================== Operational functions WINR/JB *====================*/

    /**
     * @notice manually sync last distribution time so they are in line again
     */
    function syncLastDistribution() external onlySupport {
        lastDistributionTimes = DistributionTimes(
            block.timestamp,
            block.timestamp,
            block.timestamp,
            block.timestamp,
            block.timestamp
        );
        emit DistributionSync();
    }

    /*==================== Public callable operational functions *====================*/

    /**
     * @notice returns accumulated/pending rewards for distribution addresses
     */
    function getReserves() external view returns (Reserve memory reserves_) {
        reserves_ = reserves;
    }

    /**
     * @notice returns the swap fee distribution ratios
     */
    function getSwapDistribution()
        external
        view
        returns (SwapDistributionRatio memory swapDistributionConfig_)
    {
        swapDistributionConfig_ = swapDistributionConfig;
    }

    /**
     * @notice returns the wager fee distribution ratios
     */
    function getWagerDistribution()
        external
        view
        returns (WagerDistributionRatio memory wagerDistributionConfig_)
    {
        wagerDistributionConfig_ = wagerDistributionConfig;
    }

    /**
     * @notice returns the distribution addresses (recipients of wager and swap fees) per destination
     */
    function getAddresses()
        external
        view
        returns (DistributionAddresses memory addresses_)
    {
        addresses_ = addresses;
    }

    /**
     * @notice function that checks if a given address is whitelisted
     * @dev outgoing transfers of any type can only happen if a destination address is whitelisted (safetly measure)
     * @param _address address to check if it is whitelisted
     */
    function isWhitelistedDestination(
        address _address
    ) external view returns (bool whitelisted_) {
        whitelisted_ = whitelistedDestinations[_address];
    }

    /**
     * @notice function that claims/farms the wager+swap fees in vault, and distributes it to wlp holders, stakers and core dev
     * @dev function can only be called once per interval period
     */
    function withdrawFeesAll() external onlySupport {
        _withdrawAllFees();
        emit FeesDistributed();
    }

    /**
     * @notice manaul transfer tokens from the feecollector to a whitelisted destination address
     * @dev our of safety concerns it is only possilbe to do a manual transfer to a address/wallet that is whitelisted by the governance contract/address
     * @param _targetToken address of the token to manually distriuted
     * @param _amount amount of the _targetToken
     * @param _destination destination address that will receive the token
     */
    function manualDistributionTo(
        address _targetToken,
        uint256 _amount,
        address _destination
    ) external onlySupport {
        /**
         * context: even though the manager role will be a trusted signer, we do not want that that it is possible for this role to steal funds. Therefor the manager role can only manually transfer funds to a wallet that is whitelisted. On this whitelist only multi-sigs and governance controlled treasury wallets should be added.
         */
        require(
            whitelistedDestinations[_destination],
            "FeeCollector: Destination not whitelisted"
        );
        SafeERC20.safeTransfer(IERC20(_targetToken), _destination, _amount);
        emit ManualDistributionManager(_targetToken, _amount, _destination);
    }

    /*==================== View functions *====================*/

    /**
     * @notice calculates what is a percentage portion of a certain input
     * @param _amountToDistribute amount to charge the fee over
     * @param _basisPointsPercentage basis point percentage scaled 1e4
     * @return amount_ amount to distribute
     */
    function calculateDistribution(
        uint256 _amountToDistribute,
        uint64 _basisPointsPercentage
    ) public pure returns (uint256 amount_) {
        amount_ = ((_amountToDistribute * _basisPointsPercentage) /
            BASIS_POINTS_DIVISOR);
    }

    /*==================== Emergency intervention functions *====================*/

    /**
     * @notice governance function to rescue or correct any tokens that end up in this contract by accident
     * @dev this is a timelocked function! Only the timelock contract can call this function
     * @param _tokenAddress address of the token to be transferred out
     * @param _amount amount of the token to be transferred out
     * @param _recipient address of the receiver of the token
     */
    function removeTokenByGoverance(
        address _tokenAddress,
        uint256 _amount,
        address _recipient
    ) external onlyTimelockGovernance {
        SafeERC20.safeTransfer(
            IERC20(_tokenAddress),
            timelockAddressImmutable,
            _amount
        );
        emit TokenTransferredByTimelock(_tokenAddress, _recipient, _amount);
    }

    /**
     * @notice emergency function that transfers all the tokens in this contact to the timelock contract.
     * @dev this function should be called when there is an exploit or a key of one of the manager is exposed
     */
    function emergencyDistributionToTimelock() external onlyTeam {
        address[] memory wlTokens_ = allWhitelistedTokensFeeCollector;
        // iterate over all te tokens that now sit in this contract
        for (uint256 i = 0; i < wlTokens_.length; ++i) {
            address token_ = wlTokens_[i];
            uint256 bal_ = IERC20(wlTokens_[i]).balanceOf(address(this));
            if (bal_ == 0) {
                // no balance to swipe, so proceed to next interations
                continue;
            }
            SafeERC20.safeTransfer(
                IERC20(token_),
                timelockAddressImmutable,
                bal_
            );
            emit EmergencyWithdraw(
                msg.sender,
                token_,
                bal_,
                address(timelockAddressImmutable)
            );
        }
    }

    /**
     * @notice function distributes all the accumulated/realized fees to the different destinations
     * @dev this function does not collect fees! only distributes fees that are already in the feecollector contract
     */
    function distributeAll() external onlySupport {
        transferBuyBackAndBurn();
        transferWinrStaking();
        transferWlpRewards();
        transferCore();
        transferReferral();
    }

    /**
     * @notice function that transfers the accumulated fees to the configured buyback contract
     */
    function transferBuyBackAndBurn() public onlySupport {
        // collected fees can only be distributed once every rewardIntervval
        if (!_checkLastTime(lastDistributionTimes.buybackAndBurn)) {
            // we return early, since the last time the winr staking was called was less than the reward interval
            return;
        }
        lastDistributionTimes.buybackAndBurn = block.timestamp;
        uint256 amount_ = reserves.buybackAndBurn;
        reserves.buybackAndBurn = 0;
        if (amount_ == 0) {
            return;
        }
        wlp.transfer(addresses.buybackAndBurn, amount_);
        emit TransferBuybackAndBurnTokens(addresses.buybackAndBurn, amount_);
    }

    /**
     * @notice function that transfers the accumulated fees to the configured core/dev contract destination
     */
    function transferCore() public onlySupport {
        // collected fees can only be distributed once every rewardIntervval
        if (!_checkLastTime(lastDistributionTimes.core)) {
            // we return early, since the last time the winr staking was called was less than the reward interval
            return;
        }
        lastDistributionTimes.core = block.timestamp;
        uint256 amount_ = reserves.core;
        reserves.core = 0;
        if (amount_ == 0) {
            return;
        }
        wlp.transfer(addresses.core, amount_);
        emit TransferCoreTokens(addresses.core, amount_);
    }

    /**
     * @notice function that transfers the accumulated fees to the configured wlp contract destination
     */
    function transferWlpRewards() public onlySupport {
        // collected fees can only be distributed once every rewardIntervval
        if (!_checkLastTime(lastDistributionTimes.wlpClaim)) {
            // we return early, since the last time the winr staking was called was less than the reward interval
            return;
        }
        lastDistributionTimes.wlpClaim = block.timestamp;
        _transferWlpRewards();
    }

    /**
     * @param _token address of the token fees will be withdrawn for
     */
    function manualWithdrawFeesFromVault(address _token) external onlyTeam {
        IVault vault_ = vault;
        (
            uint256 swapReserve_,
            uint256 wagerReserve_,
            uint256 referralReserve_
        ) = vault_.withdrawAllFees(_token);
        emit ManualFeeWithdraw(
            _token,
            swapReserve_,
            wagerReserve_,
            referralReserve_
        );
    }

    function collectFeesBeforeLPEvent() external {
        require(
            msg.sender == address(wlpManager),
            "Only WLP Manager can call this function"
        );
        // withdraw fees from the vault and register/distribute the fees to according to the distribution ot all destinations
        _withdrawAllFees();
        // transfer the wlp rewards to the wlp claim contract
        _transferWlpRewards();
        // note we do not the other tokens of the partition
    }

    /**
     * @notice configure if it is preferred the FC fails tx's when collecfions are collected within time interval
     */
    function setFailOnTime(bool _setting) external onlyGovernance {
        failOnTime = _setting;
    }

    /**
     * @notice internal function that transfers the accumulated wlp fees to the wlp token contract and realizes the fees
     */
    function _transferWlpRewards() internal {
        uint256 amount_ = reserves.wlpHolders;
        reserves.wlpHolders = 0;
        if (amount_ == 0) {
            return;
        }
        // transfer the wlp rewards to the wlp token contract
        wlp.transfer(addresses.wlpClaim, amount_);
        // call the update funds received function so that the transferred wlp tokens will be attributed to liquid wlp holders
        IBasicFDT(addresses.wlpClaim).updateFundsReceived_WLP();
        // for good measure we also call the vwinr rewards distribution (so that the wlp claim contract can also attribute the vwinr rewards)
        IBasicFDT(addresses.wlpClaim).updateFundsReceived_VWINR();
        // Since the wlp distributor calls the function no need to do anything
        emit TransferWLPRewardTokens(addresses.wlpClaim, amount_);
    }

    /**
     * @notice transfer the winr staking reward to the desination vwinr staking contract for claiming
     * @notice the destination address is the Token Manager contract
     * @notice checks if the total weight is 0, if so, does not transfer
     */
    function transferWinrStaking() public onlySupport {
        // collected fees can only be distributed once every rewardIntervval
        if (!_checkLastTime(lastDistributionTimes.winrStaking)) {
            // we return early, since the last time the winr staking was called was less than the reward interval
            return;
        }
        lastDistributionTimes.winrStaking = block.timestamp;

        uint256 amount_ = reserves.staking;
        reserves.staking = 0;
        if (amount_ == 0) {
            return;
        }
        if (winrStaking.totalWeight() == 0) {
            return;
        }
        wlp.transfer(addresses.winrStaking, amount_);
        // call winrStaking.share with amount
        ITokenManager(addresses.winrStaking).share(amount_);
        emit TransferWinrStakingTokens(addresses.winrStaking, amount_);
    }

    /**
     * @notice transfer the referral reward to the desination referral contract for distribution and cliaming
     */
    function transferReferral() public onlySupport {
        // collected fees can only be distributed once every rewardIntervval
        if (!_checkLastTime(lastDistributionTimes.referral)) {
            // we return early, since the last time the referral was called was less than the reward interval
            return;
        }
        lastDistributionTimes.referral = block.timestamp;
        // all the swap and wager fees from the vault now sit in this contract
        address[] memory wlTokens_ = allWhitelistedTokensFeeCollector;
        // iterate over all te tokens that now sit in this contract
        for (uint256 i = 0; i < wlTokens_.length; ++i) {
            address token_ = wlTokens_[i];
            uint256 amount_ = referralReserve[token_];
            referralReserve[token_] = 0;
            if (amount_ != 0) {
                IERC20(token_).transfer(addresses.referral, amount_);
                emit TransferReferralTokens(
                    token_,
                    addresses.referral,
                    amount_
                );
            }
        }
    }

    /**
     * @notice function to be used when for some reason the balances are incorrect, need to be corrected manually
     * @dev the function is timelocked via a gov timelock so is extremely hard to abuse at short notice
     */
    function setReserveByTimelockGov(
        uint256 _wlpHolders,
        uint256 _staking,
        uint256 _buybackAndBurn,
        uint256 _core
    ) external onlyTimelockGovernance {
        reserves = Reserve(_wlpHolders, _staking, _buybackAndBurn, _core);
    }

    /*==================== Internal functions *====================*/

    /**
     * @notice internal function taht
     */
    function _withdrawAllFees() internal {
        // all the swap and wager fees from the vault now sit in this contract
        address[] memory wlTokens_ = allWhitelistedTokensFeeCollector;
        // iterate over all te tokens that now sit in this contract
        for (uint256 i = 0; i < wlTokens_.length; ++i) {
            _withdraw(wlTokens_[i]);
        }
    }

    function _checkLastTime(uint256 _lastTime) internal view returns (bool) {
        // if true, it means a distribution can be done, since the current time is greater than the last time + the reward interval
        bool outsideInterval_ = _lastTime + rewardInterval <= block.timestamp;
        if (failOnTime) {
            require(
                outsideInterval_,
                "Fees can only be transferred once per rewardInterval"
            );
        }
        return outsideInterval_;
    }

    /**
     * @notice internal withdraw function
     * @param _token address of the token to be distributed
     */
    function _withdraw(address _token) internal {
        IVault vault_ = vault;
        (
            uint256 swapReserve_,
            uint256 wagerReserve_,
            uint256 referralReserve_
        ) = vault_.withdrawAllFees(_token);
        if (swapReserve_ != 0) {
            uint256 swapWlpAmount_ = _addLiquidity(_token, swapReserve_);
            // distribute the farmed swap fees to the addresses tat
            _setAmountsForSwap(swapWlpAmount_);
        }
        if (wagerReserve_ != 0) {
            uint256 wagerWlpAmount_ = _addLiquidity(_token, wagerReserve_);
            _setAmountsForWager(wagerWlpAmount_);
        }
        if (referralReserve_ != 0) {
            referralReserve[_token] = referralReserve_;
        }
    }

    /**
     * @notice internal function that deposits tokens and returns amount of wlp
     * @param _token token address of amount which wants to deposit
     * @param _amount amount of the token collected (FeeCollector contract)
     * @return wlpAmount_ amount of the token minted to this by depositing
     */
    function _addLiquidity(
        address _token,
        uint256 _amount
    ) internal returns (uint256 wlpAmount_) {
        IERC20(_token).approve(address(wlpManager), _amount);
        wlpAmount_ = wlpManager.addLiquidityFeeCollector(_token, _amount, 0, 0);
        return wlpAmount_;
    }

    /**
     * @notice internal function that calculates how much of each asset accumulated in the contract need to be distributed to the configured contracts and set
     * @param _amount amount of the token collected by swap in this (FeeCollector contract)
     */
    function _setAmountsForSwap(uint256 _amount) internal {
        reserves.wlpHolders += calculateDistribution(
            _amount,
            swapDistributionConfig.wlpHolders
        );
        reserves.staking += calculateDistribution(
            _amount,
            swapDistributionConfig.staking
        );
        reserves.buybackAndBurn += calculateDistribution(
            _amount,
            swapDistributionConfig.buybackAndBurn
        );
        reserves.core += calculateDistribution(
            _amount,
            swapDistributionConfig.core
        );
    }

    /**
     * @notice internal function that calculates how much of each asset accumulated in the contract need to be distributed to the configured contracts and set
     * @param _amount amount of the token collected by wager in this (FeeCollector contract)
     */
    function _setAmountsForWager(uint256 _amount) internal {
        uint256 forStaking = calculateDistribution(
            _amount,
            wagerDistributionConfig.staking
        );
        reserves.staking += forStaking;
        uint256 forBuybackAndBurn = calculateDistribution(
            _amount,
            wagerDistributionConfig.buybackAndBurn
        );
        reserves.buybackAndBurn += forBuybackAndBurn;
        reserves.core += _amount - forStaking - forBuybackAndBurn;
    }

    /**
     * @notice internal function that checks if an address is not 0x0
     */
    function _checkNotNull(address _setAddress) internal pure {
        require(_setAddress != address(0x0), "FeeCollector: Null not allowed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IFeeCollector {
	struct SwapDistributionRatio {
		uint64 wlpHolders;
		uint64 staking;
		uint64 buybackAndBurn;
		uint64 core;
	}

	struct WagerDistributionRatio {
		uint64 staking;
		uint64 buybackAndBurn;
		uint64 core;
	}

	struct Reserve {
		uint256 wlpHolders;
		uint256 staking;
		uint256 buybackAndBurn;
		uint256 core;
	}

	// *** Destination addresses for the farmed fees from the vault *** //
	// note: the 4 addresses below need to be able to receive ERC20 tokens
	struct DistributionAddresses {
		// the destination address for the collected fees attributed to WLP holders
		address wlpClaim;
		// the destination address for the collected fees attributed  to WINR stakers
		address winrStaking;
		// address of the contract that does the 'buyback and burn'
		address buybackAndBurn;
		// the destination address for the collected fees attributed to core development
		address core;
		// address of the contract/EOA that will distribute the referral fees
		address referral;
	}

	struct DistributionTimes {
		uint256 wlpClaim;
		uint256 winrStaking;
		uint256 buybackAndBurn;
		uint256 core;
		uint256 referral;
	}

	function getReserves() external returns (Reserve memory);

	function getSwapDistribution() external returns (SwapDistributionRatio memory);

	function getWagerDistribution() external returns (WagerDistributionRatio memory);

	function getAddresses() external returns (DistributionAddresses memory);

	function calculateDistribution(
		uint256 _amountToDistribute,
		uint64 _ratio
	) external pure returns (uint256 amount_);

	function withdrawFeesAll() external;

	function isWhitelistedDestination(address _address) external returns (bool);

	function syncWhitelistedTokens() external;

	function addToWhitelist(address _toWhitelistAddress, bool _setting) external;

	function setReferralDistributor(address _distributorAddress) external;

	function setCoreDevelopment(address _coreDevelopment) external;

	function setWinrStakingContract(address _winrStakingContract) external;

	function setBuyBackAndBurnContract(address _buybackAndBurnContract) external;

	function setWlpClaimContract(address _wlpClaimContract) external;

	function setWagerDistribution(
		uint64 _stakingRatio,
		uint64 _burnRatio,
		uint64 _coreRatio
	) external;

	function setSwapDistribution(
		uint64 _wlpHoldersRatio,
		uint64 _stakingRatio,
		uint64 _buybackRatio,
		uint64 _coreRatio
	) external;

	function addTokenToWhitelistList(address _tokenToAdd) external;

	function deleteWhitelistTokenList() external;

	function collectFeesBeforeLPEvent() external;

	/*==================== Events *====================*/
	event DistributionSync();
	event WithdrawSync();
	event WhitelistEdit(address whitelistAddress, bool setting);
	event EmergencyWithdraw(address caller, address token, uint256 amount, address destination);
	event ManualGovernanceDistro();
	event FeesDistributed();
	event WagerFeesManuallyFarmed(address tokenAddress, uint256 amountFarmed);
	event ManualDistributionManager(
		address targetToken,
		uint256 amountToken,
		address destinationAddress
	);
	event SetRewardInterval(uint256 timeInterval);
	event SetCoreDestination(address newDestination);
	event SetBuybackAndBurnDestination(address newDestination);
	event SetClaimDestination(address newDestination);
	event SetReferralDestination(address referralDestination);
	event SetStakingDestination(address newDestination);
	event SwapFeesManuallyFarmed(address tokenAddress, uint256 totalAmountCollected);
	event CollectedWagerFees(address tokenAddress, uint256 amountCollected);
	event CollectedSwapFees(address tokenAddress, uint256 amountCollected);
	event NothingToDistribute(address token);
	event DistributionComplete(
		address token,
		uint256 toWLP,
		uint256 toStakers,
		uint256 toBuyBack,
		uint256 toCore,
		uint256 toReferral
	);
	event WagerDistributionSet(uint64 stakingRatio, uint64 burnRatio, uint64 coreRatio);
	event SwapDistributionSet(
		uint64 _wlpHoldersRatio,
		uint64 _stakingRatio,
		uint64 _buybackRatio,
		uint64 _coreRatio
	);
	event SyncTokens();
	event DeleteAllWhitelistedTokens();
	event TokenAddedToWhitelist(address addedTokenAddress);
	event TokenTransferredByTimelock(address token, address recipient, uint256 amount);

	event ManualFeeWithdraw(
		address token,
		uint256 swapFeesCollected,
		uint256 wagerFeesCollected,
		uint256 referralFeesCollected
	);

	event TransferBuybackAndBurnTokens(address receiver, uint256 amount);
	event TransferCoreTokens(address receiver, uint256 amount);
	event TransferWLPRewardTokens(address receiver, uint256 amount);
	event TransferWinrStakingTokens(address receiver, uint256 amount);
	event TransferReferralTokens(address token, address receiver, uint256 amount);
	event VaultUpdated(address vault);
	event WLPManagerUpdated(address wlpManager);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITokenManager {
    function takeVestedWINR(address _from, uint256 _amount) external;

    function takeWINR(address _from, uint256 _amount) external;

    function sendVestedWINR(address _to, uint256 _amount) external;

    function sendWINR(address _to, uint256 _amount) external;

    function burnVestedWINR(uint256 _amount) external;

    function burnWINR(uint256 _amount) external;

    function mintWINR(address _to, uint256 _amount) external;

    function sendWLP(address _to, uint256 _amount) external;

    function mintOrTransferByPool(address _to, uint256 _amount) external;

    function mintVestedWINR(
        address _input,
        uint256 _amount,
        address _recipient
    ) external returns (uint256 _mintAmount);

    function mintedByGames() external returns (uint256);

    function MAX_MINT() external returns (uint256);

    function share(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./IVaultUtils.sol";

interface IVault {
	/*==================== Events *====================*/
	event BuyUSDW(
		address account,
		address token,
		uint256 tokenAmount,
		uint256 usdwAmount,
		uint256 feeBasisPoints
	);
	event SellUSDW(
		address account,
		address token,
		uint256 usdwAmount,
		uint256 tokenAmount,
		uint256 feeBasisPoints
	);
	event Swap(
		address account,
		address tokenIn,
		address tokenOut,
		uint256 amountIn,
		uint256 indexed amountOut,
		uint256 indexed amountOutAfterFees,
		uint256 indexed feeBasisPoints
	);
	event DirectPoolDeposit(address token, uint256 amount);
	error TokenBufferViolation(address tokenAddress);
	error PriceZero();

	event PayinWLP(
		// address of the token sent into the vault
		address tokenInAddress,
		// amount payed in (was in escrow)
		uint256 amountPayin
	);

	event PlayerPayout(
		// address the player receiving the tokens (do we need this? i guess it does not matter to who we send tokens for profit/loss calculations?)
		address recipient,
		// address of the token paid to the player
		address tokenOut,
		// net amount sent to the player (this is NOT the net loss, since it includes the payed in tokens, excludes wagerFee and swapFee!)
		uint256 amountPayoutTotal
	);

	event AmountOutNull();

	event WithdrawAllFees(
		address tokenCollected,
		uint256 swapFeesCollected,
		uint256 wagerFeesCollected,
		uint256 referralFeesCollected
	);

	event RebalancingWithdraw(address tokenWithdrawn, uint256 amountWithdrawn);

	event RebalancingDeposit(address tokenDeposit, uint256 amountDeposit);

	event WagerFeeChanged(uint256 newWagerFee);

	event ReferralDistributionReverted(uint256 registeredTooMuch, uint256 maxVaueAllowed);

	/*==================== Operational Functions *====================*/
	function setPayoutHalted(bool _setting) external;

	function isSwapEnabled() external view returns (bool);

	function setVaultUtils(IVaultUtils _vaultUtils) external;

	function setError(uint256 _errorCode, string calldata _error) external;

	function usdw() external view returns (address);

	function feeCollector() external returns (address);

	function hasDynamicFees() external view returns (bool);

	function totalTokenWeights() external view returns (uint256);

	function getTargetUsdwAmount(address _token) external view returns (uint256);

	function inManagerMode() external view returns (bool);

	function isManager(address _account) external view returns (bool);

	function tokenBalances(address _token) external view returns (uint256);

	function setInManagerMode(bool _inManagerMode) external;

	function setManager(address _manager, bool _isManager, bool _isWLPManager) external;

	function setIsSwapEnabled(bool _isSwapEnabled) external;

	function setUsdwAmount(address _token, uint256 _amount) external;

	function setBufferAmount(address _token, uint256 _amount) external;

	function setFees(
		uint256 _taxBasisPoints,
		uint256 _stableTaxBasisPoints,
		uint256 _mintBurnFeeBasisPoints,
		uint256 _swapFeeBasisPoints,
		uint256 _stableSwapFeeBasisPoints,
		uint256 _minimumBurnMintFee,
		bool _hasDynamicFees
	) external;

	function setTokenConfig(
		address _token,
		uint256 _tokenDecimals,
		uint256 _redemptionBps,
		uint256 _maxUsdwAmount,
		bool _isStable
	) external;

	function setPriceFeedRouter(address _priceFeed) external;

	function withdrawAllFees(address _token) external returns (uint256, uint256, uint256);

	function directPoolDeposit(address _token) external;

	function deposit(address _tokenIn, address _receiver, bool _swapLess) external returns (uint256);

	function withdraw(address _tokenOut, address _receiverTokenOut) external returns (uint256);

	function swap(
		address _tokenIn,
		address _tokenOut,
		address _receiver
	) external returns (uint256);

	function tokenToUsdMin(
		address _tokenToPrice,
		uint256 _tokenAmount
	) external view returns (uint256);

	function priceOracleRouter() external view returns (address);

	function taxBasisPoints() external view returns (uint256);

	function stableTaxBasisPoints() external view returns (uint256);

	function mintBurnFeeBasisPoints() external view returns (uint256);

	function swapFeeBasisPoints() external view returns (uint256);

	function stableSwapFeeBasisPoints() external view returns (uint256);

	function minimumBurnMintFee() external view returns (uint256);

	function allWhitelistedTokensLength() external view returns (uint256);

	function allWhitelistedTokens(uint256) external view returns (address);

	function stableTokens(address _token) external view returns (bool);

	function swapFeeReserves(address _token) external view returns (uint256);

	function tokenDecimals(address _token) external view returns (uint256);

	function tokenWeights(address _token) external view returns (uint256);

	function poolAmounts(address _token) external view returns (uint256);

	function bufferAmounts(address _token) external view returns (uint256);

	function usdwAmounts(address _token) external view returns (uint256);

	function maxUsdwAmounts(address _token) external view returns (uint256);

	function getRedemptionAmount(
		address _token,
		uint256 _usdwAmount
	) external view returns (uint256);

	function getMaxPrice(address _token) external view returns (uint256);

	function getMinPrice(address _token) external view returns (uint256);

	function setVaultManagerAddress(address _vaultManagerAddress, bool _setting) external;

	function wagerFeeBasisPoints() external view returns (uint256);

	function setWagerFee(uint256 _wagerFee) external;

	function wagerFeeReserves(address _token) external view returns (uint256);

	function referralReserves(address _token) external view returns (uint256);

	function getReserve() external view returns (uint256);

	function getWlpValue() external view returns (uint256);

	function usdToTokenMin(address _token, uint256 _usdAmount) external view returns (uint256);

	function usdToTokenMax(address _token, uint256 _usdAmount) external view returns (uint256);

	function usdToToken(
		address _token,
		uint256 _usdAmount,
		uint256 _price
	) external view returns (uint256);

	function returnTotalOutAndIn(
		address token_
	) external view returns (uint256 totalOutAllTime_, uint256 totalInAllTime_);

	function payout(
		address _wagerToken,
		address _escrowAddress,
		uint256 _escrowAmount,
		address _recipient,
		uint256 _totalAmount
	) external;

	function payoutNoEscrow(
		address _wagerAsset,
		address _recipient,
		uint256 _totalAmount
	) external;

	function payin(
		address _inputToken, 
		address _escrowAddress,
		uint256 _escrowAmount) external;

	function setAsideReferral(address _token, uint256 _amount) external;

	function payinWagerFee(
		address _tokenIn
	) external;

	function payinSwapFee(
		address _tokenIn
	) external;

	function payinPoolProfits(
		address _tokenIn
	) external;

	function removeAsideReferral(address _token, uint256 _amountRemoveAside) external;

	function setFeeCollector(address _feeCollector) external;

	function upgradeVault(
		address _newVault,
		address _token,
		uint256 _amount,
		bool _upgrade
	) external;

	function setCircuitBreakerAmount(address _token, uint256 _amount) external;

	function clearTokenConfig(address _token) external;

	function updateTokenBalance(address _token) external;

	function setCircuitBreakerEnabled(bool _setting) external;

	function setPoolBalance(address _token, uint256 _amount) external;
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

pragma solidity >=0.6.0 <0.9.0;

interface IVaultUtils {
	function getBuyUsdwFeeBasisPoints(
		address _token,
		uint256 _usdwAmount
	) external view returns (uint256);

	function getSellUsdwFeeBasisPoints(
		address _token,
		uint256 _usdwAmount
	) external view returns (uint256);

	function getSwapFeeBasisPoints(
		address _tokenIn,
		address _tokenOut,
		uint256 _usdwAmount
	) external view returns (uint256);

	function getFeeBasisPoints(
		address _token,
		uint256 _usdwDelta,
		uint256 _feeBasisPoints,
		uint256 _taxBasisPoints,
		bool _increment
	) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./IVault.sol";

interface IWLPManager {
    function wlp() external view returns (address);

    function usdw() external view returns (address);

    function vault() external view returns (IVault);

    function cooldownDuration() external returns (uint256);

    function getAumInUsdw(bool maximise) external view returns (uint256);

    function lastAddedAt(address _account) external returns (uint256);

    function addLiquidity(
        address _token,
        uint256 _amount,
        uint256 _minUsdw,
        uint256 _minWlp
    ) external returns (uint256);

    function addLiquidityForAccount(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount,
        uint256 _minUsdw,
        uint256 _minWlp
    ) external returns (uint256);

    function removeLiquidity(
        address _tokenOut,
        uint256 _wlpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function removeLiquidityForAccount(
        address _account,
        address _tokenOut,
        uint256 _wlpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function setCooldownDuration(uint256 _cooldownDuration) external;

    function getAum(bool _maximise) external view returns (uint256);

    function getPriceWlp(bool _maximise) external view returns (uint256);

    function getPriceWLPInUsdw(bool _maximise) external view returns (uint256);

    function circuitBreakerTrigger(address _token) external;

    function aumDeduction() external view returns (uint256);

    function reserveDeduction() external view returns (uint256);

    function maxPercentageOfWagerFee() external view returns (uint256);

    function addLiquidityFeeCollector(
        address _token,
        uint256 _amount,
        uint256 _minUsdw,
        uint256 _minWlp
    ) external returns (uint256 wlpAmount_);

    /*==================== Events *====================*/
    event AddLiquidity(
        address account,
        address token,
        uint256 amount,
        uint256 aumInUsdw,
        uint256 wlpSupply,
        uint256 usdwAmount,
        uint256 mintAmount
    );

    event RemoveLiquidity(
        address account,
        address token,
        uint256 wlpAmount,
        uint256 aumInUsdw,
        uint256 wlpSupply,
        uint256 usdwAmount,
        uint256 amountOut
    );

    event PrivateModeSet(bool inPrivateMode);

    event HandlerEnabling(bool setting);

    event HandlerSet(address handlerAddress, bool isActive);

    event CoolDownDurationSet(uint256 cooldownDuration);

    event AumAdjustmentSet(uint256 aumAddition, uint256 aumDeduction);

    event MaxPercentageOfWagerFeeSet(uint256 maxPercentageOfWagerFee);

    event CircuitBreakerTriggered(
        address forToken,
        bool pausePayoutsOnCB,
        bool pauseSwapOnCB,
        uint256 reserveDeductionOnCB
    );

    event CircuitBreakerPolicy(
        bool pausePayoutsOnCB,
        bool pauseSwapOnCB,
        uint256 reserveDeductionOnCB
    );

    event CircuitBreakerReset(
        bool pausePayoutsOnCB,
        bool pauseSwapOnCB,
        uint256 reserveDeductionOnCB
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWINRStaking {
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
        uint256 accTokenFirstDay; // The accumulated  WINR tokens earned on the first day of the stake
        uint256 accTokenPerDay; // The rate at which WINR tokens are accumulated per day
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
        uint256 winr;
        uint256 vWinr;
        uint256 vWinrVesting;
    }

    /*==================================================== Events =============================================================*/

    event Donation(address indexed player, uint amount);
    event Share(
        uint256 amount,
        uint256 totalWeight,
        uint256 totalStakedVWINR,
        uint256 totalStakedWINR
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

interface IBaseFDT {
	/**
        @dev    Returns the total amount of funds a given address is able to withdraw currently.
        @param  owner Address of FDT holder.
        @return A uint256 representing the available funds for a given account.
    */
	function withdrawableFundsOf_WLP(address owner) external view returns (uint256);

	function withdrawableFundsOf_VWINR(address owner) external view returns (uint256);

	/**
        @dev Withdraws all available funds for a FDT holder.
    */
	function withdrawFunds_WLP() external;

	function withdrawFunds_VWINR() external;

	function withdrawFunds() external;

	/**
        @dev   This event emits when new funds are distributed.
        @param by               The address of the sender that distributed funds.
        @param fundsDistributed_WLP The amount of funds received for distribution.
    */
	event FundsDistributed_WLP(address indexed by, uint256 fundsDistributed_WLP);

	event FundsDistributed_VWINR(address indexed by, uint256 fundsDistributed_VWINR);

	/**
        @dev   This event emits when distributed funds are withdrawn by a token holder.
        @param by             The address of the receiver of funds.
        @param fundsWithdrawn_WLP The amount of funds that were withdrawn.
        @param totalWithdrawn_WLP The total amount of funds that were withdrawn.
    */
	event FundsWithdrawn_WLP(
		address indexed by,
		uint256 fundsWithdrawn_WLP,
		uint256 totalWithdrawn_WLP
	);

	event FundsWithdrawn_VWINR(
		address indexed by,
		uint256 fundsWithdrawn_VWINR,
		uint256 totalWithdrawn_VWINR
	);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBaseFDT.sol";

interface IBasicFDT is IBaseFDT, IERC20 {
	event PointsPerShareUpdated_WLP(uint256);

	event PointsCorrectionUpdated_WLP(address indexed, int256);

	event PointsPerShareUpdated_VWINR(uint256);

	event PointsCorrectionUpdated_VWINR(address indexed, int256);

	function withdrawnFundsOf_WLP(address) external view returns (uint256);

	function accumulativeFundsOf_WLP(address) external view returns (uint256);

	function withdrawnFundsOf_VWINR(address) external view returns (uint256);

	function accumulativeFundsOf_VWINR(address) external view returns (uint256);

	function updateFundsReceived_WLP() external;

	function updateFundsReceived_VWINR() external;
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