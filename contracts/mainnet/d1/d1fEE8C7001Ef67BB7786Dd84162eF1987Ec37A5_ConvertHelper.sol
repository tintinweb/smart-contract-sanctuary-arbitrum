// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IV1_Portal} from "./interfaces/IV1_Portal.sol";
import {IV2_Portal} from "./interfaces/IV2_Portal.sol";
import {IV2_LP} from "./interfaces/IV2_LP.sol";

error InsufficientBalance();
error InvalidAddress();
error InvalidAmount();
error InsufficientReward();
error FailedToSendNativeToken();

/// @title ConvertHelper for PortalsV1 and V2 on Arbitrum
/// @author Possum Labs
/// @notice This contract claims pending rewards and executes the convert() function of the HLP Portal in a single transaction.
contract ConvertHelper {
    constructor() {}

    // Variables
    using SafeERC20 for IERC20;

    IERC20 public constant PSM = IERC20(0x17A8541B82BF67e10B0874284b4Ae66858cb1fd5);
    uint256 public constant PSM_AMOUNT_FOR_CONVERT = 100000 * 1e18;

    IERC20 private constant USDCE = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    IERC20 private constant WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    uint256 private constant MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    // Portal V1 related variables
    address payable private constant HLP_PORTAL_ADDRESS = payable(0x24b7d3034C711497c81ed5f70BEE2280907Ea1Fa);
    IV1_Portal public constant HLP_PORTAL = IV1_Portal(HLP_PORTAL_ADDRESS);
    address public constant HLP_PROTOCOL_REWARDER = 0x665099B3e59367f02E5f9e039C3450E31c338788;
    address public constant HMX_PROTOCOL_REWARDER = 0xB698829C4C187C85859AD2085B24f308fC1195D3;

    // Portal V2 related variables
    address payable private constant V2_VIRTUAL_LP_ADDRESS = payable(0x212Bbd56F6D4F999B2845adebd8cec147851E383);
    IV2_LP public constant V2_VIRTUAL_LP = IV2_LP(V2_VIRTUAL_LP_ADDRESS);

    ///////////////////////////////////////
    // Functions - Portals V1 Arbitrage
    ///////////////////////////////////////
    function V1_getRewardsUSDCE() public view returns (uint256 availableReward) {
        uint256 pendingRewards =
            HLP_PORTAL.getPendingRewards(HLP_PROTOCOL_REWARDER) + HLP_PORTAL.getPendingRewards(HMX_PROTOCOL_REWARDER);

        availableReward = pendingRewards + USDCE.balanceOf(address(this)) + USDCE.balanceOf(HLP_PORTAL_ADDRESS);
    }

    function V1_convertUSDCE(address _recipient, uint256 _minReceived) external {
        // Input Validation
        if (_minReceived == 0) revert InvalidAmount();
        if (_recipient == address(0)) revert InvalidAddress();

        // Check if enough rewards are available to trigger arbitrage
        uint256 reward = V1_getRewardsUSDCE();
        if (reward < _minReceived) revert InsufficientReward();

        // Attempt to update maxLockDuration of the Portal
        uint256 maxLockDuration = HLP_PORTAL.maxLockDuration();
        if (maxLockDuration < 157680000) HLP_PORTAL.updateMaxLockDuration();

        // Arbitrage sequence
        PSM.transferFrom(msg.sender, address(this), PSM_AMOUNT_FOR_CONVERT);
        HLP_PORTAL.claimRewardsHLPandHMX();
        HLP_PORTAL.convert(address(USDCE), 1, block.timestamp);

        // Transfer the rewards to the recipient
        USDCE.safeTransfer(_recipient, reward);
    }

    ///////////////////////////////////////
    // Functions - Portals V2 Arbitrage
    ///////////////////////////////////////
    function V2_getRewards(address _portal) public view returns (uint256 availableReward) {
        address principalTokenAddress = IV2_Portal(_portal).PRINCIPAL_TOKEN_ADDRESS();
        IERC20 principalToken = (principalTokenAddress == address(0)) ? WETH : IERC20(principalTokenAddress);

        uint256 pendingRewards = V2_VIRTUAL_LP.getProfitOfPortal(_portal);

        uint256 availableReward_ETH = pendingRewards + address(this).balance + address(V2_VIRTUAL_LP_ADDRESS).balance;

        uint256 availableReward_ERC20 =
            pendingRewards + principalToken.balanceOf(address(this)) + principalToken.balanceOf(V2_VIRTUAL_LP_ADDRESS);

        availableReward = (principalTokenAddress == address(0)) ? availableReward_ETH : availableReward_ERC20;
    }

    function V2_convert(address _portal, address _recipient, uint256 _minReceived) external {
        // Input Validation
        if (_minReceived == 0) revert InvalidAmount();
        if (_portal == address(0) || _recipient == address(0)) revert InvalidAddress();

        // Check if enough rewards are available to trigger arbitrage
        uint256 reward = V2_getRewards(_portal);
        if (reward < _minReceived) revert InsufficientReward();

        // Attempt to update maxLockDuration of the Portal
        uint256 maxLockDuration = IV2_Portal(_portal).maxLockDuration();
        if (maxLockDuration > 8640000 && maxLockDuration < 157680000) IV2_Portal(_portal).updateMaxLockDuration();

        // Arbitrage sequence
        address principalTokenAddress = IV2_Portal(_portal).PRINCIPAL_TOKEN_ADDRESS();
        PSM.transferFrom(msg.sender, address(this), PSM_AMOUNT_FOR_CONVERT);
        V2_VIRTUAL_LP.collectProfitOfPortal(_portal);
        V2_VIRTUAL_LP.convert(principalTokenAddress, address(this), 1, block.timestamp);

        // Transfer the rewards to the recipient
        if (principalTokenAddress == address(0)) {
            (bool sent,) = payable(_recipient).call{value: reward}("");
            if (!sent) {
                revert FailedToSendNativeToken();
            }
        } else {
            IERC20(principalTokenAddress).safeTransfer(_recipient, reward);
        }
    }

    ///////////////////////////////////////
    // General Functions
    ///////////////////////////////////////

    // Set spending allowance of PSM by Portals & V2 LP to execute convert()
    function increaseAllowances() external {
        PSM.approve(HLP_PORTAL_ADDRESS, MAX_UINT);
        PSM.approve(V2_VIRTUAL_LP_ADDRESS, MAX_UINT);
    }

    // Send stuck tokens to the HLP Portal with a 10% caller reward
    function extractToken(address _token, uint256 _minReward) external {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        uint256 reward = balance / 10;
        if (_minReward == 0) revert InvalidAmount();
        if (reward < _minReward) revert InsufficientReward();

        balance -= reward;

        IERC20(_token).safeTransfer(msg.sender, reward);
        IERC20(_token).safeTransfer(HLP_PORTAL_ADDRESS, balance);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface IV2_LP {
    function getProfitOfPortal(address _portal) external view returns (uint256 profitOfPortal);
    function collectProfitOfPortal(address _portal) external;
    function convert(address _token, address _recipient, uint256 _minReceived, uint256 _deadline) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface IV2_Portal {
    function PRINCIPAL_TOKEN_ADDRESS() external view returns (address PRINCIPAL_TOKEN_ADDRESS);
    function maxLockDuration() external view returns (uint256 maxLockDuration);
    function updateMaxLockDuration() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface IV1_Portal {
    function getPendingRewards(address _rewarder) external view returns (uint256 claimableReward);
    function claimRewardsHLPandHMX() external;
    function convert(address _token, uint256 _minReceived, uint256 _deadline) external;
    function maxLockDuration() external view returns (uint256 maxLockDuration);
    function updateMaxLockDuration() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.19;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
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

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
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
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.19;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.19;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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