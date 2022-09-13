// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.7;

import "./utils/BaseRouter.sol";
import "./utils/CurveUtils.sol";
import "./utils/BalancerUtils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title RouterBalancerCurve
 * @notice swaps tokens through balancer and curve pools
 *
 *                ,.-"""-.,                       *
 *               /   ===   \                      *
 *              /  =======  \                     *
 *           __|  (o)   (0)  |__                  *
 *          / _|    .---.    |_ \                 *
 *         | /.----/ O O \----.\ |                *
 *          \/     |     |     \/                 *
 *          |                   |                 *
 *          |                   |                 *
 *          |                   |                 *
 *          _\   -.,_____,.-   /_                 *
 *      ,.-"  "-.,_________,.-"  "-.,             *
 *     /          |       |  ╭-╮     \            *
 *    |           l.     .l  ┃ ┃      |           *
 *    |            |     |   ┃ ╰━━╮   |           *
 *    l.           |     |   ┃ ╭╮ ┃  .l           *
 *     |           l.   .l   ┃ ┃┃ ┃  | \,         *
 *     l.           |   |    ╰-╯╰-╯ .l   \,       *
 *      |           |   |           |      \,     *
 *      l.          |   |          .l        |    *
 *       |          |   |          |         |    *
 *       |          |---|          |         |    *
 *       |          |   |          |         |    *
 *       /"-.,__,.-"\   /"-.,__,.-"\"-.,_,.-"\    *
 *      |            \ /            |         |   *
 *      |             |             |         |   *
 *       \__|__|__|__/ \__|__|__|__/ \_|__|__/    *
 */
contract RouterBalancerCurve is BaseRouter, CurveUtils, BalancerUtils {
    using SafeERC20 for IERC20;

    constructor(address balancerVault) BalancerUtils(balancerVault) {}

    /**
     * @dev swaps {tokenIn} for {tokenOut} through balancer, then curve
     * @param tokenIn the token to be sent, must be in the balancer pool
     * @param intermediateToken the token that will be swapped with {tokenIn} in the
     * balancer pool, then with {tokenOut} in the curve pool
     * @param tokenOut, the token to be sent to {receiver}, must be in the curve pool
     * @param curveFactory the factory that created the curve pool
     * @param curvePool the curve pool that contains {intermediateToken} and {tokenOut}
     * @param balancerPoolId the balancer pool that contains {tokenIn} and {intermediateToken}
     * @param amountIn the amount of {tokenIn} to be sent
     * @param minOut the minimum amount of {tokenOut} to be received
     * @param receiver the address that will receive {tokenOut}
     */
    function swapBalancerToCurve(
        address tokenIn,
        address intermediateToken,
        address tokenOut,
        address curveFactory,
        address curvePool,
        bytes32 balancerPoolId,
        uint256 amountIn,
        uint256 minOut,
        address receiver
    ) external {
        require(amountIn > 0, "Amount in cannot be zero");
        _transferIn(tokenIn, amountIn);

        _swapBalancerTokens(
            tokenIn,
            intermediateToken,
            amountIn,
            balancerPoolId
        );

        _swapCurveTokens(
            intermediateToken,
            tokenOut,
            _balanceOfSelf(intermediateToken),
            curveFactory,
            curvePool
        );

        uint256 amountOut = _balanceOfSelf(tokenOut);
        require(amountOut >= minOut, "Insufficient amount out");
        IERC20(tokenOut).safeTransfer(receiver, amountOut);
    }

    /**
     * @dev swaps {tokenIn} for {tokenOut} through curve, then balancer
     * @param tokenIn the token to be sent, must be in the curve pool
     * @param intermediateToken the token that will be swapped with {tokenIn} in the
     * curve pool, then with {tokenOut} in the balancer pool
     * @param tokenOut, the token to be sent to {receiver}, must be in the balancer pool
     * @param curveFactory the factory that created the curve pool
     * @param curvePool the curve pool that contains {intermediateToken} and {tokenIn}
     * @param balancerPoolId the balancer pool that contains {tokenOut} and {intermediateToken}
     * @param amountIn the amount of {tokenIn} to be sent
     * @param minOut the minimum amount of {tokenOut} to be received
     * @param receiver the address that will receive {tokenOut}
     */
    function swapCurveToBalancer(
        address tokenIn,
        address intermediateToken,
        address tokenOut,
        address curveFactory,
        address curvePool,
        bytes32 balancerPoolId,
        uint256 amountIn,
        uint256 minOut,
        address receiver
    ) external {
        require(amountIn > 0, "Amount in cannot be zero");
        _transferIn(tokenIn, amountIn);

        _swapCurveTokens(
            tokenIn,
            intermediateToken,
            amountIn,
            curveFactory,
            curvePool
        );

        _swapBalancerTokens(
            intermediateToken,
            tokenOut,
            _balanceOfSelf(intermediateToken),
            balancerPoolId
        );

        uint256 amountOut = _balanceOfSelf(tokenOut);
        require(amountOut >= minOut, "Insufficient amount out");
        IERC20(tokenOut).safeTransfer(receiver, amountOut);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract BaseRouter {
    using SafeERC20 for IERC20;

    address internal immutable _self;

    constructor() {
        _self = address(this);
    }

    /** @notice Transfers in an ERC20 token */
    function _transferIn(address token, uint256 amount) internal {
        IERC20(token).safeTransferFrom(msg.sender, _self, amount);
    }

    /** @return the {token} balance of this contract */
    function _balanceOfSelf(address token) internal view returns (uint256) {
        return IERC20(token).balanceOf(_self);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.7;

import "../interfaces/IMetapoolFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStableSwap.sol";

contract CurveUtils {
    /**
     * @notice Swaps tokens in a curve.fi metapool
     * @param from the token to be sent
     * @param to the token to be received
     * @param amount the amount of {from} to send
     * @param metapoolFactory curve.fi metapool factory (the factory that deployed {pool})
     * @param pool The metapool that has {from} and {to} as either tokens or underlying tokens
     */
    function _swapCurveTokens(
        address from,
        address to,
        uint256 amount,
        address metapoolFactory,
        address pool
    ) internal {
        (
            int128 fromIndex,
            int128 toIndex,
            bool useUnderlying
        ) = IMetapoolFactory(metapoolFactory).get_coin_indices(pool, from, to);

        IERC20(from).approve(pool, amount);

        // min out is not handled here, which is why the last param is zero
        if (useUnderlying) {
            IStableSwap(pool).exchange_underlying(
                fromIndex,
                toIndex,
                amount,
                0
            );
        } else {
            IStableSwap(pool).exchange(fromIndex, toIndex, amount, 0);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IBalancerVault.sol";

contract BalancerUtils {
    address internal constant BALANCER_ETH = address(0);
    address internal immutable balancerVault;
    address private immutable _self;

    constructor(address _balancerVault) {
        balancerVault = _balancerVault;
        _self = address(this);
    }

    /**
     * @dev swaps {from} for {to} in balancer pool with id {poolId}
     * @dev this function does not accept ETH swaps
     * @param from the token to send
     * @param to the token to receive
     * @param amount the amount of {from} to send
     * @param poolId the id of the balancer pool
     */
    function _swapBalancerTokens(
        address from,
        address to,
        uint256 amount,
        bytes32 poolId
    ) internal {
        require(
            from != BALANCER_ETH && to != BALANCER_ETH,
            "ETH swap not directly permitted"
        );

        // from self, to self, using internal balance for neither
        IBalancerVault.FundManagement memory fundManagement = IBalancerVault
            .FundManagement(_self, false, payable(_self), false);
        // amount in is given, hence SwapKind.GIVEN_IN. No user data is needed, hence "0x00"
        IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap(
            poolId,
            IBalancerVault.SwapKind.GIVEN_IN,
            from,
            to,
            amount,
            ""
        );

        // approve and perform swap
        IERC20(from).approve(balancerVault, amount);
        IBalancerVault(balancerVault).swap(
            singleSwap,
            fundManagement,
            // min out not handled in this function, so it is set to zero
            0,
            // no deadline for this swap, hence deadline is infinite
            type(uint256).max
        );
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.7;

/**
 * Documentation based on https://curve.readthedocs.io/factory-deployer.html
 */
interface IMetapoolFactory {
    /**
     * Convert coin addresses into indices for use with pool methods.
     *
     * Returns the index of _from, index of _to, and a boolean indicating
     * if the coins are considered underlying in the given pool.
     *
     * @dev Example:
     *      >>> factory.get_coin_indices(pool, token1, token2)
     *      (0, 2, true)
     *
     * Based on the above call, we know:
     *  - the index of the coin we are swapping out of is 2
     *  - the index of the coin we are swapping into is 1
     *  - the coins are considred underlying, so we must call exchange_underlying
     *
     * From this information we can perform a token swap:
     *      >>> swap = Contract('0xFD9f9784ac00432794c8D370d4910D2a3782324C')
     *      >>> swap.exchange_underlying(2, 1, 1e18, 0, {'from': alice})
     */
    function get_coin_indices(
        address pool,
        address _from,
        address _to
    )
        external
        view
        returns (
            int128,
            int128,
            bool
        );
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.7;

/**
 * Documentation based on https://curve.readthedocs.io/factory-pools.html
 */
interface IStableSwap {
    /**
     * Perform an exchange between two underlying coins.
     * Index values can be found using get_underlying_coins within the factory contract.
     *
     * @param i Index value of the underlying token to send.
     * @param j Index value of the underlying token to receive.
     * @param _dx: The amount of i being exchanged.
     * @param _min_dy: The minimum amount of j to receive. If the swap would result in
     * less, the  * transaction will revert.
     *
     * @return the amount of j received in the exchange.
     */
    function exchange(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy
    ) external returns (uint256);

    /**
     * Performs an exchange between two tokens.
     * Index values can be found using the coins public getter method,
     * or get_coins within the factory contract.
     *
     * @param i Index value of the token to send.
     * @param j Index value of the token to receive.
     * @param _dx: The amount of i being exchanged.
     * @param _min_dy: The minimum amount of j to receive. If the swap would result in
     * less, the  * transaction will revert.
     *
     * @return the amount of j received in the exchange.
     */
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy
    ) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.7;

interface IBalancerVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }
}