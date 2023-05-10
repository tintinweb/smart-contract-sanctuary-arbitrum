// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/// @title Joe V1 Pair Interface
/// @notice Interface to interact with Joe V1 Pairs
interface IJoePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

pragma solidity ^0.8.10;

import {Address} from "../libraries/Address.sol";
import {IBaseComponent} from "../interfaces/IBaseComponent.sol";

/**
 * @title Base Component
 * @author Trader Joe
 * @notice This contract is the base contract for all components of the protocol.
 * It contains the logic to restrict access from direct calls and delegate calls.
 * It also allow the fee manager to call any contract from this contract to execute different actions,
 * mainly to recover any tokens that are sent to this contract by mistake.
 */
abstract contract BaseComponent is IBaseComponent {
    using Address for address;

    address internal immutable _THIS = address(this);

    address internal immutable _FEE_MANAGER;

    /**
     * @notice Modifier to restrict access to delegate calls.
     */
    modifier onlyDelegateCall() {
        if (address(this) == _THIS) revert BaseComponent__OnlyDelegateCall();
        _;
    }

    /**
     * @notice Modifier to restrict access to direct calls.
     */
    modifier onlyDirectCall() {
        if (address(this) != _THIS) revert BaseComponent__OnlyDelegateCall();
        _;
    }

    /**
     * @notice Modifier to restrict access to the fee manager.
     */
    modifier onlyFeeManager() {
        if (msg.sender != _FEE_MANAGER) revert BaseComponent__OnlyFeeManager();
        _;
    }

    /**
     * @dev Sets the fee manager address.
     */
    constructor(address feeManager) {
        _FEE_MANAGER = feeManager;
    }

    /**
     * @notice Returns the fee manager address.
     * @return The fee manager address.
     */
    function getFeeManager() external view returns (address) {
        return _FEE_MANAGER;
    }

    /**
     * @notice Allows the fee manager to call any contract.
     * @dev Only callable by the fee manager.
     * @param target The target contract.
     * @param data The data to call.
     * @return returnData The return data from the call.
     */
    function directCall(address target, bytes calldata data)
        external
        onlyFeeManager
        onlyDirectCall
        returns (bytes memory returnData)
    {
        if (data.length == 0) {
            target.sendValue(address(this).balance);
        } else {
            returnData = target.directCall(data);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IJoePair} from "joe-v2/interfaces/IJoePair.sol";
import {SafeERC20, IERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import {BaseComponent} from "../components/BaseComponent.sol";
import {IOneInchRouter} from "../interfaces/IOneInchRouter.sol";
import {IFeeConverter} from "../interfaces/IFeeConverter.sol";

/**
 * @title Fee Converter
 * @author Trader Joe
 * @notice This contract is used to convert the protocol fees into the redistributed token and
 * send them to the receiver.
 */
contract FeeConverter is BaseComponent, IFeeConverter {
    using SafeERC20 for IERC20;

    IOneInchRouter internal constant _ONE_INCH_ROUTER = IOneInchRouter(0x1111111254EEB25477B68fb85Ed929f73A960582);

    bytes32 internal immutable _LP_CODE_HASH;
    IERC20 internal immutable _REDISTRIBUTED_TOKEN;
    address internal immutable _RECEIVER;

    /**
     * @dev Sets the redistributed token and the receiver, as well as the code hash of the v1 pair and the fee manager.
     * @param feeManager The fee manager.
     * @param v1Pair The v1 pair.
     * @param redistributedToken The redistributed token.
     * @param receiver The receiver.
     */
    constructor(address feeManager, address v1Pair, IERC20 redistributedToken, address receiver)
        BaseComponent(feeManager)
    {
        _LP_CODE_HASH = v1Pair.codehash;

        _REDISTRIBUTED_TOKEN = redistributedToken;
        _RECEIVER = receiver;
    }

    /**
     * @notice Returns the address of the 1inch router.
     * @return The address of the 1inch router.
     */
    function getOneInchRouter() external pure override returns (IOneInchRouter) {
        return _ONE_INCH_ROUTER;
    }

    /**
     * @notice Returns the address of the redistributed token.
     * @return The address of the redistributed token.
     */
    function getRedistributedToken() external view override returns (IERC20) {
        return _REDISTRIBUTED_TOKEN;
    }

    /**
     * @notice Returns the address of the receiver.
     * @return The address of the receiver.
     */
    function getReceiver() external view override returns (address) {
        return _RECEIVER;
    }

    /**
     * @notice Swaps the given token for another one using the 1inch router.
     * @param executor The address that will execute the swap.
     * @param desc The description of the swap.
     * @param data The data of the swap.
     */
    function convert(address executor, IOneInchRouter.SwapDescription calldata desc, bytes calldata data)
        external
        override
        onlyDelegateCall
    {
        _swap(executor, desc, data);
    }

    /**
     * @notice Batch swaps the given tokens for another ones using the 1inch router.
     * @param executor The address that will execute the swaps.
     * @param descs The descriptions of the swaps.
     * @param data The data of the swaps.
     */
    function batchConvert(address executor, IOneInchRouter.SwapDescription[] calldata descs, bytes[] calldata data)
        external
        override
        onlyDelegateCall
    {
        if (descs.length != data.length) revert FeeConverter__InvalidLength();

        for (uint256 i; i < descs.length;) {
            _swap(executor, descs[i], data[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Unwraps the given lp token from the fee manager and send the underlying tokens back to it.
     * @dev The lpToken must be a V1 pair.
     * @param lpToken The lpToken to unwrap.
     */
    function unwrapLpToken(address lpToken) external override onlyDelegateCall {
        _unwrapLpToken(lpToken);
    }

    /**
     * @notice Batch unwraps the given lp tokens from the fee manager and send the underlying tokens back to it.
     * @dev The lpTokens must be V1 pairs.
     * @param lpTokens The list of lpTokens to unwrap.
     */
    function batchUnwrapLpToken(address[] calldata lpTokens) external override onlyDelegateCall {
        for (uint256 i; i < lpTokens.length;) {
            _unwrapLpToken(lpTokens[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Approves the 1inch router to spend the given token and swaps it for another one.
     * @param executor The address that will execute the swap.
     * @param desc The description of the swap.
     * @param data The data of the swap.
     */
    function _swap(address executor, IOneInchRouter.SwapDescription calldata desc, bytes calldata data) private {
        if (desc.dstToken != _REDISTRIBUTED_TOKEN) revert FeeConverter__InvalidDstToken();
        if (desc.dstReceiver != _RECEIVER) revert FeeConverter__InvalidReceiver();
        if (desc.amount == 0 || desc.minReturnAmount == 0) revert FeeConverter__ZeroAmount();

        if (desc.srcToken == _REDISTRIBUTED_TOKEN) return _tranferRedistributedToken(desc.amount);

        uint256 allowance = desc.srcToken.allowance(address(this), address(_ONE_INCH_ROUTER));
        if (allowance < desc.amount) {
            if (allowance > 0) desc.srcToken.approve(address(_ONE_INCH_ROUTER), 0);
            desc.srcToken.approve(address(_ONE_INCH_ROUTER), type(uint256).max);
        }

        (uint256 amountOut, uint256 amountIn) = _ONE_INCH_ROUTER.swap(executor, desc, "", data);

        emit Swap(_RECEIVER, address(desc.srcToken), address(desc.dstToken), amountIn, amountOut);
    }

    /**
     * @dev Unwraps the given lp token from the fee manager and send the underlying tokens to it.
     * The lpToken must be a V1 pair.
     * @param lpToken The lpToken to unwrap.
     */
    function _unwrapLpToken(address lpToken) private {
        if (lpToken.codehash != _LP_CODE_HASH) revert FeeConverter__HashMismatch(lpToken);

        uint256 balance = IERC20(lpToken).balanceOf(address(this));
        if (balance == 0) revert FeeConverter__InsufficientBalance(lpToken);

        IERC20(lpToken).safeTransfer(address(lpToken), balance);
        IJoePair(lpToken).burn(address(this));
    }

    /**
     * @dev Transfers the redistributed token to the receiver.
     * @param amount The amount to transfer.
     */
    function _tranferRedistributedToken(uint256 amount) private {
        _REDISTRIBUTED_TOKEN.safeTransfer(_RECEIVER, amount);

        emit Swap(_RECEIVER, address(_REDISTRIBUTED_TOKEN), address(_REDISTRIBUTED_TOKEN), amount, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IBaseComponent {
    error BaseComponent__OnlyDelegateCall();
    error BaseComponent__OnlyFeeManager();

    function getFeeManager() external view returns (address);

    function directCall(address target, bytes calldata data) external returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {IOneInchRouter} from "./IOneInchRouter.sol";
import {IBaseComponent} from "./IBaseComponent.sol";

interface IFeeConverter is IBaseComponent {
    error FeeConverter__InvalidLength();
    error FeeConverter__HashMismatch(address lpToken);
    error FeeConverter__InsufficientBalance(address lpToken);
    error FeeConverter__InvalidReceiver();
    error FeeConverter__InvalidDstToken();
    error FeeConverter__ZeroAmount();
    error FeeConverter__InsufficientRedistributedTokenBalance();

    event Swap(
        address recipient, address indexed srcToken, address indexed dstToken, uint256 amountIn, uint256 amountOut
    );

    function getOneInchRouter() external view returns (IOneInchRouter);

    function getRedistributedToken() external view returns (IERC20);

    function getReceiver() external view returns (address);

    function convert(address executor, IOneInchRouter.SwapDescription calldata desc, bytes calldata data) external;

    function batchConvert(address executor, IOneInchRouter.SwapDescription[] calldata descs, bytes[] calldata data)
        external;

    function unwrapLpToken(address lpToken) external;

    function batchUnwrapLpToken(address[] calldata lpTokens) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

interface IOneInchRouter {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    function swap(address executor, SwapDescription calldata desc, bytes calldata permit, bytes calldata data)
        external
        payable
        returns (uint256 returnAmount, uint256 spentAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library Address {
    error Address__SendFailed();
    error Address__NonContract();
    error Address__CallFailed();

    /**
     * @dev Sends the given amount of ether to the given address, forwarding all available gas and reverting on errors.
     * @param target The address to send ether to.
     * @param value The amount of ether to send.
     */
    function sendValue(address target, uint256 value) internal {
        (bool success,) = target.call{value: value}("");
        if (!success) revert Address__SendFailed();
    }

    /**
     * @dev Calls the target contract with the given data and bubbles up errors.
     * @param target The target contract.
     * @param data The data to call the target contract with.
     * @return The return data from the call.
     */
    function directCall(address target, bytes memory data) internal returns (bytes memory) {
        return directCallWithValue(target, data, 0);
    }

    /**
     * @dev Calls the target contract with the given data and bubbles up errors.
     * @param target The target contract.
     * @param data The data to call the target contract with.
     * @param value The amount of ether to send to the target contract.
     * @return The return data from the call.
     */
    function directCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = target.call{value: value}(data);

        _catchError(target, success, returnData);

        return returnData;
    }

    /**
     * @dev Delegate calls the target contract with the given data and bubbles up errors.
     * @param target The target contract.
     * @param data The data to delegate call the target contract with.
     * @return The return data from the delegate call.
     */
    function delegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = target.delegatecall(data);

        _catchError(target, success, returnData);

        return returnData;
    }

    /**
     * @dev Bubbles up errors from the target contract, target must be a contract.
     * @param target The target contract.
     * @param success The success flag from the call.
     * @param returnData The return data from the call.
     */
    function _catchError(address target, bool success, bytes memory returnData) private view {
        if (success) {
            if (returnData.length == 0 && target.code.length == 0) {
                revert Address__NonContract();
            }
        } else {
            if (returnData.length > 0) {
                assembly {
                    revert(add(32, returnData), mload(returnData))
                }
            } else {
                revert Address__CallFailed();
            }
        }
    }
}