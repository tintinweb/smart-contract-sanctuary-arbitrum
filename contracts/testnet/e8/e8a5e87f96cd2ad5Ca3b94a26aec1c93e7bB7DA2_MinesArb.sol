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
 * To use this libraries you can add a `using SafeERC20 for IERC20;` statement to your contract,
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IRandomizer {
    function request(
        uint256 _callbackGasLimit,
        uint256 _confirmations
    ) external returns (uint256);

    function clientWithdrawTo(address _to, uint256 _amount) external;

    function estimateFee(
        uint256 _callbackGasLimit,
        uint256 _confirmations
    ) external view returns (uint256);

    function clientDeposit(address _client) external payable;

    function getFeeStats(
        uint256 _request
    ) external view returns (uint256[2] memory);
}

interface IBankRoll {
    function getIsGame(address game) external view returns (bool);

    function getIsValidWager(
        address game,
        address tokenAddress
    ) external view returns (bool);

    function transferPayout(
        address player,
        uint256 payout,
        address token
    ) external;

    function getOwner() external view returns (address);

    function isPlayerSuspended(
        address player
    ) external view returns (bool, uint256);
}

contract CommonArb is ReentrancyGuard {
    IBankRoll public Bankroll;
    address public randomizer;
    uint256 VRFgasLimit;

    using SafeERC20 for IERC20;

    error NotApprovedBankroll();
    error InvalidValue(uint256 sent, uint256 required);
    error TransferFailed();
    error RefundFailed();
    error NotOwner(address want, address have);
    error ZeroWager();
    error PlayerSuspended(uint256 suspensionTime);

    function _transferWager(
        address tokenAddress,
        uint256 wager
    ) internal returns (uint256 VRFfee) {
        if (!Bankroll.getIsValidWager(address(this), tokenAddress)) {
            revert NotApprovedBankroll();
        }
        if (wager == 0) {
            revert ZeroWager();
        }
        (bool suspended, uint256 suspendedTime) = Bankroll.isPlayerSuspended(
            msg.sender
        );
        if (suspended) {
            revert PlayerSuspended(suspendedTime);
        }
        VRFfee = getVRFFee();
        if (tokenAddress == address(0)) {
            if (msg.value < wager + VRFfee) {
                revert InvalidValue(msg.value, wager + VRFfee);
            }
            IRandomizer(randomizer).clientDeposit{value: VRFfee}(address(this));

            _refundExcessValue(msg.value - (VRFfee + wager));
        } else {
            if (msg.value < VRFfee) {
                revert InvalidValue(VRFfee, msg.value);
            }
            IRandomizer(randomizer).clientDeposit{value: VRFfee}(address(this));
            IERC20(tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                wager
            );
            _refundExcessValue(msg.value - VRFfee);
        }
    }

    /**
     * @dev function to transfer the wager held by the game contract to the bankroll
     * @param tokenAddress address of the token to transfer
     * @param amount token amount to transfer
     */
    function _transferToBankroll(
        address tokenAddress,
        uint256 amount
    ) internal {
        if (tokenAddress == address(0)) {
            (bool success, ) = payable(address(Bankroll)).call{value: amount}(
                ""
            );
            if (!success) {
                revert RefundFailed();
            }
        } else {
            IERC20(tokenAddress).safeTransfer(address(Bankroll), amount);
        }
    }

    /**
     * @dev calculates in form of native token the fee charged by  VRF
     * @return fee amount of fee user has to pay
     */
    function getVRFFee() public view returns (uint256 fee) {
        fee = (IRandomizer(randomizer).estimateFee(2500000, 4) * 125) / 100;
    }

    /**
     * @dev returns to user the excess fee sent to pay for the VRF
     * @param refund amount to send back to user
     */
    function _refundExcessValue(uint256 refund) internal {
        if (refund == 0) {
            return;
        }
        (bool success, ) = payable(msg.sender).call{value: refund}("");
        if (!success) {
            revert RefundFailed();
        }
    }

    /**
     * @dev function to charge user for VRF
     */
    function _payVRFFee() internal returns (uint256 VRFfee) {
        VRFfee = getVRFFee();
        if (msg.value < VRFfee) {
            revert InvalidValue(VRFfee, msg.value);
        }
        IRandomizer(randomizer).clientDeposit{value: VRFfee}(address(this));
        _refundExcessValue(msg.value - VRFfee);
    }

    function _transferWagerNoVRF(
        address tokenAddress,
        uint256 wager,
        uint32 numBets
    ) internal {
        require(Bankroll.getIsGame(address(this)), "not valid");
        require(numBets > 0 && numBets < 500, "invalid bet number");
        if (tokenAddress == address(0)) {
            require(msg.value == wager * numBets, "incorrect value");

            (bool success, ) = payable(address(Bankroll)).call{
                value: msg.value
            }("");
            require(success, "eth transfer failed");
        } else {
            IERC20(tokenAddress).safeTransferFrom(
                msg.sender,
                address(Bankroll),
                wager * numBets
            );
        }
    }

    /**
     * @dev function to transfer wager to game contract, without charging for VRF
     * @param tokenAddress tokenAddress the wager is made on
     * @param wager wager amount
     */
    function _transferWagerPvPNoVRF(
        address tokenAddress,
        uint256 wager
    ) internal {
        if (!Bankroll.getIsValidWager(address(this), tokenAddress)) {
            revert NotApprovedBankroll();
        }
        if (tokenAddress == address(0)) {
            if (!(msg.value == wager)) {
                revert InvalidValue(wager, msg.value);
            }
        } else {
            IERC20(tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                wager
            );
        }
    }

    /**
     * @dev function to transfer wager to game contract, including charge for VRF
     * @param tokenAddress tokenAddress the wager is made on
     * @param wager wager amount
     */
    function _transferWagerPvP(address tokenAddress, uint256 wager) internal {
        if (!Bankroll.getIsValidWager(address(this), tokenAddress)) {
            revert NotApprovedBankroll();
        }

        uint256 VRFfee = getVRFFee();
        if (tokenAddress == address(0)) {
            if (msg.value < wager + VRFfee) {
                revert InvalidValue(msg.value, wager);
            }

            _refundExcessValue(msg.value - (VRFfee + wager));
        } else {
            if (msg.value < VRFfee) {
                revert InvalidValue(VRFfee, msg.value);
            }

            IERC20(tokenAddress).transferFrom(msg.sender, address(this), wager);
            _refundExcessValue(msg.value - VRFfee);
        }
    }

    /**
     * @dev transfers payout from the game contract to the players
     * @param player address of the player to transfer the payout to
     * @param payout amount of payout to transfer
     * @param tokenAddress address of the token that payout will be transfered
     */
    function _transferPayoutPvP(
        address player,
        uint256 payout,
        address tokenAddress
    ) internal {
        if (tokenAddress == address(0)) {
            (bool success, ) = payable(player).call{value: payout}("");
            if (!success) {
                revert TransferFailed();
            }
        } else {
            IERC20(tokenAddress).safeTransfer(player, payout);
        }
    }

    /**
     * @dev transfers house edge from game contract to bankroll
     * @param amount amount to transfer
     * @param tokenAddress address of token to transfer
     */
    function _transferHouseEdgePvP(
        uint256 amount,
        address tokenAddress
    ) internal {
        if (tokenAddress == address(0)) {
            (bool success, ) = payable(address(Bankroll)).call{value: amount}(
                ""
            );
            if (!success) {
                revert TransferFailed();
            }
        } else {
            IERC20(tokenAddress).safeTransfer(address(Bankroll), amount);
        }
    }

    /**@dev function to alter gaslimit of vrf request
     * @param limit new gas Limit on request
     */
    function setVRFGasLimit(uint256 limit) external {
        if (msg.sender != Bankroll.getOwner()) {
            revert NotOwner(Bankroll.getOwner(), msg.sender);
        }
        VRFgasLimit = limit;
    }

    /**
     * @dev function to request bankroll to give payout to player
     * @param player address of the player
     * @param payout amount of payout to give
     * @param tokenAddress address of the token in which to give the payout
     */
    function _transferPayout(
        address player,
        uint256 payout,
        address tokenAddress
    ) internal {
        Bankroll.transferPayout(player, payout, tokenAddress);
    }

    function _requestRandomWords(
        uint32 numWords
    ) internal returns (uint256 s_requestId) {
        s_requestId = IRandomizer(randomizer).request(VRFgasLimit, 4);
        return s_requestId;
    }

    function whithdrawVRF(address to, uint256 amount) external {
        if (msg.sender != Bankroll.getOwner()) {
            revert NotOwner(Bankroll.getOwner(), msg.sender);
        }
        IRandomizer(randomizer).clientWithdrawTo(to, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./CommonArb.sol";

/**
 * @title Mines game, player have 25 tiles where mines are hidden, players flip tiles until they cashout or reveal a mine in which case they lose
 */
contract MinesArb is CommonArb {
    using SafeERC20 for IERC20;

    constructor(address _bankroll, address _vrf, uint8[24] memory maxReveal) {
        Bankroll = IBankRoll(_bankroll);
        randomizer = _vrf;
        VRFgasLimit = 2000000;
        _setMaxReveal(maxReveal);
    }

    struct MinesGame {
        address tokenAddress;
        uint256 wager;
        uint256 requestID;
        uint64 blockNumber;
        uint64 currentMultiplier;
        uint8 numMines;
        bool[25] revealedTiles;
        bool[25] tilesPicked;
        bool isCashout;
    }

    struct VRFData {
        uint256 id;
        uint256 feePayed;
    }

    mapping(address => VRFData) vrfdata;
    mapping(address => MinesGame) minesGames;
    mapping(uint256 => address) minesIDs;
    mapping(uint256 => mapping(uint256 => uint256)) minesMultipliers;
    mapping(uint256 => uint256) minesMaxReveal;

    /**
     * @dev event emitted by the VRF callback with the tile reveal results
     * @param playerAddress address of the player that made the bet
     * @param wager wager amount
     * @param payout payout if player were to end the game
     * @param tokenAddress address of token the wager was made and payout, 0 address is considered the native coin
     * @param minesTiles tiles in which mines were revealed, if any is true the game is over and the player lost
     * @param revealedTiles all tiles that have been revealed, true correspond to a revealed tile
     * @param multiplier current game multiplier if the game player chooses to end the game
     */
    event Mines_Reveal_Event(
        address indexed playerAddress,
        uint256 wager,
        uint256 payout,
        address tokenAddress,
        bool[25] minesTiles,
        bool[25] revealedTiles,
        uint256 multiplier
    );

    /**
     * @dev event emitted by the VRF callback with the tile reveal results and cashout
     * @param playerAddress address of the player that made the bet
     * @param wager wager amount
     * @param payout total payout transfered to the player
     * @param tokenAddress address of token the wager was made and payout, 0 address is considered the native coin
     * @param minesTiles tiles in which mines were revealed, if any is true the game is over and the player lost
     * @param revealedTiles all tiles that have been revealed, true correspond to a revealed tile
     * @param multiplier current game multiplier
     */
    event Mines_RevealCashout_Event(
        address indexed playerAddress,
        uint256 wager,
        uint256 payout,
        address tokenAddress,
        bool[25] minesTiles,
        bool[25] revealedTiles,
        uint256 multiplier
    );

    /**
     * @dev event emitted by the VRF callback with the bet results
     * @param playerAddress address of the player that made the bet
     * @param wager wager amount
     * @param payout total payout transfered to the player
     * @param tokenAddress address of token the wager was made and payout, 0 address is considered the native coin
     * @param multiplier final game multiplier
     */
    event Mines_End_Event(
        address indexed playerAddress,
        uint256 wager,
        uint256 payout,
        address tokenAddress,
        uint256 multiplier
    );

    /**
     * @dev event emitted when a refund is done in mines
     * @param player address of the player reciving the refund
     * @param wager amount of wager that was refunded
     * @param tokenAddress address of token the refund was made in
     */
    event Mines_Refund_Event(
        address indexed player,
        uint256 wager,
        address tokenAddress
    );

    error InvalidNumMines();
    error AlreadyInGame();
    error NotInGame();
    error AwaitingVRF(uint256 requestID);
    error InvalidNumberToReveal(uint32 numberPicked, uint256 maxAllowed);
    error WagerAboveLimit(uint256 wager, uint256 maxWager);
    error NoRequestPending();
    error BlockNumberTooLow(uint256 have, uint256 want);

    /**
     * @dev function to set game multipliers only callable by the owner
     * @param numMines number of mines to set multipliers for
     */

    function Mines_SetMultipliers(uint256 numMines) external {
        if (msg.sender != Bankroll.getOwner()) {
            revert NotOwner(Bankroll.getOwner(), msg.sender);
        }

        for (uint256 g = 1; g <= 25 - numMines; g++) {
            uint256 multiplier = 1;
            uint256 divisor = 1;
            for (uint256 f = 0; f < g; f++) {
                multiplier *= (25 - numMines - f);
                divisor *= (25 - f);
            }
            minesMultipliers[numMines][g] =
                (9900 * (10 ** 9)) /
                ((multiplier * (10 ** 9)) / divisor);
        }
    }

    /**
     * @dev function to view the current mines multipliers
     * @param numMines number of mines in the game
     * @param numRevealed tiles revealed
     * @return multiplier multiplier of selected numMines and numRevealed
     */
    function Mines_GetMultipliers(
        uint256 numMines,
        uint256 numRevealed
    ) public view returns (uint256 multiplier) {
        multiplier = minesMultipliers[numMines][numRevealed];
        return multiplier;
    }

    /**
     * @dev get current game state of player
     * @param player address of the player that made the bet
     * @return minesState current state of player game
     */
    function Mines_GetState(
        address player
    ) external view returns (MinesGame memory minesState) {
        minesState = minesGames[player];
        return minesState;
    }

    /**
     * @dev function to start mines game, player cannot currently be in a game
     * @param wager wager amount
     * @param tokenAddress address of token the wager was made and payout, 0 address is considered the native coin
     * @param tiles arrays of tiles to initialy reveal, true equals that tile will be revealed
     * @param isCashout if true, game will give payout if player doesn't reveal mines
     * @param numMines number of mines present in game, range from 1-24
     */

    function Mines_Start(
        uint256 wager,
        address tokenAddress,
        uint8 numMines,
        bool[25] calldata tiles,
        bool isCashout
    ) external payable nonReentrant {
        if (!(numMines >= 1 && numMines <= 24)) {
            revert InvalidNumMines();
        }

        MinesGame storage game = minesGames[msg.sender];
        if (game.requestID != 0) {
            revert AwaitingVRF(game.requestID);
        }
        if (game.numMines != 0) {
            revert AlreadyInGame();
        }

        uint32 numTilesToReveal;
        for (uint8 i = 0; i < tiles.length; i++) {
            if (tiles[i]) {
                numTilesToReveal++;
            }
        }

        uint256 _minesMaxReveal = minesMaxReveal[numMines];
        if (numTilesToReveal == 0 || numTilesToReveal > _minesMaxReveal) {
            revert InvalidNumberToReveal(numTilesToReveal, _minesMaxReveal);
        }

        VRFData storage data = vrfdata[msg.sender];
        uint256[2] memory fees = IRandomizer(randomizer).getFeeStats(data.id);
        if (fees[0] > fees[1] && data.feePayed > fees[0] - fees[1]) {
            IRandomizer(randomizer).clientWithdrawTo(
                msg.sender,
                ((data.feePayed - (fees[0] - fees[1])) * 90) / 100
            );
        }

        _kellyWager(wager, tokenAddress, _minesMaxReveal, numMines);
        uint256 feePayed = _transferWager(tokenAddress, wager);
        uint256 id = _requestRandomWords(numTilesToReveal);
        minesIDs[id] = msg.sender;
        game.numMines = numMines;
        game.wager = wager;
        game.tokenAddress = tokenAddress;
        game.isCashout = isCashout;
        game.tilesPicked = tiles;
        game.requestID = id;
        game.blockNumber = uint64(block.number);
        vrfdata[msg.sender] = VRFData(id, feePayed);
    }

    /**
     * @dev function to end player current game and receive payout
     */
    function Mines_End() external nonReentrant {
        MinesGame storage game = minesGames[msg.sender];
        if (game.numMines == 0) {
            revert NotInGame();
        }
        if (game.requestID != 0) {
            revert AwaitingVRF(game.requestID);
        }

        VRFData storage data = vrfdata[msg.sender];
        uint256[2] memory fees = IRandomizer(randomizer).getFeeStats(data.id);
        if (fees[0] > fees[1] && data.feePayed > fees[0] - fees[1]) {
            IRandomizer(randomizer).clientWithdrawTo(
                msg.sender,
                ((data.feePayed - (fees[0] - fees[1])) * 90) / 100
            );
        }
        delete (vrfdata[msg.sender]);
        uint256 multiplier = minesGames[msg.sender].currentMultiplier;
        uint256 wager = minesGames[msg.sender].wager;
        uint256 payout = (multiplier * wager) / 10000;
        address tokenAddress = minesGames[msg.sender].tokenAddress;
        _transferToBankroll(tokenAddress, wager);
        delete (minesGames[msg.sender]);
        _transferPayout(msg.sender, payout, tokenAddress);
        emit Mines_End_Event(
            msg.sender,
            wager,
            payout,
            tokenAddress,
            multiplier
        );
    }

    error TileAlreadyRevealed(uint8 position);

    /**
     * @dev function to reveal tiles in an ongoing game
     * @param tiles array of tiles that the player wishes to reveal, can't choose already revealed tiles, true equals that tile will be revealed
     * @param isCashout if true and player doesn't reveal mines, will cashout
     */

    function Mines_Reveal(
        bool[25] calldata tiles,
        bool isCashout
    ) external payable nonReentrant {
        MinesGame storage game = minesGames[msg.sender];

        if (game.numMines == 0) {
            revert NotInGame();
        }
        if (game.requestID != 0) {
            revert AwaitingVRF(game.requestID);
        }

        uint32 numTilesRevealed;
        uint32 numTilesToReveal;
        for (uint8 i = 0; i < tiles.length; i++) {
            if (tiles[i]) {
                if (game.revealedTiles[i]) {
                    revert TileAlreadyRevealed(i);
                }
                numTilesToReveal++;
            }
            if (game.revealedTiles[i]) {
                numTilesRevealed++;
            }
        }

        if (
            numTilesToReveal == 0 ||
            numTilesToReveal + numTilesRevealed > minesMaxReveal[game.numMines]
        ) {
            revert InvalidNumberToReveal(
                numTilesToReveal + numTilesRevealed,
                minesMaxReveal[game.numMines]
            );
        }

        VRFData storage data = vrfdata[msg.sender];
        uint256[2] memory fees = IRandomizer(randomizer).getFeeStats(data.id);
        if (fees[0] > fees[1] && data.feePayed > fees[0] - fees[1]) {
            IRandomizer(randomizer).clientWithdrawTo(
                msg.sender,
                ((data.feePayed - (fees[0] - fees[1])) * 90) / 100
            );
        }

        uint256 VRFfee = _payVRFFee();

        uint256 id = _requestRandomWords(numTilesToReveal);
        minesIDs[id] = msg.sender;
        game.tilesPicked = tiles;
        game.isCashout = isCashout;
        game.requestID = id;
        game.blockNumber = uint64(block.number);
        vrfdata[msg.sender] = VRFData(id, VRFfee);
    }

    /**
     * @dev Function to get refund for game if VRF request fails
     */

    function Mines_Refund() external nonReentrant {
        if (minesGames[msg.sender].numMines == 0) {
            revert NotInGame();
        }
        if (minesGames[msg.sender].requestID == 0) {
            revert NoRequestPending();
        }
        if (minesGames[msg.sender].blockNumber + 20 > block.number) {
            revert BlockNumberTooLow(
                block.number,
                minesGames[msg.sender].blockNumber + 20
            );
        }

        uint256 wager = minesGames[msg.sender].wager;
        address tokenAddress = minesGames[msg.sender].tokenAddress;
        delete (minesGames[msg.sender]);
        if (tokenAddress == address(0)) {
            (bool success, ) = payable(msg.sender).call{value: wager}("");
            if (!success) {
                revert TransferFailed();
            }
        } else {
            IERC20(tokenAddress).safeTransfer(msg.sender, wager);
        }
        emit Mines_Refund_Event(msg.sender, wager, tokenAddress);
    }

    /**
     * @dev function called by Randomizer.ai with the random number
     * @param _id id provided when the request was made
     * @param _value random number
     */
    function randomizerCallback(uint256 _id, bytes32 _value) external {
        //Callback can only be called by randomizer
        require(msg.sender == randomizer, "Caller not Randomizer");

        address player = minesIDs[_id];
        delete (minesIDs[_id]);
        MinesGame storage game = minesGames[player];

        uint32 i;
        uint256 numberOfRevealedTiles;
        for (i = 0; i < game.revealedTiles.length; i++) {
            if (game.revealedTiles[i] == true) {
                numberOfRevealedTiles += 1;
            }
        }

        uint256 numberOfMinesLeft = game.numMines;
        bool[25] memory mines;
        bool won = true;

        for (i = 0; i < game.tilesPicked.length; i++) {
            if (
                numberOfMinesLeft == 0 ||
                25 - numberOfRevealedTiles == numberOfMinesLeft
            ) {
                if (game.tilesPicked[i]) {
                    game.revealedTiles[i] = true;
                }
                continue;
            }
            if (game.tilesPicked[i]) {
                bool gem = _pickTile(
                    player,
                    i,
                    25 - numberOfRevealedTiles,
                    numberOfMinesLeft,
                    uint256(keccak256(abi.encodePacked(_value, i)))
                );
                if (gem == false) {
                    numberOfMinesLeft -= 1;
                    mines[i] = true;
                    won = false;
                }
                numberOfRevealedTiles += 1;
            }
        }

        if (!won) {
            if (game.isCashout == false) {
                emit Mines_Reveal_Event(
                    player,
                    game.wager,
                    0,
                    game.tokenAddress,
                    mines,
                    game.revealedTiles,
                    0
                );
            } else {
                emit Mines_RevealCashout_Event(
                    player,
                    game.wager,
                    0,
                    game.tokenAddress,
                    mines,
                    game.revealedTiles,
                    0
                );
            }
            _transferToBankroll(game.tokenAddress, game.wager);
            delete (minesGames[player]);

            return;
        }

        uint256 multiplier = minesMultipliers[numberOfMinesLeft][
            numberOfRevealedTiles
        ];

        if (game.isCashout == false) {
            game.currentMultiplier = uint64(multiplier);
            game.requestID = 0;
            emit Mines_Reveal_Event(
                player,
                game.wager,
                (multiplier * game.wager) / 10000,
                game.tokenAddress,
                mines,
                game.revealedTiles,
                multiplier
            );
        } else {
            uint256 wager = game.wager;
            address tokenAddress = game.tokenAddress;
            emit Mines_RevealCashout_Event(
                player,
                wager,
                (multiplier * wager) / 10000,
                tokenAddress,
                mines,
                game.revealedTiles,
                multiplier
            );
            _transferToBankroll(tokenAddress, game.wager);
            delete (minesGames[player]);
            _transferPayout(player, (multiplier * wager) / 10000, tokenAddress);
        }
    }

    function _pickTile(
        address player,
        uint256 tileNumber,
        uint256 numberTilesLeft,
        uint256 numberOfMinesLeft,
        uint256 rng
    ) internal returns (bool) {
        uint256 winChance = 10000 -
            (numberOfMinesLeft * 10000) /
            numberTilesLeft;

        bool won = false;
        if (rng % 10000 <= winChance) {
            won = true;
        }
        minesGames[player].revealedTiles[tileNumber] = true;
        return won;
    }

    /**
     * @dev function to set game max number of reveals only callable at deploy time
     * @param maxReveal max reveal for each num Mines
     */
    function _setMaxReveal(uint8[24] memory maxReveal) internal {
        for (uint256 i = 0; i < maxReveal.length; i++) {
            minesMaxReveal[i + 1] = maxReveal[i];
        }
    }

    function _kellyWager(
        uint256 wager,
        address tokenAddress,
        uint256 maxReveal,
        uint256 numMines
    ) internal view {
        uint256 balance;
        if (tokenAddress == address(0)) {
            balance = address(Bankroll).balance;
        } else {
            balance = IERC20(tokenAddress).balanceOf(address(Bankroll));
        }
        uint256 maxWager = (balance * (11000 - 10890)) /
            (minesMultipliers[numMines][maxReveal] - 10000);
        if (wager > maxWager) {
            revert WagerAboveLimit(wager, maxWager);
        }
    }
}