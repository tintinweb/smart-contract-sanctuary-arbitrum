// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
pragma solidity 0.8.18;

/// @title Handles errors using custom errors
/// @author Pino Development Team
contract Errors {
    error ProxyError(uint256 errCode);

    /// @notice Handles custom error codes
    /// @param _condition The condition, if it's false then execution is reverted
    /// @param _code Custom code, listed in Errors.sol
    function _require(bool _condition, uint256 _code) internal pure {
        if (!_condition) {
            revert ProxyError(_code);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Errors.sol";
import "../helpers/ErrorCodes.sol";

/// @title Handles ETH re-usabilitiy
/// @author Pino Development Team
contract EthLocker is Errors {
    // 2 means unlocked. 1 means locked
    // If locked is equal to 1, then function with the ethUnlocked modifier revert
    // If locked is equal to 2, then only 1 function with the ethUnlocked modifier works
    uint8 private locked = 2;

    /// @notice Locks functions that work with ETH directly
    function lockEth() internal {
        locked = 1;
    }

    /// @notice Unlocks functions that work with ETH directly
    function unlockEth() internal {
        locked = 2;
    }

    /// @notice Checks whether eth has been used in another function or not
    modifier ethLocked() {
        _require(locked == 1, ErrorCodes.ETHER_AMOUNT_SURPASSES_MSG_VALUE);

        _;
    }

    /// @notice Checks whether
    modifier ethUnlocked() {
        _require(locked == 2, ErrorCodes.ETHER_AMOUNT_SURPASSES_MSG_VALUE);
        locked = 1;

        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./EthLocker.sol";

/// @title Handles multicall function
/// @author Pino Development Team
contract Multicall is EthLocker {
    /// @notice Multiple calls on proxy functions
    /// @param _data The destination address
    function multicall(bytes[] calldata _data) public payable {
        unlockEth();

        for (uint256 i = 0; i < _data.length;) {
            (bool success, bytes memory result) = address(this).delegatecall(_data[i]);

            if (!success) {
                if (result.length < 68) revert();

                assembly {
                    result := add(result, 0x04)
                }

                revert(abi.decode(result, (string)));
            }

            unchecked {
                ++i;
            }
        }

        unlockEth();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Payments.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Handles owner functions
/// @author Pino Development Team
contract Owner is Ownable, Payments {
    /// @notice Proxy contract constructor, sets permit2 and weth addresses
    /// @param _permit2 Permit2 contract address
    /// @param _weth WETH9 contract address
    constructor(Permit2 _permit2, IWETH9 _weth) Payments(_permit2, _weth) {}

    /// @notice Withdraws fees and transfers them to owner
    /// @param _recipient Address of the destination receiving the fees
    function withdrawAdmin(address _recipient) public onlyOwner {
        require(address(this).balance > 0);

        _sendETH(_recipient, address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Permit.sol";
import "./Errors.sol";
import "./EthLocker.sol";
import "../helpers/ErrorCodes.sol";
import "../interfaces/Permit2/Permit2.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Handles custom payment functions
/// @author Pino Development Team
contract Payments is Errors, Permit, EthLocker {
    using SafeERC20 for IERC20;

    /// @notice Proxy contract constructor, sets permit2 and weth addresses
    /// @param _permit2 Permit2 contract address
    /// @param _weth WETH9 contract address
    constructor(Permit2 _permit2, IWETH9 _weth) Permit(_permit2, _weth) {}

    /// @notice Sweeps contract tokens to msg.sender
    /// @param _token ERC20 token address
    /// @param _recipient The destination address
    function sweepToken(address _token, address _recipient) public payable {
        uint256 balanceOf = IERC20(_token).balanceOf(address(this));

        if (balanceOf > 0) {
            IERC20(_token).safeTransfer(_recipient, balanceOf);
        }
    }

    /// @notice Transfers ERC20 token to recipient
    /// @param _recipient The destination address
    /// @param _token ERC20 token address
    /// @param _amount Amount to transfer
    function _send(address _token, address _recipient, uint256 _amount) internal {
        IERC20(_token).safeTransfer(_recipient, _amount);
    }

    /// @notice Permits _spender to spend max amount of ERC20 from the contract
    /// @param _token ERC20 token address
    /// @param _spender Spender address
    function _approve(address _token, address _spender) internal {
        IERC20(_token).safeApprove(_spender, type(uint256).max);
    }

    /// @notice Sends ETH to the destination
    /// @param _recipient The destination address
    /// @param _amount Ether amount
    function _sendETH(address _recipient, uint256 _amount) internal {
        (bool success,) = payable(_recipient).call{value: _amount}("");

        _require(success, ErrorCodes.FAILED_TO_SEND_ETHER);
    }

    /// @notice Approves an ERC20 token to lendingPool and wethGateway
    /// @param _token ERC20 token address
    /// @param _spenders ERC20 token address
    function approveToken(address _token, address[] calldata _spenders) external {
        for (uint8 i = 0; i < _spenders.length;) {
            _approve(_token, _spenders[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Wraps ETH to WETH and sends to recipient
    /// @param _proxyFee Fee of the proxy contract
    function wrapETH(uint96 _proxyFee) external payable ethUnlocked {
        uint256 value = msg.value - _proxyFee;

        WETH.deposit{value: value}();
    }

    /// @notice Unwraps WETH9 to Ether and sends the amount to the recipient
    /// @param _recipient The destination address
    function _unwrapWETH9(address _recipient) internal {
        uint256 balanceWETH = WETH.balanceOf(address(this));

        if (balanceWETH > 0) {
            WETH.withdraw(balanceWETH);

            _sendETH(_recipient, balanceWETH);
        }
    }

    /// @notice Unwraps WETH9 to Ether and sends the amount to the recipient
    /// @param _recipient The destination address
    function unwrapWETH9(address _recipient) public payable {
        uint256 balanceWETH = WETH.balanceOf(address(this));

        if (balanceWETH > 0) {
            WETH.withdraw(balanceWETH);

            _sendETH(_recipient, balanceWETH);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "../interfaces/IWETH9.sol";
import "../interfaces/Permit2/Permit2.sol";

/// @title Permit2 SignatureTransfer functions
/// @author Pino Development Team
contract Permit {
    IWETH9 public immutable WETH;
    Permit2 public immutable permit2;

    /// @notice Proxy contract constructor, sets permit2 and weth addresses
    /// @param _permit2 Permit2 contract address
    /// @param _weth WETH9 contract address
    constructor(Permit2 _permit2, IWETH9 _weth) {
        WETH = _weth;
        permit2 = _permit2;
    }

    function permitTransferFrom(ISignatureTransfer.PermitTransferFrom calldata _permit, bytes calldata _signature)
        public
        payable
    {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );
    }

    function permitBatchTransferFrom(
        ISignatureTransfer.PermitBatchTransferFrom calldata _permit,
        bytes calldata _signature
    ) public payable {
        uint256 tokensLen = _permit.permitted.length;

        ISignatureTransfer.SignatureTransferDetails[] memory details =
            new ISignatureTransfer.SignatureTransferDetails[](tokensLen);

        for (uint256 i = 0; i < tokensLen;) {
            details[i].to = address(this);
            details[i].requestedAmount = _permit.permitted[i].amount;

            unchecked {
                ++i;
            }
        }

        permit2.permitTransferFrom(_permit, details, msg.sender, _signature);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Pino.sol";
import "../interfaces/IWETH9.sol";
import "../interfaces/Compound/IComet.sol";
import "../interfaces/Compound/ICToken.sol";
import "../interfaces/Compound/ICEther.sol";
import "../interfaces/Compound/ICompound.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Compound V2 proxy
/// @author Pino Development Team
/// @notice Calls Compound V2/V3 functions
/// @dev This contract uses Permit2
contract Compound is ICompound, Pino {
    using SafeERC20 for IERC20;

    IComet public immutable Comet;
    ICEther public immutable CEther;

    /// @notice Receives tokens and cTokens and approves them
    /// @param _permit2 Address of Permit2 contract
    /// @param _weth Address of WETH9 contract
    /// @param _comet Address of CompoundV3 (comet) contract
    /// @param _cEther Address of Compound V2 CEther
    /// @param _tokens List of ERC20 tokens used in Compound V2
    /// @param _cTokens List of ERC20 cTokens used in Compound V2
    /// @dev Do not put WETH and cEther addresses among _tokens or _cTokens
    constructor(
        Permit2 _permit2,
        IWETH9 _weth,
        IComet _comet,
        ICEther _cEther,
        IERC20[] memory _tokens,
        address[] memory _cTokens
    ) Pino(_permit2, _weth) {
        Comet = _comet;
        CEther = _cEther;

        // Approve WETH to the Comet protocol
        _weth.approve(address(_comet), type(uint256).max);

        for (uint8 i = 0; i < _tokens.length;) {
            // Set allowance for cTokens to spend ERC20 tokens
            _tokens[i].safeApprove(_cTokens[i], type(uint256).max);

            // Set allowance for Comet to spend ERC20 tokens
            _tokens[i].safeApprove(address(_comet), type(uint256).max);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Deposits ERC20 to the Compound protocol and transfers cTokens to the recipient
    /// @param _amount Amount to deposit
    /// @param _cToken Address of the cToken to receive
    /// @param _recipient The destination address that will receive cTokens
    function depositV2(uint256 _amount, ICToken _cToken, address _recipient) external payable {
        _cToken.mint(_amount);

        // Send cTokens to the recipient
        sweepToken(address(_cToken), _recipient);
    }

    /// @notice Deposits ETH to the Compound protocol and transfers CEther to the recipient
    /// @param _recipient The destination address that will receive cTokens
    /// @param _proxyFee Fee of the proxy contract
    /// @dev _proxyFee uses uint96 for storage efficiency
    function depositETHV2(address _recipient, uint96 _proxyFee) external payable ethUnlocked {
        CEther.mint{value: msg.value - _proxyFee}();

        // Send CEther tokens to the recipient
        sweepToken(address(CEther), _recipient);
    }

    /// @notice Deposits WETH, converts it to ETH and mints CEther
    /// @param _permit permit structure to receive WETH
    /// @param _signature Signature used by permit2
    /// @param _recipient The destination address that will receive CEther
    function depositWETHV2(
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata _signature,
        address _recipient
    ) external payable {
        permitTransferFrom(_permit, _signature);

        WETH.withdraw(_permit.permitted.amount);

        CEther.mint{value: _permit.permitted.amount}();

        sweepToken(address(CEther), _recipient);
    }

    /// @notice Deposits cTokens back to the Compound protocol and receives underlying ERC20 tokens and transfers it to the recipient
    /// @param _amount Amount to withdraw
    /// @param _cToken Address of the cToken
    /// @param _recipient The destination that will receive the underlying token
    function withdrawV2(uint256 _amount, ICToken _cToken, address _recipient) external payable {
        _cToken.redeem(_amount);

        // Send underlying ERC20 tokens to the recipient
        sweepToken(_cToken.underlying(), _recipient);
    }

    /// @notice Deposits CEther back the the Compound protocol and receives ETH and transfers it to the recipient
    /// @param _amount Amount to withdraw
    /// @param _recipient The destination address that will receive ETH
    function withdrawETHV2(uint256 _amount, address _recipient) external payable ethUnlocked {
        uint256 balanceBefore = address(this).balance;

        // Contract will receive ETH and the balance is updated
        CEther.redeem(_amount);

        uint256 balanceAfter = address(this).balance;

        // Send ETH to the recipient
        _sendETH(_recipient, balanceAfter - balanceBefore);
    }

    /// @notice Deposits CEther back the the Compound protocol and receives ETH and transfers WETH to the recipient
    /// @param _amount Amount to withdraw
    /// @param _recipient The destination address that will receive WETH
    function withdrawWETHV2(uint256 _amount, address _recipient) external payable ethUnlocked {
        uint256 balanceBefore = address(this).balance;

        // Contract will receive ETH and the balance is updated
        CEther.redeem(_amount);

        uint256 balanceAfter = address(this).balance;

        // Convert ETH to WETH
        WETH.deposit{value: balanceAfter - balanceBefore}();

        // Send WETH to the recipient
        sweepToken(address(WETH), _recipient);
    }

    /// @notice Repays a borrowed token on behalf of the recipient
    /// @param _cToken Address of the cToken
    /// @param _amount Amount to repay
    /// @param _recipient The address of the recipient
    function repayV2(ICToken _cToken, uint256 _amount, address _recipient) external payable {
        _cToken.repayBorrowBehalf(_recipient, _amount);
    }

    /// @notice Repays ETH on behalf of the recipient
    /// @param _recipient The address of the recipient
    /// @param _proxyFee Fee of the proxy contract
    function repayETHV2(address _recipient, uint96 _proxyFee) external payable ethUnlocked {
        CEther.repayBorrowBehalf{value: msg.value - _proxyFee}(_recipient);
    }

    /// @notice Repays ETH on behalf of the recipient but receives WETH from the caller
    /// @param _permit The permit structure for PERMIT2 to receive WETH
    /// @param _signature The signature used by PERMIT2 contract
    /// @param _recipient The address of the recipient
    function repayWETHV2(
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata _signature,
        address _recipient
    ) external payable ethUnlocked {
        // Transfer WETH to the contract
        permitTransferFrom(_permit, _signature);

        // Unwrap WETH to ETH
        WETH.withdraw(_permit.permitted.amount);

        // Send ETH to CEther
        CEther.repayBorrowBehalf{value: _permit.permitted.amount}(_recipient);
    }

    /// @notice Deposits ERC20 tokens to the Compound protocol on behalf of the recipient
    /// @param _token The underlying ERC20 token
    /// @param _amount Amount to deposit
    /// @param _recipient The address of the recipient
    function depositV3(address _token, uint256 _amount, address _recipient) external payable {
        Comet.supplyTo(_recipient, _token, _amount);
    }

    /// @notice Withdraws an ERC20 token and transfers it to the recipient
    /// @param _token The underlying ERC20 token to withdraw
    /// @param _amount Amount to withdraw
    /// @param _recipient The address of the recipient
    function withdrawV3(address _token, uint256 _amount, address _recipient) external payable {
        Comet.withdrawFrom(msg.sender, _recipient, _token, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library ErrorCodes {
    uint256 internal constant FAILED_TO_SEND_ETHER = 0;
    uint256 internal constant ETHER_AMOUNT_SURPASSES_MSG_VALUE = 1;

    uint256 internal constant TOKENS_MISMATCHED = 2;

    uint256 internal constant FAIELD_TO_SWAP_USING_1INCH = 3;
    uint256 internal constant FAIELD_TO_SWAP_USING_PARASWAP = 4;
    uint256 internal constant FAIELD_TO_SWAP_USING_0X = 5;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ICEther is IERC20 {
    function mint() external payable;
    function redeem(uint256 redeemTokens) external returns (uint256);
    function balanceOfUnderlying(address account) external returns (uint256);
    function underlying() external view returns (address);
    function repayBorrowBehalf(address borrower) external payable returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IComet is IERC20 {
    function allow(address manager, bool isAllowed) external;
    function hasPermission(address owner, address manager) external view returns (bool);
    function collateralBalanceOf(address account, address asset) external view returns (uint128);
    function supplyTo(address dst, address asset, uint256 amount) external;
    function withdrawFrom(address src, address dst, address asset, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ICToken.sol";
import "../Permit2/Permit2.sol";

/// @title Compound V2 proxy
/// @author Pino Development Team
/// @notice Calls Compound V2/V3 functions
/// @dev This contract uses Permit2
interface ICompound {
    /// @notice Deposits ERC20 to the Compound protocol and transfers cTokens to the recipient
    /// @param _amount Amount to deposit
    /// @param _cToken Address of the cToken to receive
    /// @param _recipient The destination address that will receive cTokens
    function depositV2(uint256 _amount, ICToken _cToken, address _recipient) external payable;

    /// @notice Deposits ETH to the Compound protocol and transfers CEther to the recipient
    /// @param _recipient The destination address that will receive cTokens
    /// @param _proxyFee Fee of the proxy contract
    /// @dev _proxyFee uses uint96 for storage efficiency
    function depositETHV2(address _recipient, uint96 _proxyFee) external payable;

    /// @notice Deposits WETH, converts it to ETH and mints CEther
    /// @param _permit permit structure to receive WETH
    /// @param _signature Signature used by permit2
    /// @param _recipient The destination address that will receive CEther
    function depositWETHV2(
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata _signature,
        address _recipient
    ) external payable;

    /// @notice Deposits cTokens back to the Compound protocol and receives underlying ERC20 tokens and transfers it to the recipient
    /// @param _amount Amount to withdraw
    /// @param _cToken Address of the cToken
    /// @param _recipient The destination that will receive the underlying token
    function withdrawV2(uint256 _amount, ICToken _cToken, address _recipient) external payable;

    /// @notice Deposits CEther back the the Compound protocol and receives ETH and transfers it to the recipient
    /// @param _amount Amount to withdraw
    /// @param _recipient The destination address that will receive ETH
    function withdrawETHV2(uint256 _amount, address _recipient) external payable;

    /// @notice Deposits CEther back the the Compound protocol and receives ETH and transfers WETH to the recipient
    /// @param _amount Amount to withdraw
    /// @param _recipient The destination address that will receive WETH
    function withdrawWETHV2(uint256 _amount, address _recipient) external payable;

    /// @notice Repays a borrowed token on behalf of the recipient
    /// @param _cToken Address of the cToken
    /// @param _amount Amount to repay
    /// @param _recipient The address of the recipient
    function repayV2(ICToken _cToken, uint256 _amount, address _recipient) external payable;

    /// @notice Repays ETH on behalf of the recipient
    /// @param _recipient The address of the recipient
    /// @param _proxyFee Fee of the proxy contract
    function repayETHV2(address _recipient, uint96 _proxyFee) external payable;

    /// @notice Repays ETH on behalf of the recipient but receives WETH from the caller
    /// @param _permit The permit structure for PERMIT2 to receive WETH
    /// @param _signature The signature used by PERMIT2 contract
    /// @param _recipient The address of the recipient
    function repayWETHV2(
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata _signature,
        address _recipient
    ) external payable;

    /// @notice Deposits ERC20 tokens to the Compound protocol on behalf of the recipient
    /// @param _token The underlying ERC20 token
    /// @param _amount Amount to deposit
    /// @param _recipient The address of the recipient
    function depositV3(address _token, uint256 _amount, address _recipient) external payable;

    /// @notice Withdraws an ERC20 token and transfers it to the recipient
    /// @param _token The underlying ERC20 token to withdraw
    /// @param _amount Amount to withdraw
    /// @param _recipient The address of the recipient
    function withdrawV3(address _token, uint256 _amount, address _recipient) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ICToken is IERC20 {
    function mint(uint256 mintAmount) external returns (uint256);
    function redeem(uint256 redeemTokens) external returns (uint256);
    function balanceOfUnderlying(address account) external returns (uint256);
    function underlying() external view returns (address);
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IWETH9 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(address src, address dst, uint256 wad) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title AllowanceTransfer
/// @notice Handles ERC20 token permissions through signature based allowance setting and ERC20 token transfers by checking allowed amounts
/// @dev Requires user's token approval on the Permit2 contract
interface IAllowanceTransfer {
    /// @notice Thrown when an allowance on a token has expired.
    /// @param deadline The timestamp at which the allowed amount is no longer valid
    error AllowanceExpired(uint256 deadline);

    /// @notice Thrown when an allowance on a token has been depleted.
    /// @param amount The maximum amount allowed
    error InsufficientAllowance(uint256 amount);

    /// @notice Thrown when too many nonces are invalidated.
    error ExcessiveInvalidation();

    /// @notice Emits an event when the owner successfully invalidates an ordered nonce.
    event NonceInvalidation(
        address indexed owner, address indexed token, address indexed spender, uint48 newNonce, uint48 oldNonce
    );

    /// @notice Emits an event when the owner successfully sets permissions on a token for the spender.
    event Approval(
        address indexed owner, address indexed token, address indexed spender, uint160 amount, uint48 expiration
    );

    /// @notice Emits an event when the owner successfully sets permissions using a permit signature on a token for the spender.
    event Permit(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint160 amount,
        uint48 expiration,
        uint48 nonce
    );

    /// @notice Emits an event when the owner sets the allowance back to 0 with the lockdown function.
    event Lockdown(address indexed owner, address token, address spender);

    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The permit message signed for multiple token allowances
    struct PermitBatch {
        // the permit data for multiple token allowances
        PermitDetails[] details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The saved permissions
    /// @dev This info is saved per owner, per token, per spender and all signed over in the permit message
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    struct PackedAllowance {
        // amount allowed
        uint160 amount;
        // permission expiry
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice A token spender pair.
    struct TokenSpenderPair {
        // the token the spender is approved
        address token;
        // the spender address
        address spender;
    }

    /// @notice Details for a token transfer.
    struct AllowanceTransferDetails {
        // the owner of the token
        address from;
        // the recipient of the token
        address to;
        // the amount of the token
        uint160 amount;
        // the token to be transferred
        address token;
    }

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(address, address, address) external view returns (uint160, uint48, uint48);

    /// @notice Approves the spender to use up to amount of the specified token up until the expiration
    /// @param token The token to approve
    /// @param spender The spender address to approve
    /// @param amount The approved amount of the token
    /// @param expiration The timestamp at which the approval is no longer valid
    /// @dev The packed allowance also holds a nonce, which will stay unchanged in approve
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;

    /// @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitSingle Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

    /// @notice Permit a spender to the signed amounts of the owners tokens via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitBatch Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitBatch memory permitBatch, bytes calldata signature) external;

    /// @notice Transfer approved tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    /// @param token The token address to transfer
    /// @dev Requires the from address to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(address from, address to, uint160 amount, address token) external;

    /// @notice Transfer approved tokens in a batch
    /// @param transferDetails Array of owners, recipients, amounts, and tokens for the transfers
    /// @dev Requires the from addresses to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external;

    /// @notice Enables performing a "lockdown" of the sender's Permit2 identity
    /// by batch revoking approvals
    /// @param approvals Array of approvals to revoke.
    function lockdown(TokenSpenderPair[] calldata approvals) external;

    /// @notice Invalidate nonces for a given (token, spender) pair
    /// @param token The token to invalidate nonces for
    /// @param spender The spender to invalidate nonces for
    /// @param newNonce The new nonce to set. Invalidates all nonces less than it.
    /// @dev Can't invalidate more than 2**16 nonces per transaction.
    function invalidateNonces(address token, address spender, uint48 newNonce) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title SignatureTransfer
/// @notice Handles ERC20 token transfers through signature based actions
/// @dev Requires user's token approval on the Permit2 contract
interface ISignatureTransfer {
    /// @notice Thrown when the requested amount for a transfer is larger than the permissioned amount
    /// @param maxAmount The maximum amount a spender can request to transfer
    error InvalidAmount(uint256 maxAmount);

    /// @notice Thrown when the number of tokens permissioned to a spender does not match the number of tokens being transferred
    /// @dev If the spender does not need to transfer the number of tokens permitted, the spender can request amount 0 to be transferred
    error LengthMismatch();

    /// @notice Emits an event when the owner successfully invalidates an unordered nonce.
    event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

    /// @notice The token and amount details for a transfer signed in the permit transfer signature
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice Specifies the recipient address and amount for batched transfers.
    /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
    /// @dev Reverts if the requested amount is greater than the permitted signed amount.
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /// @notice Used to reconstruct the signed permit message for multiple token transfers
    /// @dev Do not need to pass in spender address as it is required that it is msg.sender
    /// @dev Note that a user still signs over a spender address
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
    /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
    /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
    /// @dev It returns a uint256 bitmap
    /// @dev The index, or wordPosition is capped at type(uint248).max
    function nonceBitmap(address, uint256) external view returns (uint256);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers a token using a signed permit message
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Invalidates the bits specified in mask for the bitmap at the word position
    /// @dev The wordPos is maxed at type(uint248).max
    /// @param wordPos A number to index the nonceBitmap at
    /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ISignatureTransfer} from "./ISignatureTransfer.sol";
import {IAllowanceTransfer} from "./IAllowanceTransfer.sol";

/// @notice Permit2 handles signature-based transfers in SignatureTransfer and allowance-based transfers in AllowanceTransfer.
/// @dev Users must approve Permit2 before calling any of the transfer functions.
abstract contract Permit2 is ISignatureTransfer, IAllowanceTransfer {
// Permit2 unifies the two contracts so users have maximal flexibility with their approval.
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./base/Owner.sol";
import "./base/Multicall.sol";

/// @title Pino main contract layout
/// @author Pino Development Team
/// @notice Inherits Owner, Payments, Permit2, and Multicall
/// @dev This contract uses Permit2
contract Pino is Owner, Multicall {
    /// @notice Proxy contract constructor, sets permit2 and weth addresses
    /// @param _permit2 Permit2 contract address
    /// @param _weth WETH9 contract address
    constructor(Permit2 _permit2, IWETH9 _weth) Owner(_permit2, _weth) {}

    receive() external payable {}
}