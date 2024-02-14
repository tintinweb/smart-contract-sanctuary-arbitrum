// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract MulticallUpgradeable is Initializable {
    function __Multicall_init() internal initializer {
        __Multicall_init_unchained();
    }

    function __Multicall_init_unchained() internal initializer {
    }
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = _functionDelegateCall(address(this), data[i]);
        }
        return results;
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
pragma solidity 0.8.9;

/* External Imports */
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import '@openzeppelin/contracts/utils/Address.sol';

/**
 * @title LightBridge
 *
 * Bridge the native asset or whitelisted ERC20 tokens between whitelisted networks (L2's/L1's).
 *
 * @notice The contract itself emits events and locks the funds to be bridged/teleported. These events are then picked up by a backend service that releases the corresponding token or native asset on the destination network. Withdrawal periods (e.g. for optimistic rollups) are not handled by the contract itself, but would be handled on the Teleportation service if deemed necessary.
 * @dev Implementation of the Teleportation service can be found at https://github.com/bobanetwork/boba within /packages/boba/teleportation if not moved.
 */
contract LightBridge is PausableUpgradeable, MulticallUpgradeable {
    using Address for address;
    using SafeERC20 for IERC20;

    /**************
     *   Struct   *
     **************/
    struct Disbursement {
        address token;
        uint256 amount;
        address addr;
        uint32 sourceChainId;
        uint256 depositId;
    }

    struct FailedNativeDisbursement {
        bool failed;
        Disbursement disbursement;
    }

    struct SupportedToken {
        bool supported;
        // The minimum amount that needs to be deposited in a receive.
        uint256 minDepositAmount;
        // The maximum amount that can be deposited in a receive.
        uint256 maxDepositAmount;
        // set maximum amount of tokens that can be transferred in 24 hours
        uint256 maxTransferAmountPerDay;
        // The total amount of tokens transferred in 24 hours
        uint256 transferredAmount;
        // The timestamp of the checkpoint
        uint256 transferTimestampCheckPoint;
    }

    /*************
     * Variables *
     *************/

    /// @dev Wallet that is being used to release teleported assets on the destination network.
    address public disburser;

    /// @dev General owner wallet to change configurations.
    address public owner;

    /// @dev Assets and networks to be supported. ZeroAddress for native asset
    /// {assetAddress} => {targetChainId} => {tokenConfig}
    mapping(address => mapping(uint32 => SupportedToken)) public supportedTokens;

    /// @dev The total number of successful deposits received.
    mapping(uint256 => uint256) public totalDeposits;

    /// @dev The total number of disbursements processed.
    mapping(uint256 => uint256) public totalDisbursements;

    // @dev depositId to failed status and disbursement info
    mapping(uint256 => FailedNativeDisbursement) public failedNativeDisbursements;

    /********************
     *       Events     *
     ********************/

    event MinDepositAmountSet(
    /* @dev Zero Address = native asset **/
        address token,
        uint32 toChainId,
        uint256 previousAmount,
        uint256 newAmount
    );

    event MaxDepositAmountSet(
    /* @dev Zero Address = native asset **/
        address token,
        uint32 toChainId,
        uint256 previousAmount,
        uint256 newAmount
    );

    event MaxTransferAmountPerDaySet(
        address token,
        uint32 toChainId,
        uint256 previousAmount,
        uint256 newAmount
    );

    event AssetBalanceWithdrawn(
        address indexed token,
        address indexed owner,
        uint256 balance
    );

    event AssetReceived(
    /** @dev Must be ZeroAddress for nativeAsset */
        address token,
        uint32 sourceChainId,
        uint32 indexed toChainId,
        uint256 indexed depositId,
        address indexed emitter,
        uint256 amount
    );

    event DisbursementSuccess(
        uint256 indexed depositId,
        address indexed to,
        address indexed token,
        uint256 amount,
        uint32 sourceChainId
    );

    /** @dev only for native assets */
    event DisbursementFailed(
        uint256 indexed depositId,
        address indexed to,
        uint256 amount,
        uint32 sourceChainId
    );

    /** @dev Only for native assets */
    event DisbursementRetrySuccess(
        uint256 indexed depositId,
        address indexed to,
        uint256 amount,
        uint32 sourceChainId
    );

    event DisburserTransferred(
        address newDisburser
    );

    event OwnershipTransferred(
        address newOwner
    );

    event TokenSupported(
        address indexed token,
        uint32 indexed toChainId,
        bool supported
    );

    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyDisburser() {
        require(msg.sender == disburser, 'Caller is not the disburser');
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Caller is not the owner');
        _;
    }

    modifier onlyNotInitialized() {
        require(address(disburser) == address(0), "Contract has been initialized");
        _;
    }

    modifier onlyInitialized() {
        require(address(disburser) != address(0), "Contract has not yet been initialized");
        _;
    }

    /********************
     * Public Functions *
     ********************/

    /// @dev Initialize this contract
    function initialize() external onlyNotInitialized() initializer() {
        disburser = msg.sender;
        owner = msg.sender;

        __Context_init_unchained();
        __Pausable_init_unchained();
        __Multicall_init_unchained();

        emit DisburserTransferred(msg.sender);
        emit OwnershipTransferred(msg.sender);
    }

    /**
    * @dev Add support of a specific ERC20 token on this network.
    *
    * @param _token Token address to support or ZeroAddress for native asset.
    */
    function addSupportedToken(address _token, uint32 _toChainId, uint256 _minDepositAmount, uint256 _maxDepositAmount, uint256 _maxTransferAmountPerDay) public onlyOwner() onlyInitialized() {
        require(supportedTokens[_token][_toChainId].supported == false, "Already supported");
        // Not added ERC165 as implemented for L1 ERC20
        require(address(0) == _token || Address.isContract(_token), "Not contract or native");
        // doesn't ensure it's ERC20

        require(_minDepositAmount > 0 && _minDepositAmount <= _maxDepositAmount, "incorrect min/max deposit");
        // set maximum amount of tokens that can be transferred in 24 hours
        require(_maxDepositAmount <= _maxTransferAmountPerDay, "max deposit amount more than daily limit");

        supportedTokens[_token][_toChainId] = SupportedToken(true, _minDepositAmount, _maxDepositAmount, _maxTransferAmountPerDay, 0, block.timestamp);

        emit TokenSupported(_token, _toChainId, true);
        emit MinDepositAmountSet(_token, _toChainId, 0, _minDepositAmount);
        emit MaxDepositAmountSet(_token, _toChainId, 0, _maxDepositAmount);
        emit MaxTransferAmountPerDaySet(_token, _toChainId, 0, _maxTransferAmountPerDay);
    }

    /**
     * @dev remove the support for a specific token.
     *
     * @param _token The token not to support.
     */
    function removeSupportedToken(address _token, uint32 _toChainId) external onlyOwner() onlyInitialized() {
        require(supportedTokens[_token][_toChainId].supported == true, "Already not supported");
        delete supportedTokens[_token][_toChainId];

        emit TokenSupported(_token, _toChainId, false);
    }

    /**
     * @dev Accepts deposits that will be disbursed to the sender's address on target L2.
     * The method reverts if the amount is less than the current
     * minDepositAmount, the amount is greater than the current
     * maxDepositAmount.
     *
     * @param _token ERC20 address of the token to deposit. Zero-Address indicates native asset.
     * @param _amount The amount of token or native asset to deposit (must be the same as msg.value if native asset)
     * @param _toChainId The destination chain ID.
     */
    function teleportAsset(address _token, uint256 _amount, uint32 _toChainId)
    external
    payable
    whenNotPaused()
    {
        SupportedToken memory supToken = supportedTokens[_token][_toChainId];
        require(supToken.supported == true, "Token or chain not supported");
        require(_amount >= supToken.minDepositAmount, "Deposit amount too small");
        require(_amount <= supToken.maxDepositAmount, "Deposit amount too big");
        // minimal workaround to keep logic concise
        require((address(0) != _token && msg.value == 0) || (address(0) == _token && _amount == msg.value), "Native amount invalid");

        // check if the total amount transferred is smaller than the maximum amount of tokens can be transferred in 24 hours
        // if it's out of 24 hours, reset the transferred amount to 0 and set the transferTimestampCheckPoint to the current time
        if (block.timestamp < supToken.transferTimestampCheckPoint + 1 days) {
            supToken.transferredAmount += _amount;
            require(supToken.transferredAmount <= supToken.maxTransferAmountPerDay, "max amount per day exceeded");
        } else {
            supToken.transferredAmount = _amount;
            require(supToken.transferredAmount <= supToken.maxTransferAmountPerDay, "max amount per day exceeded");
            supToken.transferTimestampCheckPoint = block.timestamp;
        }

        supportedTokens[_token][_toChainId] = supToken;
        totalDeposits[_toChainId] += 1;
        if (_token != address(0)) {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        emit AssetReceived(_token, uint32(block.chainid), _toChainId, totalDeposits[_toChainId] - 1, msg.sender, _amount);
    }

    /**
     * @dev Accepts a list of Disbursements and forwards the amount paid to
     * the contract to each recipient. The method reverts if there are zero
     * disbursements, the total amount to forward differs from the amount sent
     * in the transaction, or the _nextDepositId is unexpected. Failed
     * disbursements will not cause the method to revert, but will instead be
     * held by the contract and availabe for the owner to withdraw.
     *
     * @param _disbursements A list of Disbursements to process.
     */
    function disburseAsset(Disbursement[] calldata _disbursements)
    external
    payable
    onlyDisburser()
    whenNotPaused()
    {
        // Ensure there are disbursements to process.
        uint256 _numDisbursements = _disbursements.length;
        require(_numDisbursements > 0, "No disbursements");

        // Process disbursements.
        uint256 remainingValue = msg.value;
        for (uint256 i = 0; i < _numDisbursements; i++) {

            uint256 _amount = _disbursements[i].amount;
            address _addr = _disbursements[i].addr;
            uint32 _sourceChainId = _disbursements[i].sourceChainId;
            uint256 _depositId = _disbursements[i].depositId;
            address _token = _disbursements[i].token;

            // Bidirectional support expected
            require(supportedTokens[_token][_sourceChainId].supported, "Token or chain not supported");

            // Ensure the depositId matches our expected value.
            require(_depositId == totalDisbursements[_sourceChainId], "Unexpected next deposit id");
            totalDisbursements[_sourceChainId] += 1;

            // ensure amount sent in the tx is equal to disbursement (moved into loop to ensure token flexibility)
            if (_token == address(0)) {
                require(_amount <= remainingValue, "Disbursement total != amount sent");
                remainingValue -= _amount;
            } else {
                IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
            }

            if (_token == address(0)) {
                // Deliver the disbursement amount to the receiver. If the
                // disbursement fails, the amount will be kept by the contract
                // rather than reverting to prevent blocking progress on other
                // disbursements.

                // slither-disable-next-line calls-loop,reentrancy-events
                (bool success,) = _addr.call{gas: 3000, value: _amount}("");
                if (success) emit DisbursementSuccess(_depositId, _addr, _token, _amount, _sourceChainId);
                else {
                    failedNativeDisbursements[_depositId] = FailedNativeDisbursement(true, _disbursements[i]);
                    emit DisbursementFailed(_depositId, _addr, _amount, _sourceChainId);
                }
            } else {
                // slither-disable-next-line calls-loop,reentrancy-events
                IERC20(_token).safeTransfer(_addr, _amount);
                emit DisbursementSuccess(_depositId, _addr, _token, _amount, _sourceChainId);
            }
        }
    }

    /**
     * @dev Retry native disbursement if it failed previously. Only applies to native disbursements bc. of low-level call.
     *
     * @param _depositIds A list of DepositIds to process.
     */
    function retryDisburseNative(uint256[] memory _depositIds)
    external
    payable
    onlyDisburser()
    whenNotPaused()
    {
        // Ensure there are disbursements to process.
        uint256 _numDisbursements = _depositIds.length;
        require(_numDisbursements > 0, "No disbursements");

        // Failed Disbursement amounts should remain in the contract

        // Process disbursements.
        for (uint256 i = 0; i < _numDisbursements; i++) {
            FailedNativeDisbursement storage failedDisbursement = failedNativeDisbursements[_depositIds[i]];
            require(failedDisbursement.failed, "DepositId not failed disbursement");
            uint256 _amount = failedDisbursement.disbursement.amount;
            address _addr = failedDisbursement.disbursement.addr;
            uint32 _sourceChainId = failedDisbursement.disbursement.sourceChainId;

            // slither-disable-next-line calls-loop,reentrancy-events
            (bool success,) = _addr.call{gas: 3000, value: _amount}("");
            if (success) {
                delete failedNativeDisbursements[_depositIds[i]];
                emit DisbursementRetrySuccess(_depositIds[i], _addr, _amount, _sourceChainId);
            }
        }
    }

    /********************
     * Admin Functions *
     ********************/

    /**
     * @dev Pause contract
     */
    function pause() external onlyOwner() {
        _pause();
    }

    /**
     * @dev UnPause contract
     */
    function unpause() external onlyOwner() {
        _unpause();
    }

    /**
     * @dev Sends the contract's current balance to the owner.
     */
    function withdrawBalance(address _token)
    external
    onlyOwner()
    onlyInitialized()
    {
        if (address(0) == _token) {
            uint256 _balance = address(this).balance;
            require(_balance > 0, "Nothing to send");
            (bool sent,) = owner.call{gas: 2300, value: _balance}("");
            require(sent, "Failed to send Ether");
            emit AssetBalanceWithdrawn(_token, owner, _balance);
        } else {
            // no supportedToken check in case of generally lost tokens
            uint256 _balance = IERC20(_token).balanceOf(address(this));
            require(_balance > 0, "Nothing to send");
            IERC20(_token).safeTransfer(owner, _balance);
            emit AssetBalanceWithdrawn(_token, owner, _balance);
        }
    }

    /**
     * @dev transfer disburser role to new address
     *
     * @param _newDisburser new disburser of this contract
     */
    function transferDisburser(
        address _newDisburser
    )
    external
    onlyOwner()
    {
        require(_newDisburser != address(0), 'New disburser cannot be the zero address');
        disburser = _newDisburser;
        emit DisburserTransferred(_newDisburser);
    }

    /**
     * @dev transfer ownership
     *
     * @param _newOwner new admin owner of this contract
     */
    function transferOwnership(
        address _newOwner
    )
    external
    onlyOwner()
    {
        require(_newOwner != address(0), 'New owner cannot be the zero address');
        owner = _newOwner;
        emit OwnershipTransferred(_newOwner);
    }

    /**
     * @notice Sets the minimum amount that can be deposited in a receive.
     *
     * @param _token configure for which token or ZeroAddress for native
     * @param _toChainId The destination network associated with the minimum deposit amount.
     * @param _minDepositAmount The new minimum deposit amount.
     */
    function setMinAmount(address _token, uint32 _toChainId, uint256 _minDepositAmount) external onlyOwner() {
        SupportedToken memory supToken = supportedTokens[_token][_toChainId];
        require(supToken.supported, "Token or chain not supported");
        require(_minDepositAmount > 0 && _minDepositAmount <= supToken.maxDepositAmount, "incorrect min deposit amount");

        uint256 pastMinDepositAmount = supToken.minDepositAmount;
        supportedTokens[_token][_toChainId].minDepositAmount = _minDepositAmount;

        emit MinDepositAmountSet(_token, _toChainId, pastMinDepositAmount, _minDepositAmount);
    }

    /**
     * @dev Sets the maximum amount that can be deposited in a receive.
     *
     * @param _token configure for which token or ZeroAddr for native asset
     * @param _toChainId target chain id to set configuration for
     * @param _maxDepositAmount The new maximum deposit amount.
     */
    function setMaxAmount(address _token, uint32 _toChainId, uint256 _maxDepositAmount) external onlyOwner() {
        SupportedToken memory supToken = supportedTokens[_token][_toChainId];
        require(supToken.supported, "Token or chain not supported");
        require(_maxDepositAmount <= supToken.maxTransferAmountPerDay, "max deposit amount more than daily limit");
        require(_maxDepositAmount > 0 && _maxDepositAmount >= supToken.minDepositAmount, "incorrect max deposit amount");
        uint256 pastMaxDepositAmount = supToken.maxDepositAmount;

        supportedTokens[_token][_toChainId].maxDepositAmount = _maxDepositAmount;
        emit MaxDepositAmountSet(_token, _toChainId, pastMaxDepositAmount, _maxDepositAmount);
    }

    /**
     * @dev Sets maximum amount of disbursements that can be processed in a day
     *
     * @param _token Token or native asset (ZeroAddr) to set value for
     * @param _maxTransferAmountPerDay The new maximum daily transfer amount.
     */
    function setMaxTransferAmountPerDay(address _token, uint32 _toChainId, uint256 _maxTransferAmountPerDay) external onlyOwner() {

        SupportedToken memory supToken = supportedTokens[_token][_toChainId];
        require(supToken.supported, "Token or chain not supported");
        require(_maxTransferAmountPerDay > 0 && _maxTransferAmountPerDay >= supToken.maxDepositAmount, "incorrect daily limit");
        uint256 pastMaxTransferAmountPerDay = supToken.maxTransferAmountPerDay;

        supportedTokens[_token][_toChainId].maxTransferAmountPerDay = _maxTransferAmountPerDay;

        emit MaxTransferAmountPerDaySet(_token, _toChainId, pastMaxTransferAmountPerDay, _maxTransferAmountPerDay);
    }
}