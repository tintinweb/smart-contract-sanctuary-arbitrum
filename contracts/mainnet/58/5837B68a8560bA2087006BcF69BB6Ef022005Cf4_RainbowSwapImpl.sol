// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library MovrErrors {
    string internal constant ADDRESS_0_PROVIDED = "ADDRESS_0_PROVIDED";
    string internal constant EMPTY_INPUT = "EMPTY_INPUT";
    string internal constant LENGTH_MISMATCH = "LENGTH_MISMATCH";
    string internal constant INVALID_VALUE = "INVALID_VALUE";
    string internal constant INVALID_AMT = "INVALID_AMT";

    string internal constant IMPL_NOT_FOUND = "IMPL_NOT_FOUND";
    string internal constant ROUTE_NOT_FOUND = "ROUTE_NOT_FOUND";
    string internal constant IMPL_NOT_ALLOWED = "IMPL_NOT_ALLOWED";
    string internal constant ROUTE_NOT_ALLOWED = "ROUTE_NOT_ALLOWED";
    string internal constant INVALID_CHAIN_DATA = "INVALID_CHAIN_DATA";
    string internal constant CHAIN_NOT_SUPPORTED = "CHAIN_NOT_SUPPORTED";
    string internal constant TOKEN_NOT_SUPPORTED = "TOKEN_NOT_SUPPORTED";
    string internal constant NOT_IMPLEMENTED = "NOT_IMPLEMENTED";
    string internal constant INVALID_SENDER = "INVALID_SENDER";
    string internal constant INVALID_BRIDGE_ID = "INVALID_BRIDGE_ID";
    string internal constant MIDDLEWARE_ACTION_FAILED =
        "MIDDLEWARE_ACTION_FAILED";
    string internal constant VALUE_SHOULD_BE_ZERO = "VALUE_SHOULD_BE_ZERO";
    string internal constant VALUE_SHOULD_NOT_BE_ZERO = "VALUE_SHOULD_NOT_BE_ZERO";
    string internal constant VALUE_NOT_ENOUGH = "VALUE_NOT_ENOUGH";
    string internal constant VALUE_NOT_EQUAL_TO_AMOUNT = "VALUE_NOT_EQUAL_TO_AMOUNT";
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../MiddlewareImplBase.sol";
import "../helpers/errors.sol";

/**
// @title 0X Implementation
// @notice Called by the registry before cross chain transfers if the user requests
// for a swap
// @dev Follows the interface of Swap Impl Base
// @author Movr Network
*/
contract ZeroXSwapImpl is MiddlewareImplBase {
    using SafeERC20 for IERC20;
    address payable public zeroXExchangeProxy;
    event UpdateZeroXExchangeProxyAddress(address indexed zeroXExchangeProxy);
    event AmountRecieved(
        uint256 amount,
        address tokenAddress,
        address receiver
    );
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// one inch aggregator contract is payable to allow ethereum swaps
    constructor(address registry, address _zeroXExchangeProxy)
        MiddlewareImplBase(registry)
    {
        zeroXExchangeProxy = payable(_zeroXExchangeProxy);
    }

    /// @notice Sets zeroXExchangeProxy address
    /// @param _zeroXExchangeProxy is the address for oneInchAggreagtor
    function setZeroXExchangeProxy(address _zeroXExchangeProxy)
        external
        onlyOwner
    {
        zeroXExchangeProxy = payable(_zeroXExchangeProxy);
        emit UpdateZeroXExchangeProxyAddress(zeroXExchangeProxy);
        (_zeroXExchangeProxy);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
    // @notice Function responsible for swapping from one token to a different token
    // @dev This is called only when there is a request for a swap. 
    // @param from userAddress or sending address.
    // @param fromToken token to be swapped
    // @param amount amount to be swapped 
    // param to not required. This is there only to follow the MiddlewareImplBase
    // @param swapExtraData data required for zeroX Exchange to get the swap done
    */
    function performAction(
        address from,
        address fromToken,
        uint256 amount,
        address receiverAddress, // receiverAddress
        bytes memory swapExtraData
    ) external payable override onlyRegistry returns (uint256) {
        require(fromToken != address(0), MovrErrors.ADDRESS_0_PROVIDED);
        (address payable toTokenAddress, bytes memory swapCallData) = abi
            .decode(swapExtraData, (address, bytes));

        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        if (toTokenAddress != NATIVE_TOKEN_ADDRESS)
            _initialBalanceTokenOut = IERC20(toTokenAddress).balanceOf(
                address(this)
            );
        else _initialBalanceTokenOut = address(this).balance;

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            IERC20(fromToken).safeTransferFrom(from, address(this), amount);
            IERC20(fromToken).safeIncreaseAllowance(zeroXExchangeProxy, amount);

            // solhint-disable-next-line
            (bool success, ) = zeroXExchangeProxy.call(swapCallData);
            IERC20(fromToken).safeApprove(zeroXExchangeProxy, 0);
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
        } else {
            (bool success, ) = zeroXExchangeProxy.call{value: amount}(
                swapCallData
            );
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
        }
        if (toTokenAddress != NATIVE_TOKEN_ADDRESS)
            _finalBalanceTokenOut = IERC20(toTokenAddress).balanceOf(
                address(this)
            );
        else _finalBalanceTokenOut = address(this).balance;

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;
        if (toTokenAddress == NATIVE_TOKEN_ADDRESS)
            payable(receiverAddress).transfer(returnAmount);
        else IERC20(toTokenAddress).transfer(receiverAddress, returnAmount);
        return returnAmount;
    }

    /**
    // @notice Function responsible for swapping from one token to a different token directly
    // @dev This is called only when there is a request for a swap. 
    // @param fromToken token to be swapped
    // @param amount amount to be swapped 
    // @param swapExtraData data required for the one inch aggregator to get the swap done
    */
    function performDirectAction(
        address fromToken,
        address toToken,
        address receiver,
        uint256 amount,
        bytes memory swapExtraData
    ) external payable {
        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        if (toToken != NATIVE_TOKEN_ADDRESS)
            _initialBalanceTokenOut = IERC20(toToken).balanceOf(address(this));
        else _initialBalanceTokenOut = address(this).balance;

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            IERC20(fromToken).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
            IERC20(fromToken).safeIncreaseAllowance(zeroXExchangeProxy, amount);

            // solhint-disable-next-line
            (bool success, ) = zeroXExchangeProxy.call(swapExtraData);
            IERC20(fromToken).safeApprove(zeroXExchangeProxy, 0);
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
        } else {
            (bool success, ) = zeroXExchangeProxy.call{value: amount}(
                swapExtraData
            );
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
        }

        if (toToken != NATIVE_TOKEN_ADDRESS)
            _finalBalanceTokenOut = IERC20(toToken).balanceOf(address(this));
        else _finalBalanceTokenOut = address(this).balance;

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;
        if (toToken == NATIVE_TOKEN_ADDRESS)
            payable(receiver).transfer(returnAmount);
        else IERC20(toToken).transfer(receiver, returnAmount);
        emit AmountRecieved(returnAmount, toToken, receiver);
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
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./helpers/errors.sol";

/**
// @title Abstract Contract for middleware services.
// @notice All middleware services will follow this interface. 
*/
abstract contract MiddlewareImplBase is Ownable {
    using SafeERC20 for IERC20;
    address public immutable registry;

    /// @notice only registry address is required.
    constructor(address _registry) Ownable() {
        registry = _registry;
    }

    modifier onlyRegistry() {
        require(msg.sender == registry, MovrErrors.INVALID_SENDER);
        _;
    }

    function performAction(
        address from,
        address fromToken,
        uint256 amount,
        address receiverAddress,
        bytes memory data
    ) external payable virtual returns (uint256);

    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(userAddress, amount);
    }

    function rescueEther(address payable userAddress, uint256 amount)
        external
        onlyOwner
    {
        userAddress.transfer(amount);
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
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../MiddlewareImplBase.sol";
import "../interfaces/refuel.sol";
import "../helpers/errors.sol";

/**
// @title 0X Implementation with refuel
// @notice Called by the registry before cross chain transfers if the user requests
// for a swap
// @dev Follows the interface of Swap Impl Base
// @author Movr Network
*/
contract ZeroXRefuelImpl is MiddlewareImplBase {
    using SafeERC20 for IERC20;
    address payable public zeroXExchangeProxy;
    IRefuel public router;
    event UpdateZeroXExchangeProxyAddress(address indexed zeroXExchangeProxy);
    event AmountRecieved(
        uint256 amount,
        address tokenAddress,
        address receiver
    );
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// one inch aggregator contract is payable to allow ethereum swaps
    constructor(
        address registry,
        address _zeroXExchangeProxy,
        IRefuel _router
    ) MiddlewareImplBase(registry) {
        zeroXExchangeProxy = payable(_zeroXExchangeProxy);
        router = _router;
    }

    /// @notice Sets zeroXExchangeProxy address
    /// @param _zeroXExchangeProxy is the address for oneInchAggreagtor
    function setZeroXExchangeProxy(address _zeroXExchangeProxy)
        external
        onlyOwner
    {
        zeroXExchangeProxy = payable(_zeroXExchangeProxy);
        emit UpdateZeroXExchangeProxyAddress(zeroXExchangeProxy);
        (_zeroXExchangeProxy);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
    // @notice Function responsible for swapping from one token to a different token
    // @dev This is called only when there is a request for a swap. 
    // @param from userAddress or sending address.
    // @param fromToken token to be swapped
    // @param amount amount to be swapped 
    // param to not required. This is there only to follow the MiddlewareImplBase
    // @param extraData data required for zeroX Exchange to get the swap done
    */
    function performAction(
        address from,
        address fromToken,
        uint256 amount,
        address receiverAddress, 
        bytes calldata extraData
    ) external payable override onlyRegistry returns (uint256) {
        require(fromToken != address(0), MovrErrors.ADDRESS_0_PROVIDED);

        (
            uint256 _destinationChainId,
            address _destionationReceiverAddress,
            uint256 _refuelAmount,
            address payable toTokenAddress,
            bytes memory swapCallData
        ) = abi.decode(extraData, (uint256, address , uint256, address, bytes));

        // if _refuelAmount is greater than 0, then we perform refuel step

        if (_refuelAmount > 0)
            router.depositNativeToken{value: _refuelAmount}(
                _destinationChainId,
              _destionationReceiverAddress
            );

        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        if (toTokenAddress != NATIVE_TOKEN_ADDRESS)
            _initialBalanceTokenOut = IERC20(toTokenAddress).balanceOf(
                address(this)
            );
        else _initialBalanceTokenOut = address(this).balance;

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            IERC20 fromTokenInstance = IERC20(fromToken);
            fromTokenInstance.safeTransferFrom(from, address(this), amount);
            fromTokenInstance.safeIncreaseAllowance(zeroXExchangeProxy, amount);

            // solhint-disable-next-line
            (bool success, ) = zeroXExchangeProxy.call(swapCallData);
            fromTokenInstance.safeApprove(zeroXExchangeProxy, 0);
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
        } else {
            (bool success, ) = zeroXExchangeProxy.call{value: amount}(
                swapCallData
            );
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
        }
        if (toTokenAddress != NATIVE_TOKEN_ADDRESS)
            _finalBalanceTokenOut = IERC20(toTokenAddress).balanceOf(
                address(this)
            );
        else _finalBalanceTokenOut = address(this).balance;

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;
        if (toTokenAddress == NATIVE_TOKEN_ADDRESS)
            payable(receiverAddress).transfer(returnAmount);
        else IERC20(toTokenAddress).transfer(receiverAddress, returnAmount);
        return returnAmount;
    }

    /**
    // @notice Function responsible for swapping from one token to a different token directly
    // @dev This is called only when there is a request for a swap. 
    // @param fromToken token to be swapped
    // @param amount amount to be swapped 
    // @param extraData data required for the one inch aggregator to get the swap done
    */
    function performDirectAction(
        address fromToken,
        address toToken,
        address receiver,
        uint256 amount,
        bytes calldata extraData
    ) external payable {
        (
            uint256 _destinationChainId,
            uint256 _refuelAmount,
            bytes memory swapExtraData
        ) = abi.decode(extraData, (uint256, uint256, bytes));

        // if _refuelAmount is greater than 0, then we perform refuel step

        if (_refuelAmount > 0)
            router.depositNativeToken{value: _refuelAmount}(
                _destinationChainId,
                receiver
            );

        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        if (toToken != NATIVE_TOKEN_ADDRESS)
            _initialBalanceTokenOut = IERC20(toToken).balanceOf(address(this));
        else _initialBalanceTokenOut = address(this).balance;

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            IERC20 fromTokenInstance = IERC20(fromToken);
            fromTokenInstance.safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
            fromTokenInstance.safeIncreaseAllowance(zeroXExchangeProxy, amount);

            // solhint-disable-next-line
            (bool success, ) = zeroXExchangeProxy.call(swapExtraData);
            fromTokenInstance.safeApprove(zeroXExchangeProxy, 0);
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
        } else {
            (bool success, ) = zeroXExchangeProxy.call{value: amount}(
                swapExtraData
            );
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
        }

        if (toToken != NATIVE_TOKEN_ADDRESS)
            _finalBalanceTokenOut = IERC20(toToken).balanceOf(address(this));
        else _finalBalanceTokenOut = address(this).balance;

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;
        if (toToken == NATIVE_TOKEN_ADDRESS)
            payable(receiver).transfer(returnAmount);
        else IERC20(toToken).transfer(receiver, returnAmount);
        emit AmountRecieved(returnAmount, toToken, receiver);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface IRefuel {
    function depositNativeToken(uint256 destinationChainId, address _to) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../MiddlewareImplBase.sol";
import "../interfaces/refuel.sol";
import "../helpers/errors.sol";

/**
// @title Rainbow Swap Implementation with refuel
// @notice Called by the registry before cross chain transfers if the user requests
// for a swap
// @dev Follows the interface of Swap Impl Base
// @author Movr Network
*/
contract RainbowSwapRefuelImpl is MiddlewareImplBase {
    using SafeERC20 for IERC20;
    address payable public rainbowSwapAggregator;
    IRefuel public router;
    event UpdateRainbowSwapAggregatorAddress(
        address indexed rainbowSwapAggregator
    );
    event AmountRecieved(
        uint256 amount,
        address tokenAddress,
        address receiver
    );
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// rainbow swap aggregator contract is payable to allow ethereum swaps
    constructor(
        address registry,
        address _rainbowSwapAggregator,
        IRefuel _router
    ) MiddlewareImplBase(registry) {
        rainbowSwapAggregator = payable(_rainbowSwapAggregator);
        router = _router;
    }

    /// @notice Sets rainbowSwapAggregator address
    /// @param _rainbowSwapAggregator is the address for rainbowSwapAggregator
    function setRainbowSwapAggregator(address _rainbowSwapAggregator)
        external
        onlyOwner
    {
        rainbowSwapAggregator = payable(_rainbowSwapAggregator);
        emit UpdateRainbowSwapAggregatorAddress(rainbowSwapAggregator);
        (_rainbowSwapAggregator);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
    // @notice Function responsible for swapping from one token to a different token
    // @dev This is called only when there is a request for a swap. 
    // @param from userAddress or sending address.
    // @param fromToken token to be swapped
    // @param amount amount to be swapped 
    // param to not required. This is there only to follow the MiddlewareImplBase
    // @param extraData data required for rainbow swap to get the swap done
    */
    function performAction(
        address from,
        address fromToken,
        uint256 amount,
        address receiverAddress,
        bytes calldata extraData
    ) external payable override onlyRegistry returns (uint256) {
        require(fromToken != address(0), MovrErrors.ADDRESS_0_PROVIDED);

        (
            uint256 _destinationChainId,
            address _destionationReceiverAddress,
            uint256 _refuelAmount,
            address payable toTokenAddress,
            bytes memory swapCallData
        ) = abi.decode(extraData, (uint256, address, uint256, address, bytes));

        // if _refuelAmount is greater than 0, then we perform refuel step

        if (_refuelAmount > 0)
            router.depositNativeToken{value: _refuelAmount}(
                _destinationChainId,
                _destionationReceiverAddress
            );

        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        if (toTokenAddress != NATIVE_TOKEN_ADDRESS)
            _initialBalanceTokenOut = IERC20(toTokenAddress).balanceOf(
                address(this)
            );
        else _initialBalanceTokenOut = address(this).balance;

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            IERC20 fromTokenInstance = IERC20(fromToken);
            fromTokenInstance.safeTransferFrom(from, address(this), amount);
            fromTokenInstance.safeIncreaseAllowance(
                rainbowSwapAggregator,
                amount
            );

            // solhint-disable-next-line
            (bool success, ) = rainbowSwapAggregator.call(swapCallData);
            fromTokenInstance.safeApprove(rainbowSwapAggregator, 0);
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
        } else {
            (bool success, ) = rainbowSwapAggregator.call{value: amount}(
                swapCallData
            );
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
        }
        if (toTokenAddress != NATIVE_TOKEN_ADDRESS)
            _finalBalanceTokenOut = IERC20(toTokenAddress).balanceOf(
                address(this)
            );
        else _finalBalanceTokenOut = address(this).balance;

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;
        if (toTokenAddress == NATIVE_TOKEN_ADDRESS)
            payable(receiverAddress).transfer(returnAmount);
        else IERC20(toTokenAddress).transfer(receiverAddress, returnAmount);
        return returnAmount;
    }

    /**
    // @notice Function responsible for swapping from one token to a different token directly
    // @dev This is called only when there is a request for a swap. 
    // @param fromToken token to be swapped
    // @param amount amount to be swapped 
    // @param extraData data required for the one inch aggregator to get the swap done
    */
    function performDirectAction(
        address fromToken,
        address toToken,
        address receiver,
        uint256 amount,
        bytes calldata extraData
    ) external payable {
        (
            uint256 _destinationChainId,
            uint256 _refuelAmount,
            bytes memory swapExtraData
        ) = abi.decode(extraData, (uint256, uint256, bytes));

        // if _refuelAmount is greater than 0, then we perform refuel step

        if (_refuelAmount > 0)
            router.depositNativeToken{value: _refuelAmount}(
                _destinationChainId,
                receiver
            );

        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        if (toToken != NATIVE_TOKEN_ADDRESS)
            _initialBalanceTokenOut = IERC20(toToken).balanceOf(address(this));
        else _initialBalanceTokenOut = address(this).balance;

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            IERC20 fromTokenInstance = IERC20(fromToken);
            fromTokenInstance.safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
            fromTokenInstance.safeIncreaseAllowance(
                rainbowSwapAggregator,
                amount
            );

            // solhint-disable-next-line
            (bool success, ) = rainbowSwapAggregator.call(swapExtraData);
            fromTokenInstance.safeApprove(rainbowSwapAggregator, 0);
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
        } else {
            (bool success, ) = rainbowSwapAggregator.call{value: amount}(
                swapExtraData
            );
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
        }

        if (toToken != NATIVE_TOKEN_ADDRESS)
            _finalBalanceTokenOut = IERC20(toToken).balanceOf(address(this));
        else _finalBalanceTokenOut = address(this).balance;

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;
        if (toToken == NATIVE_TOKEN_ADDRESS)
            payable(receiver).transfer(returnAmount);
        else IERC20(toToken).transfer(receiver, returnAmount);
        emit AmountRecieved(returnAmount, toToken, receiver);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../MiddlewareImplBase.sol";
import "../interfaces/refuel.sol";
import "../helpers/errors.sol";

/**
// @title One Inch Swap Implementation
// @notice Called by the registry before cross chain transfers if the user requests
// for a swap
// @dev Follows the interface of Swap Impl Base
// @author Movr Network
*/
contract OneInchRefuelSwapImpl is MiddlewareImplBase {
    using SafeERC20 for IERC20;
    address payable public oneInchAggregator;
    IRefuel public router;
    event UpdateOneInchAggregatorAddress(address indexed oneInchAggregator);
    event AmountRecieved(
        uint256 amount,
        address tokenAddress,
        address receiver
    );
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// one inch aggregator contract is payable to allow ethereum swaps
    constructor(
        address registry,
        address _oneInchAggregator,
        IRefuel _router
    ) MiddlewareImplBase(registry) {
        oneInchAggregator = payable(_oneInchAggregator);
        router = _router;
    }

    /// @notice Sets oneInchAggregator address
    /// @param _oneInchAggregator is the address for oneInchAggreagtor
    function setOneInchAggregator(address _oneInchAggregator)
        external
        onlyOwner
    {
        oneInchAggregator = payable(_oneInchAggregator);
        emit UpdateOneInchAggregatorAddress(_oneInchAggregator);
    }

    /**
    // @notice Function responsible for swapping from one token to a different token
    // @dev This is called only when there is a request for a swap. 
    // @param from userAddress or sending address.
    // @param fromToken token to be swapped
    // @param amount amount to be swapped 
    // param to not required. This is there only to follow the MiddlewareImplBase
    // @param extraData data required for the one inch aggregator to get the swap done
    */
    function performAction(
        address from,
        address fromToken,
        uint256 amount,
        address,
        bytes calldata extraData
    ) external payable override onlyRegistry returns (uint256) {
        require(fromToken != address(0), MovrErrors.ADDRESS_0_PROVIDED);
        (
            uint256 _destinationChainId,
            address _destionationReceiverAddress,
            uint256 _refuelAmount,
            bytes memory swapExtraData
        ) = abi.decode(extraData, (uint256, address, uint256, bytes));

        // if _refuelAmount is greater than 0, then we perform refuel step

        if (_refuelAmount > 0)
            router.depositNativeToken{value: _refuelAmount}(
                _destinationChainId,
                _destionationReceiverAddress
            );

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            IERC20 fromTokenInstance = IERC20(fromToken);
            fromTokenInstance.safeTransferFrom(from, address(this), amount);
            fromTokenInstance.safeIncreaseAllowance(oneInchAggregator, amount);
            {
                // solhint-disable-next-line
                (bool success, bytes memory result) = oneInchAggregator.call(
                    swapExtraData
                );
                fromTokenInstance.safeApprove(oneInchAggregator, 0);
                require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
                (uint256 returnAmount, ) = abi.decode(
                    result,
                    (uint256, uint256)
                );
                return returnAmount;
            }
        } else {
            (bool success, bytes memory result) = oneInchAggregator.call{
                value: amount
            }(swapExtraData);
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
            (uint256 returnAmount, ) = abi.decode(result, (uint256, uint256));
            return returnAmount;
        }
    }

    /**
    // @notice Function responsible for swapping from one token to a different token directly
    // @dev This is called only when there is a request for a swap. 
    // @param fromToken token to be swapped
    // @param amount amount to be swapped 
    // @param extraData data required for the one inch aggregator to get the swap done
    */
    function performDirectAction(
        address fromToken,
        address toToken,
        address receiver,
        uint256 amount,
        bytes calldata extraData
    ) external payable {
        (
            uint256 _destinationChainId,
            uint256 _refuelAmount,
            bytes memory swapExtraData
        ) = abi.decode(extraData, (uint256, uint256, bytes));

        // if _refuelAmount is greater than 0, then we perform refuel step

        if (_refuelAmount > 0)
            router.depositNativeToken{value: _refuelAmount}(
                _destinationChainId,
                receiver
            );

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            IERC20 fromTokenInstance = IERC20(fromToken);
            fromTokenInstance.safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
            fromTokenInstance.safeIncreaseAllowance(oneInchAggregator, amount);
            {
                // solhint-disable-next-line
                (bool success, bytes memory result) = oneInchAggregator.call(
                    swapExtraData
                );
                fromTokenInstance.safeApprove(oneInchAggregator, 0);
                require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
                (uint256 returnAmount, ) = abi.decode(
                    result,
                    (uint256, uint256)
                );
                emit AmountRecieved(returnAmount, toToken, receiver);
            }
        } else {
            (bool success, bytes memory result) = oneInchAggregator.call{
                value: amount
            }(swapExtraData);
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
            (uint256 returnAmount, ) = abi.decode(result, (uint256, uint256));
            emit AmountRecieved(returnAmount, toToken, receiver);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../MiddlewareImplBase.sol";
import "../interfaces/refuel.sol";
import "../helpers/errors.sol";

/**
// @title Refuel Implementation
// @notice Called by the registry before cross chain transfers if the user requests
// for a refuel
// @dev Follows the interface of Swap Impl Base
// @author Socket Technology
*/
contract RefuelImpl is MiddlewareImplBase {
    IRefuel public router;
    using SafeERC20 for IERC20;
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    constructor(IRefuel _router, address registry)
        MiddlewareImplBase(registry)
    {
        router = _router;
    }

    function performAction(
        address from,
        address fromToken,
        uint256 amount,
        address registry,
        bytes calldata extraData
    ) external payable override onlyRegistry returns (uint256) {
        if (fromToken != NATIVE_TOKEN_ADDRESS)
            IERC20(fromToken).safeTransferFrom(from, registry, amount);
        else payable(registry).transfer(amount);

        (
            uint256 refuelAmount,
            uint256 destinationChainId,
            address receiverAddress
        ) = abi.decode(extraData, (uint256, uint256, address));
        router.depositNativeToken{value: refuelAmount}(
            destinationChainId,
            receiverAddress
        );
        return amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../MiddlewareImplBase.sol";
import "../helpers/errors.sol";

/**
// @title Rainbow Swap Implementation
// @notice Called by the registry before cross chain transfers if the user requests
// for a swap
// @dev Follows the interface of Swap Impl Base
// @author Socket - reddyismav
*/
contract RainbowSwapImpl is MiddlewareImplBase {
    using SafeERC20 for IERC20;
    address payable public rainbowSwapAggregator;
    event UpdateRainbowSwapAggregatorAddress(
        address indexed rainbowSwapAggregator
    );
    event AmountRecieved(
        uint256 amount,
        address tokenAddress,
        address receiver
    );
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// rainbow swap aggregator contract is payable to allow ethereum swaps
    constructor(address registry, address _rainbowSwapAggregator)
        MiddlewareImplBase(registry)
    {
        rainbowSwapAggregator = payable(_rainbowSwapAggregator);
    }

    /// @notice Sets _rainbowSwapAggregator address
    /// @param _rainbowSwapAggregator is the address for rainbowSwapAggregator
    function setRainbowSwapAggregator(address _rainbowSwapAggregator)
        external
        onlyOwner
    {
        rainbowSwapAggregator = payable(_rainbowSwapAggregator);
        emit UpdateRainbowSwapAggregatorAddress(_rainbowSwapAggregator);
        (_rainbowSwapAggregator);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
    // @notice Function responsible for swapping from one token to a different token
    // @dev This is called only when there is a request for a swap. 
    // @param from userAddress or sending address.
    // @param fromToken token to be swapped
    // @param amount amount to be swapped 
    // param to not required. This is there only to follow the MiddlewareImplBase
    // @param swapExtraData data required for rainbowSwapAggregator to get the swap done
    */
    function performAction(
        address from,
        address fromToken,
        uint256 amount,
        address receiverAddress, // receiverAddress
        bytes memory swapExtraData
    ) external payable override onlyRegistry returns (uint256) {
        require(fromToken != address(0), MovrErrors.ADDRESS_0_PROVIDED);
        (address payable toTokenAddress, bytes memory swapCallData) = abi
            .decode(swapExtraData, (address, bytes));

        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        if (toTokenAddress != NATIVE_TOKEN_ADDRESS)
            _initialBalanceTokenOut = IERC20(toTokenAddress).balanceOf(
                address(this)
            );
        else _initialBalanceTokenOut = address(this).balance;

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            IERC20(fromToken).safeTransferFrom(from, address(this), amount);
            IERC20(fromToken).safeIncreaseAllowance(
                rainbowSwapAggregator,
                amount
            );

            // solhint-disable-next-line
            (bool success, ) = rainbowSwapAggregator.call(swapCallData);
            IERC20(fromToken).safeApprove(rainbowSwapAggregator, 0);
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
        } else {
            (bool success, ) = rainbowSwapAggregator.call{value: amount}(
                swapCallData
            );
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
        }
        if (toTokenAddress != NATIVE_TOKEN_ADDRESS)
            _finalBalanceTokenOut = IERC20(toTokenAddress).balanceOf(
                address(this)
            );
        else _finalBalanceTokenOut = address(this).balance;

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;
        if (toTokenAddress == NATIVE_TOKEN_ADDRESS)
            payable(receiverAddress).transfer(returnAmount);
        else IERC20(toTokenAddress).transfer(receiverAddress, returnAmount);
        return returnAmount;
    }

    /**
    // @notice Function responsible for swapping from one token to a different token directly
    // @dev This is called only when there is a request for a swap. 
    // @param fromToken token to be swapped
    // @param amount amount to be swapped 
    // @param swapExtraData data required for the one inch aggregator to get the swap done
    */
    function performDirectAction(
        address fromToken,
        address toToken,
        address receiver,
        uint256 amount,
        bytes memory swapExtraData
    ) external payable {
        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        if (toToken != NATIVE_TOKEN_ADDRESS)
            _initialBalanceTokenOut = IERC20(toToken).balanceOf(address(this));
        else _initialBalanceTokenOut = address(this).balance;

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            IERC20(fromToken).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
            IERC20(fromToken).safeIncreaseAllowance(rainbowSwapAggregator, amount);

            // solhint-disable-next-line
            (bool success, ) = rainbowSwapAggregator.call(swapExtraData);
            IERC20(fromToken).safeApprove(rainbowSwapAggregator, 0);
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
        } else {
            (bool success, ) = rainbowSwapAggregator.call{value: amount}(
                swapExtraData
            );
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
        }

        if (toToken != NATIVE_TOKEN_ADDRESS)
            _finalBalanceTokenOut = IERC20(toToken).balanceOf(address(this));
        else _finalBalanceTokenOut = address(this).balance;

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;
        if (toToken == NATIVE_TOKEN_ADDRESS)
            payable(receiver).transfer(returnAmount);
        else IERC20(toToken).transfer(receiver, returnAmount);
        emit AmountRecieved(returnAmount, toToken, receiver);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../MiddlewareImplBase.sol";
import "../helpers/errors.sol";

/**
// @title One Inch Swap Implementation
// @notice Called by the registry before cross chain transfers if the user requests
// for a swap
// @dev Follows the interface of Swap Impl Base
// @author Movr Network
*/
contract OneInchSwapImpl is MiddlewareImplBase {
    using SafeERC20 for IERC20;
    address payable public oneInchAggregator;
    event UpdateOneInchAggregatorAddress(address indexed oneInchAggregator);
    event AmountRecieved(
        uint256 amount,
        address tokenAddress,
        address receiver
    );
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// one inch aggregator contract is payable to allow ethereum swaps
    constructor(address registry, address _oneInchAggregator)
        MiddlewareImplBase(registry)
    {
        oneInchAggregator = payable(_oneInchAggregator);
    }

    /// @notice Sets oneInchAggregator address
    /// @param _oneInchAggregator is the address for oneInchAggreagtor
    function setOneInchAggregator(address _oneInchAggregator)
        external
        onlyOwner
    {
        oneInchAggregator = payable(_oneInchAggregator);
        emit UpdateOneInchAggregatorAddress(_oneInchAggregator);
    }

    /**
    // @notice Function responsible for swapping from one token to a different token
    // @dev This is called only when there is a request for a swap. 
    // @param from userAddress or sending address.
    // @param fromToken token to be swapped
    // @param amount amount to be swapped 
    // param to not required. This is there only to follow the MiddlewareImplBase
    // @param swapExtraData data required for the one inch aggregator to get the swap done
    */
    function performAction(
        address from,
        address fromToken,
        uint256 amount,
        address, // receiverAddress
        bytes memory swapExtraData
    ) external payable override onlyRegistry returns (uint256) {
        require(fromToken != address(0), MovrErrors.ADDRESS_0_PROVIDED);
        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            IERC20(fromToken).safeTransferFrom(from, address(this), amount);
            IERC20(fromToken).safeIncreaseAllowance(oneInchAggregator, amount);
            {
                // solhint-disable-next-line
                (bool success, bytes memory result) = oneInchAggregator.call(
                    swapExtraData
                );
                IERC20(fromToken).safeApprove(oneInchAggregator, 0);
                require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
                (uint256 returnAmount, ) = abi.decode(
                    result,
                    (uint256, uint256)
                );
                return returnAmount;
            }
        } else {
            (bool success, bytes memory result) = oneInchAggregator.call{
                value: amount
            }(swapExtraData);
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
            (uint256 returnAmount, ) = abi.decode(result, (uint256, uint256));
            return returnAmount;
        }
    }

    /**
    // @notice Function responsible for swapping from one token to a different token directly
    // @dev This is called only when there is a request for a swap. 
    // @param fromToken token to be swapped
    // @param amount amount to be swapped 
    // @param swapExtraData data required for the one inch aggregator to get the swap done
    */
    function performDirectAction(
        address fromToken,
        address toToken,
        address receiver,
        uint256 amount,
        bytes memory swapExtraData
    ) external payable {
        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            IERC20(fromToken).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
            IERC20(fromToken).safeIncreaseAllowance(oneInchAggregator, amount);
            {
                // solhint-disable-next-line
                (bool success, bytes memory result) = oneInchAggregator.call(
                    swapExtraData
                );
                IERC20(fromToken).safeApprove(oneInchAggregator, 0);
                require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
                (uint256 returnAmount, ) = abi.decode(
                    result,
                    (uint256, uint256)
                );
                emit AmountRecieved(returnAmount, toToken, receiver);
            }
        } else {
            (bool success, bytes memory result) = oneInchAggregator.call{
                value: amount
            }(swapExtraData);
            require(success, MovrErrors.MIDDLEWARE_ACTION_FAILED);
            (uint256 returnAmount, ) = abi.decode(result, (uint256, uint256));
            emit AmountRecieved(returnAmount, toToken, receiver);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./helpers/errors.sol";
import "./ImplBase.sol";
import "./MiddlewareImplBase.sol";

/**
// @title Movr Regisrtry Contract.
// @notice This is the main contract that is called using fund movr.
// This contains all the bridge and middleware ids. 
// RouteIds signify which bridge to be used. 
// Middleware Id signifies which aggregator will be used for swapping if required. 
*/
contract Registry is Ownable {
    using SafeERC20 for IERC20;
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    ///@notice RouteData stores information for a route
    struct RouteData {
        address route;
        bool isEnabled;
        bool isMiddleware;
    }
    RouteData[] public routes;
    modifier onlyExistingRoute(uint256 _routeId) {
        require(
            routes[_routeId].route != address(0),
            MovrErrors.ROUTE_NOT_FOUND
        );
        _;
    }

    constructor(address _owner) Ownable() {
        // first route is for direct bridging
        routes.push(RouteData(NATIVE_TOKEN_ADDRESS, true, true));
        transferOwnership(_owner);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    //
    // Events
    //
    event NewRouteAdded(
        uint256 routeID,
        address route,
        bool isEnabled,
        bool isMiddleware
    );
    event RouteDisabled(uint256 routeID);
    event ExecutionCompleted(
        uint256 middlewareID,
        uint256 bridgeID,
        uint256 inputAmount
    );

    /**
    // @param id route id of middleware to be used
    // @param optionalNativeAmount is the amount of native asset that the route requires 
    // @param inputToken token address which will be swapped to
    // BridgeRequest inputToken 
    // @param data to be used by middleware
    */
    struct MiddlewareRequest {
        uint256 id;
        uint256 optionalNativeAmount;
        address inputToken;
        bytes data;
    }

    /**
    // @param id route id of bridge to be used
    // @param optionalNativeAmount optinal native amount, to be used
    // when bridge needs native token along with ERC20    
    // @param inputToken token addresss which will be bridged 
    // @param data bridgeData to be used by bridge
    */
    struct BridgeRequest {
        uint256 id;
        uint256 optionalNativeAmount;
        address inputToken;
        bytes data;
    }

    /**
    // @param receiverAddress Recipient address to recieve funds on destination chain
    // @param toChainId Destination ChainId
    // @param amount amount to be swapped if middlewareId is 0  it will be
    // the amount to be bridged
    // @param middlewareRequest middleware Requestdata
    // @param bridgeRequest bridge request data
    */
    struct UserRequest {
        address receiverAddress;
        uint256 toChainId;
        uint256 amount;
        MiddlewareRequest middlewareRequest;
        BridgeRequest bridgeRequest;
    }

    /**
    // @notice function responsible for calling the respective implementation 
    // depending on the bridge to be used
    // If the middlewareId is 0 then no swap is required,
    // we can directly bridge the source token to wherever required,
    // else, we first call the Swap Impl Base for swapping to the required 
    // token and then start the bridging
    // @dev It is required for isMiddleWare to be true for route 0 as it is a special case
    // @param _userRequest calldata follows the input data struct
    */
    function outboundTransferTo(UserRequest calldata _userRequest)
        external
        payable
    {
        require(_userRequest.amount != 0, MovrErrors.INVALID_AMT);

        // make sure bridge ID is not 0
        require(
            _userRequest.bridgeRequest.id != 0,
            MovrErrors.INVALID_BRIDGE_ID
        );

        // make sure bridge input is provided
        require(
            _userRequest.bridgeRequest.inputToken != address(0),
            MovrErrors.ADDRESS_0_PROVIDED
        );

        // load middleware info and validate
        RouteData memory middlewareInfo = routes[
            _userRequest.middlewareRequest.id
        ];
        require(
            middlewareInfo.route != address(0) &&
                middlewareInfo.isEnabled &&
                middlewareInfo.isMiddleware,
            MovrErrors.ROUTE_NOT_ALLOWED
        );

        // load bridge info and validate
        RouteData memory bridgeInfo = routes[_userRequest.bridgeRequest.id];
        require(
            bridgeInfo.route != address(0) &&
                bridgeInfo.isEnabled &&
                !bridgeInfo.isMiddleware,
            MovrErrors.ROUTE_NOT_ALLOWED
        );

        emit ExecutionCompleted(
            _userRequest.middlewareRequest.id,
            _userRequest.bridgeRequest.id,
            _userRequest.amount
        );

        // if middlewareID is 0 it means we dont want to perform a action before bridging
        // and directly want to move for bridging
        if (_userRequest.middlewareRequest.id == 0) {
            // perform the bridging
            ImplBase(bridgeInfo.route).outboundTransferTo{value: msg.value}(
                _userRequest.amount,
                msg.sender,
                _userRequest.receiverAddress,
                _userRequest.bridgeRequest.inputToken,
                _userRequest.toChainId,
                _userRequest.bridgeRequest.data
            );
            return;
        }

        // we first perform an action using the middleware
        // we determine if the input asset is a native asset, if yes we pass
        // the amount as value, else we pass the optionalNativeAmount
        uint256 _amountOut = MiddlewareImplBase(middlewareInfo.route)
            .performAction{
            value: _userRequest.middlewareRequest.inputToken ==
                NATIVE_TOKEN_ADDRESS
                ? _userRequest.amount +
                    _userRequest.middlewareRequest.optionalNativeAmount
                : _userRequest.middlewareRequest.optionalNativeAmount
        }(
            msg.sender,
            _userRequest.middlewareRequest.inputToken,
            _userRequest.amount,
            address(this),
            _userRequest.middlewareRequest.data
        );

        // we mutate this variable if the input asset to bridge Impl is NATIVE
        uint256 nativeInput = _userRequest.bridgeRequest.optionalNativeAmount;

        // if the input asset is ERC20, we need to grant the bridge implementation approval
        if (_userRequest.bridgeRequest.inputToken != NATIVE_TOKEN_ADDRESS) {
            IERC20(_userRequest.bridgeRequest.inputToken).safeIncreaseAllowance(
                    bridgeInfo.route,
                    _amountOut
                );
        } else {
            // if the input asset is native we need to set it as value
            nativeInput =
                _amountOut +
                _userRequest.bridgeRequest.optionalNativeAmount;
        }

        // send off to bridge
        ImplBase(bridgeInfo.route).outboundTransferTo{value: nativeInput}(
            _amountOut,
            address(this),
            _userRequest.receiverAddress,
            _userRequest.bridgeRequest.inputToken,
            _userRequest.toChainId,
            _userRequest.bridgeRequest.data
        );
    }

    //
    // Route management functions
    //

    /// @notice add routes to the registry.
    function addRoutes(RouteData[] calldata _routes)
        external
        onlyOwner
        returns (uint256[] memory)
    {
        require(_routes.length != 0, MovrErrors.EMPTY_INPUT);
        uint256[] memory _routeIds = new uint256[](_routes.length);
        for (uint256 i = 0; i < _routes.length; i++) {
            require(
                _routes[i].route != address(0),
                MovrErrors.ADDRESS_0_PROVIDED
            );
            routes.push(_routes[i]);
            _routeIds[i] = routes.length - 1;
            emit NewRouteAdded(
                i,
                _routes[i].route,
                _routes[i].isEnabled,
                _routes[i].isMiddleware
            );
        }

        return _routeIds;
    }

    ///@notice disables the route  if required.
    function disableRoute(uint256 _routeId)
        external
        onlyOwner
        onlyExistingRoute(_routeId)
    {
        routes[_routeId].isEnabled = false;
        emit RouteDisabled(_routeId);
    }

    function rescueFunds(
        address _token,
        address _receiverAddress,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).safeTransfer(_receiverAddress, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./helpers/errors.sol";

/**
@title Abstract Implementation Contract.
@notice All Bridge Implementation will follow this interface. 
*/
abstract contract ImplBase is Ownable {
    using SafeERC20 for IERC20;
    address public registry;
    address public constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    event UpdateRegistryAddress(address indexed registryAddress);

    constructor(address _registry) Ownable() {
        registry = _registry;
    }

    modifier onlyRegistry() {
        require(msg.sender == registry, MovrErrors.INVALID_SENDER);
        _;
    }

    function updateRegistryAddress(address newRegistry) external onlyOwner {
        registry = newRegistry;
        emit UpdateRegistryAddress(newRegistry);
    }

    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(userAddress, amount);
    }

    function rescueEther(
        address payable userAddress,
        uint256 amount
    ) external onlyOwner {
        userAddress.transfer(amount);
    }


    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        bytes memory _extraData
    ) external payable virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../interfaces/refuel.sol";
import "../../helpers/errors.sol";
import "../../ImplBase.sol";


contract RefuelBridgeImpl is ImplBase, ReentrancyGuard {
    IRefuel public router;

    /**
    @notice Constructor sets the router address and registry address.
    */
    constructor(IRefuel _router, address _registry)
        ImplBase(_registry)
    {
        router = _router;
    }

    /**
    @notice function responsible for calling cross chain transfer using refuel bridge.
    @param _receiverAddress receivers address.
    @param _toChainId destination chain Id
    */
    function outboundTransferTo(
        uint256,
        address,
        address _receiverAddress,
        address,
        uint256 _toChainId,
        bytes calldata
    ) external payable override onlyRegistry nonReentrant {
        require(msg.value != 0, MovrErrors.VALUE_SHOULD_NOT_BE_ZERO);
        router.depositNativeToken{value: msg.value}(
                _toChainId,
                _receiverAddress
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../helpers/errors.sol";
import "../../ImplBase.sol";
import "../../interfaces/hyphen.sol";

/**
// @title Hyphen V2 Implementation.
// Called by the registry if the selected bridge is Hyphen Bridge.
// @dev Follows the interface of ImplBase.
// @author Movr Network.
*/
contract HyphenImplV2 is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    HyphenLiquidityPoolManager public immutable liquidityPoolManager;
    string constant tag = "SOCKET";

    /// @notice Liquidity pool manager address and registry address required.
    constructor(
        HyphenLiquidityPoolManager _liquidityPoolManager,
        address _registry
    ) ImplBase(_registry) {
        liquidityPoolManager = _liquidityPoolManager;
    }

    /**
    // @notice Function responsible for cross chain transfer of supported assets from l2
    // to supported l2 and l1 chains. 
    // @dev Liquidity should be checked before calling this function. 
    // @param _amount amount to be sent.
    // @param _from senders address.
    // @param _receiverAddress receivers address.
    // @param _token token address on the source chain. 
    // @param _toChainId destination chain id
    // param _data extra data that is required, not required in the case of Hyphen. 
    */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        bytes memory // _data
    ) external payable override onlyRegistry nonReentrant {
        if (_token == NATIVE_TOKEN_ADDRESS) {
            // check if value passed is not 0
            require(msg.value != 0, MovrErrors.VALUE_SHOULD_NOT_BE_ZERO);
            liquidityPoolManager.depositNative{value: _amount}(
                _receiverAddress,
                _toChainId,
                tag
            );
            return;
        }
        require(msg.value == 0, MovrErrors.VALUE_SHOULD_BE_ZERO);
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        IERC20(_token).safeIncreaseAllowance(
            address(liquidityPoolManager),
            _amount
        );
        liquidityPoolManager.depositErc20(
            _toChainId,
            _token,
            _receiverAddress,
            _amount,
            tag
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface HyphenLiquidityPoolManager {
    function depositErc20(
        uint256 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount,
        string calldata tag
    ) external;

    function depositNative(
        address receiver,
        uint256 toChainId,
        string calldata tag
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../interfaces/hop/bridge.sol";
import "../../interfaces/hop/amm.sol";
import "../../helpers/errors.sol";
import "../../ImplBase.sol";

/**
// @title HOP L2 Implementation.
// @notice This is the L2 implementation, so this is used when transferring from l2
// to supported l2s or L1.
// Called by the registry if the selected bridge is Hop Bridge.
// @dev Follows the interface of ImplBase.
// @author Movr Network.
*/
contract HopImplL2 is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    event HopBridgeSend(
        uint256 integratorId
    );
    /// @notice constructor only required resistry address.
    constructor(address _registry) ImplBase(_registry) {}

    struct HopExtraData {
        address _hopAMM;
        uint256 _bonderFee; // fees passed to relayer
        uint256 _amountOutMin;
        uint256 _deadline;
        uint256 _amountOutMinDestination;
        uint256 _deadlineDestination;
        address _tokenAddress;
        uint256 _integratorId;
    }

    /**
    // @notice Function responsible for cross chain transfer from l2 to l1 or supported
    // l2s.
    // Called by the registry when the selected bridge is Hop bridge.
    // @dev Try to check for the liquidity on the other side before calling this.
    // @param _amount amount to be sent.
    // @param _from sender address
    // @param _receiverAddress receiver address
    // @param _toChainId Destination Chain Id
    // @param _token address of the token to bridged to the destination chain. 
    // @param _data data required to call the Hop swap and send function. hopAmm address,
    // boderfee, amount out min and deadline.
    */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        bytes calldata _data
    ) external payable override onlyRegistry nonReentrant {
        // decode data

        
            (
                HopExtraData memory _hopExtraData
 
            ) = abi.decode(
                    _data,
                    (
                        HopExtraData
                    )
                );
            emit HopBridgeSend(_hopExtraData._integratorId);
            // token address might not be indication thats why passed through extraData
            if (_hopExtraData._tokenAddress == NATIVE_TOKEN_ADDRESS) {
                require(msg.value != 0, MovrErrors.VALUE_SHOULD_NOT_BE_ZERO);
                // perform bridging
                HopAMM(_hopExtraData._hopAMM).swapAndSend{value: _amount}(
                    _toChainId,
                    _receiverAddress,
                    _amount,
                    _hopExtraData._bonderFee,
                    _hopExtraData._amountOutMin,
                    _hopExtraData._deadline,
                    _hopExtraData._amountOutMinDestination,
                    _hopExtraData._deadlineDestination
                );
                return;
            }
            require(msg.value == 0, MovrErrors.VALUE_SHOULD_BE_ZERO);
            IERC20(_token).safeTransferFrom(_from, address(this), _amount);
            IERC20(_token).safeIncreaseAllowance(_hopExtraData._hopAMM, _amount);

            // perform bridging
            HopAMM(_hopExtraData._hopAMM).swapAndSend(
                _toChainId,
                _receiverAddress,
                _amount,
                _hopExtraData._bonderFee,
                _hopExtraData._amountOutMin,
                _hopExtraData._deadline,
                _hopExtraData._amountOutMinDestination,
                _hopExtraData._deadlineDestination
            );
        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// Not being used I think. Remove if unnecessary.
interface HopBridge {
    function send(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
@title HopAMM
@notice responsible for calling the HOP L2 Impl functions.
 */
interface HopAMM {
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function swapAndSend(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 destinationAmountOutMin,
        uint256 destinationDeadline
    ) external payable;

    function getTokenIndex(address tokenAddress) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../helpers/errors.sol";
import "../../ImplBase.sol";
import "../../interfaces/cbridge.sol";
import "../../helpers/Pb.sol";

/**
@title Celer L2 Implementation.
@notice This is the L2 implementation, so this is used when transferring from
l2 to supported l2s or L1.
Called by the registry if the selected bridge is Celer bridge.
@dev Follows the interface of ImplBase.
@author Socket.
*/

contract CelerImplL1L2 is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Pb for Pb.Buffer;
    ICBridge public immutable router;
    address immutable wethAddress;
    mapping(bytes32 => address) public transferIdAdrressMap;
    uint64 public immutable chainId;

    struct WithdrawMsg {
        uint64 chainid; // tag: 1
        uint64 seqnum; // tag: 2
        address receiver; // tag: 3
        address token; // tag: 4
        uint256 amount; // tag: 5
        bytes32 refid; // tag: 6
    }

    /**
    @notice Constructor sets the router address and registry address.
    @dev Celer Bridge address is constant. so no setter function required.
    */
    constructor(
        ICBridge _router,
        address _registry,
        address _wethAddress
    ) ImplBase(_registry) {
        router = _router;
        chainId = uint64(block.chainid);
        wethAddress = _wethAddress;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /**
    @notice function responsible for calling cross chain transfer using celer bridge.
    @dev the token to be passed on to the celer bridge.
    @param _amount amount to be sent.
    @param _from sender address. 
    @param _receiverAddress receivers address.
    @param _token this is the main token address on the source chain. 
    @param _toChainId destination chain Id
    @param _data data contains nonce and the maxSlippage.
    */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        bytes memory _data
    ) external payable override onlyRegistry nonReentrant {
        (uint64 nonce, uint32 maxSlippage, address senderAddress) = abi.decode(
            _data,
            (uint64, uint32, address)
        );
        if (_token == NATIVE_TOKEN_ADDRESS) {
            require(msg.value == _amount, MovrErrors.VALUE_NOT_EQUAL_TO_AMOUNT);
            bytes32 transferId = keccak256(
                abi.encodePacked(
                    address(this),
                    _receiverAddress,
                    wethAddress,
                    _amount,
                    uint64(_toChainId),
                    nonce,
                    chainId
                )
            );
            require(
                transferIdAdrressMap[transferId] == address(0),
                "Transfer Id already exist in map"
            );
            transferIdAdrressMap[transferId] = senderAddress;
            router.sendNative{value: _amount}(
                _receiverAddress,
                _amount,
                uint64(_toChainId),
                nonce,
                maxSlippage
            );
        } else {
            require(msg.value == 0, MovrErrors.VALUE_SHOULD_BE_ZERO);
            IERC20(_token).safeTransferFrom(_from, address(this), _amount);
            IERC20(_token).safeIncreaseAllowance(address(router), _amount);
            bytes32 transferId = keccak256(
                abi.encodePacked(
                    address(this),
                    _receiverAddress,
                    _token,
                    _amount,
                    uint64(_toChainId),
                    nonce,
                    chainId
                )
            );
            require(
                transferIdAdrressMap[transferId] == address(0),
                "Transfer Id already exist in map"
            );
            transferIdAdrressMap[transferId] = senderAddress;
            router.send(
                _receiverAddress,
                _token,
                _amount,
                uint64(_toChainId),
                nonce,
                maxSlippage
            );
        }
    }

    function refundCelerUser(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable nonReentrant {
        WithdrawMsg memory request = decWithdrawMsg(_request);
        bytes32 transferId = keccak256(
            abi.encodePacked(
                request.chainid,
                request.seqnum,
                request.receiver,
                request.token,
                request.amount
            )
        );
        uint256 _initialBalanceTokenOut = address(this).balance;
        if (!router.withdraws(transferId)) {
            router.withdraw(_request, _sigs, _signers, _powers);
        }
        require(request.receiver == address(this), "Invalid refund");
        address _receiver = transferIdAdrressMap[request.refid];
        delete transferIdAdrressMap[request.refid];
        require(
            _receiver != address(0),
            "Unknown transfer id or already refunded"
        );
        if (address(this).balance > _initialBalanceTokenOut) {
            payable(_receiver).transfer(request.amount);
        } else {
            IERC20(request.token).safeTransfer(_receiver, request.amount);
        }
    }

    function decWithdrawMsg(bytes memory raw)
        internal
        pure
        returns (WithdrawMsg memory m)
    {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.chainid = uint64(buf.decVarint());
            } else if (tag == 2) {
                m.seqnum = uint64(buf.decVarint());
            } else if (tag == 3) {
                m.receiver = Pb._address(buf.decBytes());
            } else if (tag == 4) {
                m.token = Pb._address(buf.decBytes());
            } else if (tag == 5) {
                m.amount = Pb._uint256(buf.decBytes());
            } else if (tag == 6) {
                m.refid = Pb._bytes32(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder WithdrawMsg
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface ICBridge {
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChinId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external;

    function sendNative(
        address _receiver,
        uint256 _amount,
        uint64 _dstChinId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external payable;

    function withdraws(bytes32 withdrawId) external view returns (bool);

    function withdraw(
        bytes calldata _wdmsg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

// runtime proto sol library
library Pb {
    enum WireType {
        Varint,
        Fixed64,
        LengthDelim,
        StartGroup,
        EndGroup,
        Fixed32
    }

    struct Buffer {
        uint256 idx; // the start index of next read. when idx=b.length, we're done
        bytes b; // hold serialized proto msg, readonly
    }

    // create a new in-memory Buffer object from raw msg bytes
    function fromBytes(bytes memory raw)
        internal
        pure
        returns (Buffer memory buf)
    {
        buf.b = raw;
        buf.idx = 0;
    }

    // whether there are unread bytes
    function hasMore(Buffer memory buf) internal pure returns (bool) {
        return buf.idx < buf.b.length;
    }

    // decode current field number and wiretype
    function decKey(Buffer memory buf)
        internal
        pure
        returns (uint256 tag, WireType wiretype)
    {
        uint256 v = decVarint(buf);
        tag = v / 8;
        wiretype = WireType(v & 7);
    }

    // count tag occurrences, return an array due to no memory map support
    // have to create array for (maxtag+1) size. cnts[tag] = occurrences
    // should keep buf.idx unchanged because this is only a count function
    function cntTags(Buffer memory buf, uint256 maxtag)
        internal
        pure
        returns (uint256[] memory cnts)
    {
        uint256 originalIdx = buf.idx;
        cnts = new uint256[](maxtag + 1); // protobuf's tags are from 1 rather than 0
        uint256 tag;
        WireType wire;
        while (hasMore(buf)) {
            (tag, wire) = decKey(buf);
            cnts[tag] += 1;
            skipValue(buf, wire);
        }
        buf.idx = originalIdx;
    }

    // read varint from current buf idx, move buf.idx to next read, return the int value
    function decVarint(Buffer memory buf) internal pure returns (uint256 v) {
        bytes10 tmp; // proto int is at most 10 bytes (7 bits can be used per byte)
        bytes memory bb = buf.b; // get buf.b mem addr to use in assembly
        v = buf.idx; // use v to save one additional uint variable
        assembly {
            tmp := mload(add(add(bb, 32), v)) // load 10 bytes from buf.b[buf.idx] to tmp
        }
        uint256 b; // store current byte content
        v = 0; // reset to 0 for return value
        for (uint256 i = 0; i < 10; i++) {
            assembly {
                b := byte(i, tmp) // don't use tmp[i] because it does bound check and costs extra
            }
            v |= (b & 0x7F) << (i * 7);
            if (b & 0x80 == 0) {
                buf.idx += i + 1;
                return v;
            }
        }
        revert(); // i=10, invalid varint stream
    }

    // read length delimited field and return bytes
    function decBytes(Buffer memory buf)
        internal
        pure
        returns (bytes memory b)
    {
        uint256 len = decVarint(buf);
        uint256 end = buf.idx + len;
        require(end <= buf.b.length); // avoid overflow
        b = new bytes(len);
        bytes memory bufB = buf.b; // get buf.b mem addr to use in assembly
        uint256 bStart;
        uint256 bufBStart = buf.idx;
        assembly {
            bStart := add(b, 32)
            bufBStart := add(add(bufB, 32), bufBStart)
        }
        for (uint256 i = 0; i < len; i += 32) {
            assembly {
                mstore(add(bStart, i), mload(add(bufBStart, i)))
            }
        }
        buf.idx = end;
    }

    // return packed ints
    function decPacked(Buffer memory buf)
        internal
        pure
        returns (uint256[] memory t)
    {
        uint256 len = decVarint(buf);
        uint256 end = buf.idx + len;
        require(end <= buf.b.length); // avoid overflow
        // array in memory must be init w/ known length
        // so we have to create a tmp array w/ max possible len first
        uint256[] memory tmp = new uint256[](len);
        uint256 i = 0; // count how many ints are there
        while (buf.idx < end) {
            tmp[i] = decVarint(buf);
            i++;
        }
        t = new uint256[](i); // init t with correct length
        for (uint256 j = 0; j < i; j++) {
            t[j] = tmp[j];
        }
        return t;
    }

    // move idx pass current value field, to beginning of next tag or msg end
    function skipValue(Buffer memory buf, WireType wire) internal pure {
        if (wire == WireType.Varint) {
            decVarint(buf);
        } else if (wire == WireType.LengthDelim) {
            uint256 len = decVarint(buf);
            buf.idx += len; // skip len bytes value data
            require(buf.idx <= buf.b.length); // avoid overflow
        } else {
            revert();
        } // unsupported wiretype
    }

    // type conversion help utils
    function _bool(uint256 x) internal pure returns (bool v) {
        return x != 0;
    }

    function _uint256(bytes memory b) internal pure returns (uint256 v) {
        require(b.length <= 32); // b's length must be smaller than or equal to 32
        assembly {
            v := mload(add(b, 32))
        } // load all 32bytes to v
        v = v >> (8 * (32 - b.length)); // only first b.length is valid
    }

    function _address(bytes memory b) internal pure returns (address v) {
        v = _addressPayable(b);
    }

    function _addressPayable(bytes memory b)
        internal
        pure
        returns (address payable v)
    {
        require(b.length == 20);
        //load 32bytes then shift right 12 bytes
        assembly {
            v := div(mload(add(b, 32)), 0x1000000000000000000000000)
        }
    }

    function _bytes32(bytes memory b) internal pure returns (bytes32 v) {
        require(b.length == 32);
        assembly {
            v := mload(add(b, 32))
        }
    }

    // uint[] to uint8[]
    function uint8s(uint256[] memory arr)
        internal
        pure
        returns (uint8[] memory t)
    {
        t = new uint8[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint8(arr[i]);
        }
    }

    function uint32s(uint256[] memory arr)
        internal
        pure
        returns (uint32[] memory t)
    {
        t = new uint32[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint32(arr[i]);
        }
    }

    function uint64s(uint256[] memory arr)
        internal
        pure
        returns (uint64[] memory t)
    {
        t = new uint64[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint64(arr[i]);
        }
    }

    function bools(uint256[] memory arr)
        internal
        pure
        returns (bool[] memory t)
    {
        t = new bool[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = arr[i] != 0;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../helpers/errors.sol";
import "../../ImplBase.sol";

/**
@title Anyswap L2 Implementation.
@notice This is the L2 implementation, so this is used when transferring from
l2 to supported l2s or L1.
Called by the registry if the selected bridge is Anyswap bridge.
@dev Follows the interface of ImplBase.
@author Movr Network.
*/
interface AnyswapV3Router {
    function anySwapOutUnderlying(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID
    ) external;
}

contract AnyswapImplL2 is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    AnyswapV3Router public immutable router;

    /**
    @notice Constructor sets the router address and registry address.
    @dev anyswap v3 address is constant. so no setter function required.
    */
    constructor(AnyswapV3Router _router, address _registry)
        ImplBase(_registry)
    {
        router = _router;
    }

    /**
    @notice function responsible for calling cross chain transfer using anyswap bridge.
    @dev the token to be passed on to anyswap function is supposed to be the wrapper token
    address.
    @param _amount amount to be sent.
    @param _from sender address. 
    @param _receiverAddress receivers address.
    @param _token this is the main token address on the source chain. 
    @param _toChainId destination chain Id
    @param _data data contains the wrapper token address for the token
    */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        bytes memory _data
    ) external payable override onlyRegistry nonReentrant {
        require(_token != NATIVE_TOKEN_ADDRESS, MovrErrors.TOKEN_NOT_SUPPORTED);
        require(msg.value == 0, MovrErrors.VALUE_SHOULD_BE_ZERO);
        address _wrapperTokenAddress = abi.decode(_data, (address));
            IERC20(_token).safeTransferFrom(_from, address(this), _amount);
            IERC20(_token).safeIncreaseAllowance(address(router), _amount);
            router.anySwapOutUnderlying(
                _wrapperTokenAddress,
                _receiverAddress,
                _amount,
                _toChainId
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../helpers/errors.sol";
import "../../ImplBase.sol";
import "../../interfaces/across.sol";

contract AcrossImplV2 is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    SpokePool public immutable spokePool;

    /**
    @notice Constructor sets the router address and registry address.
    @dev depositBox so no setter function required.
    */
    constructor(SpokePool _spokePool, address _registry) ImplBase(_registry) {
        spokePool = _spokePool;
    }

    /**
    @notice function responsible for calling l2 -> l1 transfer using across bridge.
    @dev the token to be passed on to anyswap function is supposed to be the wrapper token
    address.
    @param _amount amount to be sent.
    @param _from sender address. 
    @param _receiverAddress receivers address.
    @param _token this is the main token address on the source chain. 
    @param _extraData data contains extra data for the bridge
    */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256 toChainId,
        bytes memory _extraData
    ) external payable override onlyRegistry nonReentrant {
        (
            address _originToken,
            uint64 relayerFeePct,
            uint32 _quoteTimestamp
        ) = abi.decode(_extraData, (address, uint64, uint32));

        if (_token == NATIVE_TOKEN_ADDRESS) {
            // check if value passed is not 0
            require(msg.value != 0, MovrErrors.VALUE_SHOULD_NOT_BE_ZERO);
            spokePool.deposit{value: _amount}(
                _receiverAddress,
                _originToken,
                _amount,
                toChainId,
                relayerFeePct,
                _quoteTimestamp
            );
            return;
        }

        require(msg.value == 0, MovrErrors.VALUE_SHOULD_BE_ZERO);
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        IERC20(_token).safeIncreaseAllowance(address(spokePool), _amount);

        spokePool.deposit(
            _receiverAddress,
            _originToken,
            _amount,
            toChainId,
            relayerFeePct,
            _quoteTimestamp
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface SpokePool {
    function deposit(
        address recipient,
        address originToken,
        uint256 amount,
        uint256 destinationChainId,
        uint64 relayerFeePct,
        uint32 quoteTimestamp
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../ImplBase.sol";
import "../../helpers/errors.sol";
import "../../interfaces/polygon.sol";

/**
// @title Native Polygon Bridge Implementation.
// @notice This is the L1 implementation, so this is used when transferring 
// from ethereum to polygon via their native bridge.
// Called by the registry if the selected bridge is Native Polygon.
// @dev Follows the interface of ImplBase. This is only used for depositing POS ERC20 tokens.
// @author Movr Network.
*/
contract NativePolygonImpl is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address public rootChainManagerProxy;
    address public erc20PredicateProxy;
    event UpdateRootchainManager(address indexed rootchainManagerAddress);
    event UpdateERC20Predicate(address indexed erc20PredicateAddress);

    /**
    // @notice We set all the required addresses in the constructor while deploying the contract.
    // These will be constant addresses.
    // @dev Please use the Proxy addresses and not the implementation addresses while setting these 
    // @param _registry address of the registry contract that calls this contract
    // @param _rootChainManagerProxy address of the root chain manager proxy on the ethereum chain 
    // @param _erc20PredicateProxy address of the ERC20 Predicate proxy on the ethereum chain.
    */
    constructor(
        address _registry,
        address _rootChainManagerProxy,
        address _erc20PredicateProxy
    ) ImplBase(_registry) {
        rootChainManagerProxy = _rootChainManagerProxy;
        erc20PredicateProxy = _erc20PredicateProxy;
    }

    /**
    // @notice Function to set the root chain manager proxy address.
     */
    function setrootChainManagerProxy(address _rootChainManagerProxy)
        public
        onlyOwner
    {
        rootChainManagerProxy = _rootChainManagerProxy;
        emit UpdateRootchainManager(_rootChainManagerProxy);
    }

    /**
    // @notice Function to set the ERC20 Predicate proxy address.
     */
    function setErc20PredicateProxy(address _erc20PredicateProxy)
        public
        onlyOwner
    {
        erc20PredicateProxy = _erc20PredicateProxy;
        emit UpdateERC20Predicate(_erc20PredicateProxy);
    }

    /**
    // @notice Function responsible for depositing ERC20 tokens from ethereum to 
    //         polygon chain using the POS bridge.
    // @dev Please make sure that the token is mapped before sending it through the native bridge.
    // @param _amount amount to be sent.
    // @param _from sending address.
    // @param _receiverAddress receiving address.
    // @param _token address of the token to be bridged to polygon.
     */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256,
        bytes memory
    ) external payable override onlyRegistry nonReentrant {
        if (_token == NATIVE_TOKEN_ADDRESS) {
            require(msg.value != 0, MovrErrors.VALUE_SHOULD_NOT_BE_ZERO);
            IRootChainManager(rootChainManagerProxy).depositEtherFor{
                value: _amount
            }(_receiverAddress);
            return;
        }
        require(msg.value == 0, MovrErrors.VALUE_SHOULD_BE_ZERO);
        IERC20 token = IERC20(_token);

        // set allowance for erc20 predicate
        token.safeTransferFrom(_from, address(this), _amount);
        token.safeIncreaseAllowance(erc20PredicateProxy, _amount);

        // deposit into rootchain manager
        IRootChainManager(rootChainManagerProxy).depositFor(
            _receiverAddress,
            _token,
            abi.encodePacked(_amount)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
@title RootChain Manager Interface for Polygon Bridge.
*/
interface IRootChainManager {
    function depositEtherFor(address user) external payable;

    function depositFor(
        address sender,
        address token,
        bytes memory extraData
    ) external;
}

/**
@title FxState Sender Interface if FxPortal Bridge is used.
*/
interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../ImplBase.sol";
import "../../helpers/errors.sol";
import "../../interfaces/optimism.sol";

/**
// @title Native Optimism Bridge Implementation.
// @author Socket Technology.
*/
contract NativeOptimismImpl is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    L1StandardBridge  public bridgeProxy = L1StandardBridge(0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1); 

    /**
    // @notice We set all the required addresses in the constructor while deploying the contract.
    // These will be constant addresses.
    // @dev Please use the Proxy addresses and not the implementation addresses while setting these 
    // @param _registry address of the registry contract that calls this contract
    */
    constructor(
        address _registry
    ) ImplBase(_registry) {}


    /**
    // @param _amount amount to be sent.
    // @param _from sending address.
    // @param _receiverAddress receiving address.
    // @param _token address of the token to be bridged to optimism.
     */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256,
        bytes memory _extraData
    ) external payable override onlyRegistry nonReentrant {

        (   
            address _l2Token,
            uint32 _l2Gas,
            bytes memory _data
        ) = abi.decode(_extraData, (address, uint32, bytes));


        if (_token == NATIVE_TOKEN_ADDRESS) {
            require(msg.value != 0, MovrErrors.VALUE_SHOULD_NOT_BE_ZERO);
            bridgeProxy.depositETHTo{value: _amount}(_receiverAddress, _l2Gas, _data);
            return;
        }
        require(msg.value == 0, MovrErrors.VALUE_SHOULD_BE_ZERO);
        IERC20 token = IERC20(_token);
        // set allowance for erc20 predicate
        token.safeTransferFrom(_from, address(this), _amount);
        token.safeIncreaseAllowance(address(bridgeProxy), _amount);

        // deposit into standard bridge
        bridgeProxy.depositERC20To(_token, _l2Token, _receiverAddress, _amount, _l2Gas, _data);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface L1StandardBridge {
    function depositETHTo(
        address _to,
        uint32 _l2Gas,
        bytes calldata _data
    ) external payable;

    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _l2Gas,
        bytes calldata _data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../ImplBase.sol";
import "../../helpers/errors.sol";
import "../../interfaces/arbitrum.sol";

/**
// @title Native Arbitrum Bridge Implementation.
// @notice This is the L1 implementation, 
//          so this is used when transferring from ethereum to arbitrum via their native bridge.
// Called by the registry if the selected bridge is Native Arbitrum.
// @dev Follows the interface of ImplBase. This is only used for depositing tokens.
// @author Movr Network.
*/
contract NativeArbitrumImpl is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address public router;
    address public inbox;
    event UpdateArbitrumRouter(address indexed routerAddress);
    event UpdateArbitrumInbox(address indexed inbox);

    /// @notice registry and L1 gateway router address required.
    constructor(
        address _registry,
        address _router,
        address _inbox
    ) ImplBase(_registry) {
        router = _router;
        inbox = _inbox;
    }

    /// @notice setter function for the L1 gateway router address
    function setInbox(address _inbox) public onlyOwner {
        inbox = _inbox;
        emit UpdateArbitrumInbox(_inbox);
    }

    /// @notice setter function for the L1 gateway router address
    function setRouter(address _router) public onlyOwner {
        router = _router;
        emit UpdateArbitrumRouter(_router);
    }

    /**
    // @notice function responsible for the native arbitrum deposits from ethereum. 
    // @dev gateway address is the address where the first deposit is made. 
    //      It holds max submission price and further data.
    // @param _amount amount to be sent. 
    // @param _from senders address 
    // @param _receiverAddress receivers address
    // @param _token token address on the source chain that is L1. 
    // param _toChainId not required, follows the impl base.
    // @param _extraData extradata required for calling the l1 router function. Explain above. 
    */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256, // _toChainId
        bytes memory _extraData
    ) external payable override onlyRegistry nonReentrant {
        IERC20 token = IERC20(_token);
        (
            address _gatewayAddress,
            uint256 _maxGas,
            uint256 _gasPriceBid,
            bytes memory _data
        ) = abi.decode(_extraData, (address, uint256, uint256, bytes));

        if (_token == NATIVE_TOKEN_ADDRESS) {
            require(msg.value != 0, MovrErrors.VALUE_SHOULD_NOT_BE_ZERO);
            Inbox(inbox).depositEth{value: _amount}(_maxGas);
            return;
        }
        // @notice here we dont provide a 0 value check
        // since arbitrum may need native token as well along
        // with ERC20
        token.safeTransferFrom(_from, address(this), _amount);
        token.safeIncreaseAllowance(_gatewayAddress, _amount);
        L1GatewayRouter(router).outboundTransfer{value: msg.value}(
            _token,
            _receiverAddress,
            _amount,
            _maxGas,
            _gasPriceBid,
            _data
        );
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity >=0.8.0;

interface L1GatewayRouter {
    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes calldata);
}

interface Inbox {
     function depositEth(uint256 maxSubmissionCost) external payable returns (uint256) ; 
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../ImplBase.sol";
import "../../helpers/errors.sol";
import "../../interfaces/hop/IHopL1Bridge.sol";

/**
// @title Hop Protocol Implementation.
// @notice This is the L1 implementation, so this is used when transferring from l1 to supported l2s
//         Called by the registry if the selected bridge is HOP.
// @dev Follows the interface of ImplBase.
// @author Movr Network.
*/
contract HopImpl is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    event HopBridgeSend(
        uint256 indexed integratorId
    );

    // solhint-disable-next-line
    constructor(address _registry) ImplBase(_registry) {}

    struct HopExtraData {
        address _l1bridgeAddr;
        address _relayer;
        uint256 _amountOutMin;
        uint256 _relayerFee;
        uint256 _deadline;
        uint256 integratorId;
    }

    /**
    // @notice Function responsible for cross chain transfers from L1 to L2. 
    // @dev When calling the registry the allowance should be given to this contract, 
    //      that is the implementation contract for HOP.
    // @param _amount amount to be transferred to L2.
    // @param _from userAddress or address from which the transfer was made.
    // @param _receiverAddress address that will receive the funds on the destination chain.
    // @param _token address of the token to be used for cross chain transfer.
    // @param _toChainId chain Id for the destination chain 
    // @param _extraData parameters required to call the hop function in bytes 
    */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        bytes calldata _extraData
    ) external payable override onlyRegistry nonReentrant {
        // decode extra data
        (
            HopExtraData memory _hopExtraData
        ) = abi.decode(
                _extraData,
                (HopExtraData)
            );
        emit HopBridgeSend(_hopExtraData.integratorId);
        if (_token == NATIVE_TOKEN_ADDRESS) {
            require(msg.value == _amount, MovrErrors.VALUE_NOT_EQUAL_TO_AMOUNT);
            IHopL1Bridge(_hopExtraData._l1bridgeAddr).sendToL2{value: _amount}(
                _toChainId,
                _receiverAddress,
                _amount,
                _hopExtraData._amountOutMin,
                _hopExtraData._deadline,
                _hopExtraData._relayer,
                _hopExtraData._relayerFee
            );
            return;
        }
        require(msg.value == 0, MovrErrors.VALUE_SHOULD_BE_ZERO);
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        IERC20(_token).safeIncreaseAllowance(_hopExtraData._l1bridgeAddr, _amount);

        // perform bridging
        IHopL1Bridge(_hopExtraData._l1bridgeAddr).sendToL2(
            _toChainId,
            _receiverAddress,
            _amount,
            _hopExtraData._amountOutMin,
            _hopExtraData._deadline,
            _hopExtraData._relayer,
            _hopExtraData._relayerFee
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
@title L1Bridge Hop Interface
@notice L1 Hop Bridge, Used to transfer from L1 to L2s. 
*/
interface IHopL1Bridge {
    function sendToL2(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../helpers/errors.sol";
import "../../ImplBase.sol";

/**
@title Anyswap L1 Implementation.
@notice This is the L1 implementation, so this is used when transferring from
l1 to supported l1s or L1.
Called by the registry if the selected bridge is Anyswap bridge.
@dev Follows the interface of ImplBase.
@author Movr Network.
*/
interface AnyswapV3Router {
    function anySwapOutUnderlying(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID
    ) external;
}

contract AnyswapImplL1 is ImplBase {
    using SafeERC20 for IERC20;
    AnyswapV3Router public immutable router;

    /**
    @notice Constructor sets the router address and registry address.
    @dev anyswap v3 address is constant. so no setter function required.
    */
    constructor(AnyswapV3Router _router, address _registry)
        ImplBase(_registry)
    {
        router = _router;
    }

    /**
    @notice function responsible for calling cross chain transfer using anyswap bridge.
    @dev the token to be passed on to anyswap function is supposed to be the wrapper token
    address.
    @param _amount amount to be sent.
    @param _from sender address. 
    @param _receiverAddress receivers address.
    @param _token this is the main token address on the source chain. 
    @param _toChainId destination chain Id
    @param _data data contains the wrapper token address for the token
    */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        bytes memory _data
    ) external payable override onlyRegistry {
        require(_token != NATIVE_TOKEN_ADDRESS, MovrErrors.TOKEN_NOT_SUPPORTED);
        require(msg.value == 0, MovrErrors.VALUE_SHOULD_BE_ZERO);
        address _wrapperTokenAddress = abi.decode(_data, (address));
            IERC20(_token).safeTransferFrom(_from, address(this), _amount);
            IERC20(_token).safeIncreaseAllowance(address(router), _amount);
            router.anySwapOutUnderlying(
                _wrapperTokenAddress,
                _receiverAddress,
                _amount,
                _toChainId
            );
    }
}