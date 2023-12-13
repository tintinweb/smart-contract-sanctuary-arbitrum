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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * Provides set of properties, functions, and modifiers to help with 
 * security and access control of extending contracts
 */
contract ArcBase is Ownable2Step, Pausable, ReentrancyGuard
{
    function pause() public onlyOwner
    {
        _pause();
    }
    
    function unpause() public onlyOwner
    {
        _unpause();
    }

    function withdrawNative(address beneficiary) public onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = beneficiary.call{value: amount}("");
        require(sent, 'Unable to withdraw');
    }

    function withdrawToken(address beneficiary, address token) public onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(beneficiary, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {ArcBase} from "./ArcBase.sol";
import {IRainbowRoad} from "../interfaces/IRainbowRoad.sol";

/**
 * Extends the ArcBase contract to provide
 * for interactions with the Rainbow Road
 */
contract ArcBaseWithRainbowRoad is ArcBase
{
    IRainbowRoad public rainbowRoad;
    
    constructor(address _rainbowRoad)
    {
        require(_rainbowRoad != address(0), 'Rainbow Road cannot be zero address');
        rainbowRoad = IRainbowRoad(_rainbowRoad);
    }
    
    function setRainbowRoad(address _rainbowRoad) external onlyOwner
    {
        require(_rainbowRoad != address(0), 'Rainbow Road cannot be zero address');
        rainbowRoad = IRainbowRoad(_rainbowRoad);
    }
    
    /// @dev Only calls from the Rainbow Road are accepted.
    modifier onlyRainbowRoad() 
    {
        require(msg.sender == address(rainbowRoad), 'Must be called by Rainbow Road');
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ArcBaseWithRainbowRoad} from "../bases/ArcBaseWithRainbowRoad.sol";
import {IHandler} from "../interfaces/IHandler.sol";
import {IFeeCollectorFactory} from "../interfaces/IFeeCollectorFactory.sol";
import {IFeeCollector} from "../interfaces/IFeeCollector.sol";
import {IMintBurn} from "../interfaces/IMintBurn.sol";

/**
 * ERC20 Transfer Handler
 */
contract Erc20TransferHandler is ArcBaseWithRainbowRoad, IHandler
{
    using SafeERC20 for IERC20;
    
    bool public chargeTxFee;
    uint256 public txFeeRate;
    uint256 public bribeFeeRate;
    uint256 public constant MAX_TX_FEE_RATE = 200; // 20%
    uint256 public constant MAX_BRIBE_FEE_RATE = 1000; // 100%
    uint256 public constant MAX_FEE_ON_TRANSFER_PCT_RATE = 1000; // 100%
    address public bribeCollector;
    IFeeCollectorFactory public feeCollectorFactory;
    mapping(string => address) public feeCollectors;
    mapping(string => uint256) public feeOnTransferFlatRate;
    mapping(string => uint256) public feeOnTransferPercentageRate;
    mapping(string => bool) public isMintBurn;
    
    constructor(address _rainbowRoad, address _feeCollectorFactory) ArcBaseWithRainbowRoad(_rainbowRoad)
    {
        require(_feeCollectorFactory != address(0), 'Fee Collector Factory cannot be zero address');
        
        chargeTxFee = true;
        txFeeRate = 25; // 25 bps = 2.5%
        bribeFeeRate = 300; // 300 bps = 30%
        bribeCollector = 0x1d9E69A851b2c439A964d8dc3d611781440fd658;
        feeCollectorFactory = IFeeCollectorFactory(_feeCollectorFactory);
    }
    
    function enableTxFeeCharge() external onlyOwner
    {
        require(!chargeTxFee, 'Charge tx fee is enabled');
        chargeTxFee = true;
    }
    
    function disableTxFeeCharge() external onlyOwner
    {
        require(chargeTxFee, 'Charge tx fee is disabled');
        chargeTxFee = false;
    }
    
    function enableMintBurn(string calldata tokenSymbol) external onlyOwner
    {
        require(!isMintBurn[tokenSymbol], 'Mint and burn is enabled');
        isMintBurn[tokenSymbol] = true;
    }
    
    function disableMintBurn(string calldata tokenSymbol) external onlyOwner
    {
        require(isMintBurn[tokenSymbol], 'Mint and burn is disabled');
        isMintBurn[tokenSymbol] = false;
    }
    
    function setTxFeeRate(uint256 _txFeeRate) external {
        require(rainbowRoad.feeManagers(msg.sender), 'Invalid fee manager');
        require(_txFeeRate <= MAX_TX_FEE_RATE, 'Tx fee rate too high');
        txFeeRate = _txFeeRate;
    }
    
    function setBribeFeeRate(uint256 _bribeFeeRate) external {
        require(rainbowRoad.feeManagers(msg.sender), 'Invalid fee manager');
        require(_bribeFeeRate <= MAX_BRIBE_FEE_RATE, 'Bribe fee rate too high');
        bribeFeeRate = _bribeFeeRate;
    }
    
    function setFeeOnTransferFlatRate(string calldata tokenSymbol, uint256 _feeOnTransferFlatRate) external {
        require(rainbowRoad.feeManagers(msg.sender), 'Invalid fee manager');
        
        address tokenAddress = rainbowRoad.tokens(tokenSymbol);
        require(tokenAddress != address(0), 'Token must be whitelisted');
        require(!rainbowRoad.blockedTokens(tokenAddress), 'Token is blocked');
        feeOnTransferFlatRate[tokenSymbol] = _feeOnTransferFlatRate;
    }
    
    function setFeeOnTransferPercentageRate(string calldata tokenSymbol, uint256 _feeOnTransferPercentageRate) external {
        require(rainbowRoad.feeManagers(msg.sender), 'Invalid fee manager');
        
        address tokenAddress = rainbowRoad.tokens(tokenSymbol);
        require(tokenAddress != address(0), 'Token must be whitelisted');
        require(!rainbowRoad.blockedTokens(tokenAddress), 'Token is blocked');
        require(_feeOnTransferPercentageRate <= MAX_FEE_ON_TRANSFER_PCT_RATE, 'Fee on transfer rate too high');
        feeOnTransferPercentageRate[tokenSymbol] = _feeOnTransferPercentageRate;
    }
    
    function setBribeCollector(address _bribeCollector) external onlyOwner {
        bribeCollector = _bribeCollector;
    }
    
    function setFeeCollectorFactory(address _feeCollectorFactory) external onlyOwner
    {
        require(_feeCollectorFactory != address(0), 'Fee Collector Factory cannot be zero address');
        feeCollectorFactory = IFeeCollectorFactory(_feeCollectorFactory);
    }
    
    function setFeeCollector(string calldata tokenSymbol, address feeCollectorAddress) external onlyOwner
    {
        address tokenAddress = rainbowRoad.tokens(tokenSymbol);
        require(tokenAddress != address(0), 'Token must be whitelisted');
        require(!rainbowRoad.blockedTokens(tokenAddress), 'Token is blocked');
        require(feeCollectorAddress != address(0), 'Fee collector cannot be zero address');
        
        feeCollectors[tokenSymbol] = feeCollectorAddress;
    }
    
    function encodePayload(string calldata tokenSymbol, uint256 amount) view external returns (bytes memory payload)
    {
        address tokenAddress = rainbowRoad.tokens(tokenSymbol);
        require(tokenAddress != address(0), 'Token must be whitelisted');
        require(!rainbowRoad.blockedTokens(tokenAddress), 'Token is blocked');
        require(amount > 0, 'Invalid amount');
        
        uint256 amountToSend = amount;
        
        if(feeOnTransferPercentageRate[tokenSymbol] > 0) {
            uint256 transferFee = (feeOnTransferPercentageRate[tokenSymbol] * amount) / 1000;
            require(amountToSend > transferFee, 'Insufficient amount to send : Percent Rate');
            amountToSend = amountToSend - transferFee;
        }
        
        if(feeOnTransferFlatRate[tokenSymbol] > 0) {
            require(amountToSend > feeOnTransferFlatRate[tokenSymbol], 'Insufficient amount to send : Flat Rate');
            amountToSend = amountToSend - feeOnTransferFlatRate[tokenSymbol];
        }
        
        return abi.encode(tokenSymbol, amountToSend, amount - amountToSend);
    }
    
    function handleReceive(address target, bytes calldata payload) external onlyRainbowRoad whenNotPaused nonReentrant
    {
        (string memory tokenSymbol, uint256 amount) = abi.decode(payload, (string, uint256));
        require(amount > 0, 'Invalid amount');
        
        address tokenAddress = rainbowRoad.tokens(tokenSymbol);
        require(tokenAddress != address(0), 'Token must be whitelisted');
        require(!rainbowRoad.blockedTokens(tokenAddress), 'Token is blocked');
        
        if(isMintBurn[tokenSymbol]) {
            IMintBurn(tokenAddress).mint(address(this), amount);
        }
        
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, 'Insufficient funds for transfer');
        
        uint256 txFee = 0;
        if(chargeTxFee) {
            txFee = (txFeeRate * amount) / 1000;
            uint256 bribeFee = (bribeFeeRate * txFee) / 1000;
            uint256 lpFee = txFee - bribeFee;
            
            if(bribeFee > 0) {
                token.safeTransfer(bribeCollector, bribeFee);
            }
            
            if(feeCollectors[tokenSymbol] == address(0)) {
                feeCollectors[tokenSymbol] = feeCollectorFactory.createFeeCollector(address(rainbowRoad), address(this));
            }
            
            if(lpFee > 0) {
                token.approve(feeCollectors[tokenSymbol], lpFee);
                IFeeCollector(feeCollectors[tokenSymbol]).notifyRewardAmount(tokenAddress, lpFee);
            }
        }
        
        token.safeTransfer(target, amount - txFee);
    }
    
    function handleSend(address target, bytes calldata payload) external onlyRainbowRoad whenNotPaused nonReentrant
    {
        (string memory tokenSymbol, uint256 amount, uint256 feeOnTransferAmount) = abi.decode(payload, (string, uint256, uint256));
        require(amount > 0, 'Invalid amount');
        address tokenAddress = rainbowRoad.tokens(tokenSymbol);
        require(tokenAddress != address(0), 'Token must be whitelisted');
        require(!rainbowRoad.blockedTokens(tokenAddress), 'Token is blocked');
        
        uint256 feeOnTransfer = feeOnTransferAmount;
        
        if(feeOnTransferPercentageRate[tokenSymbol] > 0) {
            uint256 transferFee = (feeOnTransferPercentageRate[tokenSymbol] * (amount + feeOnTransferAmount)) / 1000;
            require(feeOnTransfer >= transferFee, 'Insufficient amount to send : Percent Rate');
            feeOnTransfer = feeOnTransfer - transferFee;
        }
        
        if(feeOnTransferFlatRate[tokenSymbol] > 0) {
            require(feeOnTransfer >= feeOnTransferFlatRate[tokenSymbol], 'Insufficient amount to send : Flat Rate');
            feeOnTransfer = feeOnTransfer - feeOnTransferFlatRate[tokenSymbol];
        }
        
        require(feeOnTransfer == 0, 'Invalid fee on transfer amount');
        
        uint256 amountToSend = amount + feeOnTransferAmount;
        
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(target) >= amountToSend, 'Target has insufficient balance for transfer');
        uint256 preTransferBalance = token.balanceOf(address(this));
        token.safeTransferFrom(target, address(this), amountToSend);
        uint256 postTransferBalance = token.balanceOf(address(this));
        uint256 diffTransferBalance = postTransferBalance - preTransferBalance;
        require(diffTransferBalance >= amount, 'Invalid transfer amount');
        
        if(isMintBurn[tokenSymbol]) {
            IMintBurn(tokenAddress).burn(amountToSend);
        }
    }
    
    function deposit(string calldata tokenSymbol, uint256 amount) external nonReentrant
    {
        require(rainbowRoad.tokens(tokenSymbol) != address(0), 'Token must be whitelisted');
        require(amount > 0, 'Invalid amount');
        
        address tokenAddress = rainbowRoad.tokens(tokenSymbol);
        require(tokenAddress != address(0), 'Token address cannot be zero address');
        require(!rainbowRoad.blockedTokens(tokenAddress), 'Token is blocked');
        
        if(feeCollectors[tokenSymbol] == address(0)) {
            feeCollectors[tokenSymbol] = feeCollectorFactory.createFeeCollector(address(rainbowRoad), address(this));
        }
        
        IERC20 token = IERC20(tokenAddress);
        uint256 preDepositBalance = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 postDepositBalance = token.balanceOf(address(this));
        uint256 diffDepositBalance = postDepositBalance - preDepositBalance;
        
        IFeeCollector(feeCollectors[tokenSymbol]).deposit(msg.sender, diffDepositBalance);
    }
    
    function withdraw(string calldata tokenSymbol, uint256 amount) external nonReentrant
    {
        require(rainbowRoad.tokens(tokenSymbol) != address(0), 'Token must be whitelisted');
        require(amount > 0, 'Invalid amount');
        
        address tokenAddress = rainbowRoad.tokens(tokenSymbol);
        require(tokenAddress != address(0), 'Token address cannot be zero address');
        require(!rainbowRoad.blockedTokens(tokenAddress), 'Token is blocked');
        require(feeCollectors[tokenSymbol] != address(0), 'No fee collector found');
       
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, 'Insufficient liquidity for withdrawal');
        
        IFeeCollector feeCollector = IFeeCollector(feeCollectors[tokenSymbol]);
        require(feeCollector.balanceOf(msg.sender) >= amount, 'Insufficient account balance for withdrawal');
        feeCollector.withdraw(msg.sender, amount);
        token.safeTransfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IArc {
    function approve(address _spender, uint _value) external returns (bool);
    function burn(uint amount) external;
    function mint(address account, uint amount) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address _from, address _to, uint _value) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IFeeCollector {
    function balanceLockExpires(address account) external view returns (uint);
    function balanceOf(address account) external returns (uint);
    function deposit(address account, uint amount) external;
    function earned(address token, address account) external view returns (uint);
    function getEpochStart(uint timestamp) external pure returns (uint);
    function getReward(address[] memory tokens) external;
    function isBalanceLockExpired(address account) external view returns (bool);
    function left(address token) external view returns (uint);
    function notifyRewardAmount(address token, uint amount) external;
    function withdraw(address account, uint amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IFeeCollectorFactory {
    function createFeeCollector(address rainbowRoad, address authorizedAccount) external returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IHandler {
    function handleReceive(address target, bytes calldata payload) external;
    function handleSend(address target, bytes calldata payload) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IMintBurn {
    function burn(uint amount) external;
    function mint(address account, uint amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IArc} from "./IArc.sol";

interface IRainbowRoad {
    
    function acceptTeam() external;
    function actionHandlers(string calldata action) external view returns (address);
    function arc() external view returns (IArc);
    function blockToken(address tokenAddress) external;
    function disableFeeManager(address feeManager) external;
    function disableOpenTokenWhitelisting() external;
    function disableReceiver(address receiver) external;
    function disableSender(address sender) external;
    function disableSendFeeBurn() external;
    function disableSendFeeCharge() external;
    function disableWhitelistingFeeBurn() external;
    function disableWhitelistingFeeCharge() external;
    function enableFeeManager(address feeManager) external;
    function enableOpenTokenWhitelisting() external;
    function enableReceiver(address receiver) external;
    function enableSendFeeBurn() external;
    function enableSender(address sender) external;
    function enableSendFeeCharge() external;
    function enableWhitelistingFeeBurn() external;
    function enableWhitelistingFeeCharge() external;
    function sendFee() external view returns (uint256);
    function whitelistingFee() external view returns (uint256);
    function chargeSendFee() external view returns (bool);
    function chargeWhitelistingFee() external view returns (bool);
    function burnSendFee() external view returns (bool);
    function burnWhitelistingFee() external view returns (bool);
    function openTokenWhitelisting() external view returns (bool);
    function config(string calldata configName) external view returns (bytes memory);
    function blockedTokens(address tokenAddress) external view returns (bool);
    function feeManagers(address feeManager) external view returns (bool);
    function receiveAction(string calldata action, address to, bytes calldata payload) external;
    function sendAction(string calldata action, address from, bytes calldata payload) external;
    function setActionHandler(string memory action, address handler) external;
    function setArc(address _arc) external;
    function setSendFee(uint256 _fee) external;
    function setTeam(address _team) external;
    function setTeamRate(uint256 _teamRate) external;
    function setToken(string calldata tokenSymbol, address tokenAddress) external;
    function setWhitelistingFee(uint256 _fee) external;
    function team() external view returns (address);
    function teamRate() external view returns (uint256);
    function tokens(string calldata tokenSymbol) external view returns (address);
    function MAX_TEAM_RATE() external view returns (uint256);
    function receivers(address receiver) external view returns (bool);
    function senders(address sender) external view returns (bool);
    function unblockToken(address tokenAddress) external;
    function whitelist(address tokenAddress) external;
}