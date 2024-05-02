// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IButterMosV2 {
    function swapOutToken(
        address _sender,
        address _token, // src token
        bytes memory _to,
        uint256 _amount,
        uint256 _toChain, // target chain id
        bytes calldata _swapData
    ) external returns (bytes32 orderId);

    function swapOutNative(
        address _sender,
        bytes memory _to,
        uint256 _toChain, // target chain id
        bytes calldata _swapData
    ) external payable returns (bytes32 orderId);

    function depositToken(address _token, address to, uint256 _amount) external;

    function depositNative(address _to) external payable;

    event SetButterRouterAddress(address indexed _newRouter);

    event mapTransferOut(
        uint256 indexed fromChain,
        uint256 indexed toChain,
        bytes32 orderId,
        bytes token,
        bytes from,
        bytes to,
        uint256 amount,
        bytes toChainToken
    );

    event mapDepositOut(
        uint256 indexed fromChain,
        uint256 indexed toChain,
        bytes32 orderId,
        address token,
        bytes from,
        address to,
        uint256 amount
    );

    event mapSwapOut(
        uint256 indexed fromChain, // from chain
        uint256 indexed toChain, // to chain
        bytes32 orderId, // order id
        bytes token, // token to transfer
        bytes from, // source chain from address
        bytes to,
        uint256 amount,
        bytes swapData // swap data, used on target chain dex.
    );

    event mapSwapIn(
        uint256 indexed fromChain,
        uint256 indexed toChain,
        bytes32 indexed orderId,
        address token,
        bytes from,
        address toAddress,
        uint256 amountOut
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IButterReceiver {
    //_srcToken received token (wtoken or erc20 token)
    function onReceived(
        bytes32 _orderId,
        address _srcToken,
        uint256 _amount,
        uint256 _fromChain,
        bytes calldata _from,
        bytes calldata _payload
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

// EIP-2612 is Final as of 2022-11-01. This file is deprecated.

import "./IERC20Permit.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../lib/ErrorMessage.sol";
import "../lib/Helper.sol";

abstract contract Router is Ownable2Step {
    using SafeERC20 for IERC20;
    using Address for address;

    uint256 public feeRate;
    uint256 public fixedFee;
    address public feeReceiver;
    address internal immutable wToken;
    uint256 internal nativeBalanceBeforeExec;
    uint256 private constant FEE_DENOMINATOR = 1000000;

    mapping(address => bool) public approved;

    uint256 public immutable selfChainId = block.chainid;

    event Approve(address indexed executor, bool indexed flag);
    event SetFee(address indexed receiver, uint256 indexed rate, uint256 indexed fixedf);
    event CollectFee(
        address indexed token,
        address indexed receiver,
        uint256 indexed amount,
        bytes32 transferId,
        FeeType feeType
    );

    enum FeeType {
        FIXED,
        PROPORTION
    }

    // use to solve deep stack
    struct SwapTemp {
        address srcToken;
        address swapToken;
        uint256 srcAmount;
        uint256 swapAmount;
        bytes32 transferId;
        address receiver;
        address target;
        uint256 callAmount;
        uint256 fromChain;
        uint256 toChain;
        bytes from;
        FeeType feeType;
    }

    event SwapAndCall(
        address indexed from,
        address indexed receiver,
        address indexed target,
        bytes32 transferId,
        address originToken,
        address swapToken,
        uint256 originAmount,
        uint256 swapAmount,
        uint256 callAmount
    );

    modifier transferIn(
        address token,
        uint256 amount,
        bytes memory permitData
    ) {
        require(amount > 0, ErrorMessage.ZERO_IN);

        if (permitData.length > 0) {
            Helper._permit(permitData);
        }
        nativeBalanceBeforeExec = address(this).balance - msg.value;
        if (Helper._isNative(token)) {
            require(msg.value >= amount, ErrorMessage.FEE_MISMATCH);
        } else {
            SafeERC20.safeTransferFrom(IERC20(token), msg.sender, address(this), amount);
        }

        _;

        nativeBalanceBeforeExec = 0;
    }

    constructor(address _owner, address _wToken) payable {
        require(_owner != Helper.ZERO_ADDRESS, ErrorMessage.ZERO_ADDR);
        require(_wToken.isContract(), ErrorMessage.NOT_CONTRACT);
        wToken = _wToken;
        _transferOwnership(_owner);
    }

    function _doSwapAndCall(
        bytes memory _swapData,
        bytes memory _callbackData,
        address _srcToken,
        uint256 _amount
    ) internal returns (address receiver, address target, address dstToken, uint256 swapOutAmount, uint256 callAmount) {
        bool result;
        swapOutAmount = _amount;
        dstToken = _srcToken;
        if (_swapData.length > 0) {
            Helper.SwapParam memory swap = abi.decode(_swapData, (Helper.SwapParam));
            (result, dstToken, swapOutAmount) = _makeSwap(_amount, _srcToken, swap);
            require(result, ErrorMessage.SWAP_FAIL);
            require(swapOutAmount >= swap.minReturnAmount, ErrorMessage.RECEIVE_LOW);
            receiver = swap.receiver;
            target = swap.executor;
        }

        if (_callbackData.length > 0) {
            Helper.CallbackParam memory callParam = abi.decode(_callbackData, (Helper.CallbackParam));
            (result, callAmount) = _callBack(swapOutAmount, dstToken, callParam);
            require(result, ErrorMessage.CALL_FAIL);
            receiver = callParam.receiver;
            target = callParam.target;
        }
    }

    function setFee(address _feeReceiver, uint256 _feeRate, uint256 _fixedFee) external onlyOwner {
        require(_feeReceiver != Helper.ZERO_ADDRESS, ErrorMessage.ZERO_ADDR);

        require(_feeRate < FEE_DENOMINATOR);

        feeReceiver = _feeReceiver;

        feeRate = _feeRate;

        fixedFee = _fixedFee;

        emit SetFee(_feeReceiver, _feeRate, fixedFee);
    }

    function getFee(
        uint256 _amount,
        address _token,
        FeeType _feeType
    ) external view returns (address _feeReceiver, address _feeToken, uint256 _fee, uint256 _feeAfter) {
        if (feeReceiver == Helper.ZERO_ADDRESS) {
            return (Helper.ZERO_ADDRESS, Helper.ZERO_ADDRESS, 0, _amount);
        }
        if (_feeType == FeeType.FIXED) {
            _feeToken = Helper.ZERO_ADDRESS;
            _fee = fixedFee;
            if (!Helper._isNative(_token)) {
                _feeAfter = _amount;
            } else {
                _feeAfter = _amount - _fee;
            }
        } else {
            _feeToken = _token;
            _fee = (_amount * feeRate) / FEE_DENOMINATOR;
            _feeAfter = _amount - _fee;
        }
        _feeReceiver = feeReceiver;
    }

    function getInputBeforeFee(
        uint256 _amountAfterFee,
        address _token,
        FeeType _feeType
    ) external view returns (uint256 _input, address _feeReceiver, address _feeToken, uint256 _fee) {
        if (feeReceiver == Helper.ZERO_ADDRESS) {
            return (_amountAfterFee, Helper.ZERO_ADDRESS, Helper.ZERO_ADDRESS, 0);
        }
        if (_feeType == FeeType.FIXED) {
            _feeToken = Helper.ZERO_ADDRESS;
            _fee = fixedFee;
            if (!Helper._isNative(_token)) {
                _input = _amountAfterFee;
            } else {
                _input = _amountAfterFee + _fee;
            }
        } else {
            _feeToken = _token;
            _input = (_amountAfterFee * FEE_DENOMINATOR) / (FEE_DENOMINATOR - feeRate) + 1;
            _fee = _input - _amountAfterFee;
        }
        _feeReceiver = feeReceiver;
    }

    function _collectFee(
        address _token,
        uint256 _amount,
        bytes32 transferId,
        FeeType _feeType
    ) internal returns (uint256 _fee, uint256 _remain) {
        if (feeReceiver == Helper.ZERO_ADDRESS) {
            _remain = _amount;
            return (_fee, _remain);
        }
        if (_feeType == FeeType.FIXED) {
            _fee = fixedFee;
            if (Helper._isNative(_token)) {
                require(msg.value > fixedFee, ErrorMessage.FEE_LOWER);
                _remain = _amount - _fee;
            } else {
                require(msg.value >= fixedFee, ErrorMessage.FEE_MISMATCH);
                _remain = _amount;
            }
            _token = Helper.NATIVE_ADDRESS;
        } else {
            _fee = (_amount * feeRate) / FEE_DENOMINATOR;
            _remain = _amount - _fee;
        }
        if (_fee > 0) {
            Helper._transfer(selfChainId, _token, feeReceiver, _fee);
            emit CollectFee(_token, feeReceiver, _fee, transferId, _feeType);
        }
    }

    function _callBack(
        uint256 _amount,
        address _token,
        Helper.CallbackParam memory _callParam
    ) internal returns (bool _result, uint256 _callAmount) {
        require(approved[_callParam.target], ErrorMessage.NO_APPROVE);
        (_result, _callAmount) = Helper._callBack(_amount, _token, _callParam);
        require(address(this).balance >= nativeBalanceBeforeExec, ErrorMessage.NATIVE_VALUE_OVERSPEND);
    }

    function _makeSwap(
        uint256 _amount,
        address _srcToken,
        Helper.SwapParam memory _swap
    ) internal returns (bool _result, address _dstToken, uint256 _returnAmount) {
        require(approved[_swap.executor] || _swap.executor == wToken, ErrorMessage.NO_APPROVE);
        if (_swap.executor == wToken) {
            bytes4 sig = Helper._getFirst4Bytes(_swap.data);
            //0x2e1a7d4d -> withdraw(uint256 wad)  0xd0e30db0 -> deposit()
            if (sig != bytes4(0x2e1a7d4d) && sig != bytes4(0xd0e30db0)) {
                return (false, _srcToken, 0);
            }
        }
        (_result, _dstToken, _returnAmount) = Helper._makeSwap(_amount, _srcToken, _swap);
    }

    function setAuthorization(address[] calldata _executors, bool _flag) external onlyOwner {
        require(_executors.length > 0, ErrorMessage.DATA_EMPTY);
        for (uint i = 0; i < _executors.length; i++) {
            require(_executors[i].isContract(), ErrorMessage.NOT_CONTRACT);
            approved[_executors[i]] = _flag;
            emit Approve(_executors[i], _flag);
        }
    }

    function rescueFunds(address _token, uint256 _amount) external onlyOwner {
        Helper._transfer(selfChainId, _token, msg.sender, _amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@butternetwork/bridge/contracts/interface/IButterMosV2.sol";
import "@butternetwork/bridge/contracts/interface/IButterReceiver.sol";
import "./lib/ErrorMessage.sol";
import "./abstract/Router.sol";
import "./lib/Helper.sol";

contract ButterRouterV2 is Router, ReentrancyGuard, IButterReceiver {
    using SafeERC20 for IERC20;
    using Address for address;

    address public mosAddress;

    uint256 public gasForReFund = 80000;

    struct BridgeParam {
        uint256 toChain;
        bytes receiver;
        bytes data;
    }

    event SetMos(address indexed mos);
    event SetGasForReFund(uint256 indexed _gasForReFund);
    event SwapAndBridge(
        bytes32 indexed orderId,
        address indexed from,
        address indexed originToken,
        address bridgeToken,
        uint256 originAmount,
        uint256 bridgeAmount,
        uint256 fromChain,
        uint256 toChain,
        bytes to
    );

    event RemoteSwapAndCall(
        bytes32 indexed orderId,
        address indexed receiver,
        address indexed target,
        address originToken,
        address swapToken,
        uint256 originAmount,
        uint256 swapAmount,
        uint256 callAmount,
        uint256 fromChain,
        uint256 toChain,
        bytes from
    );

    constructor(address _mosAddress, address _owner, address _wToken) payable Router(_owner, _wToken) {
        _setMosAddress(_mosAddress);
    }

    function swapAndBridge(
        address _srcToken,
        uint256 _amount,
        bytes calldata _swapData,
        bytes calldata _bridgeData,
        bytes calldata _permitData
    ) external payable nonReentrant transferIn(_srcToken, _amount, _permitData) {
        require(_swapData.length + _bridgeData.length > 0, ErrorMessage.DATA_EMPTY);
        SwapTemp memory swapTemp;
        swapTemp.srcToken = _srcToken;
        swapTemp.srcAmount = _amount;
        swapTemp.swapToken = _srcToken;
        swapTemp.swapAmount = _amount;
        bytes memory receiver;
        if (_swapData.length > 0) {
            Helper.SwapParam memory swap = abi.decode(_swapData, (Helper.SwapParam));
            bool result;
            (result, swapTemp.swapToken, swapTemp.swapAmount) = _makeSwap(swapTemp.srcAmount, swapTemp.srcToken, swap);
            require(result, ErrorMessage.SWAP_FAIL);
            require(swapTemp.swapAmount >= swap.minReturnAmount, ErrorMessage.RECEIVE_LOW);
            if (_bridgeData.length == 0 && swapTemp.swapAmount > 0) {
                receiver = abi.encodePacked(swap.receiver);
                Helper._transfer(selfChainId, swapTemp.swapToken, swap.receiver, swapTemp.swapAmount);
            }
        }
        bytes32 orderId;
        if (_bridgeData.length > 0) {
            BridgeParam memory bridge = abi.decode(_bridgeData, (BridgeParam));
            swapTemp.toChain = bridge.toChain;
            receiver = bridge.receiver;
            orderId = _doBridge(msg.sender, swapTemp.swapToken, swapTemp.swapAmount, bridge);
        }
        emit SwapAndBridge(
            orderId,
            msg.sender,
            swapTemp.srcToken,
            swapTemp.swapToken,
            swapTemp.srcAmount,
            swapTemp.swapAmount,
            block.chainid,
            swapTemp.toChain,
            receiver
        );
    }

    function swapAndCall(
        bytes32 _transferId,
        address _srcToken,
        uint256 _amount,
        FeeType _feeType,
        bytes calldata _swapData,
        bytes calldata _callbackData,
        bytes calldata _permitData
    ) external payable nonReentrant transferIn(_srcToken, _amount, _permitData) {
        SwapTemp memory swapTemp;
        swapTemp.srcToken = _srcToken;
        swapTemp.srcAmount = _amount;
        swapTemp.transferId = _transferId;
        swapTemp.feeType = _feeType;
        require(_swapData.length + _callbackData.length > 0, ErrorMessage.DATA_EMPTY);
        (, swapTemp.swapAmount) = _collectFee(
            swapTemp.srcToken,
            swapTemp.srcAmount,
            swapTemp.transferId,
            swapTemp.feeType
        );

        (
            swapTemp.receiver,
            swapTemp.target,
            swapTemp.swapToken,
            swapTemp.swapAmount,
            swapTemp.callAmount
        ) = _doSwapAndCall(_swapData, _callbackData, swapTemp.srcToken, swapTemp.swapAmount);

        if (swapTemp.swapAmount > swapTemp.callAmount) {
            Helper._transfer(selfChainId, swapTemp.swapToken, swapTemp.receiver, (swapTemp.swapAmount - swapTemp.callAmount));
        }

        emit SwapAndCall(
            msg.sender,
            swapTemp.receiver,
            swapTemp.target,
            swapTemp.transferId,
            swapTemp.srcToken,
            swapTemp.swapToken,
            swapTemp.srcAmount,
            swapTemp.swapAmount,
            swapTemp.callAmount
        );
    }

    // _srcToken must erc20 Token or wToken
    function onReceived(
        bytes32 _orderId,
        address _srcToken,
        uint256 _amount,
        uint256 _fromChain,
        bytes calldata _from,
        bytes calldata _swapAndCall
    ) external nonReentrant {
        SwapTemp memory swapTemp;
        swapTemp.srcToken = _srcToken;
        swapTemp.srcAmount = _amount;
        swapTemp.swapToken = _srcToken;
        swapTemp.swapAmount = _amount;
        swapTemp.fromChain = _fromChain;
        swapTemp.toChain = block.chainid;
        swapTemp.from = _from;
        nativeBalanceBeforeExec = address(this).balance;
        require(msg.sender == mosAddress, ErrorMessage.MOS_ONLY);
        require(Helper._getBalance(swapTemp.srcToken, address(this)) >= _amount, ErrorMessage.RECEIVE_LOW);
        (bytes memory _swapData, bytes memory _callbackData) = abi.decode(_swapAndCall, (bytes, bytes));
        require(_swapData.length + _callbackData.length > 0, ErrorMessage.DATA_EMPTY);
        bool result = true;
        uint256 minExecGas = gasForReFund * 2;
        if (_swapData.length > 0) {
            Helper.SwapParam memory swap = abi.decode(_swapData, (Helper.SwapParam));
            swapTemp.receiver = swap.receiver;
            if (gasleft() > minExecGas) {
                try
                    this.doRemoteSwap{gas: gasleft() - gasForReFund}(swap, swapTemp.srcToken, swapTemp.srcAmount)
                returns (address target, address dstToken, uint256 dstAmount) {
                    swapTemp.swapToken = dstToken;
                    swapTemp.target = target;
                    swapTemp.swapAmount = dstAmount;
                } catch {
                    result = false;
                }
            }
        }

        if (_callbackData.length > 0) {
            Helper.CallbackParam memory callParam = abi.decode(_callbackData, (Helper.CallbackParam));
            if (swapTemp.receiver == address(0)) {
                swapTemp.receiver = callParam.receiver;
            }
            if (result && gasleft() > minExecGas) {
                try
                    this.doRemoteCall{gas: gasleft() - gasForReFund}(callParam, swapTemp.swapToken, swapTemp.swapAmount)
                returns (address target, uint256 callAmount) {
                    swapTemp.target = target;
                    swapTemp.callAmount = callAmount;
                    swapTemp.receiver = callParam.receiver;
                } catch {}
            }
        }
        if (swapTemp.swapAmount > swapTemp.callAmount) {
            Helper._transfer(selfChainId, swapTemp.swapToken, swapTemp.receiver, (swapTemp.swapAmount - swapTemp.callAmount));
        }
        emit RemoteSwapAndCall(
            _orderId,
            swapTemp.receiver,
            swapTemp.target,
            swapTemp.srcToken,
            swapTemp.swapToken,
            swapTemp.srcAmount,
            swapTemp.swapAmount,
            swapTemp.callAmount,
            swapTemp.fromChain,
            swapTemp.toChain,
            swapTemp.from
        );
    }

    function doRemoteSwap(
        Helper.SwapParam memory _swap,
        address _srcToken,
        uint256 _amount
    ) external returns (address target, address dstToken, uint256 dstAmount) {
        require(msg.sender == address(this));
        bool result;
        (result, dstToken, dstAmount) = _makeSwap(_amount, _srcToken, _swap);
        require(result, ErrorMessage.SWAP_FAIL);
        require(dstAmount >= _swap.minReturnAmount, ErrorMessage.RECEIVE_LOW);
        target = _swap.executor;
    }

    function doRemoteCall(
        Helper.CallbackParam memory _callParam,
        address _callToken,
        uint256 _amount
    ) external returns (address target, uint256 callAmount) {
        require(msg.sender == address(this));
        bool result;
        (result, callAmount) = _callBack(_amount, _callToken, _callParam);
        require(result, ErrorMessage.CALL_FAIL);
        target = _callParam.target;
    }

    function _doBridge(
        address _sender,
        address _token,
        uint256 _value,
        BridgeParam memory _bridge
    ) internal returns (bytes32 _orderId) {
        if (Helper._isNative(_token)) {
            _orderId = IButterMosV2(mosAddress).swapOutNative{value: _value}(
                _sender,
                _bridge.receiver,
                _bridge.toChain,
                _bridge.data
            );
        } else {
            IERC20(_token).safeApprove(mosAddress, _value);
            _orderId = IButterMosV2(mosAddress).swapOutToken(
                _sender,
                _token,
                _bridge.receiver,
                _value,
                _bridge.toChain,
                _bridge.data
            );
        }
    }

    function setGasForReFund(uint256 _gasForReFund) external onlyOwner {
        gasForReFund = _gasForReFund;

        emit SetGasForReFund(_gasForReFund);
    }

    function setMosAddress(address _mosAddress) public onlyOwner returns (bool) {
        _setMosAddress(_mosAddress);
        return true;
    }

    function _setMosAddress(address _mosAddress) internal returns (bool) {
        require(_mosAddress.isContract(), ErrorMessage.NOT_CONTRACT);
        mosAddress = _mosAddress;
        emit SetMos(_mosAddress);
        return true;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library ErrorMessage {
    string internal constant ZERO_IN = "ButterRouterV2: zero in";

    string internal constant FEE_MISMATCH = "ButterRouterV2: fee mismatch";

    string internal constant FEE_LOWER = "ButterRouterV2: lower than fee";

    string internal constant ZERO_ADDR = "ButterRouterV2: zero addr";

    string internal constant NOT_CONTRACT = "ButterRouterV2: not contract";

    string internal constant BRIDGE_REQUIRE = "ButterRouterV2: bridge data required";

    string internal constant RECEIVE_LOW = "ButterRouterV2: receive too low";

    string internal constant SWAP_FAIL = "ButterRouterV2: swap failed";

    string internal constant SWAP_REQUIRE = "ButterRouterV2: swap data required";

    string internal constant CALL_AMOUNT_INVALID = "ButterRouterV2: callback amount invalid";

    string internal constant CALL_FAIL = "ButterRouterV2: callback failed";

    string internal constant MOS_ONLY = "ButterRouterV2: mos only";

    string internal constant DATA_EMPTY = "ButterRouterV2: data empty";

    string internal constant NO_APPROVE = "ButterRouterV2: not approved";

    string internal constant NATIVE_VALUE_OVERSPEND = "ButterRouterV2: native value overspend";
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

library Helper {
    using SafeERC20 for IERC20;
    address internal constant ZERO_ADDRESS = address(0);
    address internal constant NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct CallbackParam {
        address target;
        address approveTo;
        uint256 offset;
        uint256 extraNativeAmount;
        address receiver;
        bytes data;
    }

    struct SwapParam {
        uint8 dexType;
        address executor;
        address approveTo;
        address receiver;
        address dstToken;
        uint256 minReturnAmount;
        bytes data;
    }

    function _isNative(address token) internal pure returns (bool) {
        return (token == ZERO_ADDRESS || token == NATIVE_ADDRESS);
    }

    function _getBalance(address _token, address _account) internal view returns (uint256) {
        if (_isNative(_token)) {
            return _account.balance;
        } else {
            return IERC20(_token).balanceOf(_account);
        }
    }

    function _transfer(uint256 _chainId, address _token, address _to, uint256 _amount) internal {
        if (_isNative(_token)) {
            Address.sendValue(payable(_to), _amount);
        } else {
            if (_chainId == 728126428 && _token == 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C) {
                // Tron USDT
                _token.call(abi.encodeWithSelector(0xa9059cbb, _to, _amount));
            } else {
                IERC20(_token).safeTransfer(_to, _amount);
            }
        }
    }

    function _safeWithdraw(address _wToken, uint _value) internal returns (bool) {
        (bool success, bytes memory data) = _wToken.call(abi.encodeWithSelector(0x2e1a7d4d, _value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _getFirst4Bytes(bytes memory data) internal pure returns (bytes4 outBytes4) {
        if (data.length == 0) {
            return 0x0;
        }
        assembly {
            outBytes4 := mload(add(data, 32))
        }
    }

    function _makeSwap(
        uint256 _amount,
        address _srcToken,
        SwapParam memory _swap
    ) internal returns (bool _result, address _dstToken, uint256 _returnAmount) {
        _dstToken = _swap.dstToken;
        uint256 nativeValue = 0;
        bool isNative = Helper._isNative(_srcToken);
        if (isNative) {
            nativeValue = _amount;
        } else {
            IERC20(_srcToken).safeApprove(_swap.approveTo, 0);
            IERC20(_srcToken).safeApprove(_swap.approveTo, _amount);
        }
        _returnAmount = Helper._getBalance(_dstToken, address(this));

        (_result, ) = _swap.executor.call{value: nativeValue}(_swap.data);

        _returnAmount = Helper._getBalance(_dstToken, address(this)) - _returnAmount;

        if (!isNative) {
            IERC20(_srcToken).safeApprove(_swap.approveTo, 0);
        }
    }

    function _callBack(
        uint256 _amount,
        address _token,
        CallbackParam memory _callParam
    ) internal returns (bool _result, uint256 _callAmount) {
        _callAmount = Helper._getBalance(_token, address(this));
        uint256 offset = _callParam.offset;
        bytes memory callDatas = _callParam.data;
        if (offset != 0) {
            assembly {
                mstore(add(callDatas, offset), _amount)
            }
        }
        if (Helper._isNative(_token)) {
            (_result, ) = _callParam.target.call{value: _amount}(callDatas);
        } else {
            if (_amount != 0) IERC20(_token).safeIncreaseAllowance(_callParam.approveTo, _amount);
            // this contract not save money make sure send value can cover this
            (_result, ) = _callParam.target.call{value: _callParam.extraNativeAmount}(callDatas);
            if (_amount != 0) IERC20(_token).safeApprove(_callParam.approveTo, 0);
        }
        _callAmount = _callAmount - Helper._getBalance(_token, address(this));
    }

    function _permit(bytes memory _data) internal {
        (
            address token,
            address owner,
            address spender,
            uint256 value,
            uint256 deadline,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) = abi.decode(_data, (address, address, address, uint256, uint256, uint8, bytes32, bytes32));

        SafeERC20.safePermit(IERC20Permit(token), owner, spender, value, deadline, v, r, s);
    }
}