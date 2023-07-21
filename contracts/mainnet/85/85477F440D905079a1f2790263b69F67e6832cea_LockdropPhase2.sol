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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

interface IUniswapV2Factory {
    error IdenticalAddress();
    error ZeroAddress();
    error PairAlreadyExists();
    error OnlyFeeToSetter();

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IUniswapV2ERC20} from "./IUniswapV2ERC20.sol";

interface IUniswapV2Pair is IUniswapV2ERC20 {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

interface IUniswapV2Router01 {
    function factory() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IUniswapV2Router01} from "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    error Expired();
    error InsufficientAAmount();
    error InsufficientBAmount();
    error InsufficientOutputAmount();
    error InvalidPath();
    error ExcessiveInputAmount();

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title IAccessControlHolder
 * @notice Interface created to store reference to the access control.
 */
interface IAccessControlHolder {
    /**
     * @notice Function returns reference to IAccessControl.
     * @return IAccessControl reference to access control.
     */
    function acl() external view returns (IAccessControl);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IUniswapV2Router02} from "../dex/periphery/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "../dex/core/interfaces/IUniswapV2Pair.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ILockdrop
 * @notice  The purpose of the Lockdrop contract is to provide liquidity to the newly created dex by collecting funds from users
 */
interface ILockdrop {
    error WrongAllocationState(
        AllocationState current,
        AllocationState expected
    );

    error TimestampsIncorrect();
    error PairAlreadyCreated();

    enum AllocationState {
        NOT_STARTED,
        ALLOCATION_ONGOING,
        ALLOCATION_FINISHED
    }

    /**
     * @notice Function allows the authorized wallet to add liquidity on SpartaDEX router.
     * @param router_ Address of SpartaDexRouter.
     * @param deadline_ Deadline by which liquidity should be added.
     */
    function addTargetLiquidity(
        IUniswapV2Router02 router_,
        uint256 deadline_
    ) external;

    /**
     * @notice Function returns the newly created SpartaDexRouter.
     * @return IUniswapV2Router02 Address of the router.
     */
    function spartaDexRouter() external view returns (IUniswapV2Router02);

    /**
     * @notice Function returns the timestamp of the lockdrop start.
     * @return uint256 Start timestamp.
     */
    function lockingStart() external view returns (uint256);

    /**
     * @notice Function returns the timestamp of the lockdrop end.
     * @return uint256 End Timestamp.
     */
    function lockingEnd() external view returns (uint256);

    /**
     * @notice Function returns the timestamp of the unlocking period end.
     * @return uint256 The ending timestamp.
     */
    function unlockingEnd() external view returns (uint256);

    /**
     * @notice Function returns the amount of the tokens that correspond to the provided liquidity on SpartaDex.
     * @return uint256 Amount of LP tokens.
     */
    function initialLpTokensBalance() external view returns (uint256);

    /**
     * @notice Function returns the total reward for the lockdrop.
     * @return uint256 Total amount of reward.
     */
    function totalReward() external view returns (uint256);

    /**
     * @notice Function returns the exchange pair address for the lockdrop.
     * @return IUniswapV2Pair Address of token created on the target DEX.
     */
    function exchangedPair() external view returns (address);

    /**
     * @notice Function returns the reward of the lockdrop
     * @return IERC20 Address
     *  of reward token.
     */
    function rewardToken() external view returns (IERC20);

    /**
     * @notice Function returns time from which funds can be withdrawn if migration has not taken place.
     * @return uint256 Migration start timestamp.
     */
    function migrationEndTimestamp() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IERC20Decimals} from "../tokens/interfaces/IERC20Decimals.sol";
import {ILockdrop} from "./ILockdrop.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title ILockdropPhase2
 * @notice  The goal of LockdropPhase2 is to collect SPARTA tokens and StableCoin, which will be used to create the corresponding pair on SpartaDex.
 */
interface ILockdropPhase2 is ILockdrop {
    error RewardAlreadyTaken();
    error CannotUnlock();
    error NothingToClaim();
    error WrongLockdropState(LockdropState current, LockdropState expected);
    error OnlyLockdropPhase2ResolverAccess();
    error CannotAddLiquidity();

    event Locked(
        address indexed by,
        address indexed beneficiary,
        IERC20 indexed token,
        uint256 amount
    );

    event Unlocked(address indexed by, IERC20 indexed token, uint256 amount);

    event RewardWitdhrawn(address indexed wallet, uint256 amount);

    event TokensClaimed(address indexed wallet, uint256 amount);

    enum LockdropState {
        NOT_STARTED,
        TOKENS_ALLOCATION_LOCKING_UNLOCKING_ONGOING,
        TOKENS_ALLOCATION_LOCKING_ONGOING_UNLOCKING_FINISHED,
        TOKENS_ALLOCATION_FINISHED,
        TOKENS_EXCHANGED,
        MIGRATION_END
    }

    /**
     * @notice Function allows user to lock the certain amount of SPARTA tokens.
     * @param _amount Amount of tokens to lock.
     * @param _wallet Address of the wallet to which the blocked tokens will be assigned.
     */
    function lockSparta(uint256 _amount, address _wallet) external;

    /**
     * @notice Function allows user to lock the certain amount of StableCoin tokens.
     * @param _amount Amount of tokens to lock.
     */
    function lockStable(uint256 _amount) external;

    /**
     * @notice Function allows user to unlock already allocated StableCoin.
     * @param _amount  Amount of tokens the user want to unlock.
     */
    function unlockStable(uint256 _amount) external;

    /**
     * @notice Function allows user to unlock already allocated Sparta.
     * @param _amount  Amount of tokens the user want to unlock.
     */
    function unlockSparta(uint256 _amount) external;

    /**
     * @notice Function returns the amount of SPARTA tokens locked by the wallet.
     * @param _wallet Address for which we want to check the amount of allocated SPARTA.
     * @return uint256 Number of SPARTA tokens locked on the contract.
     */
    function walletSpartaLocked(
        address _wallet
    ) external view returns (uint256);

    /**
     * @notice Function returns the amount of Stable tokens locked by the wallet.
     * @param _wallet Address for which we want to check the amount of allocated Stable.
     * @return uint256 Amount of locked Stable coins.
     */
    function walletStableLocked(
        address _wallet
    ) external view returns (uint256);

    /**
     * @notice Function allows the user to take the corresponding amount of SPARTA/StableCoin LP token from the contract.
     */
    function claimTokens() external;

    /**
     * @notice Function allows the user to withdraw the earned reward.
     */
    function getReward() external;

    /**
     * @notice Function calculates the amount of sparta the user will get after staking particular amount of tokens.
     * @param  stableAmount Amount of StableCoin tokens.
     * @return uint256 Reward corresponding to the number of StableCoin tokens.
     */
    function calculateRewardForStable(
        uint256 stableAmount
    ) external view returns (uint256);

    /**
     * @notice Function calculates the amount of sparta a user will get after staking particular amount of tokens.
     * @param  spartaAmount Amount of SPARTA tokens.
     * @return uint256 Reward corresponding to the number of SPARTA tokens.
     */
    function calculateRewardForSparta(
        uint256 spartaAmount
    ) external view returns (uint256);

    /**
     * @notice Function calculates the reward for the given amounts of the SPARTA and the StableCoin tokens.
     * @param spartaAmount Amount of SPARTA tokens.
     * @param stableAmount Amount of StableCoin tokens.
     * @return uint256 Total reward corresponding to the amount of SPARTA and the amount of STABLE tokens.
     */
    function calculateRewardForTokens(
        uint256 spartaAmount,
        uint256 stableAmount
    ) external view returns (uint256);

    /**
     * @notice Function returns the total reward earned by the wallet.
     * @param wallet_ Address of the wallet whose reward we want to calculate.
     * @return uint256 Total reward earned by the wallet.
     */
    function calculateReward(address wallet_) external view returns (uint256);

    /**
     * @notice Function returns the current state of the lockdrop.
     * @return LockdropState State of the lockdrop.
     */
    function state() external view returns (LockdropState);

    /**
     * @notice Function calculates the amount of SPARTA/StableCoin LP tokens the user can get after providing liquidity on the SPARTA dex.
     * @param _wallet Address of the wallet of the user for whom we want to check the amount of the reward.
     * @return uint256 Amount of SPARTA/StableCoin LP tokens corresponding to the wallet.
     */
    function availableToClaim(address _wallet) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IERC20Decimals} from "../tokens/interfaces/IERC20Decimals.sol";
import {ILockdrop, IUniswapV2Router02} from "./ILockdrop.sol";
import {IAccessControl, IAccessControlHolder} from "../IAccessControlHolder.sol";
import {IUniswapV2Pair} from "../dex/core/interfaces/IUniswapV2Pair.sol";
import {ZeroAddressGuard} from "../ZeroAddressGuard.sol";
import {ZeroAmountGuard} from "../ZeroAmountGuard.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Lockdrop
 * @notice This contract is base implementation of common lockdrop functionalities.
 */
abstract contract Lockdrop is
    ILockdrop,
    IAccessControlHolder,
    ZeroAddressGuard,
    ZeroAmountGuard
{
    using SafeERC20 for IERC20;

    IUniswapV2Router02 public override spartaDexRouter;
    IAccessControl public immutable override acl;
    IERC20 public immutable override rewardToken;
    uint256 public override initialLpTokensBalance;
    uint256 public immutable override lockingStart;
    uint256 public immutable override migrationEndTimestamp;
    uint256 public immutable override lockingEnd;
    uint256 public immutable override unlockingEnd;
    uint256 public immutable override totalReward;

    /**
     * @notice Modifier verifies that the current allocation state equals the expected state.
     * @dev Modifier reverts with WrongAllocationState, when the current state is different than expected.
     * @param expected Expected state of lockdrop.
     */
    modifier onlyOnAllocationState(AllocationState expected) {
        AllocationState current = _allocationState();
        if (current != expected) {
            revert WrongAllocationState(current, expected);
        }
        _;
    }

    constructor(
        IAccessControl _acl,
        IERC20 _rewardToken,
        uint256 _lockingStart,
        uint256 _lockingEnd,
        uint256 _unlockingEnd,
        uint256 _migrationEndTimestamp,
        uint256 _totalReward
    ) notZeroAmount(_totalReward) {
        acl = _acl;
        if (
            block.timestamp > _lockingStart ||
            _lockingStart > _unlockingEnd ||
            _unlockingEnd > _lockingEnd ||
            _lockingEnd > _migrationEndTimestamp
        ) {
            revert TimestampsIncorrect();
        }
        lockingStart = _lockingStart;
        lockingEnd = _lockingEnd;
        unlockingEnd = _unlockingEnd;
        totalReward = _totalReward;
        rewardToken = _rewardToken;
        migrationEndTimestamp = _migrationEndTimestamp;
    }

    /**
     * @notice Function returns the sorted tokens used in the lockdrop.
     * @return (address, address) Sorted addresses of tokens.
     */
    // function _tokens() internal view virtual returns (address, address);

    /**
     * @notice Function returns the current allocation state.
     * @return AllocationState Current AllocationState.
     */
    function _allocationState() internal view returns (AllocationState) {
        if (block.timestamp >= lockingEnd) {
            return AllocationState.ALLOCATION_FINISHED;
        } else if (block.timestamp >= lockingStart) {
            if (rewardToken.balanceOf(address(this)) >= totalReward) {
                return AllocationState.ALLOCATION_ONGOING;
            }
        }

        return AllocationState.NOT_STARTED;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IUniswapV2Factory} from "../dex/core/interfaces/IUniswapV2Factory.sol";
import {ILockdropPhase2} from "./ILockdropPhase2.sol";
import {Lockdrop, IUniswapV2Router02, ILockdrop} from "./Lockdrop.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title LockdropPhase2
 * @notice The contract was created to raise funds in the form of Stable and SPARTA tokens,
 * which will be used to provide liquidity on Sparta DEX.
 * Users who choose to deposit a portion of their funds will be rewarded with a proportional amount of SPARTA token.
 * In addition, the user will receive a portion of the newly created liquidity tokens (proportionally to the funds deposited),
 * which will be paid out in a linear fashion over 6 months.
 */
contract LockdropPhase2 is ILockdropPhase2, Lockdrop {
    using SafeERC20 for IERC20;

    // uint256 internal constant LP_CLAIMING_DURATION = 26 * 7 days;
    uint256 internal constant LP_CLAIMING_DURATION = 1 days;
    bytes32 public constant LOCKDROP_PHASE_2_RESOLVER =
        keccak256("LOCKDROP_PHASE_2_RESOLVER");

    IERC20 public immutable sparta;
    IERC20 public immutable stable;

    uint256 public spartaTotalLocked;
    uint256 public stableTotalLocked;

    mapping(address => uint256) public override walletSpartaLocked;
    mapping(address => uint256) public override walletStableLocked;
    mapping(address => bool) public rewardTaken;
    mapping(address => uint256) public lpClaimed;

    /**
     * @notice Modifier created to check if the current state of lockdrop is as expected.
     * @dev Contract reverts with WrongLockdropState, when the state is different than expected.
     * @param expected LockdropState we should currently be in.
     */
    modifier onlyOnLockdropState(LockdropState expected) {
        LockdropState current = state();
        if (current != expected) {
            revert WrongLockdropState(current, expected);
        }
        _;
    }

    /**
     * @notice Modifier checks the signer of the message has the LOCKDROP_PHASE_2_RESOLVER role.
     * @dev Modifier reverts with OnlyLockdropPhase2ResolverAccess if the signer does not have the role.
     */
    modifier onlyLockdropPhase2Resolver() {
        if (!acl.hasRole(LOCKDROP_PHASE_2_RESOLVER, msg.sender)) {
            revert OnlyLockdropPhase2ResolverAccess();
        }
        _;
    }

    constructor(
        IAccessControl acl_,
        IERC20 sparta_,
        IERC20 stable_,
        uint256 lockingStart_,
        uint256 lockingEnd_,
        uint256 unlockingEnd_,
        uint256 migrationEndTimestamp_,
        uint256 totalReward_
    )
        Lockdrop(
            acl_,
            sparta_,
            lockingStart_,
            lockingEnd_,
            unlockingEnd_,
            migrationEndTimestamp_,
            totalReward_
        )
    {
        sparta = sparta_;
        stable = stable_;
    }

    /**
     * @inheritdoc ILockdropPhase2
     * @notice User can lock its tokens from the airdrop or reward from LockdropPhase1.
     * @dev Function reverts with WrongAllocationState if a user tries to lock the tokens before or after locking period.
     * @dev Function reverts ZeroAmount if someone tries to lock zero tokens.
     * @dev Function reverts ZeroAddress if someone tries to tokens for zero address.
     */
    function lockSparta(
        uint256 _amount,
        address _wallet
    )
        external
        onlyOnAllocationState(AllocationState.ALLOCATION_ONGOING)
        notZeroAmount(_amount)
        notZeroAddress(_wallet)
    {
        spartaTotalLocked += _amount;
        walletSpartaLocked[_wallet] += _amount;

        sparta.safeTransferFrom(msg.sender, address(this), _amount);

        emit Locked(msg.sender, _wallet, sparta, _amount);
    }

    /**
     * @inheritdoc ILockdropPhase2
     * @notice User can lock tokens directly on the contract.
     * @dev Function reverts with WrongAllocationState if a user tries to lock the tokens before or after the locking period.
     * @dev Function reverts ZeroAmount if someone tries to lock zero tokens.
     */
    function lockStable(
        uint256 _amount
    )
        external
        override
        onlyOnAllocationState(AllocationState.ALLOCATION_ONGOING)
        notZeroAmount(_amount)
    {
        stableTotalLocked += _amount;
        walletStableLocked[msg.sender] += _amount;
        stable.safeTransferFrom(msg.sender, address(this), _amount);

        emit Locked(msg.sender, msg.sender, stable, _amount);
    }

    function unlockSparta(
        uint256 _amount
    )
        external
        override
        notZeroAmount(_amount)
        onlyOnLockdropState(LockdropState.MIGRATION_END)
    {
        uint256 locked = walletSpartaLocked[msg.sender];
        if (_amount > locked) {
            revert CannotUnlock();
        }

        spartaTotalLocked -= _amount;
        walletSpartaLocked[msg.sender] -= _amount;
        sparta.safeTransfer(msg.sender, _amount);

        emit Unlocked(msg.sender, sparta, _amount);
    }

    /**
     * @inheritdoc ILockdropPhase2
     * @dev Function reverts with WrongLockdropState if a user tries to unlock the tokens before or after the unlocking period, or if the liquiidty was provided in the time range.
     * @dev Function reverts with CannotUnlock if a user tries to unlock more tokens than already locked.
     */
    function unlockStable(
        uint256 _amount
    ) external override notZeroAmount(_amount) {
        LockdropState state_ = state();
        if (
            !(state_ ==
                LockdropState.TOKENS_ALLOCATION_LOCKING_UNLOCKING_ONGOING ||
                state_ == LockdropState.MIGRATION_END)
        ) {
            revert CannotUnlock();
        }
        uint256 locked = walletStableLocked[msg.sender];
        if (_amount > locked) {
            revert CannotUnlock();
        }

        stableTotalLocked -= _amount;
        walletStableLocked[msg.sender] -= _amount;
        stable.safeTransfer(msg.sender, _amount);

        emit Unlocked(msg.sender, stable, _amount);
    }

    /**
     * @inheritdoc ILockdrop
     * @dev Function reverts with WrongLockdropState if a wallet tries to the provide liqudity before lockdrop end.
     */
    function addTargetLiquidity(
        IUniswapV2Router02 router_,
        uint256 deadline_
    )
        external
        override
        onlyOnLockdropState(LockdropState.TOKENS_ALLOCATION_FINISHED)
        onlyLockdropPhase2Resolver
    {
        if (
            IUniswapV2Factory(router_.factory()).getPair(
                address(stable),
                address(sparta)
            ) != address(0)
        ) {
            revert PairAlreadyCreated();
        }
        if (spartaTotalLocked == 0 || stableTotalLocked == 0) {
            revert CannotAddLiquidity();
        }
        sparta.forceApprove(address(router_), spartaTotalLocked);
        stable.forceApprove(address(router_), stableTotalLocked);

        spartaDexRouter = router_;

        (, , initialLpTokensBalance) = router_.addLiquidity(
            address(sparta),
            address(stable),
            spartaTotalLocked,
            stableTotalLocked,
            spartaTotalLocked,
            stableTotalLocked,
            address(this),
            deadline_
        );
    }

    /**
     * @inheritdoc ILockdropPhase2
     * @dev Function reverts with WrongLockdropState if a user tries to get tokens before the liqudity providing.
     * @dev Function reverts NothingToClaim if the sender does not have any SPARTA/StableCoin tokens to withdraw.
     */
    function claimTokens()
        external
        override
        onlyOnLockdropState(LockdropState.TOKENS_EXCHANGED)
    {
        uint256 toClaim = availableToClaim(msg.sender);
        if (toClaim == 0) {
            revert NothingToClaim();
        }
        lpClaimed[msg.sender] += toClaim;

        IERC20(exchangedPair()).safeTransfer(msg.sender, toClaim);

        emit TokensClaimed(msg.sender, toClaim);
    }

    /**
     * @inheritdoc ILockdropPhase2
     * @dev Function reverts with WrongLockdropState if a user tries to get the reward before the lockdrop end.
     * @dev Function reverts NothingToClaim if the sender does not have any reward to withdraw.
     */
    function getReward()
        external
        onlyOnLockdropState(LockdropState.TOKENS_EXCHANGED)
    {
        if (rewardTaken[msg.sender]) {
            revert RewardAlreadyTaken();
        }
        uint256 reward = calculateReward(msg.sender);
        if (reward == 0) {
            revert NothingToClaim();
        }
        rewardTaken[msg.sender] = true;
        sparta.safeTransfer(msg.sender, reward);

        emit RewardWitdhrawn(msg.sender, reward);
    }

    /**
     * @inheritdoc ILockdropPhase2
     */
    function calculateRewardForStable(
        uint256 stableAmount
    ) public view returns (uint256) {
        if (stableTotalLocked == 0) {
            return 0;
        }
        uint256 forSpartaReward = totalReward / 2;
        uint256 forStableReward = totalReward - forSpartaReward;
        return (forStableReward * stableAmount) / stableTotalLocked;
    }

    /**
     * @inheritdoc ILockdropPhase2
     */
    function calculateRewardForSparta(
        uint256 spartaAmount
    ) public view returns (uint256) {
        if (spartaTotalLocked == 0) {
            return 0;
        }
        uint256 forSpartaReward = totalReward / 2;
        return (forSpartaReward * spartaAmount) / spartaTotalLocked;
    }

    /**
     * @inheritdoc ILockdropPhase2
     */
    function calculateRewardForTokens(
        uint256 spartaAmount,
        uint256 stableAmount
    ) public view returns (uint256) {
        return
            calculateRewardForSparta(spartaAmount) +
            calculateRewardForStable(stableAmount);
    }

    /**
     * @inheritdoc ILockdropPhase2
     */
    function state() public view returns (LockdropState) {
        AllocationState allocationState = _allocationState();
        if (allocationState == AllocationState.NOT_STARTED) {
            return LockdropState.NOT_STARTED;
        } else if (allocationState == AllocationState.ALLOCATION_ONGOING) {
            if (block.timestamp > unlockingEnd) {
                return
                    LockdropState
                        .TOKENS_ALLOCATION_LOCKING_ONGOING_UNLOCKING_FINISHED;
            }
            return LockdropState.TOKENS_ALLOCATION_LOCKING_UNLOCKING_ONGOING;
        } else if (address(spartaDexRouter) == address(0)) {
            if (block.timestamp > migrationEndTimestamp) {
                return LockdropState.MIGRATION_END;
            }
            return LockdropState.TOKENS_ALLOCATION_FINISHED;
        }
        return LockdropState.TOKENS_EXCHANGED;
    }

    /**
     * @inheritdoc ILockdropPhase2
     */
    function calculateReward(
        address wallet_
    ) public view override returns (uint256) {
        return
            calculateRewardForTokens(
                walletSpartaLocked[wallet_],
                walletStableLocked[wallet_]
            );
    }

    /**
     * @inheritdoc ILockdrop
     */
    function exchangedPair()
        public
        view
        override
        onlyOnLockdropState(LockdropState.TOKENS_EXCHANGED)
        returns (address)
    {
        (address token0_, address token1_) = _tokens();

        return
            IUniswapV2Factory(spartaDexRouter.factory()).getPair(
                token0_,
                token1_
            );
    }

    /**
     * @inheritdoc ILockdropPhase2
     */
    function availableToClaim(
        address _wallet
    )
        public
        view
        onlyOnLockdropState(LockdropState.TOKENS_EXCHANGED)
        returns (uint256)
    {
        uint256 reward = calculateReward(_wallet);
        if (reward == 0) {
            return 0;
        }
        uint256 timeElapsedFromLockdropEnd = block.timestamp - lockingEnd;
        uint256 duration = timeElapsedFromLockdropEnd > LP_CLAIMING_DURATION
            ? LP_CLAIMING_DURATION
            : timeElapsedFromLockdropEnd;
        uint256 releasedFromVesting = (reward *
            initialLpTokensBalance *
            duration) / (totalReward * LP_CLAIMING_DURATION);
        return releasedFromVesting - lpClaimed[_wallet];
    }

    /**
     * @notice Function returns the sorted address of the SPARTA and StableCoin tokens.
     * @return (address, address) Sorted addresses of StableCoin and SPARTA tokens.
     */
    function _tokens() internal view returns (address, address) {
        (address spartaAddress, address stableAddress) = (
            address(sparta),
            address(stable)
        );
        return
            spartaAddress < stableAddress
                ? (spartaAddress, stableAddress)
                : (stableAddress, spartaAddress);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Decimals is IERC20 {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

/**
 * @title ZeroAddressGuard.
 * @notice This contract is responsible for ensuring that a given address is not a zero address.
 */

contract ZeroAddressGuard {
    error ZeroAddress();

    /**
     * @notice Modifier to make a function callable only when the provided address is non-zero.
     * @dev If the address is a zero address, the function reverts with ZeroAddress error.
     * @param _addr Address to be checked..
     */
    modifier notZeroAddress(address _addr) {
        _ensureIsNotZeroAddress(_addr);
        _;
    }

    /// @notice Checks if a given address is a zero address and reverts if it is.
    /// @param _addr Address to be checked.
    /// @dev If the address is a zero address, the function reverts with ZeroAddress error.
    /**
     * @notice Checks if a given address is a zero address and reverts if it is.
     * @dev     .
     * @param   _addr  .
     */
    function _ensureIsNotZeroAddress(address _addr) internal pure {
        if (_addr == address(0)) {
            revert ZeroAddress();
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

/**
 * @title ZeroAmountGuard
 * @notice This contract provides a modifier to guard against zero values in a transaction.
 */
contract ZeroAmountGuard {
    error ZeroAmount();

    /**
     * @notice Modifier ensures the amount provided is not zero.
     * param _amount The amount to check.
     * @dev If the amount is zero, the function reverts with a ZeroAmount error.
     */
    modifier notZeroAmount(uint256 _amount) {
        _ensureIsNotZero(_amount);
        _;
    }

    /**
     * @notice Function verifies that the given amount is not zero.
     * @param _amount The amount to check.
     */
    function _ensureIsNotZero(uint256 _amount) internal pure {
        if (_amount == 0) {
            revert ZeroAmount();
        }
    }
}