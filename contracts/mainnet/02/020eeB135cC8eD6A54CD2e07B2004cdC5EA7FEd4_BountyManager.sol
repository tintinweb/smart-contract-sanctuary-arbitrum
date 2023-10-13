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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import "./Initializable.sol";

contract ContextUpgradeable is Initializable {
	function __Context_init() internal onlyInitializing {}

	function __Context_init_unchained() internal onlyInitializing {}

	function _msgSender() internal view virtual returns (address payable) {
		return payable(msg.sender);
	}

	function _msgData() internal view virtual returns (bytes memory) {
		this;
		return msg.data;
	}

	uint256[50] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
	/**
	 * @dev Indicates that the contract has been initialized.
	 */
	bool private initialized;

	/**
	 * @dev Indicates that the contract is in the process of being initialized.
	 */
	bool private initializing;

	/**
	 * @dev Modifier to use in the initializer function of a contract.
	 */
	modifier initializer() {
		require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

		bool isTopLevelCall = !initializing;
		if (isTopLevelCall) {
			initializing = true;
			initialized = true;
		}

		_;

		if (isTopLevelCall) {
			initializing = false;
		}
	}

	/// @dev Returns true if and only if the function is running in the constructor
	function isConstructor() private view returns (bool) {
		// extcodesize checks the size of the code stored in an address, and
		// address returns the current address. Since the code is still not
		// deployed when running a constructor, any checks on its code size will
		// yield zero, making it an effective way to detect if a contract is
		// under construction or not.
		uint256 cs;
		//solium-disable-next-line
		assembly {
			cs := extcodesize(address())
		}
		return cs == 0;
	}

	modifier onlyInitializing() {
		require(initializing, "Initializable: contract is not initializing");
		_;
	}

	// Reserved storage space to allow for layout changes in the future.
	uint256[50] private ______gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import "./Initializable.sol";
import "./ContextUpgradeable.sol";

contract OwnableUpgradeable is Initializable, ContextUpgradeable {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	function __Ownable_init() internal onlyInitializing {
		__Ownable_init_unchained();
	}

	function __Ownable_init_unchained() internal onlyInitializing {
		_transferOwnership(_msgSender());
	}

	function owner() public view virtual returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		_transferOwnership(address(0));
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}

	uint256[49] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import "./Initializable.sol";
import "./ContextUpgradeable.sol";

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
	function __Pausable_init() internal onlyInitializing {
		__Pausable_init_unchained();
	}

	function __Pausable_init_unchained() internal onlyInitializing {
		_paused = false;
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
	 * @dev Modifier to make a function callable only when the contract is paused.
	 *
	 * Requirements:
	 *
	 * - The contract must be paused.
	 */
	modifier whenPaused() {
		_requirePaused();
		_;
	}

	/**
	 * @dev Returns true if the contract is paused, and false otherwise.
	 */
	function paused() public view virtual returns (bool) {
		return _paused;
	}

	/**
	 * @dev Throws if the contract is paused.
	 */
	function _requireNotPaused() internal view virtual {
		require(!paused(), "Pausable: paused");
	}

	/**
	 * @dev Throws if the contract is not paused.
	 */
	function _requirePaused() internal view virtual {
		require(paused(), "Pausable: not paused");
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

	/**
	 * @dev This empty reserved space is put in place to allow future versions to add new
	 * variables without shifting down storage in the inheritance chain.
	 * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
	 */
	uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IBountyManager {
	function quote(address _param) external returns (uint256 bounty);

	function claim(address _param) external returns (uint256 bounty);

	function minDLPBalance() external view returns (uint256 amt);

	function executeBounty(
		address _user,
		bool _execute,
		uint256 _actionType
	) external returns (uint256 bounty, uint256 actionType);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

interface IChefIncentivesController {
	/**
	 * @dev Called by the corresponding asset on any update that affects the rewards distribution
	 * @param user The address of the user
	 **/
	function handleActionBefore(address user) external;

	/**
	 * @dev Called by the corresponding asset on any update that affects the rewards distribution
	 * @param user The address of the user
	 * @param userBalance The balance of the user of the asset in the lending pool
	 * @param totalSupply The total supply of the asset in the lending pool
	 **/
	function handleActionAfter(address user, uint256 userBalance, uint256 totalSupply) external;

	/**
	 * @dev Called by the locking contracts after locking or unlocking happens
	 * @param user The address of the user
	 **/
	function beforeLockUpdate(address user) external;

	/**
	 * @notice Hook for lock update.
	 * @dev Called by the locking contracts after locking or unlocking happens
	 */
	function afterLockUpdate(address _user) external;

	function addPool(address _token, uint256 _allocPoint) external;

	function claim(address _user, address[] calldata _tokens) external;

	function setClaimReceiver(address _user, address _receiver) external;

	function getRegisteredTokens() external view returns (address[] memory);

	function disqualifyUser(address _user, address _hunter) external returns (uint256 bounty);

	function bountyForUser(address _user) external view returns (uint256 bounty);

	function allPendingRewards(address _user) external view returns (uint256 pending);

	function claimAll(address _user) external;

	function claimBounty(address _user, bool _execute) external returns (bool issueBaseBounty);

	function setEligibilityExempt(address _address, bool _value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface ICompounder {
	function claimCompound(address _user, bool _execute, uint256 _slippage) external returns (uint256 tokensOut);

	function viewPendingRewards(address user) external view returns (address[] memory tokens, uint256[] memory amts);

	function estimateReturns(address _in, address _out, uint256 amtIn) external view returns (uint256 amtOut);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

interface IEligibilityDataProvider {
	function refresh(address user) external returns (bool currentEligibility);

	function updatePrice() external;

	function requiredEthValue(address user) external view returns (uint256 required);

	function isEligibleForRewards(address _user) external view returns (bool isEligible);

	function lastEligibleTime(address user) external view returns (uint256 lastEligibleTimestamp);

	function lockedUsdValue(address user) external view returns (uint256);

	function requiredUsdValue(address user) external view returns (uint256 required);

	function lastEligibleStatus(address user) external view returns (bool);

	function rewardEligibleAmount(address token) external view returns (uint256);

	function setDqTime(address _user, uint256 _time) external;

	function getDqTime(address _user) external view returns (uint256);

	function autoprune() external returns (uint256 processed);

	function requiredDepositRatio() external view returns (uint256);

	function RATIO_DIVISOR() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./LockedBalance.sol";

interface IFeeDistribution {
	struct RewardData {
		address token;
		uint256 amount;
	}

	function addReward(address rewardsToken) external;

	function removeReward(address _rewardToken) external;
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableToken is IERC20 {
	function mint(address _receiver, uint256 _amount) external returns (bool);

	function burn(uint256 _amount) external returns (bool);

	function setMinter(address _minter) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./LockedBalance.sol";
import "./IFeeDistribution.sol";
import "./IMintableToken.sol";

interface IMultiFeeDistribution is IFeeDistribution {
	function exit(bool claimRewards) external;

	function stake(uint256 amount, address onBehalfOf, uint256 typeIndex) external;

	function rdntToken() external view returns (IMintableToken);

	function getPriceProvider() external view returns (address);

	function lockInfo(address user) external view returns (LockedBalance[] memory);

	function autocompoundEnabled(address user) external view returns (bool);

	function defaultLockIndex(address _user) external view returns (uint256);

	function autoRelockDisabled(address user) external view returns (bool);

	function totalBalance(address user) external view returns (uint256);

	function lockedBalance(address user) external view returns (uint256);

	function lockedBalances(
		address user
	) external view returns (uint256, uint256, uint256, uint256, LockedBalance[] memory);

	function getBalances(address _user) external view returns (Balances memory);

	function zapVestingToLp(address _address) external returns (uint256);

	function claimableRewards(address account) external view returns (IFeeDistribution.RewardData[] memory rewards);

	function setDefaultRelockTypeIndex(uint256 _index) external;

	function daoTreasury() external view returns (address);

	function stakingToken() external view returns (address);

	function userSlippage(address) external view returns (uint256);

	function claimFromConverter(address) external;

	function vestTokens(address user, uint256 amount, bool withPenalty) external;
}

interface IMFDPlus is IMultiFeeDistribution {
	function getLastClaimTime(address _user) external returns (uint256);

	function claimBounty(address _user, bool _execute) external returns (bool issueBaseBounty);

	function claimCompound(address _user, bool _execute, uint256 _slippage) external returns (uint256 bountyAmt);

	function setAutocompound(bool _newVal) external;

	function setUserSlippage(uint256 slippage) external;

	function toggleAutocompound() external;

	function getAutocompoundEnabled(address _user) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IPriceProvider {
	function getTokenPrice() external view returns (uint256);

	function getTokenPriceUsd() external view returns (uint256);

	function getLpTokenPrice() external view returns (uint256);

	function getLpTokenPriceUsd() external view returns (uint256);

	function decimals() external view returns (uint256);

	function update() external;

	function baseAssetChainlinkAdapter() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

struct LockedBalance {
	uint256 amount;
	uint256 unlockTime;
	uint256 multiplier;
	uint256 duration;
}

struct EarnedBalance {
	uint256 amount;
	uint256 unlockTime;
	uint256 penalty;
}

struct Reward {
	uint256 periodFinish;
	uint256 rewardPerSecond;
	uint256 lastUpdateTime;
	uint256 rewardPerTokenStored;
	// tracks already-added balances to handle accrued interest in aToken rewards
	// for the stakingToken this value is unused and will always be 0
	uint256 balance;
}

struct Balances {
	uint256 total; // sum of earnings and lockings; no use when LP and RDNT is different
	uint256 unlocked; // RDNT token
	uint256 locked; // LP token or RDNT token
	uint256 lockedWithMultiplier; // Multiplied locked amount
	uint256 earned; // RDNT token
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "../../dependencies/openzeppelin/upgradeability/Initializable.sol";
import {OwnableUpgradeable} from "../../dependencies/openzeppelin/upgradeability/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "../../dependencies/openzeppelin/upgradeability/PausableUpgradeable.sol";
import {RecoverERC20} from "../libraries/RecoverERC20.sol";
import {IMFDPlus} from "../../interfaces/IMultiFeeDistribution.sol";
import {IChefIncentivesController} from "../../interfaces/IChefIncentivesController.sol";
import {IPriceProvider} from "../../interfaces/IPriceProvider.sol";
import {IEligibilityDataProvider} from "../../interfaces/IEligibilityDataProvider.sol";
import {ICompounder} from "../../interfaces/ICompounder.sol";
import {IBountyManager} from "../../interfaces/IBountyManager.sol";

/// @title BountyManager Contract
/// @author Radiant Devs
contract BountyManager is Initializable, OwnableUpgradeable, PausableUpgradeable, RecoverERC20 {
	using SafeERC20 for IERC20;

	address public rdnt;
	address public weth;
	address public mfd;
	address public chef;
	address public priceProvider;
	address public eligibilityDataProvider;
	address public compounder;
	uint256 public hunterShare;
	uint256 public baseBountyUsdTarget; // decimals 18
	uint256 public maxBaseBounty;
	//Legacy storage variable, kept to preserve storage layout
	uint256 public bountyBooster;
	uint256 public bountyCount;
	uint256 public minStakeAmount;
	//Legacy storage variable, kept to preserve storage layout
	uint256 public slippageLimit;

	/// @notice Ratio Divisor
	uint256 public constant RATIO_DIVISOR = 10000;

	/// @notice The users specified slippage value for auto-compounding will be used
	uint256 internal constant DEFAULT_USERS_SLIPPAGE = 0;

	// Array of available Bounty functions to run. See _getMfdBounty, _getChefBounty, etc.
	mapping(uint256 => function(address, bool) returns (address, uint256, bool)) private bounties;

	mapping(address => bool) public whitelist;
	bool public whitelistActive;

	modifier isWhitelisted() {
		if (whitelistActive) {
			if (!whitelist[msg.sender] && msg.sender != address(this)) revert NotWhitelisted();
		}
		_;
	}

	event MinStakeAmountUpdated(uint256 indexed _minStakeAmount);
	event BaseBountyUsdTargetUpdated(uint256 indexed _newVal);
	event HunterShareUpdated(uint256 indexed _newVal);
	event MaxBaseBountyUpdated(uint256 indexed _newVal);
	event BountiesSet();
	event BountyReserveEmpty(uint256 indexed _bal);
	event WhitelistUpdated(address indexed _user, bool indexed _isActive);
	event WhitelistActiveChanged(bool indexed isActive);

	error AddressZero();
	error InvalidNumber();
	error QuoteFail();
	error Ineligible();
	error InvalidSlippage();
	error ActionTypeIndexOutOfBounds();
	error NotWhitelisted();

	/**
	 * @notice Initialize
	 * @param _rdnt RDNT address
	 * @param _weth WETH address
	 * @param _mfd MFD, to send bounties as vesting RDNT to Hunter (user calling bounty)
	 * @param _chef CIC, to query bounties for ineligible emissions
	 * @param _priceProvider PriceProvider service, to get RDNT price for bounty quotes
	 * @param _eligibilityDataProvider Eligibility data provider
	 * @param _compounder Compounder address
	 * @param _hunterShare % of reclaimed rewards to send to Hunter
	 * @param _baseBountyUsdTarget Base Bounty is paid in RDNT, will scale to match this USD target value
	 * @param _maxBaseBounty cap the scaling above
	 */
	function initialize(
		address _rdnt,
		address _weth,
		address _mfd,
		address _chef,
		address _priceProvider,
		address _eligibilityDataProvider,
		address _compounder,
		uint256 _hunterShare,
		uint256 _baseBountyUsdTarget,
		uint256 _maxBaseBounty
	) external initializer {
		if (_rdnt == address(0)) revert AddressZero();
		if (_weth == address(0)) revert AddressZero();
		if (_mfd == address(0)) revert AddressZero();
		if (_chef == address(0)) revert AddressZero();
		if (_priceProvider == address(0)) revert AddressZero();
		if (_eligibilityDataProvider == address(0)) revert AddressZero();
		if (_compounder == address(0)) revert AddressZero();
		if (_hunterShare > RATIO_DIVISOR) revert InvalidNumber();
		if (_baseBountyUsdTarget == 0) revert InvalidNumber();
		if (_maxBaseBounty == 0) revert InvalidNumber();

		rdnt = _rdnt;
		weth = _weth;
		mfd = _mfd;
		chef = _chef;
		priceProvider = _priceProvider;
		eligibilityDataProvider = _eligibilityDataProvider;
		compounder = _compounder;

		hunterShare = _hunterShare;
		baseBountyUsdTarget = _baseBountyUsdTarget;
		maxBaseBounty = _maxBaseBounty;

		bounties[1] = _getMfdBounty;
		bounties[2] = _getChefBounty;
		bounties[3] = _getAutoCompoundBounty;
		bountyCount = 3;

		__Ownable_init();
		__Pausable_init();
	}

	/**
	 * @notice Given a user, return their bounty amount. uses staticcall to run same bounty aglo, but without execution
	 * @param _user address
	 * @return bounty amount of RDNT Hunter will recieve.
	 * can be a fixed amt (Base Bounty) or dynamic amt based on rewards removed from target user during execution (ineligible revenue, autocompound fee)
	 * @return actionType which of the 3 bounty types (above) to run.
	 * _getAvailableBounty returns this based on priority (expired locks first, then inelig emissions, then autocompound)
	 */
	function quote(address _user) public view returns (uint256 bounty, uint256 actionType) {
		(bool success, bytes memory data) = address(this).staticcall(
			abi.encodeCall(IBountyManager.executeBounty, (_user, false, 0))
		);
		if (!success) revert QuoteFail();

		(bounty, actionType) = abi.decode(data, (uint256, uint256));
	}

	/**
	 * @notice Execute a bounty.
	 * @param _user address
	 * can be a fixed amt (Base Bounty) or dynamic amt based on rewards removed from target user during execution (ineligible revenue, autocompound fee)
	 * @param _actionType which of the 3 bounty types (above) to run.
	 * @return bounty in RDNT to be paid to Hunter (via vesting)
	 * @return actionType which bounty ran
	 */
	function claim(address _user, uint256 _actionType) public returns (uint256, uint256) {
		return executeBounty(_user, true, _actionType);
	}

	/**
	 * @notice Execute the most appropriate bounty on a user, check returned amount for slippage, calc amount going to Hunter, send to vesting.
	 * @param _user address
	 * @param _execute whether to execute this txn, or just quote what its execution would return
	 * can be a fixed amt (Base Bounty) or dynamic amt based on rewards removed from target user during execution (ineligible revenue, autocompound fee)
	 * @param _actionType which of the 3 bounty types (above) to run.
	 * @return bounty in RDNT to be paid to Hunter (via vesting)
	 * @return actionType which bounty ran
	 */
	function executeBounty(
		address _user,
		bool _execute,
		uint256 _actionType
	) public whenNotPaused isWhitelisted returns (uint256 bounty, uint256 actionType) {
		if (_execute && msg.sender != address(this)) {
			if (!_canBountyHunt(msg.sender)) revert Ineligible();
		}
		uint256 totalBounty;
		bool issueBaseBounty;
		address incentivizer;

		(incentivizer, totalBounty, issueBaseBounty, actionType) = _getAvailableBounty(_user, _execute, _actionType);
		if (issueBaseBounty) {
			bounty = getBaseBounty();
		} else {
			if (totalBounty != 0) {
				bounty = (totalBounty * hunterShare) / RATIO_DIVISOR;
			}
		}

		if (_execute && bounty != 0) {
			if (!issueBaseBounty) {
				IERC20(rdnt).safeTransferFrom(incentivizer, address(this), totalBounty);
			}
			bounty = _sendBounty(msg.sender, bounty);
		}
	}

	function _canBountyHunt(address _user) internal view returns (bool) {
		(, , uint256 lockedLP, , ) = IMFDPlus(mfd).lockedBalances(_user);
		bool isEmissionsEligible = IEligibilityDataProvider(eligibilityDataProvider).isEligibleForRewards(_user);
		return lockedLP >= minDLPBalance() && isEmissionsEligible;
	}

	/**
	 * @notice Given a user and actionType, execute that bounty on either CIC or MFD or Compounder.
	 * @param _user address
	 * @param _execute whether to execute this txn, or just quote what its execution would return
	 * @param _actionTypeIndex, which of the 3 bounty types (above) to run.
	 * @return incentivizer the contract that had a bounty operation performed for it.
	 * Either CIC (to remove ineligible user from emission pool, or MFD to remove expired locks)
	 * @return totalBounty raw amount of RDNT returned from Incentivizer. Hunter % will be deducted from this.
	 * @return issueBaseBounty whether Incentivizer will pay bounty from its own RDNT reserve, or from this contracts RDNT reserve
	 * @return actionType the action type index executed
	 */
	function _getAvailableBounty(
		address _user,
		bool _execute,
		uint256 _actionTypeIndex
	) internal returns (address incentivizer, uint256 totalBounty, bool issueBaseBounty, uint256 actionType) {
		if (_actionTypeIndex > bountyCount) revert ActionTypeIndexOutOfBounds();
		if (_actionTypeIndex != 0) {
			// execute bounty w/ given params
			(incentivizer, totalBounty, issueBaseBounty) = bounties[_actionTypeIndex](_user, _execute);
			actionType = _actionTypeIndex;
		} else {
			for (uint256 i = 1; i <= bountyCount; ) {
				(incentivizer, totalBounty, issueBaseBounty) = bounties[i](_user, _execute);
				if (totalBounty != 0 || issueBaseBounty) {
					actionType = i;
					break;
				}
				unchecked {
					i++;
				}
			}
		}
	}

	/**
	 * @notice call MFDPlus.claimBounty()
	 * @param _user address
	 * @param _execute whether to execute this txn, or just quote what its execution would return
	 * @return incentivizer in this case MFD
	 * @return totalBounty RDNT to pay for this _user's bounty execution
	 * @return issueBaseBounty false when !autorelock because they will have rewards removed from their ineligible time after locks expired
	 */
	function _getMfdBounty(
		address _user,
		bool _execute
	) internal returns (address incentivizer, uint256, bool issueBaseBounty) {
		try IMFDPlus(mfd).claimBounty(_user, _execute) returns (bool issueBaseBounty_) {
			issueBaseBounty = issueBaseBounty_;
		} catch {
			issueBaseBounty = false;
		}
		incentivizer = mfd;
		return (incentivizer, 0, issueBaseBounty);
	}

	/**
	 * @notice call CIC.claimBounty()
	 * @param _user address
	 * @param _execute whether to execute this txn, or just quote what its execution would return
	 * @return incentivizer in this case CIC
	 * @return totalBounty RDNT to pay for this _user's bounty execution
	 * @return issueBaseBounty will be true
	 */
	function _getChefBounty(
		address _user,
		bool _execute
	) internal returns (address incentivizer, uint256, bool issueBaseBounty) {
		issueBaseBounty = IChefIncentivesController(chef).claimBounty(_user, _execute);
		incentivizer = chef;
		return (incentivizer, 0, issueBaseBounty);
	}

	/**
	 * @notice call Compounder.claimCompound(). compound pending rewards for _user into locked LP
	 * @param _user address
	 * @param _execute whether to execute this txn, or just quote what its execution would return
	 * @return incentivizer is the Compounder
	 * @return totalBounty RDNT to pay for this _user's bounty execution. paid from Autocompound fee
	 * @return issueBaseBounty will be false, will vary based on autocompound fee
	 */
	function _getAutoCompoundBounty(
		address _user,
		bool _execute
	) internal returns (address incentivizer, uint256 totalBounty, bool issueBaseBounty) {
		(totalBounty) = ICompounder(compounder).claimCompound(_user, _execute, DEFAULT_USERS_SLIPPAGE);
		issueBaseBounty = false;
		incentivizer = compounder;
	}

	/**
	 * @notice Vest a bounty in MFD for successful bounty by Hunter
	 * @param _to Hunter address
	 * @param _amount of RDNT
	 * @return amt added to vesting
	 */
	function _sendBounty(address _to, uint256 _amount) internal returns (uint256) {
		uint256 bountyReserve = IERC20(rdnt).balanceOf(address(this));
		if (_amount > bountyReserve) {
			IERC20(rdnt).safeTransfer(address(mfd), bountyReserve);
			IMFDPlus(mfd).vestTokens(_to, bountyReserve, true);
			emit BountyReserveEmpty(bountyReserve);
			_pause();
			return bountyReserve;
		} else {
			IERC20(rdnt).safeTransfer(address(mfd), _amount);
			IMFDPlus(mfd).vestTokens(_to, _amount, true);
			return _amount;
		}
	}

	/**
	 * @notice Return RDNT amount for Base Bounty.
	 * Base Bounty used to incentivize operations that don't generate their own reward to pay to Hunter.
	 * @return bounty in RDNT
	 */
	function getBaseBounty() public view whenNotPaused returns (uint256) {
		uint256 rdntPrice = IPriceProvider(priceProvider).getTokenPriceUsd();
		uint256 bounty = (baseBountyUsdTarget * 1e8) / rdntPrice;
		return bounty > maxBaseBounty ? maxBaseBounty : bounty;
	}

	/**
	 * @notice Minimum locked lp balance
	 */
	function minDLPBalance() public view returns (uint256 min) {
		uint256 lpTokenPrice = IPriceProvider(priceProvider).getLpTokenPriceUsd();
		min = (minStakeAmount * 1e8) / lpTokenPrice;
	}

	/**
	 * @notice Sets minimum stake amount.
	 * @dev Only owner can call this function.
	 * @param _minStakeAmount Minimum stake amount
	 */
	function setMinStakeAmount(uint256 _minStakeAmount) external onlyOwner {
		minStakeAmount = _minStakeAmount;
		emit MinStakeAmountUpdated(_minStakeAmount);
	}

	/**
	 * @notice Sets target price of base bounty.
	 * @dev Only owner can call this function.
	 * @param _newVal New USD value
	 */
	function setBaseBountyUsdTarget(uint256 _newVal) external onlyOwner {
		baseBountyUsdTarget = _newVal;
		emit BaseBountyUsdTargetUpdated(_newVal);
	}

	/**
	 * @notice Sets hunter's share ratio.
	 * @dev Only owner can call this function.
	 * @param _newVal New hunter share ratio
	 */
	function setHunterShare(uint256 _newVal) external onlyOwner {
		if (_newVal > RATIO_DIVISOR) revert InvalidNumber();
		hunterShare = _newVal;
		emit HunterShareUpdated(_newVal);
	}

	/**
	 * @notice Updates maximum base bounty.
	 * @dev Only owner can call this function.
	 * @param _newVal Maximum base bounty
	 */
	function setMaxBaseBounty(uint256 _newVal) external onlyOwner {
		maxBaseBounty = _newVal;
		emit MaxBaseBountyUpdated(_newVal);
	}

	/**
	 * @notice Set bounty operations.
	 * @dev Only owner can call this function.
	 */
	function setBounties() external onlyOwner {
		bounties[1] = _getMfdBounty;
		bounties[2] = _getChefBounty;
		bounties[3] = _getAutoCompoundBounty;
		emit BountiesSet();
	}

	/**
	 * @notice Recover ERC20 tokens from the contract.
	 * @param tokenAddress Token address to recover
	 * @param tokenAmount Amount to recover
	 */
	function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
		_recoverERC20(tokenAddress, tokenAmount);
	}

	/**
	 * @notice Add new address to whitelist.
	 * @param user address
	 * @param status for whitelist
	 */
	function addAddressToWL(address user, bool status) external onlyOwner {
		whitelist[user] = status;
		emit WhitelistUpdated(user, status);
	}

	/**
	 * @notice Update whitelist active status.
	 * @param status New whitelist status
	 */
	function changeWL(bool status) external onlyOwner {
		whitelistActive = status;
		emit WhitelistActiveChanged(status);
	}

	/**
	 * @notice Pause the bounty operations.
	 */
	function pause() public onlyOwner {
		_pause();
	}

	/**
	 * @notice Unpause the bounty operations.
	 */
	function unpause() public onlyOwner {
		_unpause();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title RecoverERC20 contract
/// @author Radiant Devs
/// @dev All function calls are currently implemented without side effects
contract RecoverERC20 {
	using SafeERC20 for IERC20;

	/// @notice Emitted when ERC20 token is recovered
	event Recovered(address indexed token, uint256 amount);

	/**
	 * @notice Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
	 */
	function _recoverERC20(address tokenAddress, uint256 tokenAmount) internal {
		IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
		emit Recovered(tokenAddress, tokenAmount);
	}
}