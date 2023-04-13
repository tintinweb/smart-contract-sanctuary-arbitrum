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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IRandomizer {
  function request(uint256 _callbackGasLimit, uint256 _confirmations) external returns (uint256);

  function clientWithdrawTo(address _to, uint256 _amount) external;

  function estimateFee(uint256 _callbackGasLimit) external view returns (uint256);

  function estimateFee(uint256 _callbackGasLimit, uint256 _confirmations) external view returns (uint256);

  function clientDeposit(address _client) external payable;

  function getFeeStats(uint256 _request) external view returns (uint256[2] memory);
}

interface IBankRoll {
  function getIsGame(address game) external view returns (bool);

  function getIsValidWager(address game, address tokenAddress) external view returns (bool);

  function getBetPrice(address tokenAddress) external view returns (uint256);

  function transferPayout(address player, uint256 payout, address token) external;

  function owner() external view returns (address);

  function isPlayerSuspended(address player) external view returns (bool, uint256);
}

contract Common is ReentrancyGuard {
  using SafeERC20 for IERC20;

  IBankRoll public Bankroll;
  address public randomizer;
  uint256 VRFgasLimit;

  // Fees receivers
  address payable public marketingWallet;
  address payable public devWallet;
  address payable public yieldWallet;

  uint256 public marketingPercent = 10;
  uint256 public devPercent = 10;
  uint256 public yieldPercent = 0;
  uint256 public lastBuyPercent = 10;
  uint256 public weeklyPercent = 40;
  uint256 public jackpotPercent = 50;

  error NotApprovedBankroll();
  error InvalidValue(uint256 sent, uint256 required);
  error TransferFailed();
  error RefundFailed();
  error NotOwner(address want, address have);
  error ZeroWager();
  error PlayerSuspended(uint256 suspensionTime);

  function _transferWager(address tokenAddress, uint256 wager) internal returns (uint256 VRFfee) {
    if (!Bankroll.getIsValidWager(address(this), tokenAddress)) {
      revert NotApprovedBankroll();
    }
    if (wager == 0) {
      revert ZeroWager();
    }
    (bool suspended, uint256 suspendedTime) = Bankroll.isPlayerSuspended(msg.sender);
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
      IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), wager);
      _refundExcessValue(msg.value - VRFfee);
    }
  }

  /**
   * @dev function to transfer the wager held by the game contract to the bankroll
   * @param tokenAddress address of the token to transfer
   * @param amount token amount to transfer
   */
  function _transferToBankroll(address tokenAddress, uint256 amount) internal {
    uint256 amountToMarketing = (amount * marketingPercent) / 100;
    uint256 amountToDev = (amount * devPercent) / 100;
    uint256 amountToYield = (amount * yieldPercent) / 100;
    uint256 amountToBankroll = amount - amountToMarketing - amountToDev - amountToYield;
    if (tokenAddress == address(0)) {
      if (amountToMarketing != 0) {
        (bool success, ) = payable(address(marketingWallet)).call{value: amountToMarketing}("");
        if (!success) {
          revert RefundFailed();
        }
      }
      if (amountToDev != 0) {
        (bool success, ) = payable(address(devWallet)).call{value: amountToDev}("");
        if (!success) {
          revert RefundFailed();
        }
      }
      if (amountToYield != 0) {
        (bool success, ) = payable(address(yieldWallet)).call{value: amountToYield}("");
        if (!success) {
          revert RefundFailed();
        }
      }
      if (amountToBankroll != 0) {
        (bool success, ) = payable(address(Bankroll)).call{value: amountToBankroll}("");
        if (!success) {
          revert RefundFailed();
        }
      }
    } else {
      if (amountToMarketing != 0) {
        IERC20(tokenAddress).safeTransfer(address(marketingWallet), amountToMarketing);
      }
      if (amountToDev != 0) {
        IERC20(tokenAddress).safeTransfer(address(devWallet), amountToDev);
      }
      if (amountToYield != 0) {
        IERC20(tokenAddress).safeTransfer(address(yieldWallet), amountToYield);
      }
      if (amountToBankroll != 0) {
        IERC20(tokenAddress).safeTransfer(address(Bankroll), amountToBankroll);
      }
    }
  }

  /**
   * @dev calculates in form of native token the fee charged by  VRF
   * @return fee amount of fee user has to pay
   */
  function getVRFFee() public view returns (uint256 fee) {
    fee = (IRandomizer(randomizer).estimateFee(VRFgasLimit, 2) * 125) / 100;
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

  function _transferWagerNoVRF(address tokenAddress, uint256 wager, uint32 numBets) internal {
    require(Bankroll.getIsGame(address(this)), "not valid");
    require(numBets > 0 && numBets < 500, "invalid bet number");
    if (tokenAddress == address(0)) {
      require(msg.value == wager * numBets, "incorrect value");

      (bool success, ) = payable(address(Bankroll)).call{value: msg.value}("");
      require(success, "eth transfer failed");
    } else {
      IERC20(tokenAddress).safeTransferFrom(msg.sender, address(Bankroll), wager * numBets);
    }
  }

  /**
   * @dev function to transfer wager to game contract, without charging for VRF
   * @param tokenAddress tokenAddress the wager is made on
   * @param wager wager amount
   */
  function _transferWagerPvPNoVRF(address tokenAddress, uint256 wager) internal {
    if (!Bankroll.getIsValidWager(address(this), tokenAddress)) {
      revert NotApprovedBankroll();
    }
    if (wager == 0) {
      revert ZeroWager();
    }
    (bool suspended, uint256 suspendedTime) = Bankroll.isPlayerSuspended(msg.sender);
    if (suspended) {
      revert PlayerSuspended(suspendedTime);
    }
    if (tokenAddress == address(0)) {
      if (!(msg.value == wager)) {
        revert InvalidValue(wager, msg.value);
      }
    } else {
      IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), wager);
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
  function _transferPayoutPvP(address player, uint256 payout, address tokenAddress) internal {
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
  function _transferHouseEdgePvP(uint256 amount, address tokenAddress) internal {
    if (tokenAddress == address(0)) {
      (bool success, ) = payable(address(Bankroll)).call{value: amount}("");
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
    if (msg.sender != Bankroll.owner()) {
      revert NotOwner(Bankroll.owner(), msg.sender);
    }
    VRFgasLimit = limit;
  }

  function setFeeReceivers(
    address _marketingWallet,
    address _devWallet,
    address _yieldWallet,
    address _jackpotWallet
  ) external {
    if (msg.sender != Bankroll.owner()) {
      revert NotOwner(Bankroll.owner(), msg.sender);
    }
    marketingWallet = payable(_marketingWallet);
    devWallet = payable(_devWallet);
    yieldWallet = payable(_yieldWallet);
    Bankroll = IBankRoll(_jackpotWallet);
  }

  function setFees(
    uint256 _marketingPercent,
    uint256 _devPercent,
    uint256 _yieldPercent,
    uint256 _lastbuyPercent,
    uint256 _weeklyPercent,
    uint256 _jackpotPercent
  ) external {
    if (msg.sender != Bankroll.owner()) {
      revert NotOwner(Bankroll.owner(), msg.sender);
    }
    marketingPercent = _marketingPercent;
    devPercent = _devPercent;
    yieldPercent = _yieldPercent;
    lastBuyPercent = _lastbuyPercent;
    weeklyPercent = _weeklyPercent;
    jackpotPercent = _jackpotPercent;
  }

  /**
   * @dev function to get the current Jackpot Prize
   */
  function getCurrentJackpot() public view returns (uint256) {
    return (address(Bankroll).balance * jackpotPercent) / 200;
  }

  /**
   * @dev function to get the next Jackpot Prize
   */
  function getNextJackpot() public view returns (uint256) {
    return getCurrentJackpot() / 2;
  }

  /**
   * @dev function to get the lastbuy Prize
   */
  function getLastbuyPrize() public view returns (uint256) {
    return (address(Bankroll).balance * lastBuyPercent) / 100;
  }

  /**
   * @dev function to get the weekly Prize
   */
  function getWeeklyPrize() public view returns (uint256) {
    return (address(Bankroll).balance * weeklyPercent) / 100;
  }

  /**
   * @dev function to request bankroll to give payout to player
   * @param player address of the player
   * @param payout amount of payout to give
   * @param tokenAddress address of the token in which to give the payout
   */
  function _transferPayout(address player, uint256 payout, address tokenAddress) internal {
    Bankroll.transferPayout(player, payout, tokenAddress);
  }

  function _requestRandomWords() internal returns (uint256 s_requestId) {
    s_requestId = IRandomizer(randomizer).request(VRFgasLimit, 1);
    return s_requestId;
  }

  function whithdrawVRF(address to, uint256 amount) external {
    if (msg.sender != Bankroll.owner()) {
      revert NotOwner(Bankroll.owner(), msg.sender);
    }
    IRandomizer(randomizer).clientWithdrawTo(to, amount);
  }

  function depositVRF() external payable {
    if (msg.sender != Bankroll.owner()) {
      revert NotOwner(Bankroll.owner(), msg.sender);
    }
    IRandomizer(randomizer).clientDeposit{value: msg.value}(address(this));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Common.sol";

/**
 * @title Coin Flip game, players predict if outcome will be heads or tails
 */
contract Jackpot is Common {
  using SafeERC20 for IERC20;

  struct JackpotGame {
    uint256 wager;
    uint256 requestID;
    address tokenAddress;
    uint64 blockNumber;
    uint256 numBets;
    uint8[] playedNumbers;
  }

  enum LotteryState {
    OPEN,
    CALCULATING,
    CLOSED
  }

  mapping(address => JackpotGame) jackpotGames;
  mapping(uint256 => address) vrfJackpotIDs;
  mapping(uint256 => address) vrfLastBuyIDs;
  mapping(uint256 => address) vrfWeeklyIDs;

  uint256 public maxLoteryNumbers = 100;
  uint256 public maxPlayedNumbers = 5;

  uint256 public lastbuyLotteryRound = 0;
  mapping(uint256 => address[]) public ticketsLastbuyLotteryAtRound;
  LotteryState public lastbuyLotteryState;
  uint256 public lastbuyLimit = 100;

  uint256 public weeklyLotteryRound = 0;
  mapping(uint256 => address[]) public ticketsWeeklyLotteryAtRound;
  LotteryState public weeklyLotteryState;
  mapping(address => bool) private authorizedWeekly;

  /**
   * @dev event emitted by the VRF callback with the bet results
   * @param playerAddress address of the player that made the bet
   * @param wager wager amount
   * @param payout total payout transfered to the player
   * @param tokenAddress address of token the wager was made and payout, 0 address is considered the native coin
   */
  event Jackpot_Outcome_Event(
    address indexed playerAddress,
    uint256 wager,
    uint8[] playedNumbers,
    uint8 winnerRandomNumber,
    uint256 payout,
    address tokenAddress
  );

  event Lastbuy_Outcome_Event(
    address indexed playerAddress,
    address[] tickets,
    uint8 winnerRandomNumber,
    uint256 payout
  );

  event Weekly_Outcome_Event(
    address indexed playerAddress,
    address[] tickets,
    uint8 winnerRandomNumber,
    uint256 payout
  );

  /**
   * @dev event emitted when a refund is done in coin flip
   * @param player address of the player reciving the refund
   * @param wager amount of wager that was refunded
   * @param tokenAddress address of token the refund was made in
   */
  event Jackpot_Refund_Event(address indexed player, uint256 wager, address tokenAddress);

  error AwaitingVRF(uint256 requestID);
  error InvalidNumBets(uint256 maxNumBets);
  error WagerAboveLimit(uint256 wager, uint256 maxWager);
  error NotAwaitingVRF();
  error BlockNumberTooLow(uint256 have, uint256 want);
  error OnlyRandomizerCanFulfill(address have, address want);
  error NotAuthorized();

  constructor(address _marketingWallet, address _devWallet, address _yieldWallet, address _bankroll, address _vrf) {
    marketingWallet = payable(_marketingWallet);
    devWallet = payable(_devWallet);
    yieldWallet = payable(_yieldWallet);
    Bankroll = IBankRoll(_bankroll);
    randomizer = _vrf;
    VRFgasLimit = 2000000;
    lastbuyLotteryState = LotteryState.OPEN;
    weeklyLotteryState = LotteryState.OPEN;
    authorizedWeekly[msg.sender] = true;
  }

  /**
   * @dev function to get current request player is await from VRF, returns 0 if none
   * @param player address of the player to get the state
   */
  function jackpotGetState(address player) external view returns (JackpotGame memory) {
    return (jackpotGames[player]);
  }

  /**
   * @dev Function to play Coin Flip, takes the user wager saves bet parameters and makes a request to the VRF
   * @param _tokenAddress address of token to bet, 0 address is considered the native coin
   * @param _playedNumbers played numbers
   */

  function jackpotPlay(address _tokenAddress, uint8[] memory _playedNumbers) external payable nonReentrant {
    if (jackpotGames[msg.sender].requestID != 0) {
      revert AwaitingVRF(jackpotGames[msg.sender].requestID);
    }
    if (!(_playedNumbers.length > 0 && _playedNumbers.length <= maxPlayedNumbers)) {
      revert InvalidNumBets(maxPlayedNumbers);
    }

    uint256 betPrice = Bankroll.getBetPrice(_tokenAddress);
    uint256 wager = betPrice * _playedNumbers.length;
    _transferWagerPvPNoVRF(_tokenAddress, wager);
    uint256 id = _requestRandomWords();
    jackpotGames[msg.sender] = JackpotGame(
      wager,
      id,
      _tokenAddress,
      uint64(block.number),
      _playedNumbers.length,
      _playedNumbers
    );
    vrfJackpotIDs[id] = msg.sender;
  }

  /**
   * @dev Function to refund player in case of VRF request failling
   */
  function jackpotRefund() external nonReentrant {
    JackpotGame storage game = jackpotGames[msg.sender];
    if (game.requestID == 0) {
      revert NotAwaitingVRF();
    }
    if (game.blockNumber + 20 > block.number) {
      revert BlockNumberTooLow(block.number, game.blockNumber + 20);
    }

    uint256 wager = game.wager;
    address tokenAddress = game.tokenAddress;

    delete (vrfJackpotIDs[game.requestID]);
    delete (jackpotGames[msg.sender]);

    if (tokenAddress == address(0)) {
      (bool success, ) = payable(msg.sender).call{value: wager}("");
      if (!success) {
        revert TransferFailed();
      }
    } else {
      IERC20(tokenAddress).safeTransfer(msg.sender, wager);
    }
    emit Jackpot_Refund_Event(msg.sender, wager, tokenAddress);
  }

  /**
   * @dev function called by Randomizer.ai with the random number
   * @param _id id provided when the request was made
   * @param _value random number
   */
  function randomizerCallback(uint256 _id, bytes32 _value) external {
    //Callback can only be called by randomizer
    if (msg.sender != randomizer) {
      revert OnlyRandomizerCanFulfill(msg.sender, randomizer);
    }
    // JackPot Lottery
    address playerAddress = vrfJackpotIDs[_id];
    if (playerAddress != address(0)) {
      JackpotGame storage game = jackpotGames[playerAddress];

      uint256 payout;

      uint256 winnerRandomNumber = uint256(_value) % maxLoteryNumbers;

      for (uint32 i = 0; i < game.playedNumbers.length; i++) {
        if (winnerRandomNumber == game.playedNumbers[i]) {
          // We have a winner!!!
          payout = getCurrentJackpot();
        }
        if (lastbuyLotteryState == LotteryState.OPEN) {
          ticketsLastbuyLotteryAtRound[lastbuyLotteryRound].push(playerAddress);
        }
      }
      emit Jackpot_Outcome_Event(
        playerAddress,
        game.wager,
        game.playedNumbers,
        uint8(winnerRandomNumber),
        payout,
        game.tokenAddress
      );
      _transferToBankroll(game.tokenAddress, game.wager);
      delete (vrfJackpotIDs[_id]);
      delete (jackpotGames[playerAddress]);
      if (payout != 0) {
        _transferPayout(playerAddress, payout, game.tokenAddress);
      }
      // Check if we have to pick a new lastbuy lottery winner
      if (
        lastbuyLotteryState == LotteryState.OPEN &&
        ticketsLastbuyLotteryAtRound[lastbuyLotteryRound].length >= lastbuyLimit
      ) {
        uint256 id = _requestRandomWords();
        vrfLastBuyIDs[id] = msg.sender;
        lastbuyLotteryState = LotteryState.CALCULATING;
      }
    }
    // LastBuy Lottery
    address randomizerAddress = vrfLastBuyIDs[_id];
    if (randomizerAddress == randomizer && ticketsLastbuyLotteryAtRound[lastbuyLotteryRound].length > 0) {
      uint256 indexOfWinner = uint256(_value) % ticketsLastbuyLotteryAtRound[lastbuyLotteryRound].length;
      address lastBuyWinner = ticketsLastbuyLotteryAtRound[lastbuyLotteryRound][indexOfWinner];
      // We have a LastBuy winner!!!
      uint256 payout = getLastbuyPrize();
      lastbuyLotteryRound++;
      lastbuyLotteryState = LotteryState.OPEN;
      delete (vrfLastBuyIDs[_id]);
      if (payout != 0) {
        _transferPayout(lastBuyWinner, payout, address(0));
      }
      emit Lastbuy_Outcome_Event(
        lastBuyWinner,
        ticketsLastbuyLotteryAtRound[lastbuyLotteryRound],
        uint8(indexOfWinner),
        payout
      );
    }
    // Weekly Lottery
    address authorized = vrfWeeklyIDs[_id];
    if (authorizedWeekly[authorized] && ticketsWeeklyLotteryAtRound[weeklyLotteryRound].length > 0) {
      uint256 indexOfWinner = uint256(_value) % ticketsWeeklyLotteryAtRound[weeklyLotteryRound].length;
      address weeklyWinner = ticketsWeeklyLotteryAtRound[weeklyLotteryRound][indexOfWinner];
      // We have a Weekly winner!!!
      uint256 payout = getWeeklyPrize();
      weeklyLotteryRound++;
      weeklyLotteryState = LotteryState.OPEN;
      delete (vrfWeeklyIDs[_id]);
      if (payout != 0) {
        _transferPayout(weeklyWinner, payout, address(0));
      }
      emit Weekly_Outcome_Event(
        weeklyWinner,
        ticketsWeeklyLotteryAtRound[weeklyLotteryRound],
        uint8(indexOfWinner),
        payout
      );
    }
  }

  function requestWeeklyLottery() external {
    if (!authorizedWeekly[msg.sender]) {
      revert NotAuthorized();
    }
    require(
      weeklyLotteryState == LotteryState.OPEN && ticketsWeeklyLotteryAtRound[weeklyLotteryRound].length > 0,
      "Weekly Lottery not available"
    );

    uint256 id = _requestRandomWords();
    vrfWeeklyIDs[id] = msg.sender;
    lastbuyLotteryState = LotteryState.CALCULATING;
  }

  function setWeeklyAuthorized(address _authorized, bool _value) external {
    if (msg.sender != Bankroll.owner()) {
      revert NotOwner(Bankroll.owner(), msg.sender);
    }
    authorizedWeekly[_authorized] = _value;
  }

  function setWeeklyState(LotteryState _state) external {
    if (msg.sender != Bankroll.owner()) {
      revert NotOwner(Bankroll.owner(), msg.sender);
    }
    weeklyLotteryState = _state;
  }

  function setLastbuyState(LotteryState _state) external {
    if (msg.sender != Bankroll.owner()) {
      revert NotOwner(Bankroll.owner(), msg.sender);
    }
    lastbuyLotteryState = _state;
  }

  function setLastBuyLimit(uint256 _limit) external {
    if (msg.sender != Bankroll.owner()) {
      revert NotOwner(Bankroll.owner(), msg.sender);
    }
    lastbuyLimit = _limit;
  }

  function setMaxLoteryNumbers(uint256 _limit) external {
    if (msg.sender != Bankroll.owner()) {
      revert NotOwner(Bankroll.owner(), msg.sender);
    }
    maxLoteryNumbers = _limit;
  }

  function setMaxPlayedNumbers(uint256 _limit) external {
    if (msg.sender != Bankroll.owner()) {
      revert NotOwner(Bankroll.owner(), msg.sender);
    }
    maxPlayedNumbers = _limit;
  }

  function getCurrentNumberOfWeeklyLotteryTickets(uint256 _round) public view returns (uint256) {
    return ticketsWeeklyLotteryAtRound[_round].length;
  }

  function getCurrentWeeklyLotteryTickets(uint256 _round) public view returns (address[] memory) {
    return ticketsWeeklyLotteryAtRound[_round];
  }

  function getCurrentNumberOfLastbuyLotteryTickets(uint256 _round) public view returns (uint256) {
    return ticketsLastbuyLotteryAtRound[_round].length;
  }

  function getCurrentLastBuyLotteryTickets(uint256 _round) public view returns (address[] memory) {
    return ticketsLastbuyLotteryAtRound[_round];
  }
}