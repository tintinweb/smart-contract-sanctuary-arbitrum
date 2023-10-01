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

pragma solidity ^0.8.19;

contract Governable {
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, 'Governable: forbidden');
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '../../lib/FixedPoint.sol';

interface IPriceFeed {
    function getPrice(bytes32 productId) external view returns (FPUnsigned);

    function notifyPerp(
        bytes32 productId, FPUnsigned value, uint64 timestamp
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '../../lib/FixedPoint.sol';

interface IDomFiPerp {
    struct Position {
        address owner;
        bytes32 productId;
        uint256 margin; // collateral provided for this position
        FPUnsigned leverage;
        FPUnsigned price; // price when position was increased. weighted average by size
        FPUnsigned oraclePrice;
        FPSigned funding; // funding + interest when position was last increased
        bytes16 ownerPositionId;
        uint64 timestamp; // last position increase
        bool isLong;
        bool isNextPrice;
    }

    struct ProductParams {
        bytes32 productId;
        FPUnsigned maxLeverage;
        FPUnsigned fee;
        bool isActive;
        FPUnsigned minPriceChange; // min oracle increase % for trader to close with profit
        FPUnsigned weight; // share of the max exposure
        FPUnsigned reserveMultiplier; // Virtual reserve used to calculate slippage, based on remaining exposure
        FPUnsigned exposureMultiplier;
        FPUnsigned liquidationThreshold; // positions are liquidated if losses >= liquidationThreshold % of margin
        FPUnsigned liquidationBounty; // upon liquidation, liquidationBounty % of remaining margin is given to liquidators
        FPUnsigned fundingExponent;
    }

    struct Product {
        bytes32 productId;
        FPUnsigned maxLeverage;
        FPUnsigned fee;
        bool isActive;
        FPUnsigned openInterestLong;
        FPUnsigned openInterestShort;
        FPUnsigned minPriceChange; // min oracle increase % for trader to close with profit
        FPUnsigned weight; // share of the max exposure
        FPUnsigned reserveMultiplier; // Virtual reserve used to calculate slippage, based on remaining exposure
        FPUnsigned exposureMultiplier;
        FPUnsigned liquidationThreshold; // positions are liquidated if losses >= liquidationThreshold % of margin
        FPUnsigned liquidationBounty; // upon liquidation, liquidationBounty % of remaining margin is given to liquidators
        FPUnsigned fundingExponent;
    }

    struct IncreasePositionParams {
        address user;
        bytes16 userPositionId;
        bytes32 productId;
        uint256 margin;
        bool isLong;
        FPUnsigned leverage;
    }

    struct DecreasePositionParams {
        address user;
        bytes16 userPositionId;
        uint256 margin;
    }

    function increasePositions(IncreasePositionParams[] calldata params) external;

    function removeMargin(bytes32 positionId, FPUnsigned marginFraction) external returns (uint256);

    function decreasePositions(DecreasePositionParams[] calldata params) external;

    function getProduct(bytes32 productId) external view returns (Product memory);

    function getPosition(address account, bytes16 accountPositionId) external view returns (Position memory);

    function getPositionId(address account, bytes16 accountPositionId) external view returns (bytes32);

    function getMaxExposure(FPUnsigned productWeight, FPUnsigned productExposureMultiplier)
        external
        view
        returns (FPUnsigned);

    function validateManager(address manager, address account) external returns(bool);

    function validateOI(uint256 balance) external view;

    function asset() external view returns (address);

    function getPositionPnLAndFunding(Position memory position, FPUnsigned price)
        external
        returns (FPSigned pnl, FPSigned funding);

    function totalOpenInterest() external view returns (FPUnsigned);

    function getTotalPnl() external returns (FPSigned);

    function updatePrice(
        bytes32 productId,
        FPUnsigned value,
        uint64 timestamp,
        address _oracle
    ) external;

    event ProductAdded(bytes32 productId, Product product);
    event ProductUpdated(bytes32 productId, Product product);
    event OwnerUpdated(address newOwner);
    event GuardianUpdated(address newGuardian);
    event GovUpdated(address newGov);

    event IncreasePosition(
        bytes32 indexed positionId,
        address indexed user,
        bytes32 indexed productId,
        uint256 fee,
        Position position
    );

    event DecreasePosition(
        bytes32 indexed positionId,
        address indexed user,
        bytes32 indexed productId,
        bool didLiquidate,
        uint256 fee,
        int256 netPnl,
        FPUnsigned exitPrice,
        Position position
    );

    event RemoveMargin(
        bytes32 indexed positionId,
        address indexed user,
        uint256 oldMargin,
        FPUnsigned oldLeverage,
        Position position
    );

    event PositionLiquidated(
        bytes32 indexed positionId,
        address indexed liquidator,
        uint256 liquidatorReward,
        uint256 remainingReward,
        Position position
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '../../lib/FixedPoint.sol';

interface IFeeCalculator {
    function getTradeFee(
        FPUnsigned productFee,
        address user,
        address sender
    ) external view returns (FPUnsigned);

    function getDepositFee(address sender) external view returns (FPUnsigned);
    function getWithdrawFee(address sender) external view returns (FPUnsigned);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { FPSigned, FPUnsigned, FixedPoint } from './FixedPoint.sol';
import { floor, ceil } from './FPUnsignedOperators.sol';

/**
 * @notice Adds two `FPSigned`s, reverting on overflow.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return the sum of `a` and `b`.
*/
function add(FPSigned a, FPSigned b) pure returns (FPSigned) {
    return FPSigned.wrap(FPSigned.unwrap(a) + FPSigned.unwrap(b));
}

/**
 * @notice Subtracts two `FPSigned`s, reverting on overflow.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return the difference of `a` and `b`.
*/
function sub(FPSigned a, FPSigned b) pure returns (FPSigned) {
    return FPSigned.wrap(FPSigned.unwrap(a) - FPSigned.unwrap(b));
}

/**
 * @notice Multiplies two `FPSigned`s, reverting on overflow.
 * @dev This will "floor" the product.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return the product of `a` and `b`.
*/
function mul(FPSigned a, FPSigned b) pure returns (FPSigned) {
    // There are two caveats with this computation:
    // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
    // stored internally as an int256 ~10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
    // would round to 3, but this computation produces the result 2.
    // No need to use SafeMath because FixedPoint.SFP_SCALING_FACTOR != 0.
    return FPSigned.wrap(FPSigned.unwrap(a) * FPSigned.unwrap(b) / FixedPoint.SFP_SCALING_FACTOR);
}

function neg(FPSigned a) pure returns (FPSigned) {
    return FPSigned.wrap(FPSigned.unwrap(a) * -1);
}

/**
 * @notice Divides one `FPSigned` by a `FPSigned`, reverting on overflow or division by 0.
 * @dev This will "floor" the quotient.
 * @param a a FPSigned numerator.
 * @param b a FPSigned denominator.
 * @return the quotient of `a` divided by `b`.
*/
function div(FPSigned a, FPSigned b) pure returns (FPSigned) {
    // There are two caveats with this computation:
    // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
    // 10^41 is stored internally as an int256 10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
    // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
    return FPSigned.wrap(FPSigned.unwrap(a) * FixedPoint.SFP_SCALING_FACTOR / FPSigned.unwrap(b));
}

/**
 * @notice Whether `a` is equal to `b`.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return True if equal, or False.
*/
function isEqual(FPSigned a, FPSigned b) pure returns (bool) {
    return FPSigned.unwrap(a) == FPSigned.unwrap(b);
}

/**
 * @notice Whether `a` is equal to `b`.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return True if equal, or False.
*/
function isNotEqual(FPSigned a, FPSigned b) pure returns (bool) {
    return FPSigned.unwrap(a) != FPSigned.unwrap(b);
}

/**
 * @notice Whether `a` is greater than `b`.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return True if `a > b`, or False.
*/
function isGreaterThan(FPSigned a, FPSigned b) pure returns (bool) {
    return FPSigned.unwrap(a) > FPSigned.unwrap(b);
}

/**
 * @notice Whether `a` is greater than or equal to `b`.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return True if `a >= b`, or False.
*/
function isGreaterThanOrEqual(FPSigned a, FPSigned b) pure returns (bool) {
    return FPSigned.unwrap(a) >= FPSigned.unwrap(b);
}

/**
 * @notice Whether `a` is less than `b`.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return True if `a < b`, or False.
*/
function isLessThan(FPSigned a, FPSigned b) pure returns (bool) {
    return FPSigned.unwrap(a) < FPSigned.unwrap(b);
}

/**
 * @notice Whether `a` is less than or equal to `b`.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return True if `a <= b`, or False.
*/
function isLessThanOrEqual(FPSigned a, FPSigned b) pure returns (bool) {
    return FPSigned.unwrap(a) <= FPSigned.unwrap(b);
}

/**
 * @notice Absolute value of a FPSigned
*/
function abs(FPSigned value) pure returns (FPUnsigned) {
    int256 x = FPSigned.unwrap(value);
    uint256 raw = (x < 0) ? uint256(-x) : uint256(x);
    return FPUnsigned.wrap(raw);
}

/**
 * @notice Convert a FPUnsigned to uint, "truncating" any decimal portion.
*/
function trunc(FPSigned value) pure returns (int256) {
    return FPSigned.unwrap(value) / FixedPoint.SFP_SCALING_FACTOR;
}

/**
 * @notice Round a trader's PnL in favor of liquidity providers
*/
function roundTraderPnl(FPSigned value) pure returns (FPSigned) {
    if (FPSigned.unwrap(value) >= 0) {
        // If the P/L is a trader gain/value loss, then fractional dust gained for the trader should be reduced
        FPUnsigned pnl = FixedPoint.fromSigned(value);
        return FixedPoint.fromUnsigned(floor(pnl));
    } else {
        // If the P/L is a trader loss/vault gain, then fractional dust lost should be magnified towards the trader
        return neg(FixedPoint.fromUnsigned(ceil(abs(value))));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { FPUnsigned, FPSigned, FixedPoint } from './FixedPoint.sol';

/**
 * @notice Whether `a` is equal to `b`.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return True if equal, or False.
*/
function isEqual(FPUnsigned a, FPUnsigned b) pure returns (bool) {
    return FPUnsigned.unwrap(a) == FPUnsigned.unwrap(b);
}

/**
 * @notice Whether `a` is equal to `b`.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return True if equal, or False.
*/
function isNotEqual(FPUnsigned a, FPUnsigned b) pure returns (bool) {
    return FPUnsigned.unwrap(a) != FPUnsigned.unwrap(b);
}

/**
 * @notice Whether `a` is greater than `b`.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return True if `a > b`, or False.
*/
function isGreaterThan(FPUnsigned a, FPUnsigned b) pure returns (bool) {
    return FPUnsigned.unwrap(a) > FPUnsigned.unwrap(b);
}

/**
 * @notice Whether `a` is greater than or equal to `b`.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return True if `a >= b`, or False.
*/
function isGreaterThanOrEqual(FPUnsigned a, FPUnsigned b) pure returns (bool) {
    return FPUnsigned.unwrap(a) >= FPUnsigned.unwrap(b);
}

/**
 * @notice Whether `a` is less than `b`.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return True if `a < b`, or False.
*/
function isLessThan(FPUnsigned a, FPUnsigned b) pure returns (bool) {
    return FPUnsigned.unwrap(a) < FPUnsigned.unwrap(b);
}

/**
 * @notice Whether `a` is less than or equal to `b`.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return True if `a <= b`, or False.
*/
function isLessThanOrEqual(FPUnsigned a, FPUnsigned b) pure returns (bool) {
    return FPUnsigned.unwrap(a) <= FPUnsigned.unwrap(b);
}

/**
 * @notice Adds two `FPUnsigned`s, reverting on overflow.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return the sum of `a` and `b`.
*/
function add(FPUnsigned a, FPUnsigned b) pure returns (FPUnsigned) {
    return FPUnsigned.wrap(FPUnsigned.unwrap(a) + FPUnsigned.unwrap(b));
}

/**
 * @notice Subtracts two `FPUnsigned`s, reverting on overflow.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return the difference of `a` and `b`.
*/
function sub(FPUnsigned a, FPUnsigned b) pure returns (FPUnsigned) {
    return FPUnsigned.wrap(FPUnsigned.unwrap(a) - FPUnsigned.unwrap(b));
}

/**
 * @notice Multiplies two `FPUnsigned`s, reverting on overflow.
 * @dev This will "floor" the product.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return the product of `a` and `b`.
*/
function mul(FPUnsigned a, FPUnsigned b) pure returns (FPUnsigned) {
    // There are two caveats with this computation:
    // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
    // stored internally as a uint256 ~10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
    // would round to 3, but this computation produces the result 2.
    // No need to use SafeMath because FixedPoint.FP_SCALING_FACTOR != 0.
    return FPUnsigned.wrap(FPUnsigned.unwrap(a) * FPUnsigned.unwrap(b) / FixedPoint.FP_SCALING_FACTOR);
}

/**
 * @notice Divides one `FPUnsigned` by an `FPUnsigned`, reverting on overflow or division by 0.
 * @dev This will "floor" the quotient.
 * @param a a FPUnsigned numerator.
 * @param b a FPUnsigned denominator.
 * @return the quotient of `a` divided by `b`.
*/
function div(FPUnsigned a, FPUnsigned b) pure returns (FPUnsigned) {
    // There are two caveats with this computation:
    // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
    // 10^41 is stored internally as a uint256 10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
    // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
    return FPUnsigned.wrap(FPUnsigned.unwrap(a) * FixedPoint.FP_SCALING_FACTOR / FPUnsigned.unwrap(b));
}

/**
 * @notice Convert a FPUnsigned.FPUnsigned to uint, rounding up any decimal portion.
*/
function roundUp(FPUnsigned value) pure returns (uint256) {
    return trunc(ceil(value));
}

/**
 * @notice Convert a FPUnsigned.FPUnsigned to uint, "truncating" any decimal portion.
*/
function trunc(FPUnsigned value) pure returns (uint256) {
    return FPUnsigned.unwrap(value) / FixedPoint.FP_SCALING_FACTOR;
}

/**
 * @notice Rounding a FPUnsigned.Unsigned down to the nearest integer.
*/
function floor(FPUnsigned value) pure returns (FPUnsigned) {
    return FixedPoint.fromUnscaledUint(trunc(value));
}

/**
 * @notice Round a FPUnsigned.Unsigned up to the nearest integer.
*/
function ceil(FPUnsigned value) pure returns (FPUnsigned) {
    FPUnsigned iPart = floor(value);
    FPUnsigned fPart = sub(value, iPart);
    if (FPUnsigned.unwrap(fPart) > 0) {
        return add(iPart, FixedPoint.ONE);
    } else {
        return iPart;
    }
}

function neg(FPUnsigned a) pure returns (FPSigned) {
    return FixedPoint.fromUnsigned(a).neg();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import './FPUnsignedOperators.sol' as FPUnsignedOperators;
import './FPSignedOperators.sol' as FPSignedOperators;
import { UD60x18, pow as prbPow } from './prb-math/UD60x18.sol';

type FPUnsigned is uint256;
type FPSigned is int256;

using {
    FPUnsignedOperators.isEqual as ==,
    FPUnsignedOperators.isNotEqual as !=,
    FPUnsignedOperators.isGreaterThan as >,
    FPUnsignedOperators.isGreaterThanOrEqual as >=,
    FPUnsignedOperators.isLessThan as <,
    FPUnsignedOperators.isLessThanOrEqual as <=,
    FPUnsignedOperators.add as +,
    FPUnsignedOperators.sub as -,
    FPUnsignedOperators.mul as *,
    FPUnsignedOperators.div as /,

    FPUnsignedOperators.roundUp,
    FPUnsignedOperators.trunc,
    FPUnsignedOperators.neg
} for FPUnsigned global;

using {
    FPSignedOperators.isEqual as ==,
    FPSignedOperators.isNotEqual as !=,
    FPSignedOperators.isGreaterThan as >,
    FPSignedOperators.isGreaterThanOrEqual as >=,
    FPSignedOperators.isLessThan as <,
    FPSignedOperators.isLessThanOrEqual as <=,
    FPSignedOperators.add as +,
    FPSignedOperators.sub as -,
    FPSignedOperators.mul as *,
    FPSignedOperators.div as /,

    FPSignedOperators.neg,
    FPSignedOperators.abs,
    FPSignedOperators.roundTraderPnl,
    FPSignedOperators.trunc
} for FPSigned global;

library FixedPoint {

    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    uint256 constant FP_DECIMALS = 18;

    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
    uint256 constant FP_SCALING_FACTOR = 10**18;

    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
    int256 constant SFP_SCALING_FACTOR = 10**18;

    FPUnsigned constant ONE = FPUnsigned.wrap(10**18);
    FPUnsigned constant ZERO = FPUnsigned.wrap(0);

    // largest FPUnsigned which can be squared without reverting
    FPUnsigned constant MAX_UNSIGNED_FACTOR = FPUnsigned.wrap(340282366920938463463374607431768211455);
    // largest `FPSigned`s which can be squared without reverting
    FPSigned constant MIN_SIGNED_FACTOR = FPSigned.wrap(-240615969168004511545033772477625056927);
    FPSigned constant MAX_SIGNED_FACTOR = FPSigned.wrap(240615969168004511545033772477625056927);

    // largest FPUnsigned which can be cubed without reverting
    FPUnsigned constant MAX_UNSIGNED_CUBE_FACTOR = FPUnsigned.wrap(48740834812604276470692694885616);
    // largest `FPSigned`s which can be cubed without reverting
    FPSigned constant MIN_SIGNED_CUBE_FACTOR = FPSigned.wrap(-38685626227668133590597631999999);
    FPSigned constant MAX_SIGNED_CUBE_FACTOR = FPSigned.wrap(38685626227668133590597631999999);

    /**
    * @notice Constructs an `FPUnsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5*(10**18)`.
    * @param a uint to convert into a FixedPoint.
    * @return the converted FixedPoint.
    */
    function fromUnscaledUint(uint256 a) internal pure returns (FPUnsigned) {
        return FPUnsigned.wrap(a * FP_SCALING_FACTOR);
    }

    /**
    * @notice Given a uint with a certain number of decimal places, normalize it to a FixedPoint
    * @param value uint256, e.g. 10000000 wei USDC
    * @param decimals uint8 number of decimals to interpret `value` as, e.g. 6
    * @return output FPUnsigned, e.g. (10.000000)
    */
    function fromScalar(uint256 value, uint8 decimals) internal pure returns (FPUnsigned) {
        require(decimals <= FP_DECIMALS, 'FixedPoint: max decimals');
        return div(fromUnscaledUint(value), 10**decimals);
    }

    /**
    * @notice Constructs a `FPSigned` from an unscaled int, e.g., `b=5` gets stored internally as `5*(10**18)`.
    * @param a int to convert into a FPSigned.
    * @return the converted FPSigned.
    */
    function fromUnscaledInt(int256 a) internal pure returns (FPSigned) {
        return FPSigned.wrap(a * SFP_SCALING_FACTOR);
    }

    // --------- FPUnsigned
    function fromUnsigned(FPUnsigned a) internal pure returns (FPSigned) {
        require(FPUnsigned.unwrap(a) <= uint256(type(int256).max), 'FPUnsigned too large');
        return FPSigned.wrap(int256(FPUnsigned.unwrap(a)));
    }

    /**
    * @notice Adds an unscaled uint256 to an `FPUnsigned`, reverting on overflow.
    * @param a a FPUnsigned.
    * @param b a uint256.
    * @return the sum of `a` and `b`.
    */
    function add(FPUnsigned a, uint256 b) internal pure returns (FPUnsigned) {
        return FPUnsignedOperators.add(a, fromUnscaledUint(b));
    }

    /**
    * @notice Subtracts an unscaled uint256 from an `FPUnsigned`, reverting on overflow.
    * @param a a FPUnsigned.
    * @param b a uint256.
    * @return the difference of `a` and `b`.
    */
    function sub(FPUnsigned a, uint256 b) internal pure returns (FPUnsigned) {
        return FPUnsignedOperators.sub(a, fromUnscaledUint(b));
    }

    /**
    * @notice Multiplies an `FPUnsigned` and an unscaled uint256, reverting on overflow.
    * @dev This will "floor" the product.
    * @param a a FPUnsigned.
    * @param b a FPUnsigned.
    * @return the product of `a` and `b`.
    */
    function mul(FPUnsigned a, FPUnsigned b) internal pure returns (FPUnsigned) {
        return a * b;
    }

    /**
    * @notice Multiplies an `FPUnsigned` and an unscaled uint256, reverting on overflow.
    * @dev This will "floor" the product.
    * @param a a FPUnsigned.
    * @param b a uint256.
    * @return the product of `a` and `b`.
    */
    function mul(FPUnsigned a, uint256 b) internal pure returns (FPUnsigned) {
        return FPUnsigned.wrap(FPUnsigned.unwrap(a) * b);
    }

    /**
    * @notice Divides one `FPUnsigned` by an unscaled uint256, reverting on overflow or division by 0.
    * @dev This will "floor" the quotient.
    * @param a a FPUnsigned numerator.
    * @param b a uint256 denominator.
    * @return the quotient of `a` divided by `b`.
    */
    function div(FPUnsigned a, uint256 b) internal pure returns (FPUnsigned) {
        return FPUnsigned.wrap(FPUnsigned.unwrap(a) / b);
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FPUnsigned.
     * @param b a FPUnsigned.
     * @return the minimum of `a` and `b`.
    */
    function min(FPUnsigned a, FPUnsigned b) internal pure returns (FPUnsigned) {
        return FPUnsigned.unwrap(a) < FPUnsigned.unwrap(b) ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FPUnsigned.
     * @param b a FPUnsigned.
     * @return the maximum of `a` and `b`.
    */
    function max(FPUnsigned a, FPUnsigned b) internal pure returns (FPUnsigned) {
        return FPUnsigned.unwrap(a) > FPUnsigned.unwrap(b) ? a : b;
    }

    // --------- FPSigned

    function fromSigned(FPSigned a) internal pure returns (FPUnsigned) {
        require(FPSigned.unwrap(a) >= 0, 'Negative value provided');
        return FPUnsigned.wrap(uint256(FPSigned.unwrap(a)));
    }

    /**
     * @notice Adds a `FPSigned` to an `FPUnsigned`, reverting on overflow.
     * @param a a FPSigned.
     * @param b an FPUnsigned.
     * @return the sum of `a` and `b`.
    */
    function add(FPSigned a, FPUnsigned b) internal pure returns (FPSigned) {
        return FPSignedOperators.add(a, fromUnsigned(b));
    }

    /**
     * @notice Subtracts an unscaled int256 from a `FPSigned`, reverting on overflow.
     * @param a a FPSigned.
     * @param b an int256.
     * @return the difference of `a` and `b`.
    */
    function sub(FPSigned a, int256 b) internal pure returns (FPSigned) {
        return FPSignedOperators.sub(a, fromUnscaledInt(b));
    }

    /**
    * @notice Subtracts an `FPUnsigned` from a `FPSigned`, reverting on overflow.
    * @param a a FPSigned.
    * @param b a FPUnsigned.
    * @return the difference of `a` and `b`.
    */
    function sub(FPSigned a, FPUnsigned b) internal pure returns (FPSigned) {
        return FPSignedOperators.sub(a, fromUnsigned(b));
    }

    /**
    * @notice Subtracts an unscaled uint256 from a `FPSigned`, reverting on overflow.
    * @param a a FPSigned.
    * @param b a uint256.
    * @return the difference of `a` and `b`.
    */
    function sub(FPSigned a, uint256 b) internal pure returns (FPSigned) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
    * @notice Multiplies a `FPSigned` and an unscaled uint256, reverting on overflow.
    * @dev This will "floor" the product.
    * @param a a FPSigned.
    * @param b a uint256.
    * @return the product of `a` and `b`.
    */
    function mul(FPSigned a, uint256 b) internal pure returns (FPSigned) {
        return mul(a, fromUnscaledUint(b));
    }

    /**
    * @notice Multiplies a `FPSigned` and `FPUnsigned`, reverting on overflow.
    * @dev This will "floor" the product.
    * @param a a FPSigned.
    * @param b a FPUnsigned.
    * @return the product of `a` and `b`.
    */
    function mul(FPSigned a, FPUnsigned b) internal pure returns (FPSigned) {
        return FPSignedOperators.mul(a, fromUnsigned(b));
    }

    /**
    * @notice Divides one `FPSigned` by an `FPUnsigned`, reverting on overflow or division by 0.
    * @dev This will "floor" the quotient.
    * @param a a FPSigned numerator.
    * @param b a FPUnsigned denominator.
    * @return the quotient of `a` divided by `b`.
    */
    function div(FPSigned a, FPUnsigned b) internal pure returns (FPSigned) {
        return FPSignedOperators.div(a, fromUnsigned(b));
    }

    /**
    * @notice Divides one `FPSigned` by an unscaled uint256, reverting on overflow or division by 0.
    * @dev This will "floor" the quotient.
    * @param a a FPSigned numerator.
    * @param b a uint256 denominator.
    * @return the quotient of `a` divided by `b`.
    */
    function div(FPSigned a, uint256 b) internal pure returns (FPSigned) {
        return div(a, fromUnscaledUint(b));
    }

    /**
    * @notice The minimum of `a` and `b`.
    * @param a a FPSigned.
    * @param b a FPSigned.
    * @return the minimum of `a` and `b`.
    */
    function min(FPSigned a, FPSigned b) internal pure returns (FPSigned) {
        return FPSigned.unwrap(a) < FPSigned.unwrap(b) ? a : b;
    }

    /**
    * @notice The maximum of `a` and `b`.
    * @param a a FPSigned.
    * @param b a FPSigned.
    * @return the maximum of `a` and `b`.
    */
    function max(FPSigned a, FPSigned b) internal pure returns (FPSigned) {
        return FPSigned.unwrap(a) > FPSigned.unwrap(b) ? a : b;
    }

    /**
    * @notice The exponential  of `a^b`.
    * @param a a FPSigned
    * @param b a FPUnsigned
    * @return the exponential of `a^`
    */
    function pow(FPSigned a, FPUnsigned b) internal pure returns (FPSigned) {
        FPUnsigned result = FPUnsigned.wrap(UD60x18.unwrap(
            prbPow(
                UD60x18.wrap(FPUnsigned.unwrap(a.abs())),
                UD60x18.wrap(FPUnsigned.unwrap(b))
            )
        ));
        return a < fromUnsigned(ZERO) ? result.neg() : fromUnsigned(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import './FixedPoint.sol';
import '../interfaces/perp/IFeeCalculator.sol';

library PerpLib {
    using FixedPoint for FPSigned;
    using FixedPoint for FPUnsigned;

    function _canTakeProfit(
        bool isLong,
        uint256 positionTimestamp,
        FPUnsigned positionOraclePrice,
        FPUnsigned oraclePrice,
        FPUnsigned minPriceChange,
        uint256 minProfitTime
    ) internal view returns (bool) {
        if (block.timestamp > positionTimestamp + minProfitTime) {
            return true;
        }
        return isLong
            ? oraclePrice > positionOraclePrice * (FixedPoint.ONE + minPriceChange)
            : oraclePrice < positionOraclePrice * (FixedPoint.ONE - minPriceChange);
    }

    function _getPnl(
        bool isLong,
        FPUnsigned positionPrice,
        FPUnsigned positionLeverage,
        uint256 margin,
        FPUnsigned price
    ) internal pure returns (FPSigned pnl) {
        pnl = (isLong
            ? price.fromUnsigned().sub(positionPrice)
            : positionPrice.fromUnsigned().sub(price)
            ).mul(margin).mul(positionLeverage).div(positionPrice);
    }

    function _getFundingPayment(
        bool isLong,
        FPUnsigned positionLeverage,
        uint256 margin,
        FPSigned funding,
        FPSigned cumulativeFunding,
        FPUnsigned cumulativeInterest
    ) internal pure returns (FPSigned) {
        FPSigned actualMargin = FixedPoint.fromUnscaledUint(margin).fromUnsigned();
        return
            actualMargin.mul(positionLeverage) * (
                isLong
                ? cumulativeFunding.add(cumulativeInterest) - funding
                : funding - (cumulativeFunding.sub(cumulativeInterest))
            );
    }

    function _getTradeFee(
        uint256 margin,
        FPUnsigned leverage,
        FPUnsigned productFee,
        address user,
        address sender,
        IFeeCalculator feeCalculator
    ) internal view returns (uint256) {
        FPUnsigned fee = feeCalculator.getTradeFee(productFee, user, sender);
        return (FixedPoint.fromUnscaledUint(margin) * leverage * fee).roundUp();
    }

    function getUtilizationRatio(
        FPUnsigned totalOpenInterest,
        uint256 balance,
        FPSigned totalPnl,
        uint256 pendingWithdraw,
        FPUnsigned healthyUtilizationRatio
    ) internal pure returns (bool instantRedeemAvailable, FPSigned utilizationRatio) {
        FPSigned divider = FixedPoint.fromUnscaledInt(int256(balance - pendingWithdraw)) - totalPnl;
        if (divider != FixedPoint.ZERO.fromUnsigned()) {
            utilizationRatio = totalOpenInterest.fromUnsigned() / divider;
            instantRedeemAvailable = utilizationRatio <= healthyUtilizationRatio.fromUnsigned();
        } else {
            utilizationRatio = FixedPoint.ZERO.fromUnsigned();
            instantRedeemAvailable = totalOpenInterest == FixedPoint.ZERO;
        }
    }

    /** @notice get the withdraw delay for a withdraw request with no history
     */
    function _getWithdrawDelay(
        uint256 pendingWithdraw,
        FPUnsigned requestedShareFraction,
        FPSigned sumPnL,
        uint256 balance,
        FPUnsigned healthyUtilizationRatio,
        FPUnsigned totalOpenInterest,
        uint256 maxWithdrawDelay,
        uint256 delayPerUtilizationRatio
    ) internal pure returns (uint64) {
        (bool instantRedeemAvailable, FPSigned utilizationRatio) = getUtilizationRatio(
            totalOpenInterest,
            balance,
            sumPnL,
            pendingWithdraw,
            healthyUtilizationRatio
        );

        if (instantRedeemAvailable) {
            return 0;
        }

        int256 rawDelay = (utilizationRatio - healthyUtilizationRatio.fromUnsigned())
            .mul(delayPerUtilizationRatio).mul(requestedShareFraction).trunc();
        return uint64(
            rawDelay < 0
                ? 0
                : rawDelay > int256(maxWithdrawDelay)
                    ? maxWithdrawDelay
                    : uint256(rawDelay)
        );
    }

    /** worst-case previousWithdrawDelay == previousActualWait -> 2x penalty
        without this delay, people could on average halve withdraw time by
        always keeping a withdraw request open.
        best-case, previousActualWait -> \inf and they receive no penalty
    */
    function _getDelayForFullWithdraw(
        FPUnsigned requestedShareFraction,
        FPSigned sumPnL,
        FPUnsigned healthyUtilizationRatio,
        FPUnsigned totalOpenInterest,
        uint256 balance,
        uint256 pendingWithdraw,
        uint256 maxWithdrawDelay,
        uint256 delayPerUtilizationRatio,
        uint64 previousWithdrawDelay,
        uint64 previousActualWait
    ) internal pure returns (uint64 delay, uint64 penalty) {
        delay = _getWithdrawDelay(
            pendingWithdraw,
            requestedShareFraction,
            sumPnL,
            balance,
            healthyUtilizationRatio,
            totalOpenInterest,
            maxWithdrawDelay,
            delayPerUtilizationRatio
        );

        // TODO: scale this by relative size of new request and remaining old request
        if (previousWithdrawDelay != 0 && previousActualWait >= previousWithdrawDelay ) {
            // no penalty for new requests or increments
            penalty = uint64(
                (FixedPoint.fromUnscaledUint(previousWithdrawDelay).div(previousActualWait))
                    .mul(delay).trunc()
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./UD60x18Common.sol" as Common;

type UD60x18 is uint256;

///////////////////////////////////////////////////////////////////////////
/// Constants
///////////////////////////////////////////////////////////////////////////

/// @dev The unit number, which gives the decimal precision of UD60x18.
uint256 constant uUNIT = 1e18;
UD60x18 constant UNIT = UD60x18.wrap(uUNIT);

/// @dev Half the UNIT number.
uint256 constant uHALF_UNIT = 0.5e18;

/// @dev The unit number squared.
uint256 constant uUNIT_SQUARED = 1e36;

/// @dev Zero as a UD60x18 number.
UD60x18 constant ZERO = UD60x18.wrap(0);

/// @dev The maximum input permitted in {exp2}.
uint256 constant uEXP2_MAX_INPUT = 192e18 - 1;
UD60x18 constant EXP2_MAX_INPUT = UD60x18.wrap(uEXP2_MAX_INPUT);


///////////////////////////////////////////////////////////////////////////
/// Custom Errors
///////////////////////////////////////////////////////////////////////////

/// @notice Thrown when taking the logarithm of a number less than 1.
error PRBMath_UD60x18_Log_InputTooSmall(UD60x18 x);

/// @notice Thrown when taking the binary exponent of a base greater than 192e18.
error PRBMath_UD60x18_Exp2_InputTooBig(UD60x18 x);


///////////////////////////////////////////////////////////////////////////
/// Casting Functions
///////////////////////////////////////////////////////////////////////////

/// @notice Wraps a uint256 number into the UD60x18 value type.
function wrap(uint256 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(x);
}

/// @notice Unwraps a UD60x18 number into uint256.
function unwrap(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x);
}

///////////////////////////////////////////////////////////////////////////
/// Math Functions
///////////////////////////////////////////////////////////////////////////

/// @notice Raises x to the power of y.
///
/// For $1 \leq x \leq \infty$, the following standard formula is used:
///
/// $$
/// x^y = 2^{log_2{x} * y}
/// $$
///
/// For $0 \leq x \lt 1$, since the unsigned {log2} is undefined, an equivalent formula is used:
///
/// $$
/// i = \frac{1}{x}
/// w = 2^{log_2{i} * y}
/// x^y = \frac{1}{w}
/// $$
///
/// @dev Notes:
/// - Refer to the notes in {log2} and {mul}.
/// - Returns `UNIT` for 0^0.
/// - It may not perform well with very small values of x. Consider using SD59x18 as an alternative.
///
/// Requirements:
/// - Refer to the requirements in {exp2}, {log2}, and {mul}.
///
/// @param x The base as a UD60x18 number.
/// @param y The exponent as a UD60x18 number.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function pow(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = UD60x18.unwrap(x);
    uint256 yUint = UD60x18.unwrap(y);

    // If both x and y are zero, the result is `UNIT`. If just x is zero, the result is always zero.
    if (xUint == 0) {
        return yUint == 0 ? UNIT : ZERO;
    }
    // If x is `UNIT`, the result is always `UNIT`.
    else if (xUint == uUNIT) {
        return UNIT;
    }

    // If y is zero, the result is always `UNIT`.
    if (yUint == 0) {
        return UNIT;
    }
    // If y is `UNIT`, the result is always x.
    else if (yUint == uUNIT) {
        return x;
    }

    // If x is greater than `UNIT`, use the standard formula.
    if (xUint > uUNIT) {
        result = exp2(mul(log2(x), y));
    }
    // Conversely, if x is less than `UNIT`, use the equivalent formula.
    else {
        UD60x18 i = wrap(uUNIT_SQUARED / xUint);
        UD60x18 w = exp2(mul(log2(i), y));
        result = wrap(uUNIT_SQUARED / UD60x18.unwrap(w));
    }
}

/// @notice Calculates the binary logarithm of x using the iterative approximation algorithm:
///
/// $$
/// log_2{x} = n + log_2{y}, \text{ where } y = x*2^{-n}, \ y \in [1, 2)
/// $$
///
/// For $0 \leq x \lt 1$, the input is inverted:
///
/// $$
/// log_2{x} = -log_2{\frac{1}{x}}
/// $$
///
/// @dev See https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
///
/// Notes:
/// - Due to the lossy precision of the iterative approximation, the results are not perfectly accurate to the last decimal.
///
/// Requirements:
/// - x must be greater than zero.
///
/// @param x The UD60x18 number for which to calculate the binary logarithm.
/// @return result The binary logarithm as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function log2(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = UD60x18.unwrap(x);

    if (xUint < uUNIT) {
        revert PRBMath_UD60x18_Log_InputTooSmall(x);
    }

    unchecked {
        // Calculate the integer part of the logarithm.
        uint256 n = Common.msb(xUint / uUNIT);

        // This is the integer part of the logarithm as a UD60x18 number. The operation can't overflow because n
        // n is at most 255 and UNIT is 1e18.
        uint256 resultUint = n * uUNIT;

        // Calculate $y = x * 2^{-n}$.
        uint256 y = xUint >> n;

        // If y is the unit number, the fractional part is zero.
        if (y == uUNIT) {
            return wrap(resultUint);
        }

        // Calculate the fractional part via the iterative approximation.
        // The `delta >>= 1` part is equivalent to `delta /= 2`, but shifting bits is more gas efficient.
        uint256 DOUBLE_UNIT = 2e18;
        for (uint256 delta = uHALF_UNIT; delta > 0; delta >>= 1) {
            y = (y * y) / uUNIT;

            // Is y^2 >= 2e18 and so in the range [2e18, 4e18)?
            if (y >= DOUBLE_UNIT) {
                // Add the 2^{-m} factor to the logarithm.
                resultUint += delta;

                // Halve y, which corresponds to z/2 in the Wikipedia article.
                y >>= 1;
            }
        }
        result = wrap(resultUint);
    }
}

/// @notice Multiplies two UD60x18 numbers together, returning a new UD60x18 number.
///
/// @dev Uses {Common.mulDiv} to enable overflow-safe multiplication and division.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
///
/// @dev See the documentation in {Common.mulDiv18}.
/// @param x The multiplicand as a UD60x18 number.
/// @param y The multiplier as a UD60x18 number.
/// @return result The product as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function mul(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(Common.mulDiv18(UD60x18.unwrap(x), UD60x18.unwrap(y)));
}

/// @notice Divides two UD60x18 numbers, returning a new UD60x18 number.
///
/// @dev Uses {Common.mulDiv} to enable overflow-safe multiplication and division.
///
/// Notes:
/// - Refer to the notes in {Common.mulDiv}.
///
/// Requirements:
/// - Refer to the requirements in {Common.mulDiv}.
///
/// @param x The numerator as a UD60x18 number.
/// @param y The denominator as a UD60x18 number.
/// @param result The quotient as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function div(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(Common.mulDiv(UD60x18.unwrap(x), uUNIT, UD60x18.unwrap(y)));
}

/// @notice Calculates the binary exponent of x using the binary fraction method.
///
/// @dev See https://ethereum.stackexchange.com/q/79903/24693
///
/// Requirements:
/// - x must be less than 192e18.
/// - The result must fit in UD60x18.
///
/// @param x The exponent as a UD60x18 number.
/// @return result The result as a UD60x18 number.
/// @custom:smtchecker abstract-function-nondet
function exp2(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = UD60x18.unwrap(x);

    // Numbers greater than or equal to 192e18 don't fit in the 192.64-bit format.
    if (xUint > uEXP2_MAX_INPUT) {
        revert PRBMath_UD60x18_Exp2_InputTooBig(x);
    }

    // Convert x to the 192.64-bit fixed-point format.
    uint256 x_192x64 = (xUint << 64) / uUNIT;

    // Pass x to the {Common.exp2} function, which uses the 192.64-bit fixed-point number representation.
    result = wrap(Common.exp2(x_192x64));
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*//////////////////////////////////////////////////////////////////////////
                                    CONSTANTS
//////////////////////////////////////////////////////////////////////////*/

/// @dev The unit number, which the decimal precision of the fixed-point types.
uint256 constant UNIT = 1e18;

/// @dev The unit number inverted mod 2^256.
uint256 constant UNIT_INVERSE = 78156646155174841979727994598816262306175212592076161876661_508869554232690281;

/// @dev The the largest power of two that divides the decimal value of `UNIT`. The logarithm of this value is the least significant
/// bit in the binary representation of `UNIT`.
uint256 constant UNIT_LPOTD = 262144;


/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Thrown when the resultant value in {mulDiv18} overflows uint256.
error PRBMath_MulDiv18_Overflow(uint256 x, uint256 y);

/// @notice Thrown when the resultant value in {mulDiv} overflows uint256.
error PRBMath_MulDiv_Overflow(uint256 x, uint256 y, uint256 denominator);


/*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Calculates the binary exponent of x using the binary fraction method.
/// @dev Has to use 192.64-bit fixed-point numbers. See https://ethereum.stackexchange.com/a/96594/24693.
/// @param x The exponent as an unsigned 192.64-bit fixed-point number.
/// @return result The result as an unsigned 60.18-decimal fixed-point number.
/// @custom:smtchecker abstract-function-nondet
function exp2(uint256 x) pure returns (uint256 result) {
    unchecked {
        // Start from 0.5 in the 192.64-bit fixed-point format.
        result = 0x800000000000000000000000000000000000000000000000;

        // The following logic multiplies the result by $\sqrt{2^{-i}}$ when the bit at position i is 1. Key points:
        //
        // 1. Intermediate results will not overflow, as the starting point is 2^191 and all magic factors are under 2^65.
        // 2. The rationale for organizing the if statements into groups of 8 is gas savings. If the result of performing
        // a bitwise AND operation between x and any value in the array [0x80; 0x40; 0x20; 0x10; 0x08; 0x04; 0x02; 0x01] is 1,
        // we know that `x & 0xFF` is also 1.
        if (x & 0xFF00000000000000 > 0) {
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
        }

        if (x & 0xFF000000000000 > 0) {
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
        }

        if (x & 0xFF0000000000 > 0) {
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
        }

        if (x & 0xFF00000000 > 0) {
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
        }

        if (x & 0xFF000000 > 0) {
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
        }

        if (x & 0xFF0000 > 0) {
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
        }

        if (x & 0xFF00 > 0) {
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
        }

        if (x & 0xFF > 0) {
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
        }

        // In the code snippet below, two operations are executed simultaneously:
        //
        // 1. The result is multiplied by $(2^n + 1)$, where $2^n$ represents the integer part, and the additional 1
        // accounts for the initial guess of 0.5. This is achieved by subtracting from 191 instead of 192.
        // 2. The result is then converted to an unsigned 60.18-decimal fixed-point format.
        //
        // The underlying logic is based on the relationship $2^{191-ip} = 2^{ip} / 2^{191}$, where $ip$ denotes the,
        // integer part, $2^n$.
        result *= UNIT;
        result >>= (191 - (x >> 64));
    }
}

/// @notice Finds the zero-based index of the first 1 in the binary representation of x.
///
/// @dev See the note on "msb" in this Wikipedia article: https://en.wikipedia.org/wiki/Find_first_set
///
/// Each step in this implementation is equivalent to this high-level code:
///
/// ```solidity
/// if (x >= 2 ** 128) {
///     x >>= 128;
///     result += 128;
/// }
/// ```
///
/// Where 128 is replaced with each respective power of two factor. See the full high-level implementation here:
/// https://gist.github.com/PaulRBerg/f932f8693f2733e30c4d479e8e980948
///
/// The Yul instructions used below are:
///
/// - "gt" is "greater than"
/// - "or" is the OR bitwise operator
/// - "shl" is "shift left"
/// - "shr" is "shift right"
///
/// @param x The uint256 number for which to find the index of the most significant bit.
/// @return result The index of the most significant bit as a uint256.
/// @custom:smtchecker abstract-function-nondet
function msb(uint256 x) pure returns (uint256 result) {
    // 2^128
    assembly ("memory-safe") {
        let factor := shl(7, gt(x, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^64
    assembly ("memory-safe") {
        let factor := shl(6, gt(x, 0xFFFFFFFFFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^32
    assembly ("memory-safe") {
        let factor := shl(5, gt(x, 0xFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^16
    assembly ("memory-safe") {
        let factor := shl(4, gt(x, 0xFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^8
    assembly ("memory-safe") {
        let factor := shl(3, gt(x, 0xFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^4
    assembly ("memory-safe") {
        let factor := shl(2, gt(x, 0xF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^2
    assembly ("memory-safe") {
        let factor := shl(1, gt(x, 0x3))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^1
    // No need to shift x any more.
    assembly ("memory-safe") {
        let factor := gt(x, 0x1)
        result := or(result, factor)
    }
}

/// @notice Calculates x*y÷1e18 with 512-bit precision.
///
/// @dev A variant of {mulDiv} with constant folding, i.e. in which the denominator is hard coded to 1e18.
///
/// Notes:
/// - The body is purposely left uncommented; to understand how this works, see the documentation in {mulDiv}.
/// - The result is rounded toward zero.
/// - We take as an axiom that the result cannot be `MAX_UINT256` when x and y solve the following system of equations:
///
/// $$
/// \begin{cases}
///     x * y = MAX\_UINT256 * UNIT \\
///     (x * y) \% UNIT \geq \frac{UNIT}{2}
/// \end{cases}
/// $$
///
/// Requirements:
/// - Refer to the requirements in {mulDiv}.
/// - The result must fit in uint256.
///
/// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
/// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
/// @return result The result as an unsigned 60.18-decimal fixed-point number.
/// @custom:smtchecker abstract-function-nondet
function mulDiv18(uint256 x, uint256 y) pure returns (uint256 result) {
    uint256 prod0;
    uint256 prod1;
    assembly ("memory-safe") {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    if (prod1 == 0) {
        unchecked {
            return prod0 / UNIT;
        }
    }

    if (prod1 >= UNIT) {
        revert PRBMath_MulDiv18_Overflow(x, y);
    }

    uint256 remainder;
    assembly ("memory-safe") {
        remainder := mulmod(x, y, UNIT)
        result :=
            mul(
                or(
                    div(sub(prod0, remainder), UNIT_LPOTD),
                    mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, UNIT_LPOTD), UNIT_LPOTD), 1))
                ),
                UNIT_INVERSE
            )
    }
}

/// @notice Calculates x*y÷denominator with 512-bit precision.
///
/// @dev Credits to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
///
/// Notes:
/// - The result is rounded toward zero.
///
/// Requirements:
/// - The denominator must not be zero.
/// - The result must fit in uint256.
///
/// @param x The multiplicand as a uint256.
/// @param y The multiplier as a uint256.
/// @param denominator The divisor as a uint256.
/// @return result The result as a uint256.
/// @custom:smtchecker abstract-function-nondet
function mulDiv(uint256 x, uint256 y, uint256 denominator) pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
    // use the Chinese Remainder Theorem to reconstruct the 512-bit result. The result is stored in two 256
    // variables such that product = prod1 * 2^256 + prod0.
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly ("memory-safe") {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division.
    if (prod1 == 0) {
        unchecked {
            return prod0 / denominator;
        }
    }

    // Make sure the result is less than 2^256. Also prevents denominator == 0.
    if (prod1 >= denominator) {
        revert PRBMath_MulDiv_Overflow(x, y, denominator);
    }

    ////////////////////////////////////////////////////////////////////////////
    // 512 by 256 division
    ////////////////////////////////////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0].
    uint256 remainder;
    assembly ("memory-safe") {
        // Compute remainder using the mulmod Yul instruction.
        remainder := mulmod(x, y, denominator)

        // Subtract 256 bit number from 512-bit number.
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
    }

    unchecked {
        // Calculate the largest power of two divisor of the denominator using the unary operator ~. This operation cannot overflow
        // because the denominator cannot be zero at this point in the function execution. The result is always >= 1.
        // For more detail, see https://cs.stackexchange.com/q/138556/92363.
        uint256 lpotdod = denominator & (~denominator + 1);
        uint256 flippedLpotdod;

        assembly ("memory-safe") {
            // Factor powers of two out of denominator.
            denominator := div(denominator, lpotdod)

            // Divide [prod1 prod0] by lpotdod.
            prod0 := div(prod0, lpotdod)

            // Get the flipped value `2^256 / lpotdod`. If the `lpotdod` is zero, the flipped value is one.
            // `sub(0, lpotdod)` produces the two's complement version of `lpotdod`, which is equivalent to flipping all the bits.
            // However, `div` interprets this value as an unsigned value: https://ethereum.stackexchange.com/q/147168/24693
            flippedLpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
        }

        // Shift in bits from prod1 into prod0.
        prod0 |= prod1 * flippedLpotdod;

        // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
        // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
        // four bits. That is, denominator * inv = 1 mod 2^4.
        uint256 inverse = (3 * denominator) ^ 2;

        // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
        // in modular arithmetic, doubling the correct bits in each step.
        inverse *= 2 - denominator * inverse; // inverse mod 2^8
        inverse *= 2 - denominator * inverse; // inverse mod 2^16
        inverse *= 2 - denominator * inverse; // inverse mod 2^32
        inverse *= 2 - denominator * inverse; // inverse mod 2^64
        inverse *= 2 - denominator * inverse; // inverse mod 2^128
        inverse *= 2 - denominator * inverse; // inverse mod 2^256

        // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
        // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
        // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inverse;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../interfaces/oracle/IPriceFeed.sol';
import '../interfaces/perp/IDomFiPerp.sol';
import '../interfaces/perp/IFeeCalculator.sol';
import '../access/Governable.sol';
import '../lib/FixedPoint.sol';
import '../lib/PerpLib.sol';

/**
* @title Order book for Domination Finance. Manage orders that can be executed
         based on price triggers.
*/
contract OrderBook is Governable, ReentrancyGuard {
    using FixedPoint for FPUnsigned;
    using FixedPoint for FPSigned;

    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;
    using Address for address payable;

    enum OrderType {
        INCREASE_SIZE,
        DECREASE_SIZE,
        ADD_MARGIN,
        REMOVE_MARGIN
    }

    enum TriggerType {
        INVALID,
        PRICE,
        PNL_RATE
    }

    enum TriggerCondition {
        LTE,
        GTE
    }

    struct TriggerDetails {
        TriggerType triggerType;
        TriggerCondition triggerCondition; // should trigger >= or <= threshold?
        FPSigned triggerPnLRate; // PNL_RATE only. trigger when (PnL / Margin) crosses threshold
        FPUnsigned triggerPrice; // PRICE only. trigger when price crosses threshold
    }

    struct OrderDetails {
        // INCREASE_SIZE
        FPUnsigned leverage;
        uint256 margin; // also ADD_MARGIN
        uint256 tradeFee;

        // DECREASE_SIZE
        FPUnsigned size;

        // REMOVE_MARGIN
        FPUnsigned removeMarginFactor;
    }

    struct Order {
        uint256 executionFee; // gas reimbursement to order executor
        uint64 submittedAt;
        uint64 canceledAt; // 0 unless the order has been canceled
        uint64 executedAt; // 0 unless the order has been executed
        uint64 executionDeadline; // time after which order can only be canceled
        bytes32 productId; // position identifier

        OrderType orderType; // order details
        OrderDetails orderDetails; // order details
        TriggerDetails triggerDetails;

        bool isLong; // position identifier
        address account; // position identifier
        bytes16 accountPositionId; // position identifier
        bytes userData;
    }

    // EIP-712 signature
    struct Signature {
        uint256 amount;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    mapping(address => mapping(uint256 => Order)) public orders;
    mapping(address => uint256) public lastOrderNumber;
    mapping(address => bool) public isKeeper;

    IDomFiPerp public immutable domFiPerp;
    IERC20 public immutable collateralToken;

    address public admin;
    IPriceFeed public oracle;
    IFeeCalculator public feeCalculator;

    uint256 public minExecutionFee;
    uint64 public minTimeExecuteDelay;
    uint64 public minTimeCancelDelay;
    bool public allowPublicKeeper = false;
    bool public isKeeperCall = false;

    event CreateOrder(
        address indexed account,
        uint256 indexed orderNumber,
        bytes32 indexed productId,
        bytes16 accountPositionId,
        OrderType orderType,
        Order order
    );

    event CancelOrder(
        address indexed account,
        uint256 indexed orderNumber,
        bytes32 indexed productId,
        bytes16 accountPositionId,
        OrderType orderType,
        Order order
    );

    event UpdateOrder(
        address indexed account,
        uint256 indexed orderNumber,
        bytes32 indexed productId,
        bytes16 accountPositionId,
        OrderType orderType,
        Order prevOrder,
        Order newOrder
    );

    event ExecuteOrder(
        address indexed account,
        uint256 indexed orderNumber,
        bytes32 indexed productId,
        bytes16 accountPositionId,
        FPUnsigned executionPrice,
        FPSigned currentPnL,
        OrderType orderType,
        Order order
    );

    event ExecuteOrderError(address indexed account, uint256 indexed orderNumber, string executionError);
    event ExecuteOrderFailure(address indexed account, uint256 indexed orderNumber, bytes lowLevelData);

    event UpdateMinTimeExecuteDelay(uint64 minTimeExecuteDelay);
    event UpdateMinTimeCancelDelay(uint64 minTimeCancelDelay);
    event UpdateAllowPublicKeeper(bool allowPublicKeeper);
    event UpdateMinExecutionFee(uint256 minExecutionFee);
    event UpdateKeeper(address keeper, bool isAlive);
    event UpdateAdmin(address admin);

    modifier onlyAdmin() {
        require(msg.sender == admin, 'OrderBook: !admin');
        _;
    }

    modifier onlyKeeper() {
        require(isKeeper[msg.sender], 'OrderBook: !keeper');
        _;
    }

    constructor(
        uint256 _minExecutionFee,
        IDomFiPerp _domFiPerp,
        IPriceFeed _oracle,
        IFeeCalculator _feeCalculator
    ) {
        admin = msg.sender;
        domFiPerp = _domFiPerp;
        oracle = _oracle;
        minExecutionFee = _minExecutionFee;
        feeCalculator = _feeCalculator;
        collateralToken = IERC20(_domFiPerp.asset());
    }

    function setOracle(IPriceFeed _oracle) external onlyAdmin {
        oracle = _oracle;
    }

    function setFeeCalculator(IFeeCalculator _feeCalculator) external onlyAdmin {
        feeCalculator = _feeCalculator;
    }

    function setMinExecutionFee(uint256 _minExecutionFee) external onlyAdmin {
        minExecutionFee = _minExecutionFee;
        emit UpdateMinExecutionFee(_minExecutionFee);
    }

    function setMinTimeExecuteDelay(uint64 _minTimeExecuteDelay) external onlyAdmin {
        minTimeExecuteDelay = _minTimeExecuteDelay;
        emit UpdateMinTimeExecuteDelay(_minTimeExecuteDelay);
    }

    function setMinTimeCancelDelay(uint64 _minTimeCancelDelay) external onlyAdmin {
        minTimeCancelDelay = _minTimeCancelDelay;
        emit UpdateMinTimeCancelDelay(_minTimeCancelDelay);
    }

    function setAllowPublicKeeper(bool _allowPublicKeeper) external onlyAdmin {
        allowPublicKeeper = _allowPublicKeeper;
        emit UpdateAllowPublicKeeper(_allowPublicKeeper);
    }

    function setKeeper(address _account, bool _isActive) external onlyAdmin {
        isKeeper[_account] = _isActive;
        emit UpdateKeeper(_account, _isActive);
    }

    function setAdmin(address _admin) external onlyGov {
        admin = _admin;
        emit UpdateAdmin(_admin);
    }

    function executeOrders(
        address[] memory _addresses,
        uint256[] memory _orderIndices,
        address payable _feeReceiver
    ) public {
        require(_addresses.length == _orderIndices.length, 'OrderBook: not same length');
        isKeeperCall = isKeeper[msg.sender];

        for (uint256 i = 0; i < _addresses.length; i++) {
            try this.executeOrder(_addresses[i], _orderIndices[i], _feeReceiver) {}
            catch Error(string memory executionError) {
                emit ExecuteOrderError(_addresses[i], _orderIndices[i], executionError);
            }
            catch (bytes memory lowLevelData) {
                emit ExecuteOrderFailure(_addresses[i], _orderIndices[i], lowLevelData);
            }
        }
    }

    function cancelMultiple(
        address payable _address,
        uint256[] memory _orderIndices
    ) external {
        for (uint256 i = 0; i < _orderIndices.length; i++) {
            cancelOrder(_address, _orderIndices[i]);
        }
    }

    struct OrderParams {
        bytes16 accountPositionId;
        bytes32 productId;
        bool isLong;
        OrderType orderType;
        OrderDetails orderDetails;
        TriggerDetails triggerDetails;
        uint256 executionFee; // gas reimbursement to order executor
        uint64 executionDeadline; // time after which order can only be canceled
        bytes userData;
    }

    function createOrders(OrderParams[] calldata _orderParams, Signature memory _signature) external payable {
        uint256 unspentExecutionFees = msg.value;

        if (_signature.v != 0 && _signature.r != 0 && _signature.s != 0) {
            IERC20Permit(address(collateralToken)).safePermit(
                msg.sender,
                address(this),
                _signature.amount,
                _signature.deadline,
                _signature.v,
                _signature.r,
                _signature.s
            );
        }

        for (uint256 i = 0; i < _orderParams.length; i++) {
            OrderParams calldata order = _orderParams[i];

            require(
                order.executionFee >= minExecutionFee,
                'OrderBook: not enough executionFee'
            );
            require(
                unspentExecutionFees >= order.executionFee,
                'OrderBook: executionFee not sent'
            );
            unchecked {
                unspentExecutionFees -= order.executionFee;
            }

            require(order.accountPositionId != 0, 'OrderBook: !postionNumber');
            require(
                order.executionDeadline > block.timestamp,
                'OrderBook: !executionDeadline'
            );
            TriggerDetails calldata trigger = order.triggerDetails;
            require(
                trigger.triggerType == TriggerType.PRICE && trigger.triggerPnLRate == FixedPoint.ZERO.fromUnsigned()
                || trigger.triggerType == TriggerType.PNL_RATE && trigger.triggerPrice == FixedPoint.ZERO,
                'OrderBook: !triggerDetails'
            );

            uint256 tradeFee;
            if (order.orderType == OrderType.INCREASE_SIZE) {
                tradeFee = getTradeFeeRate(order.productId, msg.sender)
                    .mul(order.orderDetails.margin)
                    .mul(order.orderDetails.leverage)
                    .roundUp();
            }
            if (order.orderType == OrderType.INCREASE_SIZE || order.orderType == OrderType.ADD_MARGIN) {
                collateralToken.safeTransferFrom(
                    msg.sender,
                    address(this),
                    order.orderDetails.margin + tradeFee
                );
            }

            // get new order details with tradeFee
            OrderDetails memory newOrderDetails = OrderDetails({
                margin: order.orderDetails.margin,
                leverage: order.orderDetails.leverage,
                tradeFee: tradeFee,
                size: order.orderDetails.size,
                removeMarginFactor: order.orderDetails.removeMarginFactor
            });

            // store
            Order memory newOrder = Order({
                account: msg.sender,
                accountPositionId: order.accountPositionId,
                productId: order.productId,
                isLong: order.isLong,
                orderType: order.orderType,
                orderDetails: newOrderDetails,
                triggerDetails: order.triggerDetails,
                executionFee: order.executionFee,
                submittedAt: uint64(block.timestamp),
                canceledAt: 0,
                executedAt: 0,
                executionDeadline: order.executionDeadline,
                userData: order.userData
            });

            uint256 orderNumber = lastOrderNumber[msg.sender] + 1;
            lastOrderNumber[msg.sender] = orderNumber;

            orders[msg.sender][orderNumber] = newOrder;
            emit CreateOrder(
                msg.sender,
                orderNumber,
                order.productId,
                order.accountPositionId,
                order.orderType,
                newOrder
            );
        }
    }

    /**
     * Before editing an order, must check that
     * - it belongs to the owner (i.e. not uninitialized)
     * - it hasn't been marked executed/canceled/expired
     */
    function checkValidUnresolved(Order memory order, address owner) internal pure {
        require(order.account == owner, 'OrderBook: !order_account');
        require(order.canceledAt == 0, 'OrderBook: order deleted');
        require(order.executedAt == 0, 'OrderBook: order already executed');
    }

    /**
     * Before executing an order, must also check that
     * - it is after order delay but before expiration
     * - price is past the trigger
     */
    function checkExecutable(Order storage order, address owner) internal returns (FPUnsigned currentPrice, FPSigned pnl) {
        require(block.timestamp < uint64(order.executionDeadline), 'OrderBook: execution deadline expired');
        require(
            (msg.sender == address(this) && isKeeperCall) ||
                isKeeper[msg.sender] ||
                (allowPublicKeeper && uint64(order.submittedAt) + minTimeExecuteDelay < block.timestamp),
            'OrderBook: min time execute delay'
        );

        TriggerDetails memory triggerDetails = order.triggerDetails;
        require(
            triggerDetails.triggerType == TriggerType.PRICE && triggerDetails.triggerPnLRate == FixedPoint.ZERO.fromUnsigned()
            || triggerDetails.triggerType == TriggerType.PNL_RATE && triggerDetails.triggerPrice == FixedPoint.ZERO,
            'OrderBook: !triggerDetails'
        );

        IDomFiPerp.Product memory product = domFiPerp.getProduct(order.productId);
        currentPrice = oracle.getPrice(product.productId);

        bool priceTriggered;
        if (triggerDetails.triggerType == TriggerType.PNL_RATE) {
            // trigger when PnL reaches to the condition
            IDomFiPerp.Position memory position = domFiPerp.getPosition(owner, order.accountPositionId);
            (pnl, ) = domFiPerp.getPositionPnLAndFunding(position, currentPrice);
            priceTriggered = triggerDetails.triggerCondition == TriggerCondition.GTE
                ? pnl.div(position.margin) >= triggerDetails.triggerPnLRate
                : pnl.div(position.margin) <= triggerDetails.triggerPnLRate;
        } else if (triggerDetails.triggerType == TriggerType.PRICE) {
            priceTriggered = triggerDetails.triggerCondition  == TriggerCondition.GTE
                ? currentPrice >= triggerDetails.triggerPrice
                : currentPrice <= triggerDetails.triggerPrice;
        }

        require(priceTriggered, 'OrderBook: order price cond');
    }

    function cancelOrder(
        address payable _address,
        uint256 _orderNumber
    ) public nonReentrant {
        require(_address != address(0), 'OrderBook: !account');
        require(_orderNumber > 0, 'OrderBook: !orderNumber');

        Order storage order = orders[_address][_orderNumber];
        checkValidUnresolved(order, _address);
        require(
            order.submittedAt + minTimeCancelDelay < uint64(block.timestamp),
            'OrderBook: min time cancel delay'
        );
        require(
            _address == msg.sender || block.timestamp > order.executionDeadline,
            'OrderBook: unexpired'
        );

        order.canceledAt = uint64(block.timestamp);

        if (order.orderType == OrderType.ADD_MARGIN) {
            collateralToken.safeTransfer(_address, order.orderDetails.margin);
        } else if (order.orderType == OrderType.INCREASE_SIZE) {
            collateralToken.safeTransfer(_address, order.orderDetails.margin + order.orderDetails.tradeFee);
        }

        _address.sendValue(order.executionFee);

        emit CancelOrder(
            order.account,
            _orderNumber,
            order.productId,
            order.accountPositionId,
            order.orderType,
            order
        );
    }

    function updateOrder(
        uint256 _orderNumber,
        OrderDetails memory _newOrderDetails,
        TriggerDetails memory _triggerDetails,
        bytes calldata _userData,
        Signature memory _signature
    ) external nonReentrant {
        address _address = msg.sender;
        require(_orderNumber > 0, 'OrderBook: !orderNumber');

        require(
            _triggerDetails.triggerType == TriggerType.PRICE && _triggerDetails.triggerPnLRate == FixedPoint.ZERO.fromUnsigned()
            || _triggerDetails.triggerType == TriggerType.PNL_RATE && _triggerDetails.triggerPrice == FixedPoint.ZERO,
            'OrderBook: !triggerDetails'
        );

        Order storage order = orders[_address][_orderNumber];
        Order memory prevOrder = order;
        checkValidUnresolved(order, _address);

        if (_signature.v != 0 && _signature.r != 0 && _signature.s != 0) {
            IERC20Permit(address(collateralToken)).safePermit(
                msg.sender,
                address(this),
                _signature.amount,
                _signature.deadline,
                _signature.v,
                _signature.r,
                _signature.s
            );
        }

        if (order.orderType == OrderType.INCREASE_SIZE) {
            FPUnsigned oldSize = order.orderDetails.leverage.mul(order.orderDetails.margin);
            FPUnsigned newSize = _newOrderDetails.leverage.mul(_newOrderDetails.margin);

            int256 additionalCollateralRequired = 0;
            if (newSize != oldSize) {
                FPUnsigned feeRate = getTradeFeeRate(order.productId, order.account);
                uint256 newFee = (feeRate * newSize).roundUp();
                additionalCollateralRequired = int256(newFee) - int256(order.orderDetails.tradeFee);
                order.orderDetails.tradeFee = newFee;
            }
            additionalCollateralRequired += int256(_newOrderDetails.margin) - int256(order.orderDetails.margin);
            order.orderDetails.margin = _newOrderDetails.margin;

            order.orderDetails.leverage = _newOrderDetails.leverage;

            if (additionalCollateralRequired > 0) {
                collateralToken.safeTransferFrom(_address, address(this), uint256(additionalCollateralRequired));
            } else if (additionalCollateralRequired < 0) {
                collateralToken.safeTransfer(_address, uint256(-additionalCollateralRequired));
            }
        } else if (order.orderType == OrderType.ADD_MARGIN) {
            int256 additionalCollateralRequired = int256(_newOrderDetails.margin) - int256(order.orderDetails.margin);
            order.orderDetails.margin = _newOrderDetails.margin;
            if (additionalCollateralRequired > 0) {
                collateralToken.safeTransferFrom(_address, address(this), uint256(additionalCollateralRequired));
            } else if (additionalCollateralRequired < 0) {
                collateralToken.safeTransfer(_address, uint256(-additionalCollateralRequired));
            }
        } else if (order.orderType == OrderType.REMOVE_MARGIN) {
            order.orderDetails.removeMarginFactor = _newOrderDetails.removeMarginFactor;
        } else if (order.orderType == OrderType.DECREASE_SIZE) {

            order.orderDetails.size = _newOrderDetails.size;
        } 

        // upadte common order information
        order.triggerDetails = _triggerDetails;
        order.submittedAt = uint64(block.timestamp);
        order.userData = _userData;

        emit UpdateOrder(
            _address,
            _orderNumber,
            order.productId,
            order.accountPositionId,
            order.orderType,
            prevOrder,
            order
        );
    }

    function executeOrder(address _address, uint256 _orderNumber, address payable _feeReceiver) public nonReentrant {
        require(_address != address(0), 'OrderBook: !account');
        require(_orderNumber > 0, 'OrderBook: !orderNumber');

        Order storage order = orders[_address][_orderNumber];

        checkValidUnresolved(order, _address);
        (FPUnsigned currentPrice, FPSigned pnl) = checkExecutable(order, _address);

        order.executedAt = uint64(block.timestamp);

        if (order.orderType == OrderType.INCREASE_SIZE) {
            collateralToken.safeApprove(
                address(domFiPerp),
                order.orderDetails.margin + order.orderDetails.tradeFee
            );

            IDomFiPerp.IncreasePositionParams[] memory params = new IDomFiPerp.IncreasePositionParams[](1);
            params[0] = IDomFiPerp.IncreasePositionParams({
                user: order.account,
                userPositionId: order.accountPositionId,
                productId: order.productId,
                isLong: order.isLong,
                margin: order.orderDetails.margin,
                leverage: order.orderDetails.leverage
            });
            domFiPerp.increasePositions(params);

        } else if (order.orderType == OrderType.ADD_MARGIN) {
            collateralToken.safeApprove(
                address(domFiPerp),
                order.orderDetails.margin
            );

            IDomFiPerp.IncreasePositionParams[] memory params = new IDomFiPerp.IncreasePositionParams[](1);
            params[0] = IDomFiPerp.IncreasePositionParams({
                user: order.account,
                userPositionId: order.accountPositionId,
                productId: order.productId,
                isLong: order.isLong,
                margin: order.orderDetails.margin,
                leverage: FixedPoint.ZERO
            });
            domFiPerp.increasePositions(params);

        } else if (order.orderType == OrderType.DECREASE_SIZE) {
            IDomFiPerp.Position memory position = domFiPerp.getPosition(_address, order.accountPositionId);
            uint256 closeMargin = (order.orderDetails.size / position.leverage).roundUp();
            if (closeMargin > position.margin) {
                closeMargin = position.margin;
            }

            IDomFiPerp.DecreasePositionParams[] memory params = new IDomFiPerp.DecreasePositionParams[](1);
            params[0] = IDomFiPerp.DecreasePositionParams({
                user: _address,
                userPositionId: order.accountPositionId,
                margin: closeMargin
            });
            domFiPerp.decreasePositions(params);

        } else {
            bytes32 positionId = domFiPerp.getPositionId(_address, order.accountPositionId);
            domFiPerp.removeMargin(positionId, order.orderDetails.removeMarginFactor);
        }

        // pay executor
        _feeReceiver.sendValue(order.executionFee);

        emit ExecuteOrder(
            order.account,
            _orderNumber,
            order.productId,
            order.accountPositionId,
            currentPrice,
            pnl,
            order.orderType,
            order
        );
    }

    function getTradeFeeRate(bytes32 _productId, address _account) private view returns (FPUnsigned) {
        IDomFiPerp.Product memory product = domFiPerp.getProduct(_productId);
        return feeCalculator.getTradeFee(product.fee, _account, msg.sender);
    }

    function getOrder(address account, uint256 orderNumber) external view returns (Order memory) {
        return orders[account][orderNumber];
    }

    /**
        @notice get minimum fees for createOrder to succeed.  allowance must be >= margin + tradeFee
        @param _orderParams order to compute fees for
        @param executor EOA that will be calling executeOrder
        @return tradeFee collateral token, charged by DomFiPerp.
        @return executionFee network token, charged by OrderBook.
     */
    function getFees(OrderParams calldata _orderParams, address executor) external view returns (uint tradeFee, uint executionFee) {
        executionFee = minExecutionFee;
        IDomFiPerp.Product memory product = domFiPerp.getProduct(_orderParams.productId);

        if (_orderParams.orderType == OrderType.INCREASE_SIZE) {            
            tradeFee = PerpLib._getTradeFee({
                margin: _orderParams.orderDetails.margin,
                leverage: _orderParams.orderDetails.leverage,
                productFee: feeCalculator.getTradeFee(product.fee, msg.sender, executor),
                user: msg.sender,
                sender: executor,
                feeCalculator: feeCalculator
            });
        } else if (_orderParams.orderType == OrderType.DECREASE_SIZE) {
            IDomFiPerp.Position memory position = domFiPerp.getPosition(msg.sender, _orderParams.accountPositionId);
            uint256 closeMargin = (_orderParams.orderDetails.size / position.leverage).roundUp();
            if (closeMargin > position.margin) {
                closeMargin = position.margin;
            }
            tradeFee = PerpLib._getTradeFee({
                margin: closeMargin,
                leverage: position.leverage,
                productFee: feeCalculator.getTradeFee(product.fee, msg.sender, executor),
                user: msg.sender,
                sender: executor,
                feeCalculator: feeCalculator
            });
        }
    }

    receive() external payable {}
}