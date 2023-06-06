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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
pragma solidity ^0.8.9;

interface AggregatorV3Interface {
    /**
     * Returns the decimals to offset on the getLatestPrice call
     */
    function decimals() external view returns (uint8);

    /**
     * Returns the description of the underlying price feed aggregator
     */
    function description() external view returns (string memory);

    /**
     * Returns the version number representing the type of aggregator the proxy points to
     */
    function version() external view returns (uint256);

    /**
     * Returns price data about a specific round
     */
    function getRoundData(uint80 _roundId) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    /**
     * Returns price data from the latest round
     */
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.9;

interface IDIAOracleV2 {
  function getValue(string memory key) external view returns(uint128,uint128);
}

//SPDX-License-Identifier: NONE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../libraries/Types.sol";

interface IMarket {

  /// @notice Emitted when placing a bet
  event PlaceBet(
                 address indexed account,
                 uint indexed ticketId,
                 uint8 indexed option,
                 uint estimatedOdds,
                 uint size
                 );

  /// @notice Emitted when updating base odds (in decimal format, scaled by 1e8)
  event UpdateBaseOdds(uint oddsA, uint oddsB);
  
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

  /// @notice Emitted when `_maxExposure` is updated
  event SetMaxExposure(uint maxExposure);

  
  /** ACCESS CONTROLLED FUNCTIONS **/

  /// @notice Updates the base odds (in decimal format) for this market
  /// @param oddsA New odds of option A, in decimal format, scaled by 1e8
  /// @param oddsB New odds of option B, in decimal format, scaled by 1e8
  function _updateBaseOdds(uint oddsA, uint oddsB) external;
  
  /// @notice Called by `ToroAdmin` when announcing a result for the `Market`.
  /// The `Market` can either have a distinct winning `Option`, or it can be a
  /// tie. In the case of a result, the `Market` should contain exactly enough
  /// balance to pay out all the results. In the case of a tie, the `Market`
  /// should contain exactly enough balance to refund the total size of all
  /// bets. All remaining balance can be sent back to `ToroPool`.
  /// @param result_ Enum of the winning option
  /// @param label_ Double check option by providing its label string
  function _resolveMarket(uint8 result_, string memory label_) external;

  /// @notice Called by `ToroAdmin` to set the max `exposure` allowed in this
  /// `Market` before bets get rejected. The purpose of `_maxExposure` is to
  /// limit the maximum amount of one-sided risk a `Market` can take on.
  /// @param maxExposure_ New max exposure
  function _setMaxExposure(uint maxExposure_) external;

  
  /** USER INTERFACE **/


  /// @notice Called by user when placing a bet. The option enum indicates
  /// which side the user wants to bet, and the size is pre-commission fee.
  /// Commission fees are charged at the time of placing a bet, and whatever
  /// is remaining is the actual size placed for the wager. Hence, the
  /// `Ticket` that user receives when placing a bet will be for a slightly
  /// smaller amount than `size`.
  /// The `Market` must also manage all the currency balances when a bet is
  /// placed. Importantly, the `Market` should contain exactly as much as the
  /// `maxPayout` of any single option at all times. Everything else should be
  /// sent back to `ToroPool` to maintain as much capital efficiency as possible.
  /// @param option The side which user picks to win
  /// @param size Pre-commission fee size which user wishes to bet
  function placeBet(uint8 option, uint size) external;

  /// @notice Called by user when claiming a `Ticket`. Since the `Market` always
  /// must keep the `maxPayout` balance at all times (before `Market` close) or
  /// the payout of the winning `option` (after `Market` close), the contract
  /// should always have enough to pay every winning `Ticket` without requesting
  /// for fund transfers from `ToroPool`. This function must check the validity of
  /// the `Ticket`, and if it passes all checks, releases the funds to the
  /// winning account
  /// @param ticketId ID of the `Ticket`
  function claimTicket(uint ticketId) external;


  /** VIEW FUNCTIONS **/

  function toroAdmin() external view returns(address);
  
  function toroPool() external view returns(address);
  
  /// @notice Gets the current state of the `Market`. The states are:
  /// OPEN: Still open for taking new bets
  /// PENDING: No new bets allowed, but no winner/tie declared yet
  /// CLOSED: Result declared, still available for redemptions
  /// EXPIRED: Redemption window expired, `Market` eligible to be deleted
  /// @return uint8 Current state
  function state() external view returns(uint8);
  
  function result() external view returns(uint8);

  function sportId() external view returns(uint);

  function optionA() external view returns(Types.Option memory);

  function optionB() external view returns(Types.Option memory);
  
  function label() external view returns(string memory);
  
  function deadline() external view returns(uint);
  
  function currency() external view returns(IERC20);

  function totalSize() external view returns(uint);

  function totalPayout() external view returns(uint);

  function maxPayout() external view returns(uint);

  function minPayout() external view returns(uint);

  function minLockedBalance() external view returns(uint);
  
  function maxExposure() external view returns(uint);
  
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPriceOracle {

  /// @notice Emitted when setting DIA oracle
  event SetDIAOracle(address DIAOracleAddr);

  /// @notice Emitted when setting oracle feeds
  event SetOracleFeed(address token, address oracleFeed);

  /** ADMIN/RESTRICTED FUNCTIONS **/
  
  function _setDIAOracle(address DIAOracleAddr) external;

  function _setOracleFeed(IERC20 token, address oracleFeed) external;
  
  /** VIEW FUNCTIONS **/

  /// @notice Converts any local value into its value in USD using oracle feed price
  /// @param token ERC20 token
  /// @param amountLocal Amount denominated in terms of the ERC20 token
  /// @return uint Amount in USD (18 digit precision)
  function localToUSD(IERC20 token, uint amountLocal) external view returns(uint);

  /// @notice Converts any value in USD into its value in local using oracle feed price
  /// @param token ERC20 token
  /// @param valueUSD Amount in USD (18 digit precision)
  /// @return uint Amount denominated in terms of the ERC20 token
  function USDToLocal(IERC20 token, uint valueUSD) external view returns(uint);

  /// @notice Convenience function for getting price feed from various oracles.
  /// Returned prices should ALWAYS be normalized to eight decimal places.
  /// @param token Address of the underlying token
  /// @return answer uint256, decimals uint8
  function priceFeed(IERC20 token) external view returns(uint256, uint8);
  
  /// @notice Get the address of the `ToroAdmin` contract
  /// @return address Address of `ToroAdmin` contract
  function toroAdmin() external view returns(address);

}

//SPDX-License-Identifier: NONE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IToroPool.sol";
import "./IMarket.sol";

interface IToroAdmin is IAccessControlUpgradeable {

  /// @notice Emitted when setting `_toroDB`
  event SetToroDB(address toroDBAddr);

  /// @notice Emitted when setting `_priceOracle`
  event SetPriceOracle(address priceOracleAddr);
  
  /// @notice Emitted when setting `_feeEmissionsController`
  event SetFeeEmissionsController(address feeEmissionsControllerAddr);

  /// @notice Emitted when setting `_affiliateERC721`
  event SetAffiliateERC721(address affiliateERC721Addr);

  /// @notice Emitted when setting `_affiliateMintFee`
  event SetAffiliateMintFee(uint affiliateMintFee);

  /// @notice Emitted when adding a new `Market`
  event AddMarket(address indexed currency, uint indexed sportId, string label, address marketAddr);

  /// @notice Emitted when deleting a `Market`
  event DeleteMarket(address indexed currency, uint indexed sportId, string label, address marketAddr);
  
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
  event SetMarketExpiryDeadline(uint marketExpiryDeadline_);

  /// @notice Emitted when setting the LP cooldown
  event SetCooldownLP(uint redeemLPCooldown_);

  /// @notice Emitted when setting the LP window
  event SetWindowLP(uint windowLP_);
  
  /** ACCESS CONTROLLED FUNCTIONS **/

  /// @notice Called upon initialization after deploying `ToroDB` contract
  /// @param toroDBAddr Address of `ToroDB` deployment
  function _setToroDB(address toroDBAddr) external;

  /// @notice Called upon initialization after deploying `PriceOracle` contract
  /// @param priceOracleAddr Address of `PriceOracle` deployment
  function _setPriceOracle(address priceOracleAddr) external;
  
  /// @notice Called upon initialization after deploying `FeeEmissionsController` contract
  /// @param feeEmissionsControllerAddr Address of `FeeEmissionsController` deployment
  function _setFeeEmissionsController(address feeEmissionsControllerAddr) external;

  /// @notice Called up initialization after deploying `AffiliateERC721` contract
  /// @param affiliateERC721Addr Address of `AffiliateERC721` deployment
  function _setAffiliateERC721(address affiliateERC721Addr) external;

  /// @notice Adds a new `ToroPool` currency contract for new `Market`s to be
  /// listed under.
  /// @param toroPool_ New `ToroPool` currency contract
  function _addToroPool(IToroPool toroPool_) external;

  /// @notice Adds a new `Market`. `Market`s can only be added if there is a
  /// matching `ToroPool` contract that supports the `Market` currency
  /// @param marketAddr Address of the `Market`
  function _addMarket(address marketAddr) external;

  /// @notice Sets the max exposure for a particular `Market`
  /// @param marketAddr Address of the target `Market`
  /// @param maxExposure_ New max exposure, in local currency
  function _setMaxExposure(address marketAddr, uint maxExposure_) external;

  /// @notice Updates the base odds for an array of `Market`s. This function
  /// accepts an array of bytes32 data, where each bytes32 element is encoded
  /// as follows:
  /// data[0:20] => Market address
  /// data[21:26] => odds of side A, represented as bytes6
  /// data[27:32] => odds of side B, represented as bytes6
  /// When converted to decimal format, the odds should be expressed in decimal
  /// odds format, scaled by 1e8
  /// @param data Array of encoded bytes32 containing market, oddsA, and oddsB
  /// information
  function _updateBaseOdds(bytes32[] calldata data) external;
  
  /// @notice Resolves a `Market` and declares a winner. As a safeguard against
  /// human error, admin must input not only the winning option, but also the
  /// string corresponding to the option. In the case of a tie, the string
  /// can be left empty.
  /// @param market Target `Market` to close
  /// @param result 0 for `Option` 0, 1 for `Option` 1, 2 for tie game
  /// @param optionStr String corresponding to winning option, empty if tie game
  function _resolveMarket(IMarket market, uint8 result, string memory optionStr) external;

  /// @notice Removes a `Market` completely from being associated with the
  /// `ToroPool` token completely. This should only done after a minimum period
  /// of time after the `Market` has closed, or else users won't be able to
  /// redeem from it.
  /// @param marketAddr Address of target `Market` to be deleted
  function _deleteMarket(address marketAddr) external;

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
  /// @param marketExpiryDeadline_ New `Market` expiry deadline (in seconds)
  function _setMarketExpiryDeadline(uint marketExpiryDeadline_) external;

  /// @notice Set the global cooldown timer for LP actions
  /// @param cooldownLP_ New cooldown time (in seconds)
  function _setCooldownLP(uint cooldownLP_) external;

  /// @notice Set the global window for LP actions
  /// @param windowLP_ New window time (in seconds)
  function _setWindowLP(uint windowLP_) external;

  /** VIEW FUNCTIONS **/

  function affiliateERC721() external view returns(address);

  function toroDB() external view returns(address);
  
  function priceOracle() external view returns(address);
  
  function feeEmissionsController() external view returns(address);

  function toroPool(IERC20 currency) external view returns(IToroPool);

  function markets(IERC20 currency, uint sportId) external view returns(address[] memory);

  function affiliateMintFee() external view returns(uint);

  function bookmakingFeeBps() external view returns(uint);
  
  function commissionFeeBps() external view returns(uint);

  function affiliateBonusBps() external view returns(uint);

  function referentDiscountBps() external view returns(uint);

  function marketExpiryDeadline() external view returns(uint);

  function cooldownLP() external view returns(uint);

  function windowLP() external view returns(uint);
  
  function ADMIN_ROLE() external view returns(bytes32);
  
  function MARKET_ROLE() external view returns(bytes32);
  
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
  
}

//SPDX-License-Identifier: NONE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IToroPool is IERC20Upgradeable {

  /// @notice Emitted when setting burn request
  event SetLastBurnRequest(address indexed user, uint timestamp);


  /** ACCESS CONTROLLED FUNCTIONS **/


  /// @notice Transfers funds to a `Market` to ensure it can cover the
  /// maximum payout. This is an access-controlled function - only the `Market`
  /// contracts may call this function
  function _transferToMarket(address market, uint amount) external;

  /// @notice Accounting function to increase the amount credited to `ToroPool`
  /// i.e., How much is owed TO `ToroPool` FROM `Market`s
  /// @param amount Amount to increase `_credits`
  function _incrementCredits(uint amount) external;

  /// @notice Accounting function to decrease the amount credited to `ToroPool`
  /// i.e., How much is owed TO `ToroPool` FROM `Market`s
  /// @param amount Amount to decrease `_credits`
  function _decrementCredits(uint amount) external;
  
  /// @notice Accounting function to increase the amount debited to `ToroPool`
  /// i.e., How much is owed FROM `ToroPool` TO `Market`s
  /// @param amount Amount to increase `_debits`
  function _incrementDebits(uint amount) external;

  /// @notice Accounting function to decrease the amount debited to `ToroPool`
  /// i.e., How much is owed FROM `ToroPool` TO `Market`s
  /// @param amount Amount to decrease `_debits`
  function _decrementDebits(uint amount) external;

  
  /** USER INTERFACE **/


  /// @notice Deposit underlying currency and receive LP tokens
  /// NOTE: We need to strip out the amounts locked or amounts transferred by
  /// currently open `Market`s (i.e. their `netDebt`). Hence, to get a fair
  /// picture of the amount of LP tokens due to minters, we need to use the
  /// `netBalance`, which is the sum of the free balance currently inside the
  /// `ToroPool` contract and the `netDebt` of all open `Market`s.
  /// @param amount Amount user wishes to deposit, in underlying token
  function mint(uint amount) external;

  /// @notice Burn LP tokens to receive back underlying currency.
  /// NOTE: We need to strip out the amounts locked or amounts transferred by
  /// currently open `Market`s (i.e. their `netDebt`). Hence, to get a fair
  /// picture of the underlying amount due to LPs, we need to use the
  /// `netBalance`, which is the sum of the free balance currently inside the
  /// `ToroPool` contract and the `netDebt` of all open `Market`s. Because of
  /// this, it is possible that `ToroPool` potentially may not have enough balance
  /// if enough currency is locked inside open `Market`s relative to free
  /// balance in the contract. In that case, LPs will have to wait until the
  /// current `Market`s are closed or for new minters before they can redeem.
  /// We also disable redemptions when the total exposure in pending `Market`s
  /// is too large, as users may be incentivized to withdraw  in the middle of
  /// a pending event with large exposure, using extra knowledge of which
  /// `Option` may be more likely to win
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
  /// account the balance that is currently locked inside open `Market`s
  /// @param amount Amount of underlying tokens
  /// @return uint Amount of LP tokens
  function underlyingToLP(uint amount) external view returns(uint);

  /// @notice Conversion from LP tokens to underlying tokens, taking into
  /// account the balance that is currently locked inside open `Market`s
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
  /// @member currentOdds Latest neutral odds (in decimal format) for this `Option`, scaled by 1e8
  /// @member size Total action currently placed on this `Option`
  /// @member payout Total amount owed to bettors if this `Option` wins
  struct Option {
    string label;
    uint currentOdds;
    uint size;
    uint payout;
  }
  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/chainlink/AggregatorV3Interface.sol";
import "./interfaces/DIA/IDIAOracleV2.sol";
import "./interfaces/IToroAdmin.sol";
import "./interfaces/IPriceOracle.sol";

contract PriceOracle is Initializable, IPriceOracle {

  /// @notice Contract storing all global parameters
  IToroAdmin private _toroAdmin;

  /// @notice Address of DIA Oracle
  IDIAOracleV2 private _DIAOracle;

  /// @notice Mapping of IERC20 tokens to oracle feeds
  mapping(IERC20 => address) private _oracleFeeds;
  
  /// @notice Constructor for upgradeable contracts
  /// @param toroAdminAddress_ Address of the `ToroAdmin` contract
  function initialize(address toroAdminAddress_) public initializer {
    _toroAdmin = IToroAdmin(toroAdminAddress_);
  }

  modifier onlyAdmin() {
    require(_toroAdmin.hasRole(_toroAdmin.ADMIN_ROLE(), msg.sender), "only admin");
    _;
  }

  /** ADMIN/RESTRICTED FUNCTIONS **/
  
  function _setDIAOracle(address DIAOracleAddr) external onlyAdmin() {
    
    // Only allow oracle set once
    require(address(_DIAOracle) == address(0), "already set");
    
    _DIAOracle = IDIAOracleV2(DIAOracleAddr);

    // Emit the event
    emit SetDIAOracle(DIAOracleAddr);
  }

  function _setOracleFeed(IERC20 token, address oracleFeed) external onlyAdmin() {

    _oracleFeeds[token] = oracleFeed;

    // Emit the event
    emit SetOracleFeed(address(token), oracleFeed);
  }

  
  /** VIEW FUNCTIONS **/
  
  /// @notice Converts any local value into its value in USD using oracle feed price
  /// @param token ERC20 token
  /// @param amountLocal Amount denominated in terms of the ERC20 token
  /// @return uint Amount in USD (18 digit precision)
  function localToUSD(IERC20 token, uint amountLocal) external view returns(uint){
    return _localToUSD(token, amountLocal);
  }

  /// @notice Converts any value in USD into its value in local using oracle feed price
  /// @param token ERC20 token
  /// @param valueUSD Amount in USD (18 digit precision)
  /// @return uint Amount denominated in terms of the ERC20 token
  function USDToLocal(IERC20 token, uint valueUSD) external view returns(uint){
    return _USDToLocal(token, valueUSD);
  }

  /// @notice Convenience function for getting price feed from various oracles.
  /// Returned prices should ALWAYS be normalized to eight decimal places.
  /// @param token Address of the underlying token
  /// @return answer uint256, decimals uint8
  function priceFeed(IERC20 token) external view returns(uint256, uint8){
    return _priceFeed(token);
  }
  
  /// @notice Get the address of the `ToroAdmin` contract
  /// @return address Address of `ToroAdmin` contract
  function toroAdmin() external view returns(address){
    return address(_toroAdmin);
  }

  /** INTERNAL FUNCTIONS **/
  
  /// @notice Converts any local value into its value in USD using oracle feed price
  /// @param token ERC20 token
  /// @param amountLocal Amount denominated in terms of the ERC20 token
  /// @return uint Amount in USD (18 decimal place precision)
  function _localToUSD(IERC20 token, uint amountLocal) internal view returns(uint){
    
    // Instantiate the underlying token ERC20 with decimal data
    IERC20Metadata tokenWithMetadata = IERC20Metadata(address(token));
        
    // Get the oracle feed
    address oracleFeed = _oracleFeeds[token];
    require(oracleFeed != address(0), "unsupported token");

    // Get the exchange rates
    (uint exchRate, uint8 exchDecimals) = _priceFeed(token);
    
    // Initialize all the necessary mantissas first
    uint exchRateMantissa = 10 ** exchDecimals;
    uint tokenMantissa = 10 ** tokenWithMetadata.decimals();
    
    // Apply exchange rate to convert from local amount of tokens to value in USD
    uint valueUSD = amountLocal * exchRate * _toroAdmin.MANTISSA_USD();
    
    // Divide by mantissas last for maximum precision
    valueUSD = valueUSD / tokenMantissa / exchRateMantissa;
    
    return valueUSD;
  }

  /// @notice Converts any value in USD into its amount in local using oracle feed price.
  /// For yield-bearing tokens, it will convert the value in USD directly into the
  /// amount of yield-bearing token (NOT the amount of underlying token)
  /// @param token ERC20 token
  /// @param valueUSD Amount in USD (18 digit precision)
  /// @return uint Amount denominated in terms of the ERC20 token
  function _USDToLocal(IERC20 token, uint valueUSD) internal view returns(uint){

    // Instantiate the underlying token ERC20 with decimal data
    IERC20Metadata tokenWithMetadata = IERC20Metadata(address(token));
    
    // Get the oracle feed
    address oracleFeed = _oracleFeeds[token];
    require(oracleFeed != address(0), "unsupported token");

    // Get the exchange rates
    (uint exchRate, uint8 exchDecimals) = _priceFeed(token);

    // Initialize all the necessary mantissas first
    uint exchRateMantissa = 10 ** exchDecimals;
    uint tokenMantissa = 10 ** tokenWithMetadata.decimals();

    // Multiply by mantissas first for maximum precision
    uint amountLocal = valueUSD * tokenMantissa * exchRateMantissa;

    // Apply exchange rate to convert from value in USD to local amount of tokens
    amountLocal = amountLocal / exchRate / _toroAdmin.MANTISSA_USD();
    
    return amountLocal;    
  }

  /// @notice Convenience function for getting price feed from various oracles.
  /// Returned prices should ALWAYS be normalized to eight decimal places.
  /// @param token Address of the underlying token
  /// @return answer uint256, decimals uint8
  function _priceFeed(IERC20 token) internal view returns(uint256, uint8) {

    // Get the oracle feed
    address oracleFeed = _oracleFeeds[token];
    require(oracleFeed != address(0), "unsupported token");
    
    if(oracleFeed == address(_DIAOracle)) {

      return _priceFeedDIA(token);
      
    } else {

      return _priceFeedChainlink(oracleFeed);
      
    }
    
  }

  /// @notice Convenience function for getting price feed from DIA  oracle
  /// @param token Address of the underlying token
  /// @return answer uint256, decimals uint8
  function _priceFeedDIA(IERC20 token) internal view returns(uint256, uint8) {

    // We need to retrieve the `symbol` string from the token, which is not
    // a part of the standard IERC20 interface
    IERC20Metadata tokenWithMetadata = IERC20Metadata(address(token));
      
    // DIA Oracle takes pair string input, e.g. `_DIAOracle.getValue("BTC/USD")`
    string memory key = string(abi.encodePacked(tokenWithMetadata.symbol(), "/USD"));
    
    // Catch and convert exceptions to the proper format
    if(keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("WBTC/USD"))) {
      key = "BTC/USD";
    } else if(keccak256(abi.encodePacked(key)) == keccak256(abi.encodePacked("WETH/USD"))) {
      key = "ETH/USD";
    }
    
    // Get the value from DIA oracle
    (uint128 answer, uint128 timestamp) = _DIAOracle.getValue(key);    
    
    // Ensure valid key is being used
    require(timestamp != 0, "DIA key not found");
    
    // By default, DIA oracles return the current asset price in USD with a
    // fix-comma notation of 8 decimal places.
    return (uint(answer), 8);
    
  }

  /// @notice Convenience function for getting price feed from Chainlink oracle
  /// @param oracleFeed Address of the chainlink oracle feed
  /// @return answer uint256, decimals uint8
  function _priceFeedChainlink(address oracleFeed) internal view returns(uint256, uint8) {
    AggregatorV3Interface aggregator = AggregatorV3Interface(oracleFeed);
    (, int256 answer,,,) =  aggregator.latestRoundData();
    uint8 decimals = aggregator.decimals();
    return (uint(answer), decimals);      
  }
    
}