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