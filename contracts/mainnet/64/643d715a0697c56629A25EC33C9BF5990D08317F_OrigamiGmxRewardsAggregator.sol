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

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (common/access/Governable.sol)

import {GovernableBase} from "contracts/common/access/GovernableBase.sol";

/// @notice Enable a contract to be governable (eg by a Timelock contract)
abstract contract Governable is GovernableBase {
    
    constructor(address initialGovernor) {
        _init(initialGovernor);
    }

}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (common/access/GovernableBase.sol)

import {CommonEventsAndErrors} from "contracts/common/CommonEventsAndErrors.sol";

/// @notice Base contract to enable a contract to be governable (eg by a Timelock contract)
/// @dev Either implement a constructor or initializer (upgradable proxy) to set the 
abstract contract GovernableBase {
    address internal _gov;
    address internal _proposedNewGov;

    event NewGovernorProposed(address indexed previousGov, address indexed previousProposedGov, address indexed newProposedGov);
    event NewGovernorAccepted(address indexed previousGov, address indexed newGov);

    error NotGovernor();

    function _init(address initialGovernor) internal {
        if (_gov != address(0)) revert NotGovernor();
        if (initialGovernor == address(0)) revert CommonEventsAndErrors.InvalidAddress(address(0));
        _gov = initialGovernor;
    }

    /**
     * @dev Returns the address of the current governor.
     */
    function gov() external view returns (address) {
        return _gov;
    }

    /**
     * @dev Proposes a new Governor.
     * Can only be called by the current governor.
     */
    function proposeNewGov(address newProposedGov) external onlyGov {
        if (newProposedGov == address(0)) revert CommonEventsAndErrors.InvalidAddress(newProposedGov);
        emit NewGovernorProposed(_gov, _proposedNewGov, newProposedGov);
        _proposedNewGov = newProposedGov;
    }

    /**
     * @dev Caller accepts the role as new Governor.
     * Can only be called by the proposed governor
     */
    function acceptGov() external {
        if (msg.sender != _proposedNewGov) revert CommonEventsAndErrors.InvalidAddress(msg.sender);
        emit NewGovernorAccepted(_gov, msg.sender);
        _gov = msg.sender;
        delete _proposedNewGov;
    }

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGov() {
        if (msg.sender != _gov) revert NotGovernor();
        _;
    }

}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (common/access/Operators.sol)

/// @notice Inherit to add an Operator role which multiple addreses can be granted.
/// @dev Derived classes to implement addOperator() and removeOperator()
abstract contract Operators {
    /// @notice A set of addresses which are approved to run operations.
    mapping(address => bool) internal _operators;

    event AddedOperator(address indexed account);
    event RemovedOperator(address indexed account);

    error OnlyOperators(address caller);

    function operators(address _account) external view returns (bool) {
        return _operators[_account];
    }

    function _addOperator(address _account) internal {
        emit AddedOperator(_account);
        _operators[_account] = true;
    }

    /// @notice Grant `_account` the operator role
    /// @dev Derived classes to implement and add protection on who can call
    function addOperator(address _account) external virtual;

    function _removeOperator(address _account) internal {
        emit RemovedOperator(_account);
        delete _operators[_account];
    }

    /// @notice Revoke the operator role from `_account`
    /// @dev Derived classes to implement and add protection on who can call
    function removeOperator(address _account) external virtual;

    modifier onlyOperators() {
        if (!_operators[msg.sender]) revert OnlyOperators(msg.sender);
        _;
    }
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (common/CommonEventsAndErrors.sol)

/// @notice A collection of common errors thrown within the Origami contracts
library CommonEventsAndErrors {
    error InsufficientBalance(address token, uint256 required, uint256 balance);
    error InvalidToken(address token);
    error InvalidParam();
    error InvalidAddress(address addr);
    error InvalidAmount(address token, uint256 amount);
    error ExpectedNonZero();
    error Slippage(uint256 minAmountExpected, uint256 acutalAmount);
    error IsPaused();
    error UnknownExecuteError(bytes returndata);
    event TokenRecovered(address indexed to, address indexed token, uint256 amount);
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (common/FractionalAmount.sol)

import {CommonEventsAndErrors} from "./CommonEventsAndErrors.sol";

/// @notice Utilities to operate on fractional amounts of an input
/// - eg to calculate the split of rewards for fees.
library FractionalAmount {

    struct Data {
        uint128 numerator;
        uint128 denominator;
    }

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    /// @notice Return the fractional amount as basis points (ie fractional amount at precision of 10k)
    function asBasisPoints(Data storage self) internal view returns (uint256) {
        return (self.numerator * BASIS_POINTS_DIVISOR) / self.denominator;
    }

    /// @notice Helper to set the storage value with safety checks.
    function set(Data storage self, uint128 _numerator, uint128 _denominator) internal {
        if (_denominator == 0 || _numerator > _denominator) revert CommonEventsAndErrors.InvalidParam();
        self.numerator = _numerator;
        self.denominator = _denominator;
    }

    /// @notice Split an amount into two parts based on a fractional ratio
    /// eg: 333/1000 (33.3%) can be used to split an input amount of 600 into: (199, 401).
    /// @dev The numerator amount is truncated if necessary
    function split(Data storage self, uint256 inputAmount) internal view returns (uint256 amount1, uint256 amount2) {
        return split(self.numerator, self.denominator, inputAmount);
    }

    /// @notice Split an amount into two parts based on a fractional ratio
    /// eg: 333/1000 (33.3%) can be used to split an input amount of 600 into: (199, 401).
    /// @dev Overloaded version of the above, using calldata/pure to avoid a copy from storage in some scenarios
    function split(Data calldata self, uint256 inputAmount) internal pure returns (uint256 amount1, uint256 amount2) {
        return split(self.numerator, self.denominator, inputAmount);
    }

    function split(uint128 numerator, uint128 denominator, uint256 inputAmount) internal pure returns (uint256 amount1, uint256 amount2) {
        unchecked {
            amount1 = (inputAmount * numerator) / denominator;
            amount2 = inputAmount - amount1;
        }
    }
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/common/IMintableToken.sol)

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/// @notice An ERC20 token which can be minted/burnt by approved accounts
interface IMintableToken is IERC20, IERC20Permit {
    function mint(address to, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/common/IRepricingToken.sol)

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/// @notice A re-pricing token which implements the ERC20 interface.
/// Each minted RepricingToken represents 1 share.
/// 
///  pricePerShare = numShares * totalReserves / totalSupply
/// So operators can increase the totalReserves in order to increase the pricePerShare
interface IRepricingToken is IERC20, IERC20Permit {
    /// @notice The token used to track reserves for this investment
    function reserveToken() external view returns (address);

    /// @notice The fully vested reserve tokens
    /// @dev Comprised of both user deposited reserves (when new shares are issued)
    /// And also when new reserves are deposited by the protocol to increase the reservesPerShare
    /// (which vest in over time)
    function vestedReserves() external returns (uint256);

    /// @notice Extra reserve tokens deposited by the protocol to increase the reservesPerShare
    /// @dev These vest in per second over `vestingDuration`
    function pendingReserves() external returns (uint256);

    /// @notice When new reserves are added to increase the reservesPerShare, 
    /// they will vest over this duration (in seconds)
    function reservesVestingDuration() external returns (uint256);

    /// @notice The time at which any accrued pendingReserves were last moved from `pendingReserves` -> `vestedReserves`
    function lastVestingCheckpoint() external returns (uint256);

    /// @notice The current amount of fully vested reserves plus any accrued pending reserves
    function totalReserves() external view returns (uint256);

    /// @notice How many reserve tokens would one get given a single share, as of now
    function reservesPerShare() external view returns (uint256);

    /// @notice How many reserve tokens would one get given a number of shares, as of now
    function sharesToReserves(uint256 shares) external view returns (uint256);

    /// @notice How many shares would one get given a number of reserve tokens, as of now
    function reservesToShares(uint256 reserves) external view returns (uint256);

    /// @notice The accrued vs outstanding amount of pending reserve tokens which have
    /// not yet been fully vested.
    function unvestedReserves() external view returns (uint256 accrued, uint256 outstanding);

    /// @notice Add pull in and add reserve tokens, which slowly increases the pricePerShare()
    /// @dev The new amount is vested in continuously per second over an `reservesVestingDuration`
    /// starting from now.
    /// If any amount was still pending and unvested since the previous `addReserves()`, it will be carried over.
    function addPendingReserves(uint256 amount) external;

    /// @notice Checkpoint any pending reserves as long as the `reservesVestingDuration` period has completely passed.
    /// @dev No economic benefit, but may be useful for book keeping purposes.
    function checkpointReserves() external;

    /// @notice Return the current estimated APR based on the pending reserves which are vesting per second
    /// into the totalReserves.
    /// @dev APR = annual reserve token rewards / total reserves
    function apr() external view returns (uint256 aprBps);
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/investments/gmx/IOrigamiGmxEarnAccount.sol)

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {FractionalAmount} from "../../../common/FractionalAmount.sol";

interface IOrigamiGmxEarnAccount {
    // Input parameters required when claiming/compounding rewards from GMX.io
    struct HandleGmxRewardParams {
        bool shouldClaimGmx;
        bool shouldStakeGmx;
        bool shouldClaimEsGmx;
        bool shouldStakeEsGmx;
        bool shouldStakeMultiplierPoints;
        bool shouldClaimWeth;
    }

    // Rewards that Origami claimed from GMX.io
    struct ClaimedRewards {
        uint256 wrappedNativeFromGmx;
        uint256 wrappedNativeFromGlp;
        uint256 esGmxFromGmx;
        uint256 esGmxFromGlp;
        uint256 vestedGmx;
    }

    enum VaultType {
        GLP,
        GMX
    }

    /// @notice The current wrappedNative and esGMX rewards per second
    /// @dev This includes any boost to wrappedNative (ie ETH/AVAX) from staked multiplier points.
    /// @param vaultType If for GLP, get the reward rates for just staked GLP rewards. If GMX get the reward rates for combined GMX/esGMX/mult points
    /// for Origami's share of the upstream GMX.io rewards.
    function rewardRates(VaultType vaultType) external view returns (uint256 wrappedNativeTokensPerSec, uint256 esGmxTokensPerSec);

    /// @notice The amount of $esGMX and $Native (ETH/AVAX) which are claimable by Origami as of now
    /// @param vaultType If GLP, get the reward rates for just staked GLP rewards. If GMX get the reward rates for combined GMX/esGMX/mult points
    /// @dev This is composed of both the staked GMX and staked GLP rewards that this account may hold
    function harvestableRewards(VaultType vaultType) external view returns (
        uint256 wrappedNativeAmount, 
        uint256 esGmxAmount
    );

    /// @notice Harvest all rewards, and apply compounding:
    /// - Claim all wrappedNative and send to origamiGmxManager
    /// - Claim all esGMX and:
    ///     - Deposit a portion into vesting (given by `esGmxVestingRate`)
    ///     - Stake the remaining portion
    /// - Claim all GMX from vested esGMX and send to origamiGmxManager
    /// - Stake/compound any multiplier point rewards (aka bnGmx) 
    /// @dev only the OrigamiGmxManager can call since we need to track and action based on the amounts harvested.
    function harvestRewards(FractionalAmount.Data calldata _esGmxVestingRate) external returns (ClaimedRewards memory claimedRewards);

    /// @notice Pass-through handleRewards() for harvesting/compounding rewards.
    function handleRewards(HandleGmxRewardParams calldata params) external returns (ClaimedRewards memory claimedRewards);

    /// @notice Stake any $GMX that this contract holds at GMX.io
    function stakeGmx(uint256 _amount) external;

    /// @notice Unstake $GMX from GMX.io and send to the operator
    /// @dev This will burn any aggregated multiplier points, so should be avoided where possible.
    function unstakeGmx(uint256 _maxAmount) external;

    /// @notice Buy and stake $GLP using GMX.io's contracts using a whitelisted token.
    /// @dev GMX.io takes fees dependent on the pool constituents.
    function mintAndStakeGlp(
        uint256 fromAmount,
        address fromToken,
        uint256 minUsdg,
        uint256 minGlp
    ) external returns (uint256);

    /// @notice Unstake and sell $GLP using GMX.io's contracts, to a whitelisted token.
    /// @dev GMX.io takes fees dependent on the pool constituents.
    function unstakeAndRedeemGlp(
        uint256 glpAmount, 
        address toToken, 
        uint256 minOut, 
        address receiver
    ) external returns (uint256);

    /// @notice Transfer staked $GLP to another receiver. This will unstake from this contract and restake to another user.
    function transferStakedGlp(uint256 glpAmount, address receiver) external;

    /// @notice Attempt to transfer staked $GLP to another receiver. This will unstake from this contract and restake to another user.
    /// @dev If the transfer cannot happen in this transaction due to the GLP cooldown
    /// then future GLP deposits will be paused such that it can be attempted again.
    /// When the transfer succeeds in the future, deposits will be unpaused.
    function transferStakedGlpOrPause(uint256 glpAmount, address receiver) external;

    /// @notice The GMX contract which can transfer staked GLP from one user to another.
    function stakedGlp() external view returns (IERC20Upgradeable);

    /// @notice When this contract is free to exit a GLP position, a cooldown period after the latest GLP purchase
    function glpInvestmentCooldownExpiry() external view returns (uint256);

    /// @notice The last timestamp that staked GLP was transferred out of this account.
    function glpLastTransferredAt() external view returns (uint256);

    /// @notice Whether GLP purchases are currently paused
    function glpInvestmentsPaused() external view returns (bool);
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/investments/gmx/IOrigamiGmxManager.sol)

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMintableToken} from "../../common/IMintableToken.sol";
import {IOrigamiGmxEarnAccount} from "./IOrigamiGmxEarnAccount.sol";
import {IOrigamiInvestment} from "../IOrigamiInvestment.sol";

interface IOrigamiGmxManager {
    /// @notice The amount of rewards up to this block that Origami is due to distribute to users.
    /// @param vaultType If GLP, get the reward rates for just staked GLP rewards. If GMX, get the reward rates for combined GMX/esGMX/mult points
    /// ie the net amount after Origami has deducted it's fees.
    function harvestableRewards(IOrigamiGmxEarnAccount.VaultType vaultType) external view returns (uint256[] memory amounts);

    /// @notice The current native token and oGMX reward rates per second
    /// @param vaultType If GLP, get the reward rates for just staked GLP rewards. If GMX, get the reward rates for combined GMX/esGMX/mult points
    /// @dev Based on the current total Origami rewards, minus any portion of fees which we will take
    function projectedRewardRates(IOrigamiGmxEarnAccount.VaultType vaultType) external view returns (uint256[] memory amounts);

    /** 
     * @notice Harvest any claimable rewards up to this block from GMX.io, from the primary earn account.
     * 1/ Claimed esGMX:
     *     Vest a portion, and stake the rest -- according to `esGmxVestingRate` ratio
     *     Mint oGMX 1:1 for any esGMX that has been claimed.
     * 2/ Claimed GMX (from vested esGMX):
     *     Stake the GMX at GMX.io
     * 3/ Claimed ETH/AVAX
     *     Collect a portion as protocol fees and send the rest to the reward aggregators
     * 4/ Minted oGMX (from esGMX 1:1)
     *     Collect a portion as protocol fees and send the rest to the reward aggregators
     */
    function harvestRewards() external;

    /** 
     * @notice Claim any ETH/AVAX rewards from the secondary earn account,
     * and perpetually stake any esGMX/multiplier points.
     */
    function harvestSecondaryRewards() external;

    /// @notice The set of reward tokens we give to the rewards aggregator
    function rewardTokensList() external view returns (address[] memory tokens);

    /// @notice $GMX (GMX.io)
    function gmxToken() external view returns (IERC20);

    /// @notice $GLP (GMX.io)
    function glpToken() external view returns (IERC20);

    /// @notice $oGMX - The Origami ERC20 receipt token over $GMX
    /// Users get oGMX for initial $GMX deposits, and for each esGMX which Origami is rewarded,
    /// minus a fee.
    function oGmxToken() external view returns (IMintableToken);

    /// @notice $oGLP - The Origami ECR20 receipt token over $GLP
    /// Users get oGLP for initial $GLP deposits.
    function oGlpToken() external view returns (IMintableToken);

    /// @notice The set of accepted tokens which can be used to invest/exit into oGMX.
    function acceptedOGmxTokens() external view returns (address[] memory);

    /**
     * @notice Get a quote to buy the oGMX using GMX.
     * @param fromTokenAmount How much of GMX to invest with
     * @param fromToken This must be the address of the GMX token
     * @param maxSlippageBps The maximum acceptable slippage of the received investment amount
     * @param deadline The maximum deadline to execute the exit.
     * @return quoteData The quote data, including any other quote params required for this investment type. To be passed through when executing the quote.
     * @return investFeeBps [GMX.io's fee when depositing with `fromToken`]
     */
    function investOGmxQuote(
        uint256 fromTokenAmount,
        address fromToken,
        uint256 maxSlippageBps,
        uint256 deadline
    ) external view returns (
        IOrigamiInvestment.InvestQuoteData memory quoteData, 
        uint256[] memory investFeeBps
    );

    /** 
      * @notice User buys oGMX with an amount GMX.
      * @param quoteData The quote data received from investQuote()
      * @return investmentAmount The actual number of receipt tokens received, inclusive of any fees.
      */
    function investOGmx(
        IOrigamiInvestment.InvestQuoteData calldata quoteData
    ) external returns (
        uint256 investmentAmount
    );

    /**
     * @notice Get a quote to sell oGMX to GMX.
     * @param investmentTokenAmount The amount of oGMX to sell
     * @param toToken This must be the address of the GMX token
     * @param maxSlippageBps The maximum acceptable slippage of the received `toToken`
     * @param deadline The maximum deadline to execute the exit.
     * @return quoteData The quote data, including any other quote params required for this investment type. To be passed through when executing the quote.
     * @return exitFeeBps [Origami's exit fee]
     */
    function exitOGmxQuote(
        uint256 investmentTokenAmount, 
        address toToken,
        uint256 maxSlippageBps,
        uint256 deadline
    ) external view returns (
        IOrigamiInvestment.ExitQuoteData memory quoteData, 
        uint256[] memory exitFeeBps
    );

    /** 
      * @notice Sell oGMX to receive GMX. 
      * @param quoteData The quote data received from exitQuote()
      * @param recipient The receiving address of the GMX
      * @return toTokenAmount The number of GMX tokens received upon selling the oGMX.
      * @return toBurnAmount The number of oGMX to be burnt after exiting this position
      */
    function exitOGmx(
        IOrigamiInvestment.ExitQuoteData memory quoteData, 
        address recipient
    ) external returns (uint256 toTokenAmount, uint256 toBurnAmount);

    /// @notice The set of whitelisted GMX.io tokens which can be used to buy GLP (and hence oGLP)
    /// @dev Native tokens (ETH/AVAX) and using staked GLP can also be used.
    function acceptedGlpTokens() external view returns (address[] memory);

    /**
     * @notice Get a quote to buy the oGLP using one of the approved tokens, inclusive of GMX.io fees.
     * @dev The 0x0 address can be used for native chain ETH/AVAX
     * @param fromTokenAmount How much of `fromToken` to invest with
     * @param fromToken What ERC20 token to purchase with. This must be one of `acceptedInvestTokens`
     * @return quoteData The quote data, including any other quote params required for the underlying investment type. To be passed through when executing the quote.
     * @return investFeeBps [GMX.io's fee when depositing with `fromToken`]
     */
    function investOGlpQuote(
        uint256 fromTokenAmount, 
        address fromToken,
        uint256 slippageBps,
        uint256 deadline
    ) external view returns (
        IOrigamiInvestment.InvestQuoteData memory quoteData, 
        uint256[] memory investFeeBps
    );

    /** 
      * @notice User buys oGLP with an amount of one of the approved ERC20 tokens. 
      * @param fromToken The token override to invest with. May be different from the `quoteData.fromToken`
      * @param quoteData The quote data received from investQuote()
      * @return investmentAmount The actual number of receipt tokens received, inclusive of any fees.
      */
    function investOGlp(
        address fromToken,
        IOrigamiInvestment.InvestQuoteData calldata quoteData
    ) external returns (
        uint256 investmentAmount
    );

    /**
     * @notice Get a quote to sell oGLP to receive one of the accepted tokens.
     * @dev The 0x0 address can be used for native chain ETH/AVAX
     * @param investmentTokenAmount The amount of oGLP to sell
     * @param toToken The token to receive when selling. This must be one of `acceptedExitTokens`
     * @return quoteData The quote data, including any other quote params required for this investment type. To be passed through when executing the quote.
     * @return exitFeeBps [Origami's exit fee, GMX.io's fee when selling to `toToken`]
     */
    function exitOGlpQuote(
        uint256 investmentTokenAmount, 
        address toToken,
        uint256 slippageBps,
        uint256 deadline
    ) external view returns (
        IOrigamiInvestment.ExitQuoteData memory quoteData, 
        uint256[] memory exitFeeBps
    );

    /** 
      * @notice Sell oGLP to receive one of the accepted tokens. 
      * @param toToken The token override to invest with. May be different from the `quoteData.toToken`
      * @param quoteData The quote data received from exitQuote()
      * @param recipient The receiving address of the `toToken`
      * @return toTokenAmount The number of `toToken` tokens received upon selling the oGLP
      * @return toBurnAmount The number of oGLP to be burnt after exiting this position
      */
    function exitOGlp(
        address toToken,
        IOrigamiInvestment.ExitQuoteData memory quoteData, 
        address recipient
    ) external returns (uint256 toTokenAmount, uint256 toBurnAmount);

    struct Paused {
        bool glpInvestmentsPaused;
        bool gmxInvestmentsPaused;

        bool glpExitsPaused;
        bool gmxExitsPaused;
    }

    /// @notice Current status of whether investments/exits are paused
    function paused() external view returns (Paused memory);
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/investments/IOrigamiInvestment.sol)

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/**
 * @title Origami Investment
 * @notice Users invest in the underlying protocol and receive a number of this Origami investment in return.
 * Origami will apply the accepted investment token into the underlying protocol in the most optimal way.
 */
interface IOrigamiInvestment is IERC20, IERC20Permit {

    /**
     * @notice Track the depoyed version of this contract. 
     */
    function apiVersion() external pure returns (string memory);

    /**
     * @notice The underlying token this investment wraps. 
     * @dev For informational purposes only, eg integrations/FE
     * If the investment wraps a protocol without an ERC20 (eg a non-liquid staked position)
     * then this may be 0x0
     */
    function baseToken() external view returns (address);

    /** 
     * @notice Emitted when a user makes a new investment
     * @param user The user who made the investment
     * @param fromTokenAmount The number of `fromToken` used to invest
     * @param fromToken The token used to invest, one of `acceptedInvestTokens()`
     * @param investmentAmount The number of investment tokens received, after fees
     **/
    event Invested(address indexed user, uint256 fromTokenAmount, address indexed fromToken, uint256 investmentAmount);

    /**
     * @notice Emitted when a user exists a position in an investment
     * @param user The user who exited the investment
     * @param investmentAmount The number of Origami investment tokens sold
     * @param toToken The token the user exited into
     * @param toTokenAmount The number of `toToken` received, after fees
     * @param recipient The receipient address of the `toToken`s
     **/
    event Exited(address indexed user, uint256 investmentAmount, address indexed toToken, uint256 toTokenAmount, address indexed recipient);

    /// @notice Errors for unsupported functions - for example if native chain ETH/AVAX/etc isn't a vaild investment
    error Unsupported();

    /**
     * @notice The set of accepted tokens which can be used to invest.
     * If the native chain ETH/AVAX is accepted, 0x0 will also be included in this list.
     */
    function acceptedInvestTokens() external view returns (address[] memory);

    /**
     * @notice The set of accepted tokens which can be used to exit into.
     * If the native chain ETH/AVAX is accepted, 0x0 will also be included in this list.
     */
    function acceptedExitTokens() external view returns (address[] memory);

    /**
     * @notice Whether new investments are paused.
     */
    function areInvestmentsPaused() external view returns (bool);

    /**
     * @notice Whether exits are temporarily paused.
     */
    function areExitsPaused() external view returns (bool);

    /**
     * @notice Quote data required when entering into this investment.
     */
    struct InvestQuoteData {
        /// @notice The token used to invest, which must be one of `acceptedInvestTokens()`
        address fromToken;

        /// @notice The quantity of `fromToken` to invest with
        uint256 fromTokenAmount;

        /// @notice The maximum acceptable slippage of the `expectedInvestmentAmount`
        uint256 maxSlippageBps;

        /// @notice The maximum deadline to execute the transaction.
        uint256 deadline;

        /// @notice The expected amount of this Origami Investment token to receive in return
        uint256 expectedInvestmentAmount;

        /// @notice The minimum amount of this Origami Investment Token to receive after
        /// slippage has been applied.
        uint256 minInvestmentAmount;

        /// @notice Any extra quote parameters required by the underlying investment
        bytes underlyingInvestmentQuoteData;
    }

    /**
     * @notice Quote data required when exoomg this investment.
     */
    struct ExitQuoteData {
        /// @notice The amount of this investment to sell
        uint256 investmentTokenAmount;

        /// @notice The token to sell into, which must be one of `acceptedExitTokens()`
        address toToken;

        /// @notice The maximum acceptable slippage of the `expectedToTokenAmount`
        uint256 maxSlippageBps;

        /// @notice The maximum deadline to execute the transaction.
        uint256 deadline;

        /// @notice The expected amount of `toToken` to receive in return
        /// @dev Note slippage is applied to this when calling `invest()`
        uint256 expectedToTokenAmount;

        /// @notice The minimum amount of `toToken` to receive after
        /// slippage has been applied.
        uint256 minToTokenAmount;

        /// @notice Any extra quote parameters required by the underlying investment
        bytes underlyingInvestmentQuoteData;
    }

    /**
     * @notice Get a quote to buy this Origami investment using one of the accepted tokens. 
     * @dev The 0x0 address can be used for native chain ETH/AVAX
     * @param fromTokenAmount How much of `fromToken` to invest with
     * @param fromToken What ERC20 token to purchase with. This must be one of `acceptedInvestTokens`
     * @param maxSlippageBps The maximum acceptable slippage of the received investment amount
     * @param deadline The maximum deadline to execute the exit.
     * @return quoteData The quote data, including any params required for the underlying investment type.
     * @return investFeeBps Any fees expected when investing with the given token, either from Origami or from the underlying investment.
     */
    function investQuote(
        uint256 fromTokenAmount, 
        address fromToken,
        uint256 maxSlippageBps,
        uint256 deadline
    ) external view returns (
        InvestQuoteData memory quoteData, 
        uint256[] memory investFeeBps
    );

    /** 
      * @notice User buys this Origami investment with an amount of one of the approved ERC20 tokens. 
      * @param quoteData The quote data received from investQuote()
      * @return investmentAmount The actual number of this Origami investment tokens received.
      */
    function investWithToken(
        InvestQuoteData calldata quoteData
    ) external returns (
        uint256 investmentAmount
    );

    /** 
      * @notice User buys this Origami investment with an amount of native chain token (ETH/AVAX)
      * @param quoteData The quote data received from investQuote()
      * @return investmentAmount The actual number of this Origami investment tokens received.
      */
    function investWithNative(
        InvestQuoteData calldata quoteData
    ) external payable returns (
        uint256 investmentAmount
    );

    /**
     * @notice Get a quote to sell this Origami investment to receive one of the accepted tokens.
     * @dev The 0x0 address can be used for native chain ETH/AVAX
     * @param investmentAmount The number of Origami investment tokens to sell
     * @param toToken The token to receive when selling. This must be one of `acceptedExitTokens`
     * @param maxSlippageBps The maximum acceptable slippage of the received `toToken`
     * @param deadline The maximum deadline to execute the exit.
     * @return quoteData The quote data, including any params required for the underlying investment type.
     * @return exitFeeBps Any fees expected when exiting the investment to the nominated token, either from Origami or from the underlying investment.
     */
    function exitQuote(
        uint256 investmentAmount,
        address toToken,
        uint256 maxSlippageBps,
        uint256 deadline
    ) external view returns (
        ExitQuoteData memory quoteData, 
        uint256[] memory exitFeeBps
    );

    /** 
      * @notice Sell this Origami investment to receive one of the accepted tokens.
      * @param quoteData The quote data received from exitQuote()
      * @param recipient The receiving address of the `toToken`
      * @return toTokenAmount The number of `toToken` tokens received upon selling the Origami investment tokens.
      */
    function exitToToken(
        ExitQuoteData calldata quoteData,
        address recipient
    ) external returns (
        uint256 toTokenAmount
    );

    /** 
      * @notice Sell this Origami investment to native ETH/AVAX.
      * @param quoteData The quote data received from exitQuote()
      * @param recipient The receiving address of the native chain token.
      * @return nativeAmount The number of native chain ETH/AVAX/etc tokens received upon selling the Origami investment tokens.
      */
    function exitToNative(
        ExitQuoteData calldata quoteData, 
        address payable recipient
    ) external returns (
        uint256 nativeAmount
    );
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/staking/IOrigamiInvestmentManager.sol)

interface IOrigamiInvestmentManager {
    event PerformanceFeesCollected(address indexed token, uint256 amount, address indexed feeCollector);

    function rewardTokensList() external view returns (address[] memory tokens);
    function harvestRewards(bytes calldata harvestParams) external;
    function harvestableRewards() external view returns (uint256[] memory amounts);
    function projectedRewardRates(bool subtractPerformanceFees) external view returns (uint256[] memory amounts);
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/investments/IOrigamiInvestmentVault.sol)

import {IOrigamiInvestment} from "./IOrigamiInvestment.sol";
import {IRepricingToken} from "../common/IRepricingToken.sol";

/**
 * @title Origami Investment Vault
 * @notice A repricing Origami Investment. Users invest in the underlying protocol and are allocated shares.
 * Origami will apply the supplied token into the underlying protocol in the most optimal way.
 * The pricePerShare() will increase over time as upstream rewards are claimed by the protocol added to the reserves.
 * This makes the Origami Investment Vault auto-compounding.
 */
interface IOrigamiInvestmentVault is IOrigamiInvestment, IRepricingToken {
    /**
     * @notice The performance fee which Origami takes from harvested rewards before compounding into reserves.
     */
    function performanceFee() external view returns (uint128 numerator, uint128 denominator);
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (investments/gmx/OrigamiGmxRewardsAggregator.sol)

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IOrigamiInvestmentManager} from "../../interfaces/investments/IOrigamiInvestmentManager.sol";
import {IOrigamiInvestmentVault} from "../../interfaces/investments/IOrigamiInvestmentVault.sol";
import {IOrigamiGmxManager} from "../../interfaces/investments/gmx/IOrigamiGmxManager.sol";
import {IOrigamiInvestment} from "../../interfaces/investments/IOrigamiInvestment.sol";
import {IOrigamiGmxEarnAccount} from "../../interfaces/investments/gmx/IOrigamiGmxEarnAccount.sol";
import {CommonEventsAndErrors} from "../../common/CommonEventsAndErrors.sol";
import {FractionalAmount} from "../../common/FractionalAmount.sol";
import {Operators} from "../../common/access/Operators.sol";
import {Governable} from "../../common/access/Governable.sol";

/// @title Origami GMX/GLP Rewards Aggregator
/// @notice Manages the collation and selection of GMX.io rewards sources to the correct Origami investment vault.
/// ie the Origami GMX vault and the Origami GLP vault
/// @dev This implements the IOrigamiInvestmentManager interface -- the Origami GMX/GLP Rewards Distributor 
/// calls to harvest aggregated rewards.
contract OrigamiGmxRewardsAggregator is IOrigamiInvestmentManager, Governable, Operators {
    using SafeERC20 for IERC20;

    /**
     * @notice The type of vault this aggregator is for - either GLP or GMX.
     * The ovGLP vault gets compounding rewards from:
     *    1/ 'staked GLP'
     * The ovGMX vault gets compounding rewards from:
     *    2/ 'staked GMX'
     *    3/ 'staked GMX/esGMX/mult points' where that GMX/esGMX/mult points was earned from the staked GMX (2)
     *    4/ 'staked GMX/esGMX/mult points' where that GMX/esGMX/mult points was earned from the staked GLP (1)
     */
    IOrigamiGmxEarnAccount.VaultType public vaultType;

    /// @notice The Origami contract managing the holdings of staked GMX derived rewards
    /// @dev The GMX Vault needs to pick staked GMX/esGMX/mult point rewards from both GMX Manager and also GLP Manager 
    IOrigamiGmxManager public gmxManager;

    /// @notice The Origami contract managing the holdings of staked GLP derived rewards
    /// @dev The GLP Vault picks staked GLP rewards from the GLP manager. 
    /// The GMX vault picks staked GMX/esGMX/mult points from the GLP Manager
    IOrigamiGmxManager public glpManager;

    /// @notice $wrappedNative - wrapped ETH/AVAX
    IERC20 public immutable wrappedNativeToken;

    /// @notice The address of the 0x proxy for GMX <--> ETH swaps
    address public immutable zeroExProxy;

    /// @notice The set of reward tokens that the GMX manager yields to users.
    /// [ ETH/AVAX, oGMX ]
    address[] public rewardTokens;

    /// @notice The ovToken that rewards will compound into when harvested/swapped. 
    IOrigamiInvestmentVault public immutable ovToken;

    /// @notice The last timestamp that the harvest successfully ran.
    uint256 public lastHarvestedAt;

    /// @notice The address used to collect the Origami performance fees.
    address public performanceFeeCollector;

    /// @notice Parameters required when compounding ovGMX rewards
    struct HarvestGmxParams {
        /// @dev The required calldata to swap from wETH/wAVAX -> GMX
        bytes nativeToGmxSwapData;

        /// @dev The quote to invest in oGMX with GMX
        IOrigamiInvestment.InvestQuoteData oGmxInvestQuoteData;

        /// @dev How much percentage of the oGMX to add as reserves to ovGMX
        /// 10_000 == 100%
        uint256 addToReserveAmountPct;
    }

    /// @notice Parameters required when compounding ovGLP rewards
    struct HarvestGlpParams {
        /// @dev The quote to exit from oGMX -> GMX
        IOrigamiInvestment.ExitQuoteData oGmxExitQuoteData;

        /// @dev The required calldata to swap from GMX -> wETH/wAVAX
        bytes gmxToNativeSwapData;

        /// @dev The quote to invest in oGLP with wETH/wAVAX
        IOrigamiInvestment.InvestQuoteData oGlpInvestQuoteData;

        /// @dev How much of the oGLP to add as reserves to ovGLP
        /// 10_000 == 100%
        uint256 addToReserveAmountPct;
    }
    
    event OrigamiGmxManagersSet(IOrigamiGmxEarnAccount.VaultType _vaultType, address indexed gmxManager, address indexed glpManager);
    event CompoundOvGmx(HarvestGmxParams harvestParams);
    event CompoundOvGlp(HarvestGlpParams harvestParams);
    event PerformanceFeeCollectorSet(address indexed performanceFeeCollector);

    error UnknownSwapError(bytes result);

    constructor(
        address _initialGov,
        IOrigamiGmxEarnAccount.VaultType _vaultType,
        address _gmxManager,
        address _glpManager,
        address _ovToken,
        address _wrappedNativeToken,
        address _zeroExProxy,
        address _performanceFeeCollector
    ) Governable(_initialGov) {
        vaultType = _vaultType;
        gmxManager = IOrigamiGmxManager(_gmxManager);
        glpManager = IOrigamiGmxManager(_glpManager);
        rewardTokens = vaultType == IOrigamiGmxEarnAccount.VaultType.GLP
            ? glpManager.rewardTokensList() 
            : gmxManager.rewardTokensList();
        ovToken = IOrigamiInvestmentVault(_ovToken);
        wrappedNativeToken = IERC20(_wrappedNativeToken);
        zeroExProxy = _zeroExProxy;
        performanceFeeCollector = _performanceFeeCollector;

        // Set approvals for compounding
        {
            uint256 maxAllowance = type(uint256).max;
            if (_vaultType == IOrigamiGmxEarnAccount.VaultType.GLP) {
                address oGlpAddr = address(gmxManager.oGlpToken());
                wrappedNativeToken.safeIncreaseAllowance(oGlpAddr, maxAllowance);
                gmxManager.gmxToken().safeIncreaseAllowance(zeroExProxy, maxAllowance);
                IERC20(oGlpAddr).safeIncreaseAllowance(address(ovToken), maxAllowance);
            } else {
                address oGmxAddr = address(gmxManager.oGmxToken());
                wrappedNativeToken.safeIncreaseAllowance(zeroExProxy, maxAllowance);
                gmxManager.gmxToken().safeIncreaseAllowance(oGmxAddr, maxAllowance);
                IERC20(oGmxAddr).safeIncreaseAllowance(address(ovToken), maxAllowance);
            }           
        }
    }

    function addOperator(address _address) external override onlyGov {
        _addOperator(_address);
    }

    function removeOperator(address _address) external override onlyGov {
        _removeOperator(_address);
    }
    
    /// @notice Set the Origami GMX Manager contract used to apply GMX to earn rewards.
    function setOrigamiGmxManagers(
        IOrigamiGmxEarnAccount.VaultType _vaultType, 
        address _gmxManager, 
        address _glpManager
    ) external onlyGov {
        emit OrigamiGmxManagersSet(_vaultType, _gmxManager, _glpManager);
        vaultType = _vaultType;
        gmxManager = IOrigamiGmxManager(_gmxManager);
        glpManager = IOrigamiGmxManager(_glpManager);
    }

    /// @notice Set the address for where Origami performance fees are sent
    function setPerformanceFeeCollector(address _performanceFeeCollector) external onlyGov {
        emit PerformanceFeeCollectorSet(_performanceFeeCollector);
        performanceFeeCollector = _performanceFeeCollector;
    }

    /// @notice The set of reward tokens we give to the staking contract.
    /// @dev Part of the IOrigamiInvestmentManager interface
    function rewardTokensList() external view override returns (address[] memory tokens) {
        return rewardTokens;
    }

    /// @notice The amount of rewards up to this block that Origami is due to harvest ready for compounding
    /// ie the net amount after Origami has deducted it's fees.
    /// Performance fees are not deducted from these amounts.
    function harvestableRewards() external override view returns (uint256[] memory amounts) {
        // Pull the GLP manager rewards - for both GMX and GLP vaults
        amounts = glpManager.harvestableRewards(vaultType);

        // Pull the GMX manager rewards - only relevant for the GMX vault
        uint256 i;
        if (vaultType == IOrigamiGmxEarnAccount.VaultType.GMX) {
            uint256[] memory _gmxAmounts = gmxManager.harvestableRewards(vaultType);
            for (; i < rewardTokens.length; ++i) {
                amounts[i] += _gmxAmounts[i];
            }
        }

        // And also add in any not-yet-distributed harvested amounts (ie if gmxManager.harvestRewards() was called directly),
        // and sitting in this aggregator, but not yet converted & compounded
        for (i=0; i < rewardTokens.length; ++i) {
            amounts[i] += IERC20(rewardTokens[i]).balanceOf(address(this));
        }
    }

    /// @notice The current native token and oGMX reward rates per second
    /// @dev Based on the current total Origami rewards, minus any portion of performance fees which Origami receives
    /// will take.
    function projectedRewardRates(bool subtractPerformanceFees) external view override returns (uint256[] memory amounts) {
        // Pull the GLP manager rewards - for both GMX and GLP vaults
        amounts = glpManager.projectedRewardRates(vaultType);

        // Pull the GMX manager rewards - only relevant for the GMX vault
        uint256 i;
        if (vaultType == IOrigamiGmxEarnAccount.VaultType.GMX) {
            uint256[] memory _gmxAmounts = gmxManager.projectedRewardRates(vaultType);
            for (; i < rewardTokens.length; ++i) {
                amounts[i] += _gmxAmounts[i];
            }
        }

        // Remove any performance fees as users aren't due these.
        if (subtractPerformanceFees) {
            (uint128 feeNumerator, uint128 feeDenominator) = ovToken.performanceFee();
            for (i=0; i < rewardTokens.length; ++i) {
                (, amounts[i]) = FractionalAmount.split(feeNumerator, feeDenominator, amounts[i]);
            }
        } 
    }

    /**
     * @notice Harvest any Origami claimable rewards from the glpManager and gmxManager, and auto-compound
     * by converting rewards into the oToken and adding as reserves of the ovToken.
     * @dev The amount of oToken actually added as new reserves may less than the total balance held by this address,
     * in order to smooth out lumpy yield.
     * Performance fees are deducted from the amount to actually add to reserves.
     */
    function harvestRewards(bytes calldata harvestParams) external override onlyOperators {
        lastHarvestedAt = block.timestamp;

        // Pull the GLP manager rewards - for both GMX and GLP vaults
        glpManager.harvestRewards();

        // The GLP vault doesn't need to harvest from the GMX vault - it won't have any rewards.
        if (vaultType == IOrigamiGmxEarnAccount.VaultType.GMX) {
            gmxManager.harvestRewards();
            _compoundOvGmxRewards(harvestParams);
        } else {
            _compoundOvGlpRewards(harvestParams);
        }
    }

    function _compoundOvGmxRewards(bytes calldata harvestParams) internal {
        HarvestGmxParams memory params = abi.decode(harvestParams, (HarvestGmxParams));
        emit CompoundOvGmx(params);

        for (uint256 i; i < rewardTokens.length; ++i) {
            // Swap native Token to GMX
            if (rewardTokens[i] == address(wrappedNativeToken)) {
                _swapAssetToAsset0x(params.nativeToGmxSwapData);
            }
        }

        // Swap GMX -> oGMX
        IOrigamiInvestment oGmx = IOrigamiInvestment(address(gmxManager.oGmxToken()));
        oGmx.investWithToken(params.oGmxInvestQuoteData);

        // Add a percentage of all available oGMX reserves, taking a performance fee.
        uint256 reserveTokenBalance = oGmx.balanceOf(address(this));
        _addReserves(address(oGmx), reserveTokenBalance * params.addToReserveAmountPct / 10_000);
    }

    function _compoundOvGlpRewards(bytes calldata harvestParams) internal {
        HarvestGlpParams memory params = abi.decode(harvestParams, (HarvestGlpParams));
        emit CompoundOvGlp(params);

        address oGmxAddr = address(gmxManager.oGmxToken());
        IOrigamiInvestment oGmx = IOrigamiInvestment(oGmxAddr);
        
        for (uint256 i; i < rewardTokens.length; ++i) {
            if (rewardTokens[i] == oGmxAddr) {
                // Swap oGMX -> GMX 
                oGmx.exitToToken(params.oGmxExitQuoteData, address(this));

                // Swap GMX -> wrappedNativeToken
                _swapAssetToAsset0x(params.gmxToNativeSwapData);
            }
        }

        // Swap wrappedNativeToken -> oGLP
        IOrigamiInvestment oGlp = IOrigamiInvestment(address(glpManager.oGlpToken()));
        oGlp.investWithToken(params.oGlpInvestQuoteData);

        // Add a percentage of all available oGLP reserves, taking a performance fee.
        uint256 reserveTokenBalance = oGlp.balanceOf(address(this));
        _addReserves(address(oGlp), reserveTokenBalance * params.addToReserveAmountPct / 10_000);
    }

    function _addReserves(address reserveToken, uint256 totalReservesAmount) internal {
        // Collect performance fees
        (uint128 feeNumerator, uint128 feeDenominator) = ovToken.performanceFee();
        (uint256 fees, uint256 reserves) = FractionalAmount.split(feeNumerator, feeDenominator, totalReservesAmount);
        
        if (fees != 0) {
            emit PerformanceFeesCollected(reserveToken, fees, performanceFeeCollector);
            IERC20(reserveToken).safeTransfer(performanceFeeCollector, fees);
        }

        // Add the oGMX as reserves into ovToken
        if (reserves != 0) {
            ovToken.addPendingReserves(reserves);
        }
    }

    /// @notice Use external aggregators 0x to contract the swap transaction
    function _swapAssetToAsset0x(bytes memory swapData) internal {
        (bool success, bytes memory returndata) = zeroExProxy.call(swapData);
        
        if (!success) {
            if (returndata.length != 0) {
                // Look for revert reason and bubble it up if present
                // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L232
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            }
            revert UnknownSwapError(returndata);
        }
    }

    /// @notice Gov can recover tokens
    function recoverToken(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyGov {
        // Can't recover any of the reward tokens or transient conversion tokens.
        if (_token == address(wrappedNativeToken)) revert CommonEventsAndErrors.InvalidToken(_token);
        if (_token == address(gmxManager.gmxToken())) revert CommonEventsAndErrors.InvalidToken(_token);
        if (_token == address(gmxManager.oGmxToken())) revert CommonEventsAndErrors.InvalidToken(_token);
        if (_token == address(gmxManager.oGlpToken())) revert CommonEventsAndErrors.InvalidToken(_token);

        emit CommonEventsAndErrors.TokenRecovered(_to, _token, _amount);
        IERC20(_token).safeTransfer(_to, _amount);
    }
}