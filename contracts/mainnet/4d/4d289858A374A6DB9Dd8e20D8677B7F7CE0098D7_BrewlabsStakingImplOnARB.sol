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

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(
        address sender,
        address unused
    ) external pure returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(
        address destination
    ) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(
        address destination,
        bytes calldata data
    ) external payable returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (uint256 size, bytes32 root, bytes32[] memory partials);

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );

    error InvalidBlockNumber(uint256 requested, uint256 current);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBrewlabsAggregator {
    struct Trade {
        uint256 amountIn;
        uint256 amountOut;
        address[] path;
        address[] adapters;
    }

    struct FormattedOffer {
        uint256[] amounts;
        address[] adapters;
        address[] path;
        uint256 gasEstimate;
    }

    function WNATIVE() external view returns (address);
    function BREWS_FEE() external view returns (uint256);
    function findBestPath(uint256 _amountIn, address _tokenIn, address _tokenOut, uint256 _maxSteps)
        external
        view
        returns (FormattedOffer memory);
    function swapNoSplit(Trade memory _trade, address _to, uint256 _deadline) external;
    function swapNoSplitFromETH(Trade memory _trade, address _to, uint256 _deadline) external payable;
    function swapNoSplitToETH(Trade memory _trade, address _to, uint256 _deadline) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IBrewlabsAggregator} from "../libs/IBrewlabsAggregator.sol";
import {IWETH} from "../libs/IWETH.sol";
import "../libs/ArbSys.sol";

interface WhiteList {
    function whitelisted(address _address) external view returns (bool);
}

contract BrewlabsStakingImplOnARB is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Whether it is initialized
    bool public isInitialized;

    uint256 private PERCENT_PRECISION;
    uint256 private BLOCKS_PER_DAY;
    uint256 public PRECISION_FACTOR;
    uint256 public PRECISION_FACTOR_REFLECTION;
    uint256 public MAX_FEE;

    address public WNATIVE;

    // The staked token
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    // The dividend token of staking token
    address public dividendToken;

    bool public hasDividend;
    bool public autoAdjustableForRewardRate = false;

    uint256 public duration;
    // The block number when staking starts.
    uint256 public startBlock;
    // The block number when staking ends.
    uint256 public bonusEndBlock;
    // tokens created per block.
    uint256 public rewardPerBlock;
    // The block number of the last pool update
    uint256 public lastRewardBlock;
    // Accrued token per share
    uint256 public accTokenPerShare;
    uint256 public accDividendPerShare;
    // The deposit & withdraw fee
    uint256 public depositFee;
    uint256 public withdrawFee;

    address public walletA;
    address public treasury;
    uint256 public performanceFee;

    address public factory;
    address public deployer;
    address public operator;

    // Whether a limit is set for users
    bool public hasUserLimit;
    // The pool limit (0 if none)
    uint256 public poolLimitPerUser;
    address public whiteList;

    IBrewlabsAggregator public swapAggregator;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt
        uint256 reflectionDebt; // Reflection debt
    }

    // Info of each user that stakes tokens (stakingToken)
    mapping(address => UserInfo) public userInfo;

    uint256 public totalStaked;
    uint256 private totalEarned;
    uint256 private totalReflections;
    uint256 private reflections;

    uint256 public paidRewards;
    uint256 private shouldTotalPaid;
    // Arbitrum precompile
    ArbSys constant arbsys =
        ArbSys(address(0x0000000000000000000000000000000000000064));

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event ClaimDividend(address indexed user, uint256 amount);
    event Compound(address indexed user, uint256 amount);
    event CompoundDividend(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event AdminTokenRecovered(address tokenRecovered, uint256 amount);

    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event RewardsStop(uint256 blockNumber);
    event EndBlockChanged(uint256 blockNumber);
    event UpdatePoolLimit(uint256 poolLimitPerUser, bool hasLimit);

    event ServiceInfoChanged(address _addr, uint256 _fee);
    event WalletAUpdated(address _addr);
    event DurationChanged(uint256 _duration);
    event OperatorTransferred(address oldOperator, address newOperator);
    event SetAutoAdjustableForRewardRate(bool status);
    event SetWhiteList(address _whitelist);
    event SetSwapAggregator(address aggregator);

    modifier onlyAdmin() {
        require(
            msg.sender == owner() || msg.sender == operator,
            "Caller is not owner or operator"
        );
        _;
    }

    constructor() {}

    /**
     * @notice Initialize the contract
     * @param _stakingToken: staked token address
     * @param _rewardToken: earned token address
     * @param _dividendToken: reflection token address
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _depositFee: deposit fee
     * @param _withdrawFee: withdraw fee
     * @param _hasDividend: reflection available flag
     * @param _aggregator: brewlabs swap aggregator
     * @param _owner: owner address
     * @param _deployer: deployer address
     */
    function initialize(
        IERC20 _stakingToken,
        IERC20 _rewardToken,
        address _dividendToken,
        uint256 _duration,
        uint256 _rewardPerBlock,
        uint256 _depositFee,
        uint256 _withdrawFee,
        bool _hasDividend,
        address _aggregator,
        address _owner,
        address _deployer
    ) external {
        require(!isInitialized, "Already initialized");
        require(
            owner() == address(0x0) || msg.sender == owner(),
            "Not allowed"
        );

        // Make this contract initialized
        isInitialized = true;

        PERCENT_PRECISION = 10000;
        BLOCKS_PER_DAY = 28800;
        MAX_FEE = 2000;

        duration = 365; // 365 days
        if (_duration > 0) duration = _duration;

        treasury = 0x5Ac58191F3BBDF6D037C6C6201aDC9F99c93C53A;
        performanceFee = 0.0035 ether;

        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        dividendToken = _dividendToken;
        hasDividend = _hasDividend;

        rewardPerBlock = _rewardPerBlock;

        require(_depositFee <= MAX_FEE, "Invalid deposit fee");
        require(_withdrawFee <= MAX_FEE, "Invalid withdraw fee");

        depositFee = _depositFee;
        withdrawFee = _withdrawFee;

        factory = msg.sender;
        deployer = _deployer;
        operator = _deployer;

        walletA = _deployer;

        uint256 decimalsRewardToken = uint256(
            IERC20Metadata(address(rewardToken)).decimals()
        );
        require(decimalsRewardToken < 30, "Must be inferior to 30");
        PRECISION_FACTOR = uint256(10 ** (40 - decimalsRewardToken));

        uint256 decimalsdividendToken = 18;
        if (address(dividendToken) != address(0x0)) {
            decimalsdividendToken = uint256(
                IERC20Metadata(address(dividendToken)).decimals()
            );
            require(decimalsdividendToken < 30, "Must be inferior to 30");
        }
        PRECISION_FACTOR_REFLECTION = uint256(
            10 ** (40 - decimalsdividendToken)
        );

        swapAggregator = IBrewlabsAggregator(_aggregator);
        WNATIVE = swapAggregator.WNATIVE();

        _transferOwnership(_owner);
    }

    /**
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to stake (in staking token)
     */
    function deposit(uint256 _amount) external payable nonReentrant {
        require(
            startBlock > 0 && startBlock < arbsys.arbBlockNumber(),
            "Staking hasn't started yet"
        );
        require(_amount > 0, "Amount should be greator than 0");
        if (whiteList != address(0x0)) {
            require(
                WhiteList(whiteList).whitelisted(msg.sender),
                "not whitelisted"
            );
        }

        UserInfo storage user = userInfo[msg.sender];

        if (hasUserLimit) {
            require(
                _amount + user.amount <= poolLimitPerUser,
                "User amount above limit"
            );
        }

        _transferPerformanceFee();
        _updatePool();

        if (user.amount > 0) {
            uint256 pending = (user.amount * accTokenPerShare) /
                PRECISION_FACTOR -
                user.rewardDebt;
            if (pending > 0) {
                require(
                    availableRewardTokens() >= pending,
                    "Insufficient reward tokens"
                );
                rewardToken.safeTransfer(address(msg.sender), pending);

                totalEarned = totalEarned > pending ? totalEarned - pending : 0;
                paidRewards = paidRewards + pending;
                emit Claim(msg.sender, pending);
            }

            uint256 pendingReflection = (user.amount * accDividendPerShare) /
                PRECISION_FACTOR_REFLECTION -
                user.reflectionDebt;

            if (pendingReflection > 0 && hasDividend) {
                uint256 _pendingReflection = estimateDividendAmount(
                    pendingReflection
                );
                totalReflections = totalReflections - pendingReflection;
                if (address(dividendToken) == address(0x0)) {
                    payable(msg.sender).transfer(_pendingReflection);
                } else {
                    IERC20(dividendToken).safeTransfer(
                        address(msg.sender),
                        _pendingReflection
                    );
                }
                emit ClaimDividend(msg.sender, _pendingReflection);
            }
        }

        uint256 beforeAmount = stakingToken.balanceOf(address(this));
        stakingToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        uint256 afterAmount = stakingToken.balanceOf(address(this));
        uint256 realAmount = afterAmount - beforeAmount;
        if (realAmount > _amount) realAmount = _amount;

        if (depositFee > 0) {
            uint256 fee = (realAmount * depositFee) / PERCENT_PRECISION;
            stakingToken.safeTransfer(walletA, fee);
            realAmount = realAmount - fee;
        }

        user.amount = user.amount + realAmount;
        user.rewardDebt = (user.amount * accTokenPerShare) / PRECISION_FACTOR;
        user.reflectionDebt =
            (user.amount * accDividendPerShare) /
            PRECISION_FACTOR_REFLECTION;

        totalStaked = totalStaked + realAmount;

        emit Deposit(msg.sender, realAmount);

        if (autoAdjustableForRewardRate) _updateRewardRate();
    }

    /**
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in staking token)
     */
    function withdraw(uint256 _amount) external payable nonReentrant {
        require(_amount > 0, "Amount should be greator than 0");

        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");

        _transferPerformanceFee();
        _updatePool();

        if (user.amount > 0) {
            uint256 pending = (user.amount * accTokenPerShare) /
                PRECISION_FACTOR -
                user.rewardDebt;
            if (pending > 0) {
                require(
                    availableRewardTokens() >= pending,
                    "Insufficient reward tokens"
                );
                rewardToken.safeTransfer(address(msg.sender), pending);

                totalEarned = totalEarned > pending ? totalEarned - pending : 0;
                paidRewards = paidRewards + pending;
                emit Claim(msg.sender, pending);
            }

            uint256 pendingReflection = (user.amount * accDividendPerShare) /
                PRECISION_FACTOR_REFLECTION -
                user.reflectionDebt;

            if (pendingReflection > 0 && hasDividend) {
                uint256 _pendingReflection = estimateDividendAmount(
                    pendingReflection
                );
                totalReflections = totalReflections - pendingReflection;
                if (address(dividendToken) == address(0x0)) {
                    payable(msg.sender).transfer(_pendingReflection);
                } else {
                    IERC20(dividendToken).safeTransfer(
                        address(msg.sender),
                        _pendingReflection
                    );
                }
                emit ClaimDividend(msg.sender, _pendingReflection);
            }
        }

        uint256 realAmount = _amount;
        if (user.amount < _amount) {
            realAmount = user.amount;
        }

        user.amount = user.amount - realAmount;
        totalStaked = totalStaked - realAmount;
        emit Withdraw(msg.sender, realAmount);

        if (withdrawFee > 0) {
            uint256 fee = (realAmount * withdrawFee) / PERCENT_PRECISION;
            stakingToken.safeTransfer(walletA, fee);
            realAmount = realAmount - fee;
        }

        stakingToken.safeTransfer(address(msg.sender), realAmount);

        user.rewardDebt = (user.amount * accTokenPerShare) / PRECISION_FACTOR;
        user.reflectionDebt =
            (user.amount * accDividendPerShare) /
            PRECISION_FACTOR_REFLECTION;

        if (autoAdjustableForRewardRate) _updateRewardRate();
    }

    function claimReward() external payable nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        _transferPerformanceFee();
        _updatePool();

        if (user.amount == 0) return;

        uint256 pending = (user.amount * accTokenPerShare) /
            PRECISION_FACTOR -
            user.rewardDebt;
        if (pending > 0) {
            require(
                availableRewardTokens() >= pending,
                "Insufficient reward tokens"
            );
            rewardToken.safeTransfer(address(msg.sender), pending);

            if (totalEarned > pending) {
                totalEarned = totalEarned - pending;
            } else {
                totalEarned = 0;
            }
            paidRewards = paidRewards + pending;
            emit Claim(msg.sender, pending);
        }

        user.rewardDebt = (user.amount * accTokenPerShare) / PRECISION_FACTOR;
    }

    function claimDividend() external payable nonReentrant {
        require(hasDividend == true, "No reflections");
        UserInfo storage user = userInfo[msg.sender];

        _transferPerformanceFee();
        _updatePool();

        if (user.amount == 0) return;

        uint256 pendingReflection = (user.amount * accDividendPerShare) /
            PRECISION_FACTOR_REFLECTION -
            user.reflectionDebt;

        if (pendingReflection > 0) {
            uint256 _pendingReflection = estimateDividendAmount(
                pendingReflection
            );
            totalReflections = totalReflections - pendingReflection;
            if (address(dividendToken) == address(0x0)) {
                payable(msg.sender).transfer(_pendingReflection);
            } else {
                IERC20(dividendToken).safeTransfer(
                    address(msg.sender),
                    _pendingReflection
                );
            }
            emit ClaimDividend(msg.sender, _pendingReflection);
        }

        user.reflectionDebt =
            (user.amount * accDividendPerShare) /
            PRECISION_FACTOR_REFLECTION;
    }

    function precomputeCompound(
        bool isDividend
    ) external view returns (IBrewlabsAggregator.FormattedOffer memory offer) {
        if (!isDividend && address(stakingToken) == address(rewardToken))
            return offer;
        if (isDividend && address(stakingToken) == dividendToken) return offer;

        uint256 pending = isDividend
            ? pendingDividends(msg.sender)
            : pendingReward(msg.sender);
        if (pending == 0) return offer;

        if (!isDividend) {
            offer = swapAggregator.findBestPath(
                pending,
                address(rewardToken),
                address(stakingToken),
                2
            );
        } else {
            offer = swapAggregator.findBestPath(
                pending,
                dividendToken == address(0x0) ? WNATIVE : dividendToken,
                address(stakingToken),
                2
            );
        }
    }

    function compoundReward(
        IBrewlabsAggregator.Trade memory _trade
    ) external payable nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        _transferPerformanceFee();
        _updatePool();

        if (user.amount == 0) return;

        uint256 pending = (user.amount * accTokenPerShare) /
            PRECISION_FACTOR -
            user.rewardDebt;
        if (pending > 0) {
            require(
                availableRewardTokens() >= pending,
                "Insufficient reward tokens"
            );
            if (totalEarned > pending) {
                totalEarned = totalEarned - pending;
            } else {
                totalEarned = 0;
            }
            paidRewards = paidRewards + pending;
            emit Compound(msg.sender, pending);

            if (address(stakingToken) != address(rewardToken)) {
                pending = _safeSwap(
                    pending,
                    address(rewardToken),
                    address(stakingToken),
                    address(this),
                    _trade
                );
            }

            if (hasUserLimit) {
                require(
                    pending + user.amount <= poolLimitPerUser,
                    "User amount above limit"
                );
            }

            totalStaked = totalStaked + pending;
            user.amount = user.amount + pending;
            user.reflectionDebt =
                user.reflectionDebt +
                (pending * accDividendPerShare) /
                PRECISION_FACTOR_REFLECTION;

            emit Deposit(msg.sender, pending);
        }

        user.rewardDebt = (user.amount * accTokenPerShare) / PRECISION_FACTOR;
    }

    function compoundDividend(
        IBrewlabsAggregator.Trade memory _trade
    ) external payable nonReentrant {
        require(hasDividend == true, "No reflections");
        UserInfo storage user = userInfo[msg.sender];

        _transferPerformanceFee();
        _updatePool();

        if (user.amount == 0) return;

        uint256 _pending = (user.amount * accDividendPerShare) /
            PRECISION_FACTOR_REFLECTION -
            user.reflectionDebt;
        uint256 pending = estimateDividendAmount(_pending);
        totalReflections = totalReflections - _pending;
        if (pending > 0) {
            emit CompoundDividend(msg.sender, pending);

            if (address(stakingToken) != address(dividendToken)) {
                if (address(dividendToken) == address(0x0)) {
                    IWETH(WNATIVE).deposit{value: pending}();

                    pending = _safeSwap(
                        pending,
                        WNATIVE,
                        address(stakingToken),
                        address(this),
                        _trade
                    );
                } else {
                    pending = _safeSwap(
                        pending,
                        dividendToken,
                        address(stakingToken),
                        address(this),
                        _trade
                    );
                }
            }

            if (hasUserLimit) {
                require(
                    pending + user.amount <= poolLimitPerUser,
                    "User amount above limit"
                );
            }

            totalStaked = totalStaked + pending;
            user.amount = user.amount + pending;
            user.rewardDebt =
                user.rewardDebt +
                (pending * accTokenPerShare) /
                PRECISION_FACTOR;

            emit Deposit(msg.sender, pending);
        }

        user.reflectionDebt =
            (user.amount * accDividendPerShare) /
            PRECISION_FACTOR_REFLECTION;
    }

    function _transferPerformanceFee() internal {
        require(
            msg.value >= performanceFee,
            "should pay small gas to compound or harvest"
        );

        payable(treasury).transfer(performanceFee);
        if (msg.value > performanceFee) {
            payable(msg.sender).transfer(msg.value - performanceFee);
        }
    }

    /**
     * @notice Withdraw staked tokens without caring about rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.reflectionDebt = 0;

        if (amountToTransfer > 0) {
            stakingToken.safeTransfer(address(msg.sender), amountToTransfer);
            totalStaked = totalStaked - amountToTransfer;
        }

        emit EmergencyWithdraw(msg.sender, amountToTransfer);
    }

    /**
     * @notice Available amount of reward token
     */
    function availableRewardTokens() public view returns (uint256) {
        if (address(rewardToken) == address(dividendToken)) return totalEarned;

        uint256 _amount = rewardToken.balanceOf(address(this));
        if (address(rewardToken) == address(stakingToken)) {
            if (_amount < totalStaked) return 0;
            return _amount - totalStaked;
        }

        return _amount;
    }

    /**
     * @notice Available amount of reflection token
     */
    function availableDividendTokens() public view returns (uint256) {
        if (address(dividendToken) == address(0x0)) {
            return address(this).balance;
        }

        uint256 _amount = IERC20(dividendToken).balanceOf(address(this));

        if (address(dividendToken) == address(rewardToken)) {
            if (_amount < totalEarned) return 0;
            _amount = _amount - totalEarned;
        }

        if (address(dividendToken) == address(stakingToken)) {
            if (_amount < totalStaked) return 0;
            _amount = _amount - totalStaked;
        }

        return _amount;
    }

    function insufficientRewards() public view returns (uint256) {
        uint256 adjustedShouldTotalPaid = shouldTotalPaid;
        uint256 remainRewards = availableRewardTokens() + paidRewards;

        if (startBlock == 0) {
            adjustedShouldTotalPaid =
                adjustedShouldTotalPaid +
                rewardPerBlock *
                duration *
                BLOCKS_PER_DAY;
        } else {
            uint256 remainBlocks = _getMultiplier(
                lastRewardBlock,
                bonusEndBlock
            );
            adjustedShouldTotalPaid =
                adjustedShouldTotalPaid +
                rewardPerBlock *
                remainBlocks;
        }

        if (remainRewards >= adjustedShouldTotalPaid) return 0;

        return adjustedShouldTotalPaid - remainRewards;
    }

    /**
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) public view returns (uint256) {
        UserInfo memory user = userInfo[_user];

        uint256 adjustedTokenPerShare = accTokenPerShare;
        if (
            arbsys.arbBlockNumber() > lastRewardBlock &&
            totalStaked != 0 &&
            lastRewardBlock > 0
        ) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, arbsys.arbBlockNumber());
            uint256 rewards = multiplier * rewardPerBlock;

            adjustedTokenPerShare =
                accTokenPerShare +
                ((rewards * PRECISION_FACTOR) / totalStaked);
        }

        return
            (user.amount * adjustedTokenPerShare) /
            PRECISION_FACTOR -
            user.rewardDebt;
    }

    function pendingDividends(address _user) public view returns (uint256) {
        if (totalStaked == 0) return 0;

        UserInfo memory user = userInfo[_user];

        uint256 reflectionAmount = availableDividendTokens();
        if (reflectionAmount > totalReflections) {
            reflectionAmount -= totalReflections;
        } else {
            reflectionAmount = 0;
        }

        uint256 sTokenBal = totalStaked;
        uint256 eTokenBal = availableRewardTokens();
        if (address(stakingToken) == address(rewardToken)) {
            sTokenBal = sTokenBal + eTokenBal;
        }

        uint256 adjustedReflectionPerShare = accDividendPerShare +
            ((reflectionAmount * PRECISION_FACTOR_REFLECTION) / sTokenBal);

        uint256 pendingReflection = (user.amount * adjustedReflectionPerShare) /
            PRECISION_FACTOR_REFLECTION -
            user.reflectionDebt;

        return pendingReflection;
    }

    /**
     * Admin Methods
     */
    function harvestTo(address _treasury) external onlyAdmin {
        _updatePool();

        if (reflections > 0) {
            if (address(dividendToken) == address(0x0)) {
                payable(_treasury).transfer(
                    estimateDividendAmount(reflections)
                );
            } else {
                IERC20(dividendToken).safeTransfer(
                    _treasury,
                    estimateDividendAmount(reflections)
                );
            }

            totalReflections = totalReflections - reflections;
            reflections = 0;
        }
    }

    /**
     * @notice Deposit reward token
     * @dev Only call by owner. Needs to be for deposit of reward token when reflection token is same with reward token.
     */
    function depositRewards(uint256 _amount) external onlyAdmin nonReentrant {
        require(_amount > 0, "invalid amount");

        uint256 beforeAmt = rewardToken.balanceOf(address(this));
        rewardToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 afterAmt = rewardToken.balanceOf(address(this));

        totalEarned = totalEarned + afterAmt - beforeAmt;
    }

    function increaseEmissionRate(uint256 _amount) external onlyAdmin {
        require(startBlock > 0, "pool is not started");
        require(bonusEndBlock > arbsys.arbBlockNumber(), "pool was already finished");
        require(_amount > 0, "invalid amount");

        _updatePool();

        uint256 beforeAmt = rewardToken.balanceOf(address(this));
        rewardToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 afterAmt = rewardToken.balanceOf(address(this));

        totalEarned = totalEarned + afterAmt - beforeAmt;
        _updateRewardRate();
    }

    function _updateRewardRate() internal {
        if (bonusEndBlock <= arbsys.arbBlockNumber()) return;

        uint256 remainRewards = availableRewardTokens() + paidRewards;
        if (remainRewards > shouldTotalPaid) {
            remainRewards = remainRewards - shouldTotalPaid;

            uint256 remainBlocks = bonusEndBlock - arbsys.arbBlockNumber();
            rewardPerBlock = remainRewards / remainBlocks;
            emit NewRewardPerBlock(rewardPerBlock);
        }
    }

    /**
     * @notice Withdraw reward token
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        require(arbsys.arbBlockNumber() > bonusEndBlock, "Pool is running");
        require(
            availableRewardTokens() >= _amount,
            "Insufficient reward tokens"
        );

        if (_amount == 0) _amount = availableRewardTokens();
        rewardToken.safeTransfer(address(msg.sender), _amount);

        if (totalEarned > 0) {
            if (_amount > totalEarned) {
                totalEarned = 0;
            } else {
                totalEarned = totalEarned - _amount;
            }
        }
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _token: the address of the token to withdraw
     * @param _amount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function rescueTokens(address _token, uint256 _amount) external onlyOwner {
        require(
            _token != address(rewardToken) || _token == dividendToken,
            "Cannot be reward token"
        );

        if (_token == address(stakingToken)) {
            uint256 tokenBal = stakingToken.balanceOf(address(this));
            require(_amount <= tokenBal - totalStaked, "Insufficient balance");
        }

        if (_token == address(0x0)) {
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(address(msg.sender), _amount);
        }

        emit AdminTokenRecovered(_token, _amount);
    }

    function startReward() external onlyAdmin {
        require(startBlock == 0, "Pool was already started");
        require(
            insufficientRewards() == 0,
            "All reward tokens have not been deposited"
        );

        startBlock = arbsys.arbBlockNumber() + 100;
        bonusEndBlock = startBlock + duration * BLOCKS_PER_DAY;
        lastRewardBlock = startBlock;

        emit NewStartAndEndBlocks(startBlock, bonusEndBlock);
    }

    function stopReward() external onlyAdmin {
        _updatePool();

        uint256 remainRewards = availableRewardTokens() + paidRewards;
        if (remainRewards > shouldTotalPaid) {
            remainRewards = remainRewards - shouldTotalPaid;
            rewardToken.safeTransfer(msg.sender, remainRewards);

            if (totalEarned > remainRewards) {
                totalEarned = totalEarned - remainRewards;
            } else {
                totalEarned = 0;
            }
        }

        bonusEndBlock = arbsys.arbBlockNumber();
        emit RewardsStop(bonusEndBlock);
    }

    function updateEndBlock(uint256 _endBlock) external onlyAdmin {
        require(startBlock > 0, "Pool is not started");
        require(bonusEndBlock > arbsys.arbBlockNumber(), "Pool was already finished");
        require(
            _endBlock > arbsys.arbBlockNumber() && _endBlock > startBlock,
            "Invalid end block"
        );
        bonusEndBlock = _endBlock;
        emit EndBlockChanged(_endBlock);
    }

    /**
     * @notice Update pool limit per user
     * @dev Only callable by owner.
     * @param _hasUserLimit: whether the limit remains forced
     * @param _poolLimitPerUser: new pool limit per user
     */
    function updatePoolLimitPerUser(
        bool _hasUserLimit,
        uint256 _poolLimitPerUser
    ) external onlyOwner {
        if (_hasUserLimit) {
            require(
                _poolLimitPerUser > poolLimitPerUser,
                "New limit must be higher"
            );
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            poolLimitPerUser = 0;
        }
        hasUserLimit = _hasUserLimit;

        emit UpdatePoolLimit(poolLimitPerUser, hasUserLimit);
    }

    /**
     * @notice Update reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyAdmin {
        // require(arbsys.arbBlockNumber() < startBlock, "Pool was already started");
        _updatePool();

        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }

    function setServiceInfo(address _treasury, uint256 _fee) external {
        require(msg.sender == treasury, "setServiceInfo: FORBIDDEN");
        require(_treasury != address(0x0), "Invalid address");

        treasury = _treasury;
        performanceFee = _fee;

        emit ServiceInfoChanged(_treasury, _fee);
    }

    function updateWalletA(address _walletA) external onlyOwner {
        require(
            _walletA != address(0x0) || _walletA != walletA,
            "Invalid address"
        );

        walletA = _walletA;
        emit WalletAUpdated(_walletA);
    }

    function setDuration(uint256 _duration) external onlyOwner {
        require(_duration >= 30, "lower limit reached");

        duration = _duration;
        if (startBlock > 0) {
            bonusEndBlock = startBlock + duration * BLOCKS_PER_DAY;
            require(bonusEndBlock > arbsys.arbBlockNumber(), "invalid duration");
        }
        emit DurationChanged(_duration);
    }

    function setAutoAdjustableForRewardRate(bool _status) external onlyOwner {
        autoAdjustableForRewardRate = _status;
        emit SetAutoAdjustableForRewardRate(_status);
    }

    function transferOperator(address _operator) external onlyAdmin {
        require(_operator != address(0x0), "invalid address");
        emit OperatorTransferred(operator, _operator);
        operator = _operator;
    }

    /**
     * @notice Update swap aggregator.
     * @param _aggregator: swap Aggregator address
     */
    function setSwapAggregator(address _aggregator) external onlyOwner {
        require(_aggregator != address(0x0), "Invalid address");
        require(
            IBrewlabsAggregator(_aggregator).WNATIVE() != address(0x0),
            "Invalid swap aggregator"
        );

        swapAggregator = IBrewlabsAggregator(_aggregator);
        WNATIVE = IBrewlabsAggregator(_aggregator).WNATIVE();
        emit SetSwapAggregator(_aggregator);
    }

    function setWhitelist(address _whitelist) external onlyOwner {
        whiteList = _whitelist;
        emit SetWhiteList(_whitelist);
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        // calc reflection rate
        if (totalStaked > 0 && hasDividend) {
            uint256 reflectionAmount = availableDividendTokens();
            if (reflectionAmount > totalReflections) {
                reflectionAmount -= totalReflections;
            } else {
                reflectionAmount = 0;
            }

            uint256 sTokenBal = totalStaked;
            uint256 eTokenBal = availableRewardTokens();
            if (address(stakingToken) == address(rewardToken)) {
                sTokenBal = sTokenBal + eTokenBal;
            }

            accDividendPerShare +=
                (reflectionAmount * PRECISION_FACTOR_REFLECTION) /
                sTokenBal;

            reflections += (reflectionAmount * eTokenBal) / sTokenBal;
            totalReflections += reflectionAmount;
        }

        if (arbsys.arbBlockNumber() <= lastRewardBlock || lastRewardBlock == 0) return;
        if (totalStaked == 0) {
            lastRewardBlock = arbsys.arbBlockNumber();
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardBlock, arbsys.arbBlockNumber());
        uint256 _reward = multiplier * rewardPerBlock;
        accTokenPerShare += (_reward * PRECISION_FACTOR) / totalStaked;

        lastRewardBlock = arbsys.arbBlockNumber();
        shouldTotalPaid = shouldTotalPaid + _reward;
    }

    function estimateDividendAmount(
        uint256 amount
    ) internal view returns (uint256) {
        uint256 dTokenBal = availableDividendTokens();
        if (amount > totalReflections) amount = totalReflections;
        if (amount > dTokenBal) amount = dTokenBal;
        return amount;
    }

    /**
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(
        uint256 _from,
        uint256 _to
    ) internal view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to - _from;
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock - _from;
        }
    }

    function _safeSwap(
        uint256 _amountIn,
        address _fromToken,
        address _toToken,
        address _to,
        IBrewlabsAggregator.Trade memory _trade
    ) internal returns (uint256) {
        IERC20(_fromToken).safeApprove(address(swapAggregator), _amountIn);

        uint256 beforeAmount = IERC20(_toToken).balanceOf(_to);
        _trade.amountIn = _amountIn;
        swapAggregator.swapNoSplit(_trade, _to, block.timestamp + 600);
        uint256 afterAmount = IERC20(_toToken).balanceOf(_to);

        return afterAmount - beforeAmount;
    }

    receive() external payable {}
}