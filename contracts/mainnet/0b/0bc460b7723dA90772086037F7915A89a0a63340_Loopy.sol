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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

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
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

// Inspired by Aave Protocol's IFlashLoanReceiver.

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IFlashLoanRecipient {
  /**
   * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
   *
   * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
   * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
   * Vault, or else the entire flash loan will revert.
   *
   * `userData` is the same value passed in the `IVault.flashLoan` call.
   */
  function receiveFlashLoan(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    uint256[] memory feeAmounts,
    bytes memory userData
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILoopy {
    struct UserData {
        address user;
        uint256 tokenAmount;
        IERC20 borrowedToken;
        uint256 borrowedAmount;
        IERC20 tokenToLoop;
    }

    error UNAUTHORIZED(string);
    error INVALID_LEVERAGE();
    error INVALID_APPROVAL();
    error FAILED(string);
}

interface IGlpDepositor {
    function deposit(uint256 _amount) external;

    function redeem(uint256 _amount) external;

    function donate(uint256 _assets) external;
}

interface IRewardRouterV2 {
    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);
}

interface ICERC20Update {
    function borrowBehalf(uint256 borrowAmount, address borrowee) external returns (uint256);
    function _addReserves(uint256 addAmount) external returns (uint256);
}

interface ICERC20 is IERC20, ICERC20Update {
    // CToken
    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Returns the current per-block borrow interest rate for this cToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view returns (uint256);

    /**
     * @notice Returns the current per-block supply interest rate for this cToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view returns (uint256);

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    // Cerc20
    function mint(uint256 mintAmount) external returns (uint256);
}

interface IPriceOracleProxyETH {
    function getUnderlyingPrice(address cToken) external view returns (uint256);
}

// 6/26/2023: https://docs.balancer.fi/reference/contracts/deployment-addresses/mainnet.html#gauges-and-governance
interface IProtocolFeesCollector {
    function getFlashLoanFeePercentage() external view returns (uint256);
}

interface IGlpOracleInterface {
    function getGLPPrice() external view returns (uint256);

    function getPlvGLPPrice() external view returns (uint256);
}

interface IUnitrollerInterface {
    function getAccountLiquidity(address account) external view returns (uint256, uint256, uint256);

    function getHypotheticalAccountLiquidity(
        address account,
        address cTokenModify,
        uint256 redeemTokens,
        uint256 borrowTokens
    ) external view returns (uint256, uint256, uint256);
}

interface SushiRouterInterface {
    function WETH() external returns (address);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        fixed swapAmountETH,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import './IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.17;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IFlashLoanRecipient.sol';

interface IVault {
  /**
   * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
   * and then reverting unless the tokens plus a proportional protocol fee have been returned.
   *
   * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
   * for each token contract. `tokens` must be sorted in ascending order.
   *
   * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
   * `receiveFlashLoan` call.
   *
   * Emits `FlashLoan` events.
   */
  function flashLoan(
    IFlashLoanRecipient recipient,
    IERC20[] memory tokens,
    uint256[] memory amounts,
    bytes memory userData
  ) external;
}

//SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

// Ref: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
interface IUniswapV2Pair {
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

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

// importing dependencies and required interfaces
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IFlashLoanRecipient.sol";
import "./LoopyConstants.sol";
import "./utils/Swap.sol";

/**
 * @title Loopy
 * @notice This contract allows users to leverage their positions by borrowing 
 * assets, increasing their supply and thus enabling higher yields.
 * @dev The contract implements the ILoopy, LoopyConstantsMock, Swap, Ownable2Step, 
 * IFlashLoanRecipient, and ReentrancyGuard interfaces. It uses SafeERC20 for 
 * safe token transfers.
 */
contract Loopy is ILoopy, LoopyConstants, Swap, Ownable2Step, IFlashLoanRecipient, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // add mapping of token addresses to their decimal places
    mapping(IERC20 => uint8) public decimals;
    // add mapping to store the allowed tokens. Mapping provides faster access than array
    mapping(IERC20 => bool) public allowedTokens;
    // add mapping to store lToken contracts
    mapping(IERC20 => ICERC20) private lTokenMapping;
    // add mapping to store lToken collateral factors
    mapping(IERC20 => uint64) private collateralFactor;

    constructor() {
        // initialize decimals for each token
        decimals[USDC_NATIVE] = 6;
        decimals[USDC_BRIDGED] = 6;
        decimals[USDT] = 6;
        decimals[WBTC] = 8;
        decimals[DAI] = 18;
        decimals[FRAX] = 18;
        decimals[ARB] = 18;
        decimals[PLVGLP] = 18;

        // set the allowed tokens in the constructor
        // we can add/remove these with owner functions later
        allowedTokens[USDC_NATIVE] = true;
        allowedTokens[USDC_BRIDGED] = true;
        allowedTokens[USDT] = true;
        allowedTokens[WBTC] = true;
        allowedTokens[DAI] = true;
        allowedTokens[FRAX] = true;
        allowedTokens[ARB] = true;
        allowedTokens[PLVGLP] = true;

        // map tokens to lTokens
        lTokenMapping[USDC_NATIVE] = lUSDC;
        lTokenMapping[USDC_BRIDGED] = lUSDCe;
        lTokenMapping[USDT] = lUSDT;
        lTokenMapping[WBTC] = lWBTC;
        lTokenMapping[DAI] = lDAI;
        lTokenMapping[FRAX] = lFRAX;
        lTokenMapping[ARB] = lARB;
        lTokenMapping[PLVGLP] = lPLVGLP;

        // map lTokens to collateralFactors
        collateralFactor[USDC_NATIVE] = 820000000000000000;
        collateralFactor[USDC_BRIDGED] = 820000000000000000;
        collateralFactor[USDT] = 700000000000000000;
        collateralFactor[WBTC] = 750000000000000000;
        collateralFactor[DAI] = 750000000000000000;
        collateralFactor[FRAX] = 750000000000000000;
        collateralFactor[ARB] = 700000000000000000;
        collateralFactor[PLVGLP] = 750000000000000000;

        // approve glp contracts to spend USDC for minting GLP
        USDC_BRIDGED.approve(address(REWARD_ROUTER_V2), type(uint256).max);
        USDC_BRIDGED.approve(address(GLP), type(uint256).max);
        USDC_BRIDGED.approve(address(GLP_MANAGER), type(uint256).max);
        // approve GlpDepositor to spend GLP for minting plvGLP
        sGLP.approve(address(GLP_DEPOSITOR), type(uint256).max);
        GLP.approve(address(GLP_DEPOSITOR), type(uint256).max);
        sGLP.approve(address(REWARD_ROUTER_V2), type(uint256).max);
        GLP.approve(address(REWARD_ROUTER_V2), type(uint256).max);
        // approve balancer vault
        USDC_BRIDGED.approve(address(VAULT), type(uint256).max);
        USDT.approve(address(VAULT), type(uint256).max);
        WBTC.approve(address(VAULT), type(uint256).max);
        DAI.approve(address(VAULT), type(uint256).max);
        FRAX.approve(address(VAULT), type(uint256).max);
        ARB.approve(address(VAULT), type(uint256).max);
        // approve lTokens to be minted using underlying
        USDC_NATIVE.approve(address(lUSDC), type(uint256).max);
        USDC_BRIDGED.approve(address(lUSDCe), type(uint256).max);
        PLVGLP.approve(address(lPLVGLP), type(uint256).max);
        USDT.approve(address(lUSDT), type(uint256).max);
        WBTC.approve(address(lWBTC), type(uint256).max);
        DAI.approve(address(lDAI), type(uint256).max);
        FRAX.approve(address(lFRAX), type(uint256).max);
        ARB.approve(address(lARB), type(uint256).max);
        // approve uni router for native and bridged USDC swap
        USDC_NATIVE.approve(address(UNI_ROUTER), type(uint256).max);
        USDC_BRIDGED.approve(address(UNI_ROUTER), type(uint256).max);
        // approve our address to send tokens back to the user (used in the USDC native workflow)
        USDC_BRIDGED.approve(address(this), type(uint256).max);
    }

    // declare events
    event ProtocolFeeUpdated(uint256 amount);
    event AmountAddedToReserves(uint256 amount);

    /**
     * @notice Allows the owner to add a token to the platform
     * @param tokenAddress The token's contract address
     * @param tokenDecimals The token's decimal places
     * @param lTokenAddress The associated lToken contract's address
     */
    function addToken(IERC20 tokenAddress, uint8 tokenDecimals, ICERC20 lTokenAddress, uint64 tokenCollateralFactor) external onlyOwner {
        require(!allowedTokens[tokenAddress], "token already allowed");
        allowedTokens[tokenAddress] = true;

        // create our IERC20 object and map it accordingly
        ICERC20 _lTokenSymbol = ICERC20(lTokenAddress);
        decimals[tokenAddress] = tokenDecimals;
        lTokenMapping[tokenAddress] = _lTokenSymbol;
        collateralFactor[tokenAddress] = tokenCollateralFactor;

        // approve balance vault and the lToken market to be able to spend the newly added underlying
        tokenAddress.approve(address(VAULT), type(uint256).max);
        tokenAddress.approve(address(_lTokenSymbol), type(uint256).max);
    }

    /**
     * @notice Allows the owner to remove a token from the platform
     * @param tokenAddress The token's contract address
     */
    function removeToken(IERC20 tokenAddress) external onlyOwner {
        require(allowedTokens[tokenAddress], "token not allowed");
        allowedTokens[tokenAddress] = false;

        // nullify, essentially, existing records
        delete decimals[tokenAddress];
        delete lTokenMapping[tokenAddress];
        delete collateralFactor[tokenAddress];
    }

    /**
     * @notice Allows the owner to update the protocol's fee percentage
     * @param _protocolFeePercentage The new protocol fee percentage
     */
    function updateProtocolFeePercentage(uint256 _protocolFeePercentage) external onlyOwner {
        protocolFeePercentage = _protocolFeePercentage;
        emit ProtocolFeeUpdated(protocolFeePercentage);
    }

    /**
     * @notice Simulates a loop operation and checks whether the user can perform it with their current balance
     * @param _token The underlying token that the user wants to leverage
     * @param _amount The amount of the token that the user wants to use
     * @param _leverage The desired leverage (between 2x - 3x)
     * @param _user The user's address
     * @return 0 if the operation can be performed, 1 otherwise
     */
    function mockLoop(IERC20 _token, uint256 _amount, uint16 _leverage, address _user) external view returns (uint256) {
        {
            uint256 hypotheticalSupply;
            uint256 decimalScale;
            uint256 decimalExp;
            uint256 tokenDecimals;
            uint256 price;

            (uint256 loanAmount, IERC20 tokenToBorrow) = getNotionalLoanAmountIn1e18(_token, _amount, _leverage);

            loanAmount = loanAmount * (10000 + protocolFeePercentage) / 10000;

            // mock a hypothetical borrow to see what state it puts the account in (before factoring in our new liquidity)
            (, uint256 hypotheticalLiquidity, uint256 hypotheticalShortfall) = UNITROLLER
                .getHypotheticalAccountLiquidity(_user, address(lTokenMapping[tokenToBorrow]), 0, loanAmount);

            // if the account is still healthy without factoring in our newly supplied balance, we know for a fact they can support this operation.
            // so let's just return now and not waste any more time
            if (hypotheticalLiquidity > 0) {
                return 0; // pass
            } else {
                // otherwise, lets do some maths
                // lets get our hypotheticalSupply and and see if it's greater than our hypotheticalShortfall. if it is, we know the account can support this operation
                if (_token == PLVGLP) {
                    uint256 plvGLPPriceInEth = PLVGLP_ORACLE.getPlvGLPPrice();
                    tokenDecimals = (10 ** (decimals[PLVGLP]));
                    hypotheticalSupply =
                        (plvGLPPriceInEth * (loanAmount * (collateralFactor[PLVGLP] / 1e18))) /
                        tokenDecimals;
                } else {
                    // tokenToBorrow == _token in every instance that doesn't involve plvGLP (which borrows USDC)
                    uint256 tokenPriceInEth = PRICE_ORACLE.getUnderlyingPrice(address(lTokenMapping[tokenToBorrow]));
                    decimalScale = 18 - decimals[tokenToBorrow];
                    decimalExp = (10 ** decimalScale);
                    price = tokenPriceInEth / decimalExp;
                    tokenDecimals = (10 ** (decimals[tokenToBorrow]));
                    hypotheticalSupply =
                        (price * (loanAmount * (collateralFactor[tokenToBorrow] / 1e18))) /
                        tokenDecimals;
                }

                if (hypotheticalSupply > hypotheticalShortfall) {
                    return 0; // pass
                } else {
                    return 1; // fail
                }
            }
        }
    }

    /**
     * @notice Allows users to loop to a desired leverage, within pre-set ranges
     * @param _token The underlying token that the user wants to leverage
     * @param _amount The amount of the token that the user wants to use
     * @param _leverage The desired leverage (between 2x - 3x)
     * @param _useWalletBalance Flag to indicate if user's wallet balance should be used (0 being false, 1 being true)
     */
    function loop(IERC20 _token, uint256 _amount, uint16 _leverage, uint16 _useWalletBalance) external {
        require(allowedTokens[_token], "token not allowed to loop");
        require(tx.origin == msg.sender, "not an EOA");
        require(_amount > 0, "amount must be greater than 0");
        require(
            _leverage >= DIVISOR && _leverage <= MAX_LEVERAGE,
            "invalid leverage, range must be between DIVISOR and MAX_LEVERAGE values"
        );

        // mock loop when the user wants to use their existing lodestar balance.
        // if it fails we know the account cannot loop in the current state they are in
        if (_useWalletBalance == 0 && _token != PLVGLP && _token != USDC_NATIVE) {
            uint256 shortfall = this.mockLoop(_token, _amount, _leverage, msg.sender);
            require(
                shortfall == 0,
                "Existing balance on Lodestar unable to support operation. Please consider increasing your supply balance first."
            );
        }

        if (_useWalletBalance == 0 && (_token == PLVGLP || _token == USDC_NATIVE)) {
            uint256 amountPlusSlippage = (_amount * 101) / 100;
            uint256 shortfall = this.mockLoop(_token, amountPlusSlippage, _leverage, msg.sender);
            require(
                shortfall == 0,
                "Existing balance on Lodestar unable to support operation. Please consider increasing your supply balance first."
            );
        }
        // if the user wants us to mint using their existing wallet balance (indiciated with 1), then do so.
        // otherwise, read their existing balance and flash loan to increase their position
        if (_useWalletBalance == 1) {
            // transfer tokens to this contract so we can mint in 1 go.
            _token.safeTransferFrom(msg.sender, address(this), _amount);
        }

        uint256 loanAmount;
        IERC20 tokenToBorrow;

        (loanAmount, tokenToBorrow) = getNotionalLoanAmountIn1e18(_token, _amount, _leverage);

        if (tokenToBorrow.balanceOf(address(BALANCER_VAULT)) < loanAmount)
            revert FAILED("balancer vault token balance < loan");

        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = tokenToBorrow;

        uint256[] memory loanAmounts = new uint256[](1);
        loanAmounts[0] = loanAmount;

        UserData memory userData = UserData({
            user: msg.sender,
            tokenAmount: _amount,
            borrowedToken: tokenToBorrow,
            borrowedAmount: loanAmount,
            tokenToLoop: _token
        });

        BALANCER_VAULT.flashLoan(IFlashLoanRecipient(this), tokens, loanAmounts, abi.encode(userData));
    }

    /**
     * @notice Callback function to be executed after the flash loan operation
     * @param tokens Array of token addresses involved in the loan
     * @param amounts Array of token amounts involved in the loan
     * @param feeAmounts Array of fee amounts for the loan
     * @param userData Data regarding the user of the loan
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override nonReentrant {
        if (msg.sender != address(BALANCER_VAULT)) revert UNAUTHORIZED("balancer vault is not the sender");

        UserData memory data = abi.decode(userData, (UserData));

        // ensure the transaction is user originated
        if (tx.origin != data.user) revert UNAUTHORIZED("user did not originate transaction");

        // ensure we borrowed the proper amounts
        if (data.borrowedAmount != amounts[0] || data.borrowedToken != tokens[0])
            revert FAILED("borrowed amounts and/or borrowed tokens do not match initially set values");

        // account for some plvGLP specific logic
        if (data.tokenToLoop == PLVGLP) {
            uint256 nominalSlippage = 5e16; // 5% slippage tolerance
            uint256 glpPrice = getGLPPrice(); // returns in 1e18
            uint256 minumumExpectedUSDCSwapAmount = (data.borrowedAmount) * (1e18 - nominalSlippage);
            uint256 minimumExpectedGlpSwapAmount = (minumumExpectedUSDCSwapAmount / (glpPrice / 1e18)) / 1e6;

            // mint GLP. approval needed
            uint256 glpAmount = REWARD_ROUTER_V2.mintAndStakeGlp(
                address(data.borrowedToken), // the token to buy GLP with
                data.borrowedAmount, // the amount of token to use for the purchase
                0, // the minimum acceptable USD value of the GLP purchased
                minimumExpectedGlpSwapAmount // the minimum acceptible GLP amount
            );
            if (glpAmount == 0) revert FAILED("glp=0");
            if (glpAmount < minimumExpectedGlpSwapAmount)
                revert FAILED("glp amount returned less than minumum expected swap amount");

            // this contract always needs to be whitelisted for plvGLP mint
            // mint plvGLP. approval needed
            uint256 _oldPlvglpBal = PLVGLP.balanceOf(address(this));
            GLP_DEPOSITOR.deposit(glpAmount);

            // check new balances and confirm we properly minted
            uint256 _newPlvglpBal = PLVGLP.balanceOf(address(this));
            require(_newPlvglpBal > _oldPlvglpBal, "glp deposit failed, new balance < old balance");
        }

        uint256 baseBorrowAmount;
        uint256 finalBal;

        // mint our respective token by depositing it into Lodestar's respective lToken contract (approval needed)
        unchecked {
            // if we are in the native usdc loop flow, let's make sure we swap our borrowed bridged usdc from balancer for native usdc before minting
            if (data.tokenToLoop == USDC_NATIVE) {
                uint256 bridgedUSDCBalance = USDC_BRIDGED.balanceOf(address(this));
                // account for slippage on the swap back to bridged USDC
                uint256 minAmountOut = (bridgedUSDCBalance * 99 / 100);
                Swap.swapThroughUniswap(
                    address(USDC_BRIDGED),
                    address(USDC_NATIVE),
                    bridgedUSDCBalance,
                    minAmountOut
                );
            }
            lTokenMapping[data.tokenToLoop].mint(data.tokenToLoop.balanceOf(address(this)));
            lTokenMapping[data.tokenToLoop].transfer(
                data.user,
                lTokenMapping[data.tokenToLoop].balanceOf(address(this))
            );
            finalBal = lTokenMapping[data.tokenToLoop].balanceOf(address(this));

            // emit lTokenBalance(_finalBal);
            require(finalBal == 0, "lToken balance not 0 at the end of loop");
        }

        uint256 repayAmountFactoringInFeeAmount;
        uint256 repayAmountFactoringInFeeAndSlippage;
        uint256 repayAmountFactoringInBothFeeAmounts;

        // factor in any balancer fees into the overall loan amount we wish to borrow
        uint256 currentBalancerFeePercentage = BALANCER_PROTOCOL_FEES_COLLECTOR.getFlashLoanFeePercentage();
        uint256 currentBalancerFeeAmount = (data.borrowedAmount * currentBalancerFeePercentage) / 1e18;

        // if the loop token is plvGLP or native USDC, we need to borrow a little more to account for extra fees
        if (data.tokenToLoop == PLVGLP || data.tokenToLoop == USDC_NATIVE) {
            // add in the various fees (balancer and protocol)
            baseBorrowAmount = (data.borrowedAmount * 101) / 100;
            repayAmountFactoringInFeeAmount = data.borrowedAmount + currentBalancerFeeAmount;
            repayAmountFactoringInFeeAndSlippage = baseBorrowAmount + currentBalancerFeeAmount;
            repayAmountFactoringInBothFeeAmounts = repayAmountFactoringInFeeAndSlippage * (10000 + protocolFeePercentage) / 10000;
        } else {
            // add in the various fees (balancer and protocol)
            repayAmountFactoringInFeeAmount = data.borrowedAmount + currentBalancerFeeAmount;
            repayAmountFactoringInBothFeeAmounts = repayAmountFactoringInFeeAmount * (10000 + protocolFeePercentage) / 10000;
        }

        uint256 amountToAddToReserves;
        if (data.tokenToLoop == PLVGLP || data.tokenToLoop == USDC_NATIVE) {
            // plvGLP requires us to repay the loan with USDC
            lUSDC.borrowBehalf(repayAmountFactoringInBothFeeAmounts, data.user);

            // transfer native USDC back into the contract after borrowing bridged USDC
            USDC_NATIVE.safeTransferFrom(data.user, address(this), repayAmountFactoringInBothFeeAmounts);

            // take the protocol fee while we still have native USDC and deposit it into the lUSDC market reserves
            uint256 slippage = repayAmountFactoringInFeeAndSlippage - repayAmountFactoringInFeeAmount;

            amountToAddToReserves = repayAmountFactoringInBothFeeAmounts - repayAmountFactoringInFeeAmount - slippage;
            lTokenMapping[USDC_NATIVE]._addReserves(amountToAddToReserves);
            emit AmountAddedToReserves(amountToAddToReserves);

            // we need to swap our native USDC for bridged USDC to repay the loan
            uint256 nativeUSDCBalance = USDC_NATIVE.balanceOf(address(this));
            Swap.swapThroughUniswap(
                address(USDC_NATIVE),
                address(USDC_BRIDGED),
                nativeUSDCBalance,
                repayAmountFactoringInFeeAmount
            );

            // transfer bridged USDC back to the user so we can repay the loan
            USDC_BRIDGED.safeTransferFrom(address(this), data.user, USDC_BRIDGED.balanceOf(address(this)));

            // repay loan, where msg.sender = vault
            USDC_BRIDGED.safeTransferFrom(data.user, msg.sender, repayAmountFactoringInFeeAmount);
        } else {
            // call borrowBehalf to borrow tokens on behalf of user
            lTokenMapping[data.tokenToLoop].borrowBehalf(repayAmountFactoringInBothFeeAmounts, data.user);

            // take the protocol fee while we still have native USDC and deposit it into the lUSDC market reserves
            amountToAddToReserves = repayAmountFactoringInBothFeeAmounts - repayAmountFactoringInFeeAmount;

            // transfer the reserves owed back to the contract after borrowing on the users behalf and before repaying the loan
            data.tokenToLoop.safeTransferFrom(data.user, address(this), amountToAddToReserves);
            lTokenMapping[data.tokenToLoop]._addReserves(amountToAddToReserves);
            emit AmountAddedToReserves(amountToAddToReserves);

            // repay loan, where msg.sender = vault
            data.tokenToLoop.safeTransferFrom(data.user, msg.sender, repayAmountFactoringInFeeAmount);
        }
    }

    /**
     * @notice Retrieves the current price of GLP from our PLVGLP Price Oracle.
    */
    function getGLPPrice() internal view returns (uint256) {
        uint256 price = PLVGLP_ORACLE.getGLPPrice();
        require(price > 0, "invalid glp price returned");
        return price; // glp oracle returns price scaled to 18 decimals, no need to extend here
    }

    /**
     * @dev Calculates the notional loan amount in a specific token, taking into account the specified leverage.
     * The notional loan amount is a way of calculating a loan amount that represents the underlying value of the loan, 
     * considering the token and the leverage used.
     * @param _token The ERC20 token for which the notional loan amount is to be calculated.
     * @param _amount The quantity of the token.
     * @param _leverage The leverage factor to apply to the loan amount.
     * @return _loanAmount The calculated notional loan amount.
     * @return _tokenToBorrow The ERC20 token to be borrowed.
     *
     * This function checks for the token type and applies different logic based on the type:
     * 1. For PLVGLP, the token price in Ethereum (ETH) and the USDC price in ETH are used to compute the loan amount.
     * 2. For USDC_NATIVE, the function calculates the loan amount based on the given amount and the leverage.
     * 3. For any other tokens, the function assumes that the loan will be in the supplied token and uses the given amount and the leverage to calculate the loan amount.
     */
    function getNotionalLoanAmountIn1e18(
        IERC20 _token,
        uint256 _amount,
        uint16 _leverage
    ) private view returns (uint256, IERC20) {
        // declare consts
        IERC20 _tokenToBorrow;
        uint256 _loanAmount;

        if (_token == PLVGLP) {
            uint256 _tokenPriceInEth;
            uint256 _usdcPriceInEth;
            uint256 _computedAmount;

            // constant used for converting plvGLP to USDC
            uint256 PLVGLP_DIVISOR = 1e30;

            // plvGLP borrows USDC to loop
            _tokenToBorrow = USDC_BRIDGED;
            _tokenPriceInEth = PRICE_ORACLE.getUnderlyingPrice(address(lTokenMapping[_token]));
            _usdcPriceInEth = (PRICE_ORACLE.getUnderlyingPrice(address(lUSDC)) / 1e12);
            _computedAmount = (_amount * (_tokenPriceInEth * 1e18 / _usdcPriceInEth)) / PLVGLP_DIVISOR;

            _loanAmount = _getNotionalLoanAmountIn1e18(_computedAmount, _leverage);
        } else if (_token == USDC_NATIVE) {
            _tokenToBorrow = USDC_BRIDGED;
            _loanAmount = _getNotionalLoanAmountIn1e18(
                _amount, // we can just send over the exact amount
                _leverage
            );
        } else {
            // the rest of the contracts just borrow whatever token is supplied
            _tokenToBorrow = _token;
            _loanAmount = _getNotionalLoanAmountIn1e18(
                _amount, // we can just send over the exact amount
                _leverage
            );
        }

        return (_loanAmount, _tokenToBorrow);
    }

    /**
     * @dev Internal helper function that calculates the notional loan amount based on the token quantity and the leverage.
     * @param _notionalTokenAmountIn1e18 The quantity of the token, represented in a denomination of 1e18.
     * @param _leverage The leverage factor to apply to the loan amount.
     * @return The notional loan amount, computed by multiplying the notional token amount by the leverage factor (minus the divisor), then dividing by the divisor.
     * 
     * The `unchecked` block is used to ignore overflow errors. This is because the operation of multiplying the leverage and the notional token amount may cause an overflow. 
     * The function assumes that the inputs (_notionalTokenAmountIn1e18 and _leverage) have been validated beforehand.
     */
    function _getNotionalLoanAmountIn1e18(
        uint256 _notionalTokenAmountIn1e18,
        uint16 _leverage
    ) private pure returns (uint256) {
        unchecked {
            return ((_leverage - DIVISOR) * _notionalTokenAmountIn1e18) / DIVISOR;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/IVault.sol";
import {ILoopy, ICERC20, IGlpDepositor, IRewardRouterV2, IPriceOracleProxyETH, IProtocolFeesCollector, IGlpOracleInterface, IUnitrollerInterface, SushiRouterInterface} from "./interfaces/Interfaces.sol";
import "./interfaces/ISwapRouter.sol";

contract LoopyConstants {
    // BALANCER
    IVault internal constant BALANCER_VAULT = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    IProtocolFeesCollector internal constant BALANCER_PROTOCOL_FEES_COLLECTOR =
        IProtocolFeesCollector(0xce88686553686DA562CE7Cea497CE749DA109f9F);

    // UNDERLYING TOKENS
    IERC20 internal constant USDC_BRIDGED = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    IERC20 internal constant USDC_NATIVE = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
    IERC20 internal constant ARB = IERC20(0x912CE59144191C1204E64559FE8253a0e49E6548);
    IERC20 internal constant WBTC = IERC20(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);
    IERC20 internal constant USDT = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    IERC20 internal constant DAI = IERC20(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
    IERC20 internal constant FRAX = IERC20(0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F);
    IERC20 internal constant PLVGLP = IERC20(0x5326E71Ff593Ecc2CF7AcaE5Fe57582D6e74CFF1);
    IERC20 internal constant GLP = IERC20(0x1aDDD80E6039594eE970E5872D247bf0414C8903);

    // GMX
    IERC20 internal constant VAULT = IERC20(0x489ee077994B6658eAfA855C308275EAd8097C4A);
    IERC20 internal constant GLP_MANAGER = IERC20(0x3963FfC9dff443c2A94f21b129D429891E32ec18);
    IERC20 internal constant sGLP = IERC20(0x2F546AD4eDD93B956C8999Be404cdCAFde3E89AE);
    IRewardRouterV2 internal constant REWARD_ROUTER_V2 = IRewardRouterV2(0xB95DB5B167D75e6d04227CfFFA61069348d271F5);

    // PLUTUS
    IGlpDepositor internal constant GLP_DEPOSITOR = IGlpDepositor(0xEAE85745232983CF117692a1CE2ECf3d19aDA683);

    // LODESTAR
    ICERC20 internal constant lUSDCe = ICERC20(0x1ca530f02DD0487cef4943c674342c5aEa08922F);
    ICERC20 internal constant lUSDC = ICERC20(0x4C9aAed3b8c443b4b634D1A189a5e25C604768dE);
    ICERC20 internal constant lPLVGLP = ICERC20(0xeA0a73c17323d1a9457D722F10E7baB22dc0cB83);
    ICERC20 internal constant lARB = ICERC20(0x8991d64fe388fA79A4f7Aa7826E8dA09F0c3C96a);
    ICERC20 internal constant lWBTC = ICERC20(0xC37896BF3EE5a2c62Cdbd674035069776f721668);
    ICERC20 internal constant lUSDT = ICERC20(0x9365181A7df82a1cC578eAE443EFd89f00dbb643);
    ICERC20 internal constant lDAI = ICERC20(0x4987782da9a63bC3ABace48648B15546D821c720);
    ICERC20 internal constant lFRAX = ICERC20(0xD12d43Cdf498e377D3bfa2c6217f05B466E14228);

    IUnitrollerInterface internal constant UNITROLLER =
        IUnitrollerInterface(0xa86DD95c210dd186Fa7639F93E4177E97d057576);
    IGlpOracleInterface internal constant PLVGLP_ORACLE =
        IGlpOracleInterface(0x5ba0828A5488c20a9C6521a90ecc9c49e5390604);
    IPriceOracleProxyETH internal constant PRICE_ORACLE =
        IPriceOracleProxyETH(0xcCf9393df2F656262FD79599175950faB4D4ec01);

    // SWAP
    ISwapRouter internal constant UNI_ROUTER = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    SushiRouterInterface internal constant SUSHI_ROUTER =
        SushiRouterInterface(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    uint256 public constant DIVISOR = 1e4;
    uint16 public constant MAX_LEVERAGE = 30_000; // in {DIVISOR} terms. E.g. 30_000 = 3.0;

    // set default fee percentage (can be updated via admin function below)
    uint256 public protocolFeePercentage = 25; // 25 basis points
}

//SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "../interfaces/UniswapV2Interface.sol";
import "../LoopyConstants.sol";

abstract contract Swap is LoopyConstants {
    /**
     * @dev Swaps a certain `amountIn` of a token for another token through Uniswap, ensuring a `minAmountOut` is returned. The pool fee of 100 is used to find the path of a pool and is specific for the BRIDGED_USDC/NATIVE_USDC pool.
     * @param token0Address The address of the token being swapped from.
     * @param token1Address The address of the token being swapped to.
     * @param amountIn The amount of `token0Address` tokens to be swapped.
     * @param minAmountOut The minimum amount of `token1Address` tokens to be returned.
     * @return The actual amount of `token1Address` tokens returned from the swap.
     *
     * This function uses the Uniswap protocol for token swaps. A swap involves trading a specific amount of one token to receive another token.
     * It specifies the addresses of the input and output tokens, the input amount, the minimum output amount, and a pool fee.
     * If the swap is successful, it returns the amount of `token1Address` tokens received.
     */
    function swapThroughUniswap(
        address token0Address,
        address token1Address,
        uint256 amountIn,
        uint256 minAmountOut
    ) public returns (uint256) {
        uint24 poolFee = 100;

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: abi.encodePacked(token0Address, poolFee, token1Address),
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: minAmountOut
        });

        uint256 amountOut = UNI_ROUTER.exactInput(params);
        return amountOut;
    }

    /**
     * @dev Swaps a certain `amountIn` of a token for another token through Sushiswap, ensuring a `minAmountOut` is returned.
     * @param token0Address The address of the token being swapped from.
     * @param token1Address The address of the token being swapped to.
     * @param amountIn The amount of `token0Address` tokens to be swapped.
     * @param minAmountOut The minimum amount of `token1Address` tokens to be returned.
     *
     * This function uses the Sushiswap protocol for token swaps. It performs a swap of a specific amount of one token for another token.
     * It specifies the addresses of the input and output tokens, the input amount, and the minimum output amount.
     * This function only supports swapping tokens for tokens, if operations involve ETH, separate calls for wrapping/unwrapping to/from WETH should be made in the WETH contract.
     */
    function swapThroughSushiswap(
        address token0Address,
        address token1Address,
        uint256 amountIn,
        uint256 minAmountOut
    ) public {
        address[] memory path = new address[](2);
        path[0] = token0Address;
        path[1] = token1Address;
        address to = address(this);
        uint256 deadline = block.timestamp;
        SUSHI_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, minAmountOut, path, to, deadline);
    }
}