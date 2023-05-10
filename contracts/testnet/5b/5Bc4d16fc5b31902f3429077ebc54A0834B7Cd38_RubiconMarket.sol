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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/// @title RubiconMarket.sol
/// @notice Please see the repository for this code at https://github.com/RubiconDeFi/rubicon-protocol-v1;
/// @notice This contract is a derivative work, and spiritual continuation, of the open-source work from Oasis DEX: https://github.com/OasisDEX/oasis

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/// @notice DSAuth events for authentication schema
contract DSAuthEvents {
    /// event LogSetAuthority(address indexed authority); /// TODO: this event is not used in the contract, remove?
    event LogSetOwner(address indexed owner);
}

/// @notice DSAuth library for setting owner of the contract
/// @dev Provides the auth modifier for authenticated function calls
contract DSAuth is DSAuthEvents {
    address public owner;

    function setOwner(address owner_) external auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    modifier auth() {
        require(isAuthorized(msg.sender), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src) internal view returns (bool) {
        if (src == owner) {
            return true;
        } else {
            return false;
        }
    }
}

/// @notice DSMath library for safe math without integer overflow/underflow
contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }
}

/// @notice Events contract for logging trade activity on Rubicon Market
/// @dev Provides the key event logs that are used in all core functionality of exchanging on the Rubicon Market
contract EventfulMarket {
    event LogItemUpdate(uint256 id);

    /// TODO: double check it is sound logic to kill this event
    /// event LogTrade(
    ///     uint256 pay_amt,
    ///     address indexed pay_gem,
    ///     uint256 buy_amt,
    ///     address indexed buy_gem
    /// );

    /// event LogMake(
    ///     bytes32 indexed id,
    ///     bytes32 indexed pair,
    ///     address indexed maker,
    ///     IERC20 pay_gem,
    ///     IERC20 buy_gem,
    ///     uint128 pay_amt,
    ///     uint128 buy_amt,
    ///     uint64 timestamp
    /// );

    event emitOffer(
        bytes32 indexed id,
        bytes32 indexed pair,
        address indexed maker,
        IERC20 pay_gem,
        IERC20 buy_gem,
        uint128 pay_amt,
        uint128 buy_amt
    );

    /// TODO: double check it is sound logic to kill this event
    /// event LogBump(
    ///     bytes32 indexed id,
    ///     bytes32 indexed pair,
    ///     address indexed maker,
    ///     IERC20 pay_gem,
    ///     IERC20 buy_gem,
    ///     uint128 pay_amt,
    ///     uint128 buy_amt,
    ///     uint64 timestamp
    /// );

    /// event LogTake(
    ///     bytes32 id,
    ///     bytes32 indexed pair,
    ///     address indexed maker,
    ///     IERC20 pay_gem,
    ///     IERC20 buy_gem,
    ///     address indexed taker,
    ///     uint128 take_amt,
    ///     uint128 give_amt,
    ///     uint64 timestamp
    /// );

    event emitTake(
        bytes32 indexed id,
        bytes32 indexed pair,
        address indexed maker,
        address taker,
        IERC20 pay_gem,
        IERC20 buy_gem,
        uint128 take_amt,
        uint128 give_amt
    );

    /// event LogKill(
    ///     bytes32 indexed id,
    ///     bytes32 indexed pair,
    ///     address indexed maker,
    ///     IERC20 pay_gem,
    ///     IERC20 buy_gem,
    ///     uint128 pay_amt,
    ///     uint128 buy_amt,
    ///     uint64 timestamp
    /// );

    event emitCancel(
        bytes32 indexed id,
        bytes32 indexed pair,
        address indexed maker,
        IERC20 pay_gem,
        IERC20 buy_gem,
        uint128 pay_amt,
        uint128 buy_amt
    );

    /// TODO: double check it is sound logic to kill this event
    /// event LogInt(string lol, uint256 input);

    /// event FeeTake(
    ///     bytes32 indexed id,
    ///     bytes32 indexed pair,
    ///     IERC20 asset,
    ///     address indexed taker,
    ///     address feeTo,
    ///     uint256 feeAmt,
    ///     uint64 timestamp
    /// );

    /// TODO: we will need to make sure this emit is included in any taker pay maker scenario
    event emitFee(
        bytes32 indexed id,
        address indexed taker,
        address indexed feeTo,
        bytes32 pair,
        IERC20 asset,
        uint256 feeAmt
    );

    /// event OfferDeleted(bytes32 indexed id);

    event emitDelete(
        bytes32 indexed id,
        bytes32 indexed pair,
        address indexed maker
    );
}

/// @notice Core trading logic for ERC-20 pairs, an orderbook, and transacting of tokens
/// @dev This contract holds the core ERC-20 / ERC-20 offer, buy, and cancel logic
contract SimpleMarket is EventfulMarket, DSMath {
    using SafeERC20 for IERC20;

    uint256 public last_offer_id;

    /// @dev The mapping that makes up the core orderbook of the exchange
    mapping(uint256 => OfferInfo) public offers;

    bool locked;

    /// @dev This parameter is in basis points
    uint256 internal feeBPS;

    /// @dev This parameter provides the address to which fees are sent
    address internal feeTo;

    bytes32 internal constant MAKER_FEE_SLOT = keccak256("WOB_MAKER_FEE");

    struct OfferInfo {
        uint256 pay_amt;
        IERC20 pay_gem;
        uint256 buy_amt;
        IERC20 buy_gem;
        address recipient;
        uint64 timestamp;
        address owner;
    }

    /// @notice Modifier that insures an order exists and is properly in the orderbook
    modifier can_buy(uint256 id) virtual {
        require(isActive(id));
        _;
    }

    // /// @notice Modifier that checks the user to make sure they own the offer and its valid before they attempt to cancel it
    modifier can_cancel(uint256 id) virtual {
        require(isActive(id));
        require(
            (msg.sender == getOwner(id)) ||
                (msg.sender == getRecipient(id) && getOwner(id) == address(0))
        );
        _;
    }

    modifier can_offer() virtual {
        _;
    }

    modifier synchronized() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    /// @notice get makerFee value
    function makerFee() public view returns (uint256) {
        return StorageSlot.getUint256Slot(MAKER_FEE_SLOT).value;
    }

    function isActive(uint256 id) public view returns (bool active) {
        return offers[id].timestamp > 0;
    }

    function getOwner(uint256 id) public view returns (address owner) {
        return offers[id].owner;
    }

    function getRecipient(uint256 id) public view returns (address owner) {
        return offers[id].recipient;
    }

    function getOffer(
        uint256 id
    ) public view returns (uint256, IERC20, uint256, IERC20) {
        OfferInfo memory _offer = offers[id];
        return (_offer.pay_amt, _offer.pay_gem, _offer.buy_amt, _offer.buy_gem);
    }

    /// @notice Accept a given `quantity` of an offer. Transfers funds from caller/taker to offer maker, and from market to caller/taker.
    /// @notice The fee for taker trades is paid in this function.
    function buy(
        uint256 id,
        uint256 quantity
    ) public virtual can_buy(id) synchronized returns (bool) {
        OfferInfo memory _offer = offers[id];
        uint256 spend = mul(quantity, _offer.buy_amt) / _offer.pay_amt;

        require(uint128(spend) == spend, "spend is not an int");
        require(uint128(quantity) == quantity, "quantity is not an int");

        ///@dev For backwards semantic compatibility.
        if (
            quantity == 0 ||
            spend == 0 ||
            quantity > _offer.pay_amt ||
            spend > _offer.buy_amt
        ) {
            return false;
        }

        offers[id].pay_amt = sub(_offer.pay_amt, quantity);
        offers[id].buy_amt = sub(_offer.buy_amt, spend);

        /// @dev Fee logic added on taker trades
        uint256 fee = mul(spend, feeBPS) / 100_000;

        _offer.buy_gem.safeTransferFrom(msg.sender, feeTo, fee);

        // taker pay maker 0_0
        if (makerFee() > 0) {
            uint256 mFee = mul(spend, makerFee()) / 100_000;

            /// @dev Handle the v1 -> v2 migration case where if owner == address(0) we transfer this fee to _offer.recipient
            if (_offer.owner == address(0) && getRecipient(id) != address(0)) {
                _offer.buy_gem.safeTransferFrom(
                    msg.sender,
                    _offer.recipient,
                    mFee
                );
            } else {
                _offer.buy_gem.safeTransferFrom(msg.sender, _offer.owner, mFee);
            }

            emit emitFee(
                bytes32(id),
                msg.sender,
                _offer.owner,
                keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
                _offer.buy_gem,
                mFee
            );
        }
        _offer.buy_gem.safeTransferFrom(msg.sender, _offer.recipient, spend);

        _offer.pay_gem.safeTransfer(msg.sender, quantity);

        emit LogItemUpdate(id);

        /// emit LogTake(
        ///     bytes32(id),
        ///     keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
        ///     _offer.owner,
        ///     _offer.pay_gem,
        ///     _offer.buy_gem,
        ///     msg.sender,
        ///     uint128(quantity),
        ///     uint128(spend),
        ///     uint64(block.timestamp)
        /// );

        emit emitTake(
            bytes32(id),
            keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
            _offer.owner != address(0) ? _offer.owner : _offer.recipient,
            msg.sender,
            _offer.pay_gem,
            _offer.buy_gem,
            uint128(quantity),
            uint128(spend)
        );

        /// emit FeeTake(
        ///     bytes32(id),
        ///     keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
        ///     _offer.buy_gem,
        ///     msg.sender,
        ///     feeTo,
        ///     fee,
        ///     uint64(block.timestamp)
        /// );

        emit emitFee(
            bytes32(id),
            msg.sender,
            feeTo,
            keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
            _offer.buy_gem,
            fee
        );

        /// TODO: double check it is sound logic to kill this event
        /// emit LogTrade(
        ///     quantity,
        ///     address(_offer.pay_gem),
        ///     spend,
        ///     address(_offer.buy_gem)
        /// );

        if (offers[id].pay_amt == 0) {
            delete offers[id];
            /// emit OfferDeleted(bytes32(id));

            emit emitDelete(
                bytes32(id),
                keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
                _offer.owner != address(0) ? _offer.owner : _offer.recipient
            );
        }

        return true;
    }

    /// @notice Allows the caller to cancel the offer if it is their own.
    /// @notice This function refunds the offer to the maker.
    function cancel(
        uint256 id
    ) public virtual can_cancel(id) synchronized returns (bool success) {
        OfferInfo memory _offer = offers[id];
        delete offers[id];

        /// @dev V1 orders after V2 upgrade will point to address(0) in owner
        _offer.owner == address(0)
            ? _offer.pay_gem.safeTransfer(_offer.recipient, _offer.pay_amt)
            : _offer.pay_gem.safeTransfer(_offer.owner, _offer.pay_amt);

        emit LogItemUpdate(id);
        /// emit LogKill(
        ///     bytes32(id),
        ///     keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
        ///     _offer.owner,
        ///     _offer.pay_gem,
        ///     _offer.buy_gem,
        ///     uint128(_offer.pay_amt),
        ///     uint128(_offer.buy_amt)
        /// );

        emit emitCancel(
            bytes32(id),
            keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
            _offer.owner != address(0) ? _offer.owner : _offer.recipient,
            _offer.pay_gem,
            _offer.buy_gem,
            uint128(_offer.pay_amt),
            uint128(_offer.buy_amt)
        );

        success = true;
    }

    /// @notice Key function to make a new offer. Takes funds from the caller into market escrow.
    function offer(
        uint256 pay_amt,
        IERC20 pay_gem,
        uint256 buy_amt,
        IERC20 buy_gem,
        address owner,
        address recipient
    ) public virtual can_offer synchronized returns (uint256 id) {
        require(uint128(pay_amt) == pay_amt);
        require(uint128(buy_amt) == buy_amt);
        require(pay_amt > 0);
        require(pay_gem != IERC20(address(0))); /// @dev Note, modified from: require(pay_gem != IERC20(0x0)) which compiles in 0.7.6
        require(buy_amt > 0);
        require(buy_gem != IERC20(address(0))); /// @dev Note, modified from: require(buy_gem != IERC20(0x0)) which compiles in 0.7.6
        require(pay_gem != buy_gem);
        require(owner != address(0), "Zero owner address");
        require(recipient != address(0), "Zero recipient address");

        OfferInfo memory info;
        info.pay_amt = pay_amt;
        info.pay_gem = pay_gem;
        info.buy_amt = buy_amt;
        info.buy_gem = buy_gem;
        info.recipient = recipient;
        info.owner = owner;
        info.timestamp = uint64(block.timestamp);
        id = _next_id();
        offers[id] = info;

        pay_gem.safeTransferFrom(msg.sender, address(this), pay_amt);

        emit LogItemUpdate(id);

        /// emit LogMake(
        ///     bytes32(id),
        ///     keccak256(abi.encodePacked(pay_gem, buy_gem)),
        ///     msg.sender,
        ///     pay_gem,
        ///     buy_gem,
        ///     uint128(pay_amt),
        ///     uint128(buy_amt),
        ///     uint64(block.timestamp)
        /// );

        emit emitOffer(
            bytes32(id),
            keccak256(abi.encodePacked(pay_gem, buy_gem)),
            msg.sender,
            pay_gem,
            buy_gem,
            uint128(pay_amt),
            uint128(buy_amt)
        );
    }

    function _next_id() internal returns (uint256) {
        last_offer_id++;
        return last_offer_id;
    }

    // Fee logic
    function getFeeBPS() public view returns (uint256) {
        return feeBPS;
    }
}

/// @notice Expiring market is a Simple Market with a market lifetime.
/// @dev When the close_time has been reached, offers can only be cancelled (offer and buy will throw).
contract ExpiringMarket is DSAuth, SimpleMarket {
    bool public stopped;

    /// @dev After close_time has been reached, no new offers are allowed.
    modifier can_offer() override {
        require(!isClosed());
        _;
    }

    /// @dev After close, no new buys are allowed.
    modifier can_buy(uint256 id) override {
        require(isActive(id));
        require(!isClosed());
        _;
    }

    /// @dev After close, anyone can cancel an offer.
    modifier can_cancel(uint256 id) virtual override {
        require(isActive(id));
        require(
            (msg.sender == getOwner(id)) ||
                isClosed() ||
                (msg.sender == getRecipient(id) && getOwner(id) == address(0))
        );
        _;
    }

    function isClosed() public pure returns (bool closed) {
        return false;
    }

    function getTime() public view returns (uint64) {
        return uint64(block.timestamp);
    }

    function stop() external auth {
        stopped = true;
    }
}

contract DSNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed guy,
        bytes32 indexed foo,
        bytes32 indexed bar,
        uint256 wad,
        bytes fax
    ) anonymous;

    modifier note() {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);

        _;
    }
}

contract MatchingEvents {
    /// event LogBuyEnabled(bool isEnabled); /// TODO: this event is not used in the contract, remove?
    event LogMinSell(address pay_gem, uint256 min_amount);
    /// event LogMatchingEnabled(bool isEnabled); /// TODO: this event is not used in the contract, remove?
    event LogUnsortedOffer(uint256 id);
    event LogSortedOffer(uint256 id);
    /// event LogInsert(address keeper, uint256 id); /// TODO: this event is not used in the contract, remove?
    event LogDelete(address keeper, uint256 id);
    event LogMatch(uint256 id, uint256 amount);
}

/// @notice The core Rubicon Market smart contract
/// @notice This contract is based on the original open-source work done by OasisDEX under the Apache License 2.0
/// @dev This contract inherits the key trading functionality from SimpleMarket
contract RubiconMarket is MatchingEvents, ExpiringMarket, DSNote {
    bool public buyEnabled = true; //buy enabled TODO: review this decision!
    bool public matchingEnabled = true; //true: enable matching,

    /// @dev Below is variable to allow for a proxy-friendly constructor
    bool public initialized;

    /// @dev unused deprecated variable for applying a token distribution on top of a trade
    bool public AqueductDistributionLive;
    /// @dev unused deprecated variable for applying a token distribution of this token on top of a trade
    address public AqueductAddress;

    struct sortInfo {
        uint256 next; //points to id of next higher offer
        uint256 prev; //points to id of previous lower offer
        uint256 delb; //the blocknumber where this entry was marked for delete
    }
    mapping(uint256 => sortInfo) public _rank; //doubly linked lists of sorted offer ids
    mapping(address => mapping(address => uint256)) public _best; //id of the highest offer for a token pair
    mapping(address => mapping(address => uint256)) public _span; //number of offers stored for token pair in sorted orderbook
    mapping(address => uint256) public _dust; //minimum sell amount for a token to avoid dust offers
    mapping(uint256 => uint256) public _near; //next unsorted offer id
    uint256 public _head; //first unsorted offer id
    uint256 public dustId; // id of the latest offer marked as dust

    // *** MAPPING TO CHECK POTENTIALLY BLACKLISTED TOKENS ***
    mapping(address => bool) public tokenRequiresBlacklistCheck;

    /// @dev Proxy-safe initialization of storage
    function initialize(address _feeTo) public {
        require(!initialized, "contract is already initialized");
        require(_feeTo != address(0));

        /// @notice The market fee recipient
        feeTo = _feeTo;

        owner = msg.sender;
        emit LogSetOwner(msg.sender);

        /// @notice The starting fee on taker trades in basis points
        feeBPS = 1;

        initialized = true;
        matchingEnabled = true;
        buyEnabled = true;
    }

    // // After close, anyone can cancel an offer
    modifier can_cancel(uint256 id) override {
        require(isActive(id), "Offer was deleted or taken, or never existed.");
        require(
            isClosed() ||
                msg.sender == getOwner(id) ||
                id == dustId ||
                (msg.sender == getRecipient(id) && getOwner(id) == address(0)),
            "Offer can not be cancelled because user is not owner, and market is open, and offer sells required amount of tokens."
        );
        _;
    }

    // ---- Public entrypoints ---- //
    // simplest offer entry-point
    function offer(
        uint256 pay_amt, //maker (ask) sell how much
        IERC20 pay_gem, //maker (ask) sell which token
        uint256 buy_amt, //maker (ask) buy how much
        IERC20 buy_gem //maker (ask) buy which token
    ) public can_offer returns (uint256) {
        return
            offer(
                pay_amt,
                pay_gem,
                buy_amt,
                buy_gem,
                0,
                true,
                msg.sender,
                msg.sender
            );
    }

    function offer(
        uint256 pay_amt, //maker (ask) sell how much
        IERC20 pay_gem, //maker (ask) sell which token
        uint256 buy_amt, //maker (ask) buy how much
        IERC20 buy_gem, //maker (ask) buy which token
        uint pos, //position to insert offer, 0 should be used if unknown
        bool rounding
    ) external can_offer returns (uint256) {
        return
            offer(
                pay_amt,
                pay_gem,
                buy_amt,
                buy_gem,
                pos,
                rounding,
                msg.sender,
                msg.sender
            );
    }

    // Make a new offer. Takes funds from the caller into market escrow.
    function offer(
        uint256 pay_amt, //maker (ask) sell how much
        IERC20 pay_gem, //maker (ask) sell which token
        uint256 buy_amt, //maker (ask) buy how much
        IERC20 buy_gem, //maker (ask) buy which token
        uint256 pos, //position to insert offer, 0 should be used if unknown
        address owner,
        address recipient
    ) external can_offer returns (uint256) {
        return
            offer(
                pay_amt,
                pay_gem,
                buy_amt,
                buy_gem,
                pos,
                true,
                owner,
                recipient
            );
    }

    function offer(
        uint256 pay_amt,
        IERC20 pay_gem,
        uint256 buy_amt,
        IERC20 buy_gem,
        address owner,
        address recipient
    ) public override can_offer returns (uint) {
        return
            offer(
                pay_amt,
                pay_gem,
                buy_amt,
                buy_gem,
                0,
                true,
                owner,
                recipient
            );
    }

    function setTokenRequiresBlacklistCheck(
        address token,
        bool requiresCheck
    ) external auth {
        tokenRequiresBlacklistCheck[token] = requiresCheck;
    }

    function offer(
        uint256 pay_amt, //maker (ask) sell how much
        IERC20 pay_gem, //maker (ask) sell which token
        uint256 buy_amt, //maker (ask) buy how much
        IERC20 buy_gem, //maker (ask) buy which token
        uint256 pos, //position to insert offer, 0 should be used if unknown
        bool matching, //match "close enough" orders?
        address _owner, // owner of the offer
        address recipient // recipient of the offer's fill
    ) public can_offer returns (uint256) {
        require(!locked, "Reentrancy attempt");
        require(_dust[address(pay_gem)] <= pay_amt);

        if (tokenRequiresBlacklistCheck[address(buy_gem)]) {
            require(
                !_addressIsBlacklisted(address(buy_gem), _owner, recipient)
            );
        }

        /// @dev currently matching is perma-enabled
        // if (matchingEnabled) {
        return
            _matcho(
                pay_amt,
                pay_gem,
                buy_amt,
                buy_gem,
                pos,
                matching,
                _owner,
                recipient
            );
        // }
        // return super.offer(pay_amt, pay_gem, buy_amt, buy_gem);
    }

    //Transfers funds from caller to offer maker, and from market to caller.
    function buy(
        uint256 id,
        uint256 amount
    ) public override can_buy(id) returns (bool) {
        require(!locked, "Reentrancy attempt");

        function(uint256, uint256) returns (bool) fn = matchingEnabled
            ? _buys
            : super.buy;

        return fn(id, amount);
    }

    // Cancel an offer. Refunds offer maker.
    function cancel(
        uint256 id
    ) public override can_cancel(id) returns (bool success) {
        require(!locked, "Reentrancy attempt");
        if (matchingEnabled) {
            if (isOfferSorted(id)) {
                require(_unsort(id));
            } else {
                require(_hide(id), "can't hide");
            }
        }
        return super.cancel(id); //delete the offer.
    }

    // *** Batch Functionality ***
    /// @notice Batch offer functionality - multuple offers in a single transaction
    function batchOffer(
        uint[] calldata payAmts,
        address[] calldata payGems,
        uint[] calldata buyAmts,
        address[] calldata buyGems
    ) external {
        require(
            payAmts.length == payGems.length &&
                payAmts.length == buyAmts.length &&
                payAmts.length == buyGems.length,
            "Array lengths do not match"
        );
        for (uint i = 0; i < payAmts.length; i++) {
            offer(
                payAmts[i],
                IERC20(payGems[i]),
                buyAmts[i],
                IERC20(buyGems[i])
            );
        }
    }

    /// @notice Cancel multiple offers in a single transaction
    function batchCancel(uint[] calldata ids) external {
        for (uint i = 0; i < ids.length; i++) {
            cancel(ids[i]);
        }
    }

    /// @notice Update outstanding offers to new offers, in a batch, in a single transaction
    function batchRequote(
        uint[] calldata ids,
        uint[] calldata payAmts,
        address[] calldata payGems,
        uint[] calldata buyAmts,
        address[] calldata buyGems
    ) external {
        require(
            payAmts.length == payGems.length &&
                payAmts.length == ids.length &&
                payAmts.length == buyAmts.length &&
                payAmts.length == buyGems.length,
            "Array lengths do not match"
        );
        for (uint i = 0; i < ids.length; i++) {
            cancel(ids[i]);
            offer(
                payAmts[i],
                IERC20(payGems[i]),
                buyAmts[i],
                IERC20(buyGems[i])
            );
        }
    }

    //deletes _rank [id]
    //  Function should be called by keepers.
    function del_rank(uint256 id) external returns (bool) {
        require(!locked);

        require(
            !isActive(id) &&
                _rank[id].delb != 0 &&
                _rank[id].delb < block.number - 10
        );
        delete _rank[id];
        emit LogDelete(msg.sender, id);
        return true;
    }

    //set the minimum sell amount for a token
    //    Function is used to avoid "dust offers" that have
    //    very small amount of tokens to sell, and it would
    //    cost more gas to accept the offer, than the value
    //    of tokens received.
    function setMinSell(
        IERC20 pay_gem, //token to assign minimum sell amount to
        uint256 dust //maker (ask) minimum sell amount
    ) external auth note returns (bool) {
        _dust[address(pay_gem)] = dust;
        emit LogMinSell(address(pay_gem), dust);
        return true;
    }

    //returns the minimum sell amount for an offer
    function getMinSell(
        IERC20 pay_gem //token for which minimum sell amount is queried
    ) external view returns (uint256) {
        return _dust[address(pay_gem)];
    }

    //return the best offer for a token pair
    //      the best offer is the lowest one if it's an ask,
    //      and highest one if it's a bid offer
    function getBestOffer(
        IERC20 sell_gem,
        IERC20 buy_gem
    ) public view returns (uint256) {
        return _best[address(sell_gem)][address(buy_gem)];
    }

    //return the next worse offer in the sorted list
    //      the worse offer is the higher one if its an ask,
    //      a lower one if its a bid offer,
    //      and in both cases the newer one if they're equal.
    function getWorseOffer(uint256 id) public view returns (uint256) {
        return _rank[id].prev;
    }

    //return the next better offer in the sorted list
    //      the better offer is in the lower priced one if its an ask,
    //      the next higher priced one if its a bid offer
    //      and in both cases the older one if they're equal.
    function getBetterOffer(uint256 id) external view returns (uint256) {
        return _rank[id].next;
    }

    //return the amount of better offers for a token pair
    function getOfferCount(
        IERC20 sell_gem,
        IERC20 buy_gem
    ) public view returns (uint256) {
        return _span[address(sell_gem)][address(buy_gem)];
    }

    //get the first unsorted offer that was inserted by a contract
    //      Contracts can't calculate the insertion position of their offer because it is not an O(1) operation.
    //      Their offers get put in the unsorted list of offers.
    //      Keepers can calculate the insertion position offchain and pass it to the insert() function to insert
    //      the unsorted offer into the sorted list. Unsorted offers will not be matched, but can be bought with buy().
    function getFirstUnsortedOffer() public view returns (uint256) {
        return _head;
    }

    //get the next unsorted offer
    //      Can be used to cycle through all the unsorted offers.
    function getNextUnsortedOffer(uint256 id) public view returns (uint256) {
        return _near[id];
    }

    function isOfferSorted(uint256 id) public view returns (bool) {
        return
            _rank[id].next != 0 ||
            _rank[id].prev != 0 ||
            _best[address(offers[id].pay_gem)][address(offers[id].buy_gem)] ==
            id;
    }

    function sellAllAmount(
        IERC20 pay_gem,
        uint256 pay_amt,
        IERC20 buy_gem,
        uint256 min_fill_amount
    ) external returns (uint256 fill_amt) {
        require(!locked);

        uint256 offerId;
        while (pay_amt > 0) {
            //while there is amount to sell
            offerId = getBestOffer(buy_gem, pay_gem); //Get the best offer for the token pair
            require(offerId != 0, "0 offerId"); //Fails if there are not more offers

            // There is a chance that pay_amt is smaller than 1 wei of the other token
            if (
                mul(pay_amt, 1 ether) <
                wdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)
            ) {
                break; //We consider that all amount is sold
            }
            if (pay_amt >= offers[offerId].buy_amt) {
                //If amount to sell is higher or equal than current offer amount to buy
                fill_amt = add(fill_amt, offers[offerId].pay_amt); //Add amount bought to acumulator
                pay_amt = sub(pay_amt, offers[offerId].buy_amt); //Decrease amount to sell
                buy((offerId), uint128(offers[offerId].pay_amt)); //We take the whole offer
            } else {
                // if lower
                uint256 baux = rmul(
                    mul(pay_amt, 10 ** 9),
                    rdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)
                ) / 10 ** 9;
                fill_amt = add(fill_amt, baux); //Add amount bought to acumulator
                buy((offerId), uint128(baux)); //We take the portion of the offer that we need
                pay_amt = 0; //All amount is sold
            }
        }
        require(fill_amt >= min_fill_amount, "min_fill_amount isn't filled");
    }

    function buyAllAmount(
        IERC20 buy_gem,
        uint256 buy_amt,
        IERC20 pay_gem,
        uint256 max_fill_amount
    ) external returns (uint256 fill_amt) {
        require(!locked);
        uint256 offerId;
        while (buy_amt > 0) {
            //Meanwhile there is amount to buy
            offerId = getBestOffer(buy_gem, pay_gem); //Get the best offer for the token pair
            require(offerId != 0, "offerId == 0");

            // There is a chance that buy_amt is smaller than 1 wei of the other token
            if (
                mul(buy_amt, 1 ether) <
                wdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)
            ) {
                break; //We consider that all amount is sold
            }
            if (buy_amt >= offers[offerId].pay_amt) {
                //If amount to buy is higher or equal than current offer amount to sell
                fill_amt = add(fill_amt, offers[offerId].buy_amt); //Add amount sold to acumulator
                buy_amt = sub(buy_amt, offers[offerId].pay_amt); //Decrease amount to buy
                buy((offerId), uint128(offers[offerId].pay_amt)); //We take the whole offer
            } else {
                //if lower
                fill_amt = add(
                    fill_amt,
                    rmul(
                        mul(buy_amt, 10 ** 9),
                        rdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)
                    ) / 10 ** 9
                ); //Add amount sold to acumulator
                buy((offerId), uint128(buy_amt)); //We take the portion of the offer that we need
                buy_amt = 0; //All amount is bought
            }
        }
        require(
            fill_amt <= max_fill_amount,
            "fill_amt exceeds max_fill_amount"
        );
    }

    function calculateFees(
        uint256 amount,
        bool isPay /// @param denote direction
    ) public view returns (uint256 _amount) {
        // Add fee amount
        if (isPay) {
            _amount = amount;
            _amount += mul(amount, feeBPS) / 100_000;

            if (makerFee() > 0) {
                _amount += mul(amount, makerFee()) / 100_000;
            }
        }
        // Reduce fee amount
        else {
            _amount = amount;
            _amount -= mul(amount, feeBPS) / 100_000;

            if (makerFee() > 0) {
                _amount -= mul(amount, makerFee()) / 100_000;
            }
        }
    }

    /// @return buy_amt - fill with fee deducted
    /// @return approvalAmount - amount user should approve for interaction
    function getBuyAmountWithFee(
        IERC20 buy_gem,
        IERC20 pay_gem,
        uint256 pay_amt
    ) external view returns (uint256 buy_amt, uint256 approvalAmount) {
        uint modifiedAmount = calculateFees(pay_amt, false);
        buy_amt = (getBuyAmount(buy_gem, pay_gem, modifiedAmount));

        approvalAmount = pay_amt;
        return (buy_amt, approvalAmount);
    }

    /// @return fill_amt - fill amount without fee!
    function getBuyAmount(
        IERC20 buy_gem,
        IERC20 pay_gem,
        uint256 pay_amt
    ) public view returns (uint256 fill_amt) {
        uint256 offerId = getBestOffer(buy_gem, pay_gem); //Get best offer for the token pair
        while (pay_amt > offers[offerId].buy_amt) {
            fill_amt = add(fill_amt, offers[offerId].pay_amt); //Add amount to buy accumulator
            pay_amt = sub(pay_amt, offers[offerId].buy_amt); //Decrease amount to pay
            if (pay_amt > 0) {
                //If we still need more offers
                offerId = getWorseOffer(offerId); //We look for the next best offer
                require(offerId != 0); //Fails if there are not enough offers to complete
            }
        }
        fill_amt = add(
            fill_amt,
            rmul(
                mul(pay_amt, 10 ** 9),
                rdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)
            ) / 10 ** 9
        ); //Add proportional amount of last offer to buy accumulator
    }

    /// @return pay_amt - fill with fee deducted
    /// @return approvalAmount - amount user should approve for interaction
    function getPayAmountWithFee(
        IERC20 pay_gem,
        IERC20 buy_gem,
        uint256 buy_amt
    ) public view returns (uint256 pay_amt, uint256 approvalAmount) {
        uint modifiedAmount = calculateFees(buy_amt, true);
        pay_amt = (getPayAmount(pay_gem, buy_gem, modifiedAmount));

        approvalAmount = pay_amt;
        return (pay_amt, approvalAmount);
    }

    function getPayAmount(
        IERC20 pay_gem,
        IERC20 buy_gem,
        uint256 buy_amt
    ) public view returns (uint256 fill_amt) {
        uint256 offerId = getBestOffer(buy_gem, pay_gem); //Get best offer for the token pair
        while (buy_amt > offers[offerId].pay_amt) {
            fill_amt = add(fill_amt, offers[offerId].buy_amt); //Add amount to pay accumulator
            buy_amt = sub(buy_amt, offers[offerId].pay_amt); //Decrease amount to buy
            if (buy_amt > 0) {
                //If we still need more offers
                offerId = getWorseOffer(offerId); //We look for the next best offer
                require(offerId != 0); //Fails if there are not enough offers to complete
            }
        }
        fill_amt = add(
            fill_amt,
            rmul(
                mul(buy_amt, 10 ** 9),
                rdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)
            ) / 10 ** 9
        ); //Add proportional amount of last offer to pay accumulator
    }

    // ---- Internal Functions ---- //

    function _isBlacklistedWithSelector(
        address _token,
        address _user,
        bytes4 _selector
    ) internal view returns (bool) {
        (bool success, bytes memory result) = _token.staticcall{gas: 5000}(
            abi.encodeWithSelector(_selector, _user)
        );
        return success && abi.decode(result, (bool));
    }

    function _addressIsBlacklisted(
        address _token,
        address _owner,
        address _recipient
    ) internal view returns (bool) {
        bytes4 blacklistSelector1 = bytes4(keccak256("isBlacklisted(address)"));
        bytes4 blacklistSelector2 = bytes4(keccak256("isBlackListed(address)"));

        return (_isBlacklistedWithSelector(
            _token,
            _owner,
            blacklistSelector1
        ) ||
            _isBlacklistedWithSelector(_token, _owner, blacklistSelector2) ||
            _isBlacklistedWithSelector(
                _token,
                _recipient,
                blacklistSelector1
            ) ||
            _isBlacklistedWithSelector(_token, _recipient, blacklistSelector2));
    }

    function _buys(uint256 id, uint256 amount) internal returns (bool) {
        require(buyEnabled);
        if (amount == offers[id].pay_amt) {
            if (isOfferSorted(id)) {
                //offers[id] must be removed from sorted list because all of it is bought
                _unsort(id);
            } else {
                _hide(id);
            }
        }

        require(super.buy(id, amount));

        // If offer has become dust during buy, we cancel it
        if (
            isActive(id) &&
            offers[id].pay_amt < _dust[address(offers[id].pay_gem)]
        ) {
            dustId = id; //enable current msg.sender to call cancel(id)
            cancel(id);
        }
        return true;
    }

    //find the id of the next higher offer after offers[id]
    function _find(uint256 id) internal view returns (uint256) {
        require(id > 0);

        address buy_gem = address(offers[id].buy_gem);
        address pay_gem = address(offers[id].pay_gem);
        uint256 top = _best[pay_gem][buy_gem];
        uint256 old_top = 0;

        // Find the larger-than-id order whose successor is less-than-id.
        while (top != 0 && _isPricedLtOrEq(id, top)) {
            old_top = top;
            top = _rank[top].prev;
        }
        return old_top;
    }

    //find the id of the next higher offer after offers[id]
    function _findpos(uint256 id, uint256 pos) internal view returns (uint256) {
        require(id > 0);

        // Look for an active order.
        while (pos != 0 && !isActive(pos)) {
            pos = _rank[pos].prev;
        }

        if (pos == 0) {
            //if we got to the end of list without a single active offer
            return _find(id);
        } else {
            // if we did find a nearby active offer
            // Walk the order book down from there...
            if (_isPricedLtOrEq(id, pos)) {
                uint256 old_pos;

                // Guaranteed to run at least once because of
                // the prior if statements.
                while (pos != 0 && _isPricedLtOrEq(id, pos)) {
                    old_pos = pos;
                    pos = _rank[pos].prev;
                }
                return old_pos;

                // ...or walk it up.
            } else {
                while (pos != 0 && !_isPricedLtOrEq(id, pos)) {
                    pos = _rank[pos].next;
                }
                return pos;
            }
        }
    }

    //return true if offers[low] priced less than or equal to offers[high]
    function _isPricedLtOrEq(
        uint256 low, //lower priced offer's id
        uint256 high //higher priced offer's id
    ) internal view returns (bool) {
        return
            mul(offers[low].buy_amt, offers[high].pay_amt) >=
            mul(offers[high].buy_amt, offers[low].pay_amt);
    }

    //these variables are global only because of solidity local variable limit

    //match offers with taker offer, and execute token transactions
    function _matcho(
        uint256 t_pay_amt, //taker sell how much
        IERC20 t_pay_gem, //taker sell which token
        uint256 t_buy_amt, //taker buy how much
        IERC20 t_buy_gem, //taker buy which token
        uint256 pos, //position id
        bool rounding, //match "close enough" orders?
        address owner,
        address recipient
    ) internal returns (uint256 id) {
        uint256 best_maker_id; //highest maker id
        uint256 t_buy_amt_old; //taker buy how much saved
        uint256 m_buy_amt; //maker offer wants to buy this much token
        uint256 m_pay_amt; //maker offer wants to sell this much token

        // there is at least one offer stored for token pair
        while (_best[address(t_buy_gem)][address(t_pay_gem)] > 0) {
            best_maker_id = _best[address(t_buy_gem)][address(t_pay_gem)];
            m_buy_amt = offers[best_maker_id].buy_amt;
            m_pay_amt = offers[best_maker_id].pay_amt;

            // Ugly hack to work around rounding errors. Based on the idea that
            // the furthest the amounts can stray from their "true" values is 1.
            // Ergo the worst case has t_pay_amt and m_pay_amt at +1 away from
            // their "correct" values and m_buy_amt and t_buy_amt at -1.
            // Since (c - 1) * (d - 1) > (a + 1) * (b + 1) is equivalent to
            // c * d > a * b + a + b + c + d, we write...
            if (
                mul(m_buy_amt, t_buy_amt) >
                mul(t_pay_amt, m_pay_amt) +
                    (
                        rounding
                            ? m_buy_amt + t_buy_amt + t_pay_amt + m_pay_amt
                            : 0
                    )
            ) {
                break;
            }
            // ^ The `rounding` parameter is a compromise borne of a couple days
            // of discussion.
            buy(best_maker_id, min(m_pay_amt, t_buy_amt));
            emit LogMatch(id, min(m_pay_amt, t_buy_amt));
            t_buy_amt_old = t_buy_amt;
            t_buy_amt = sub(t_buy_amt, min(m_pay_amt, t_buy_amt));
            t_pay_amt = mul(t_buy_amt, t_pay_amt) / t_buy_amt_old;

            if (t_pay_amt == 0 || t_buy_amt == 0) {
                break;
            }
        }

        if (
            t_buy_amt > 0 &&
            t_pay_amt > 0 &&
            t_pay_amt >= _dust[address(t_pay_gem)]
        ) {
            //new offer should be created
            id = super.offer(
                t_pay_amt,
                t_pay_gem,
                t_buy_amt,
                t_buy_gem,
                owner,
                recipient
            );
            //insert offer into the sorted list
            _sort(id, pos);
        }
    }

    //put offer into the sorted list
    function _sort(
        uint256 id, //maker (ask) id
        uint256 pos //position to insert into
    ) internal {
        require(isActive(id));

        IERC20 buy_gem = offers[id].buy_gem;
        IERC20 pay_gem = offers[id].pay_gem;
        uint256 prev_id; //maker (ask) id

        pos = pos == 0 ||
            offers[pos].pay_gem != pay_gem ||
            offers[pos].buy_gem != buy_gem ||
            !isOfferSorted(pos)
            ? _find(id)
            : _findpos(id, pos);

        if (pos != 0) {
            //offers[id] is not the highest offer
            //requirement below is satisfied by statements above
            //require(_isPricedLtOrEq(id, pos));
            prev_id = _rank[pos].prev;
            _rank[pos].prev = id;
            _rank[id].next = pos;
        } else {
            //offers[id] is the highest offer
            prev_id = _best[address(pay_gem)][address(buy_gem)];
            _best[address(pay_gem)][address(buy_gem)] = id;
        }

        if (prev_id != 0) {
            //if lower offer does exist
            //requirement below is satisfied by statements above
            //require(!_isPricedLtOrEq(id, prev_id));
            _rank[prev_id].next = id;
            _rank[id].prev = prev_id;
        }

        _span[address(pay_gem)][address(buy_gem)]++;
        emit LogSortedOffer(id);
    }

    // Remove offer from the sorted list (does not cancel offer)
    function _unsort(
        uint256 id //id of maker (ask) offer to remove from sorted list
    ) internal returns (bool) {
        address buy_gem = address(offers[id].buy_gem);
        address pay_gem = address(offers[id].pay_gem);
        require(_span[pay_gem][buy_gem] > 0);

        require(
            _rank[id].delb == 0 && //assert id is in the sorted list
                isOfferSorted(id)
        );

        if (id != _best[pay_gem][buy_gem]) {
            // offers[id] is not the highest offer
            require(_rank[_rank[id].next].prev == id);
            _rank[_rank[id].next].prev = _rank[id].prev;
        } else {
            //offers[id] is the highest offer
            _best[pay_gem][buy_gem] = _rank[id].prev;
        }

        if (_rank[id].prev != 0) {
            //offers[id] is not the lowest offer
            require(_rank[_rank[id].prev].next == id);
            _rank[_rank[id].prev].next = _rank[id].next;
        }

        _span[pay_gem][buy_gem]--;
        _rank[id].delb = block.number; //mark _rank[id] for deletion
        return true;
    }

    //Hide offer from the unsorted order book (does not cancel offer)
    function _hide(
        uint256 id //id of maker offer to remove from unsorted list
    ) internal returns (bool) {
        uint256 uid = _head; //id of an offer in unsorted offers list
        uint256 pre = uid; //id of previous offer in unsorted offers list

        require(!isOfferSorted(id), "offer sorted"); //make sure offer id is not in sorted offers list

        if (_head == id) {
            //check if offer is first offer in unsorted offers list
            _head = _near[id]; //set head to new first unsorted offer
            _near[id] = 0; //delete order from unsorted order list
            return true;
        }
        while (uid > 0 && uid != id) {
            //find offer in unsorted order list
            pre = uid;
            uid = _near[uid];
        }
        if (uid != id) {
            //did not find offer id in unsorted offers list
            return false;
        }
        _near[pre] = _near[id]; //set previous unsorted offer to point to offer after offer id
        _near[id] = 0; //delete order from unsorted order list
        return true;
    }

    function setFeeBPS(uint256 _newFeeBPS) external auth returns (bool) {
        feeBPS = _newFeeBPS;
        return true;
    }

    function setMakerFee(uint256 _newMakerFee) external auth returns (bool) {
        StorageSlot.getUint256Slot(MAKER_FEE_SLOT).value = _newMakerFee;
        return true;
    }

    function setFeeTo(address newFeeTo) external auth returns (bool) {
        require(newFeeTo != address(0));
        feeTo = newFeeTo;
        return true;
    }

    function getFeeTo() external view returns (address) {
        return feeTo;
    }

    // *** Admin only function to remove blacklisted offers, if needed
    /// @dev If a user places orders in the book and then later becomes blacklisted, we need a way to handle that for no DOS by removing the order
    function cancelBlacklistedOffer(uint256 id) external auth synchronized {
        OfferInfo memory _offer = offers[id];

        // owner or recipient MUST be blacklisted in buy_gem OR pay_gem
        bool isBlacklisted = _addressIsBlacklisted(
            address(_offer.pay_gem),
            _offer.owner,
            _offer.recipient
        ) ||
            _addressIsBlacklisted(
                address(_offer.buy_gem),
                _offer.owner,
                _offer.recipient
            );
        require(isBlacklisted, "neither owner nor recipient is blacklisted");

        // remove order from the sorted list
        require(_unsort(id));
        // delete offer manually
        // not returning tokens back to the bad guy
        delete offers[id];
    }
}