// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITypeAndVersion} from "../../shared/interfaces/ITypeAndVersion.sol";
import {IAutomationRegistryConsumer} from "./IAutomationRegistryConsumer.sol";

interface IAutomationForwarder is ITypeAndVersion {
  function forward(uint256 gasAmount, bytes memory data) external returns (bool success, uint256 gasUsed);

  function updateRegistry(address newRegistry) external;

  function getRegistry() external view returns (IAutomationRegistryConsumer);

  function getTarget() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice IAutomationRegistryConsumer defines the LTS user-facing interface that we intend to maintain for
 * across upgrades. As long as users use functions from within this interface, their upkeeps will retain
 * backwards compatability across migrations.
 * @dev Functions can be added to this interface, but not removed.
 */
interface IAutomationRegistryConsumer {
  function getBalance(uint256 id) external view returns (uint96 balance);

  function getMinBalance(uint256 id) external view returns (uint96 minBalance);

  function cancelUpkeep(uint256 id) external;

  function pauseUpkeep(uint256 id) external;

  function unpauseUpkeep(uint256 id) external;

  function addFunds(uint256 id, uint96 amount) external;

  function withdrawFunds(uint256 id, address to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../UpkeepFormat.sol";

interface MigratableKeeperRegistryInterfaceV2 {
  /**
   * @notice Migrates upkeeps from one registry to another, including LINK and upkeep params.
   * Only callable by the upkeep admin. All upkeeps must have the same admin. Can only migrate active upkeeps.
   * @param upkeepIDs ids of upkeeps to migrate
   * @param destination the address of the registry to migrate to
   */
  function migrateUpkeeps(uint256[] calldata upkeepIDs, address destination) external;

  /**
   * @notice Called by other registries when migrating upkeeps. Only callable by other registries.
   * @param encodedUpkeeps abi encoding of upkeeps to import - decoded by the transcoder
   */
  function receiveUpkeeps(bytes calldata encodedUpkeeps) external;

  /**
   * @notice Specifies the version of upkeep data that this registry requires in order to import
   */
  function upkeepVersion() external view returns (uint8 version);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev this struct is only maintained for backwards compatibility with MigratableKeeperRegistryInterface
 * it should be deprecated in the future in favor of MigratableKeeperRegistryInterfaceV2
 */
enum UpkeepFormat {
  V1,
  V2,
  V3
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITypeAndVersion {
  function typeAndVersion() external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);

  function transferFrom(address from, address to, uint256 value) external returns (bool success);
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
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IAutomationRegistryConsumer} from
    "@chainlink/contracts/src/v0.8/automation/interfaces/IAutomationRegistryConsumer.sol";
import {AutomationCompatibleInterface} from
    "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {IAutomationForwarder} from "@chainlink/contracts/src/v0.8/automation/interfaces/IAutomationForwarder.sol";
import {MigratableKeeperRegistryInterfaceV2} from
    "@chainlink/contracts/src/v0.8/automation/interfaces/MigratableKeeperRegistryInterfaceV2.sol";
import {Governable} from "flashliquidity-acs/contracts/Governable.sol";
import {IAutomationStation} from "./interfaces/IAutomationStation.sol";

/**
 * @title AutomationStation
 * @author Oddcod3 (@oddcod3)
 * @notice This contract is used for managing upkeeps in the Chainlink Automation Network.
 */
contract AutomationStation is IAutomationStation, AutomationCompatibleInterface, Governable {
    using SafeERC20 for IERC20;

    error AutomationStation__AlreadyInitialized();
    error AutomationStation__NoRegisteredUpkeep();
    error AutomationStation__InconsistentParamsLength();
    error AutomationStation__RefuelNotNeeded();
    error AutomationStation__CannotDismantle();
    error AutomationStation__UpkeepRegistrationFailed();
    error AutomationStation__TooEarlyForNextRefuel();
    error AutomationStation__NotFromForwarder();

    /// @dev Reference to the LinkTokenInterface, used for LINK token interactions.
    LinkTokenInterface public immutable i_linkToken;
    /// @dev Refueling configuration for upkeeps.
    RefuelConfig private s_refuelConfig;
    /// @dev Automation forwarder for the station upkeep.
    IAutomationForwarder private s_forwarder;
    /// @dev Automation registrar address
    address private s_registrar;
    /// @dev Function selector of the registrar registerUpkeep function.
    bytes4 private s_registerUpkeepSelector;
    /// @dev An array of upkeep IDs managed by this station, allowing tracking and management of multiple upkeeps.
    uint256[] private s_upkeepIDs;
    /// @dev Unique identifier for this station's upkeep registered in the Chainlink Automation Network.
    uint256 private s_stationUpkeepID;
    /// @dev Mapping from upkeep ID to last refuel timestamp.
    mapping(uint256 upkeepID => uint256 lastRefuelTimestamp) private s_lastRefuelTimestamp;

    event UpkeepRegistered(uint256 upkeepID);
    event UpkeepUnregistered(uint256 upkeepID);
    event UpkeepsAdded(uint256[] upkeepIDs);
    event UpkeepRemoved(uint256 upkeepID);
    event UpkeepsMigrated(address indexed oldRegistry, address indexed newRegistry, uint256[] upkeepIDs);
    event StationDismantled(uint256 stationUpkeepID);
    event RegistrarChanged(address newRegistrar);
    event ForwarderChanged(address newForwarder);

    constructor(
        address governor,
        address linkToken,
        address registrar,
        bytes4 registerUpkeepSelector,
        uint96 refuelAmount,
        uint96 stationUpkeepMinBalance,
        uint32 minDelayNextRefuel
    ) Governable(governor) {
        i_linkToken = LinkTokenInterface(linkToken);
        s_registerUpkeepSelector = registerUpkeepSelector;
        s_registrar = registrar;
        s_refuelConfig = RefuelConfig({
            refuelAmount: refuelAmount,
            stationUpkeepMinBalance: stationUpkeepMinBalance,
            minDelayNextRefuel: minDelayNextRefuel
        });
    }

    /// @inheritdoc IAutomationStation
    function initialize(uint256 approveAmountLINK, bytes calldata registrationParams) external onlyGovernor {
        if (s_stationUpkeepID > 0) revert AutomationStation__AlreadyInitialized();
        s_stationUpkeepID = _registerUpkeep(approveAmountLINK, registrationParams);
    }

    /// @inheritdoc IAutomationStation
    function dismantle() external onlyGovernor {
        uint256 stationUpkeepID = s_stationUpkeepID;
        if (stationUpkeepID == 0 || s_upkeepIDs.length > 0) revert AutomationStation__CannotDismantle();
        s_stationUpkeepID = 0;
        _getStationUpkeepRegistry().cancelUpkeep(stationUpkeepID);
        emit StationDismantled(stationUpkeepID);
    }

    /// @inheritdoc IAutomationStation
    function setForwarder(address forwarder) external onlyGovernor {
        s_forwarder = IAutomationForwarder(forwarder);
        emit ForwarderChanged(forwarder);
    }

    /// @inheritdoc IAutomationStation
    function setRegistrar(address registrar) external onlyGovernor {
        s_registrar = registrar;
        emit RegistrarChanged(registrar);
    }

    /// @inheritdoc IAutomationStation
    function setRegisterUpkeepSelector(bytes4 registerUpkeepSelector) external onlyGovernor {
        s_registerUpkeepSelector = registerUpkeepSelector;
    }

    /// @inheritdoc IAutomationStation
    function setRefuelConfig(uint96 refuelAmount, uint96 stationUpkeepMinBalance, uint32 minDelayNextReful)
        external
        onlyGovernor
    {
        s_refuelConfig = RefuelConfig({
            refuelAmount: refuelAmount,
            stationUpkeepMinBalance: stationUpkeepMinBalance,
            minDelayNextRefuel: minDelayNextReful
        });
    }

    /// @inheritdoc IAutomationStation
    function recoverERC20(address to, address[] memory tokens, uint256[] memory amounts) external onlyGovernor {
        uint256 tokensLen = tokens.length;
        if (tokensLen != amounts.length) revert AutomationStation__InconsistentParamsLength();
        for (uint256 i; i < tokensLen;) {
            IERC20(tokens[i]).safeTransfer(to, amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IAutomationStation
    function forceStationRefuel(uint96 refuelAmount) external onlyGovernor {
        _getStationUpkeepRegistry().addFunds(s_stationUpkeepID, refuelAmount);
    }

    /// @inheritdoc IAutomationStation
    function forceUpkeepRefuel(uint256 upkeepIndex, uint96 refuelAmount) external onlyGovernor {
        _getStationUpkeepRegistry().addFunds(s_upkeepIDs[upkeepIndex], refuelAmount);
    }

    /// @inheritdoc IAutomationStation
    function registerUpkeep(uint256 approveAmountLINK, bytes calldata registrationParams) external onlyGovernor {
        uint256 upkeepID = _registerUpkeep(approveAmountLINK, registrationParams);
        if (upkeepID > 0) {
            s_upkeepIDs.push(upkeepID);
            emit UpkeepRegistered(upkeepID);
        }
    }

    /// @inheritdoc IAutomationStation
    function unregisterUpkeep(uint256 upkeepIndex) external onlyGovernor {
        uint256 upkeepID = _removeUpkeep(upkeepIndex);
        _getStationUpkeepRegistry().cancelUpkeep(upkeepID);
        emit UpkeepUnregistered(upkeepID);
    }

    /// @inheritdoc IAutomationStation
    function addUpkeeps(uint256[] calldata upkeepIDs) external onlyGovernor {
        uint256 upkeepsLen = upkeepIDs.length;
        uint256 upkeepID;
        for (uint256 i; i < upkeepsLen;) {
            upkeepID = upkeepIDs[i];
            s_upkeepIDs.push(upkeepID);
            unchecked {
                ++i;
            }
        }
        emit UpkeepsAdded(upkeepIDs);
    }

    function removeUpkeep(uint256 upkeepIndex) external onlyGovernor {
        uint256 upkeepID = _removeUpkeep(upkeepIndex);
        emit UpkeepRemoved(upkeepID);
    }

    /// @inheritdoc IAutomationStation
    function pauseUpkeeps(uint256[] calldata upkeepIDs) external onlyGovernor {
        uint256 upkeepsLen = upkeepIDs.length;
        IAutomationRegistryConsumer registry = _getStationUpkeepRegistry();
        for (uint256 i; i < upkeepsLen;) {
            registry.pauseUpkeep(upkeepIDs[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IAutomationStation
    function unpauseUpkeeps(uint256[] calldata upkeepIDs) external onlyGovernor {
        uint256 upkeepsLen = upkeepIDs.length;
        IAutomationRegistryConsumer registry = _getStationUpkeepRegistry();
        for (uint256 i; i < upkeepsLen;) {
            registry.unpauseUpkeep(upkeepIDs[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IAutomationStation
    function withdrawUpkeeps(uint256[] calldata upkeepIDs) external {
        uint256 upkeepsLen = upkeepIDs.length;
        IAutomationRegistryConsumer registry = _getStationUpkeepRegistry();
        for (uint256 i; i < upkeepsLen;) {
            registry.withdrawFunds(upkeepIDs[i], address(this));
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IAutomationStation
    function migrateUpkeeps(address oldRegistry, address newRegistry, uint256[] calldata upkeepIDs)
        external
        onlyGovernor
    {
        MigratableKeeperRegistryInterfaceV2(oldRegistry).migrateUpkeeps(upkeepIDs, newRegistry);
        emit UpkeepsMigrated(oldRegistry, newRegistry, upkeepIDs);
    }

    /// @inheritdoc AutomationCompatibleInterface
    function performUpkeep(bytes calldata performData) external {
        IAutomationForwarder forwarder = s_forwarder;
        if (msg.sender != address(forwarder)) revert AutomationStation__NotFromForwarder();
        IAutomationRegistryConsumer registry = _getStationUpkeepRegistry();
        uint256 upkeepIndex = abi.decode(performData, (uint256));
        uint256 stationUpkeepID = s_stationUpkeepID;
        uint256 upkeepID;
        uint256 minBalance;
        RefuelConfig memory config = s_refuelConfig;
        if (upkeepIndex == type(uint256).max) {
            upkeepID = s_stationUpkeepID;
            minBalance = config.stationUpkeepMinBalance;
        } else {
            upkeepID = s_upkeepIDs[upkeepIndex];
            minBalance = registry.getMinBalance(upkeepID);
        }
        if (registry.getBalance(upkeepID) > minBalance) revert AutomationStation__RefuelNotNeeded();
        if (block.timestamp - s_lastRefuelTimestamp[upkeepID] < config.minDelayNextRefuel) {
            revert AutomationStation__TooEarlyForNextRefuel();
        }
        if (stationUpkeepID != upkeepID) s_lastRefuelTimestamp[upkeepID] = block.timestamp;
        i_linkToken.approve(address(registry), config.refuelAmount);
        registry.addFunds(upkeepID, config.refuelAmount);
    }

    /**
     * @dev Internal function to register a new upkeep.
     * @param approveAmountLINK Amount of LINK tokens approved to the registrar.
     * @param registrationParams Encoded registration params.
     * @return upkeepID The ID assigned to the newly registered upkeep.
     * @notice This function reverts with `AutomationStation__UpkeepRegistrationFailed` if the registration returns a zero ID.
     */
    function _registerUpkeep(uint256 approveAmountLINK, bytes calldata registrationParams)
        internal
        returns (uint256 upkeepID)
    {
        address registrar = s_registrar;
        i_linkToken.approve(registrar, approveAmountLINK);
        (bool success, bytes memory returnData) =
            registrar.call(bytes.concat(s_registerUpkeepSelector, registrationParams));
        if (!success) revert AutomationStation__UpkeepRegistrationFailed();
        return abi.decode(returnData, (uint256));
    }

    function _removeUpkeep(uint256 upkeepIndex) internal returns (uint256) {
        uint256 upkeepsLen = s_upkeepIDs.length;
        if (upkeepsLen == 0) revert AutomationStation__NoRegisteredUpkeep();
        uint256 upkeepID = s_upkeepIDs[upkeepIndex];
        if (upkeepIndex < upkeepsLen - 1) {
            s_upkeepIDs[upkeepIndex] = s_upkeepIDs[upkeepsLen - 1];
        }
        s_upkeepIDs.pop();
        return upkeepID;
    }

    function _getStationUpkeepRegistry() internal view returns (IAutomationRegistryConsumer registry) {
        return s_forwarder.getRegistry();
    }

    /// @inheritdoc AutomationCompatibleInterface
    function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory performData) {
        uint256 upkeepsLen = s_upkeepIDs.length;
        uint256 upkeepID;
        IAutomationRegistryConsumer registry = _getStationUpkeepRegistry();
        if (registry.getBalance(s_stationUpkeepID) <= s_refuelConfig.stationUpkeepMinBalance) {
            return (true, abi.encode(type(uint256).max));
        }
        for (uint256 i; i < upkeepsLen;) {
            upkeepID = s_upkeepIDs[i];
            if (registry.getBalance(upkeepID) <= registry.getMinBalance(upkeepID)) {
                return (true, abi.encode(i));
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IAutomationStation
    function getStationUpkeepRegistry() external view returns (address) {
        return address(_getStationUpkeepRegistry());
    }

    /// @inheritdoc IAutomationStation
    function getStationUpkeepID() external view returns (uint256) {
        return s_stationUpkeepID;
    }

    /// @inheritdoc IAutomationStation
    function getForwarder() external view returns (address) {
        return address(s_forwarder);
    }

    /// @inheritdoc IAutomationStation
    function getRegistrar() external view returns (address) {
        return s_registrar;
    }

    /// @inheritdoc IAutomationStation
    function getRegisterUpkeepSelector() external view returns (bytes4) {
        return s_registerUpkeepSelector;
    }

    /// @inheritdoc IAutomationStation
    function getUpkeepIdAtIndex(uint256 upkeepIndex) external view returns (uint256) {
        return s_upkeepIDs[upkeepIndex];
    }

    /// @inheritdoc IAutomationStation
    function allUpkeepsLength() external view returns (uint256) {
        return s_upkeepIDs.length;
    }

    /// @inheritdoc IAutomationStation
    function getRefuelConfig() external view returns (RefuelConfig memory) {
        return s_refuelConfig;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAutomationStation {
    /// @notice Represents the configuration settings for refueling upkeeps in the Automation Station.
    /// @dev This struct holds settings that determine the behavior of the refueling process for upkeeps.
    struct RefuelConfig {
        uint96 refuelAmount; // The amount of LINK tokens to refuel an upkeep.
        uint96 stationUpkeepMinBalance; // The minimum balance threshold for the station's upkeep.
        uint32 minDelayNextRefuel; // The minimum delay time (in seconds) required between successive refuels. (station upkeep excluded)
    }

    /**
     * @dev Initializes the station.
     * @param approveAmountLINK Amount of LINK tokens approved to the registrar, must be equal or greater of the amount encoded in the registrationParams.
     * @param registrationParams Encoded registration params.
     */
    function initialize(uint256 approveAmountLINK, bytes calldata registrationParams) external;

    /// @dev Dismantles the station by canceling the station upkeep.
    function dismantle() external;

    /// @param forwarder The new Automation forwarder address.
    function setForwarder(address forwarder) external;

    /// @param registrar The new Automation registrar address.
    function setRegistrar(address registrar) external;

    /// @param registerUpkeepSelector The new registerUpkeep function selector of the Automation registrar.
    function setRegisterUpkeepSelector(bytes4 registerUpkeepSelector) external;

    /**
     * @notice Updates the configuration settings for refueling upkeeps in the Automation Station.
     * @dev Sets the new refueling configuration for the station. This includes the amount of tokens for refueling,
     *      the minimum balance threshold for upkeeps, and the minimum delay between refuels.
     * @param refuelAmount The amount of tokens (e.g., LINK) to be used for each refuel operation.
     * @param stationUpkeepMinBalance The minimum balance of the station upkeep.
     * @param minDelayNextReful The minimum time interval (in seconds) required between consecutive refuel operations.
     */
    function setRefuelConfig(uint96 refuelAmount, uint96 stationUpkeepMinBalance, uint32 minDelayNextReful) external;

    /**
     * @dev Recovers ERC20 tokens sent to the contract.
     * @param to Address to send the recovered tokens.
     * @param tokens Array of token addresses.
     * @param amounts Array of amounts of tokens to recover.
     */
    function recoverERC20(address to, address[] memory tokens, uint256[] memory amounts) external;

    /**
     * @dev Forces the refuel of the station upkeep with the specified amount.
     * @param refuelAmount The amount of LINK tokens to refuel.
     */
    function forceStationRefuel(uint96 refuelAmount) external;

    /**
     * @dev Forces the refuel of a registered upkeep with the specified amount.
     * @param upkeepIndex The index in the s_upkeepIDs array of the upkeep to refuel
     * @param refuelAmount The amount of LINK tokens to refuel.
     */
    function forceUpkeepRefuel(uint256 upkeepIndex, uint96 refuelAmount) external;

    /**
     * @dev Register a new upkeep, add its upkeepID to the s_upkeepIDs array of the station if max auto-approval has not been hit.
     * @param approveAmountLINK Amount of LINK tokens approved to the registrar, must be equal or greater of the amount encoded in the registrationParams.
     * @param registrationParams Encoded registration params.
     */
    function registerUpkeep(uint256 approveAmountLINK, bytes calldata registrationParams) external;

    /**
     * @dev Removes an upkeep from the station by its index and calls cancelUpkeep in the Chainlink Automation Registry.
     * @param upkeepIndex The index of the upkeep in the station's array.
     */
    function unregisterUpkeep(uint256 upkeepIndex) external;

    /**
     * @dev Add multiple upkeep to the s_upkeepIDs array of the station.
     * @param upkeepIDs Array of upkeep IDs to be added.
     */
    function addUpkeeps(uint256[] calldata upkeepIDs) external;

    /**
     * Remove an upkeep from the s_upkeepIDs array of the station.
     * @param upkeepIndex The index of the upkeep in the station's array to be removed.
     */
    function removeUpkeep(uint256 upkeepIndex) external;

    /**
     * @dev Pauses a set of upkeeps identified by their IDs.
     * @param upkeepIDs An array of `uint256` IDs of the upkeeps to be paused.
     */
    function pauseUpkeeps(uint256[] calldata upkeepIDs) external;

    /**
     * @dev Unpauses a set of upkeeps identified by their IDs.
     * @param upkeepIDs An array of `uint256` IDs of the upkeeps to be unpaused.
     */
    function unpauseUpkeeps(uint256[] calldata upkeepIDs) external;

    /**
     * @dev Withdraws LINK tokens from canceled upkeeps.
     * @param upkeepIDs Array of upkeep IDs to withdraw funds from.
     */
    function withdrawUpkeeps(uint256[] calldata upkeepIDs) external;

    /**
     * @notice Migrate a batch of upkeeps from an old registry to a new one.
     * @param oldRegistry The address of the current registry holding the upkeeps.
     * @param newRegistry The address of the new registry to which the upkeeps will be transferred.
     * @param upkeepIDs An array of `uint256` IDs representing the upkeeps to be migrated.
     */
    function migrateUpkeeps(address oldRegistry, address newRegistry, uint256[] calldata upkeepIDs) external;

    /// @return stationUpkeepRegistry The address of the station upkeep registry.
    function getStationUpkeepRegistry() external view returns (address stationUpkeepRegistry);

    /// @return stationUpkeepID The station upkeep.
    function getStationUpkeepID() external view returns (uint256 stationUpkeepID);

    /// @return forwarder The automation forwarder address.
    function getForwarder() external view returns (address forwarder);

    /// @return registrar The automation registrar address.
    function getRegistrar() external view returns (address);

    /// @return registerUpkeepSelector The function selector for registerUpkeep function of the registrar.
    function getRegisterUpkeepSelector() external view returns (bytes4 registerUpkeepSelector);

    /**
     * @param upkeepIndex The index in the array of upkeeps.
     * @return upkeepId The ID of the upkeep at the specified index.
     */
    function getUpkeepIdAtIndex(uint256 upkeepIndex) external view returns (uint256);

    /// @return upkeepsLength The total number of upkeeps registered in this station.
    function allUpkeepsLength() external view returns (uint256 upkeepsLength);

    /**
     * @notice Retrieves the current refueling configuration settings for the Automation Station.
     * @return refuelConfig RefuelConfig struct.
     */
    function getRefuelConfig() external view returns (RefuelConfig memory refuelConfig);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IGovernable} from "./interfaces/IGovernable.sol";

/**
 * @title Governable
 * @notice A 2-step governable contract with a delay between setting the pending governor and transferring governance.
 */
contract Governable is IGovernable {
    error Governable__ZeroAddress();
    error Governable__NotAuthorized();
    error Governable__TooEarly(uint64 timestampReady);

    address private s_governor;
    address private s_pendingGovernor;
    uint64 private s_govTransferReqTimestamp;
    uint32 public constant TRANSFER_GOVERNANCE_DELAY = 3 days;

    event GovernanceTrasferred(address indexed oldGovernor, address indexed newGovernor);
    event PendingGovernorChanged(address indexed pendingGovernor);

    modifier onlyGovernor() {
        _revertIfNotGovernor();
        _;
    }

    constructor(address governor) {
        s_governor = governor;
        emit GovernanceTrasferred(address(0), governor);
    }

    /// @inheritdoc IGovernable
    function setPendingGovernor(address pendingGovernor) external onlyGovernor {
        if (pendingGovernor == address(0)) revert Governable__ZeroAddress();
        s_pendingGovernor = pendingGovernor;
        s_govTransferReqTimestamp = uint64(block.timestamp);
        emit PendingGovernorChanged(pendingGovernor);
    }

    /// @inheritdoc IGovernable
    function transferGovernance() external {
        address newGovernor = s_pendingGovernor;
        address oldGovernor = s_governor;
        uint64 govTransferReqTimestamp = s_govTransferReqTimestamp;
        if (msg.sender != oldGovernor && msg.sender != newGovernor) revert Governable__NotAuthorized();
        if (newGovernor == address(0)) revert Governable__ZeroAddress();
        if (block.timestamp - govTransferReqTimestamp < TRANSFER_GOVERNANCE_DELAY) {
            revert Governable__TooEarly(govTransferReqTimestamp + TRANSFER_GOVERNANCE_DELAY);
        }
        s_pendingGovernor = address(0);
        s_governor = newGovernor;
        emit GovernanceTrasferred(oldGovernor, newGovernor);
    }

    function _revertIfNotGovernor() internal view {
        if (msg.sender != s_governor) revert Governable__NotAuthorized();
    }

    function _getGovernor() internal view returns (address) {
        return s_governor;
    }

    function _getPendingGovernor() internal view returns (address) {
        return s_pendingGovernor;
    }

    function _getGovTransferReqTimestamp() internal view returns (uint64) {
        return s_govTransferReqTimestamp;
    }

    function getGovernor() external view returns (address) {
        return _getGovernor();
    }

    function getPendingGovernor() external view returns (address) {
        return _getPendingGovernor();
    }

    function getGovTransferReqTimestamp() external view returns (uint64) {
        return _getGovTransferReqTimestamp();
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGovernable {
    /**
     * @param pendingGovernor The new pending governor address.
     * @notice A call to transfer governance is required to promote the new pending governor to the governor role.
     */
    function setPendingGovernor(address pendingGovernor) external;

    /// @notice Promote the pending governor to the governor role.
    function transferGovernance() external;

    function getGovernor() external view returns (address);

    function getPendingGovernor() external view returns (address);

    function getGovTransferReqTimestamp() external view returns (uint64);
}