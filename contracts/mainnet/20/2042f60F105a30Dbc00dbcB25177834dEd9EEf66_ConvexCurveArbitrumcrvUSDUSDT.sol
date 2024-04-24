// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

abstract contract Logic {
    error NotImplemented();

    function claimRewards(address recipient) external payable virtual {
        revert NotImplemented();
    }

    function emergencyExit() external payable virtual {
        revert NotImplemented();
    }

    function withdrawLiquidity(
        address recipient,
        uint256 amount
    ) external payable virtual {
        revert NotImplemented();
    }

    function enter() external payable virtual;

    function exit(uint256 liquidity) external payable virtual;

    function accountLiquidity(
        address account
    ) external view virtual returns (uint256);
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDefii is IERC20 {
    /// @notice Instruction type
    /// @dev SWAP_BRIDGE is combination of SWAP + BRIDGE instructions.
    /// @dev Data for MIN_LIQUIDITY_DELTA type is just `uint256`
    enum InstructionType {
        SWAP,
        BRIDGE,
        SWAP_BRIDGE,
        REMOTE_CALL,
        MIN_LIQUIDITY_DELTA,
        MIN_TOKENS_DELTA
    }

    /// @notice DEFII type
    enum Type {
        LOCAL,
        REMOTE
    }

    /// @notice DEFII instruction
    struct Instruction {
        InstructionType type_;
        bytes data;
    }

    /// @notice Swap instruction
    /// @dev `routerCalldata` - 1inch router calldata from API
    struct SwapInstruction {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        bytes routerCalldata;
    }

    /// @notice Bridge instruction
    /// @dev `slippage` should be in bps
    struct BridgeInstruction {
        address token;
        uint256 amount;
        uint256 slippage;
        address bridgeAdapter;
        uint256 value;
        bytes bridgeParams;
    }

    /// @notice Swap and bridge instruction. Do swap and bridge all token from swap
    /// @dev `routerCalldata` - 1inch router calldata from API
    /// @dev `slippage` should be in bps
    struct SwapBridgeInstruction {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        bytes routerCalldata;
        address bridgeAdapter;
        uint256 value;
        bytes bridgeParams;
        uint256 slippage;
    }

    struct MinTokensDeltaInstruction {
        address[] tokens;
        uint256[] deltas;
    }

    /// @notice Enters DEFII with predefined logic
    /// @param amount Notion amount for enter
    /// @param positionId Position id (used in callback)
    /// @param instructions List with instructions for enter
    /// @dev Caller should implement `IVault` interface
    function enter(
        uint256 amount,
        uint256 positionId,
        Instruction[] calldata instructions
    ) external payable;

    /// @notice Exits from DEFII with predefined logic
    /// @param shares Defii lp amount to burn
    /// @param positionId Position id (used in callback)
    /// @param instructions List with instructions for enter
    /// @dev Caller should implement `IVault` interface
    function exit(
        uint256 shares,
        uint256 positionId,
        Instruction[] calldata instructions
    ) external payable;

    /// @notice Withdraw liquidity (eg lp tokens) from
    /// @param shares Defii lp amount to burn
    /// @param recipient Address for withdrawal
    /// @param instructions List with instructions
    /// @dev Caller should implement `IVault` interface
    function withdrawLiquidity(
        address recipient,
        uint256 shares,
        Instruction[] calldata instructions
    ) external payable;

    /// @notice DEFII notion (start token)
    /// @return notion address
    // solhint-disable-next-line named-return-values
    function notion() external view returns (address);

    /// @notice DEFII type
    /// @return type Type
    // solhint-disable-next-line named-return-values
    function defiiType() external pure returns (Type);
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

library Constants {
    uint256 constant BPS = 1e4;
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {Logic} from "../defii/execution/Logic.sol";
import {IDefii} from "../interfaces/IDefii.sol";

abstract contract SelfManagedLogic is Logic {
    error WrongBuildingBlockId(uint256);

    function enterWithParams(bytes memory params) external payable virtual {
        revert NotImplemented();
    }

    function emergencyExitPrivate() external payable virtual {
        revert NotImplemented();
    }

    function exitBuildingBlock(
        uint256 buildingBlockId
    ) external payable virtual;
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.9;

uint256 constant CHAIN_ID = 42161;

address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
address constant USDCe = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
address constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
address constant MIM = 0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A;
address constant crvUSD = 0x498Bf2B1e120FeD3ad3D42EA2165E9b73f99C1e5;

address constant LZ_ENDPOINT = 0x3c2269811836af69497E5F486A85D7316753cf62;
uint16 constant LZ_ID = 110;

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.9;

address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
address constant wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
address constant wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant crvUSD = 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E;
address constant XAI = 0xd7C9F0e536dC865Ae858b0C0453Fe76D13c3bEAc;
address constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
address constant eUSD = 0xA0d69E286B938e21CBf7E51D71F6A4c8918f482F;
address constant GHO = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.9;

import {ConvexCurveArbitrumcrvUSD} from "../templates/ConvexCurveArbitrumcrvUSD.sol";

contract ConvexCurveArbitrumcrvUSDUSDT is ConvexCurveArbitrumcrvUSD {
    constructor()
    ConvexCurveArbitrumcrvUSD(
        18
    )
    {}
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.9;

import {crvUSD} from "../../constants/arbitrumOne.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract crvUSDArbitrumEmergencyExit {
    IStableSwapNG public constant CRVUSD_USDC = IStableSwapNG(0xec090cf6DD891D2d014beA6edAda6e05E025D93d);
    IStableSwapNG public constant CRVUSD_USDT = IStableSwapNG(0x73aF1150F265419Ef8a5DB41908B700C32D49135);

    function _redeemCurveUSD() internal {
        uint256 crvUSDAmount = IERC20(crvUSD).balanceOf(address(this));
        uint256 potentialUSDCAmount = CRVUSD_USDC.get_dy(0, 1, crvUSDAmount);
        uint256 potentialUSDTAmount = CRVUSD_USDT.get_dy(0, 1, crvUSDAmount);
        if (potentialUSDCAmount > potentialUSDTAmount) {
            IERC20(crvUSD).approve(address(CRVUSD_USDC), crvUSDAmount);
            CRVUSD_USDC.exchange(0, 1, crvUSDAmount, 0);
        } else {
            IERC20(crvUSD).approve(address(CRVUSD_USDT), crvUSDAmount);
            CRVUSD_USDT.exchange(0, 1, crvUSDAmount, 0);
        }
    }
}

interface IStableSwapNG {
    function get_dy(int128, int128, uint256) external returns (uint256);
    function exchange(
        int128,
        int128,
        uint256,
        uint256
    ) external returns (uint256);
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {SelfManagedLogicWithUtils} from "./SelfManagedLogicWithUtils.sol";

abstract contract ConvexCurveArbitrum is SelfManagedLogicWithUtils {
    IBoosterArbitrum public constant BOOSTER = IBoosterArbitrum(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    IRewardPoolArbitrum public immutable REWARD_POOL;
    ICurveStablePool public immutable CURVE_POOL;

    uint256 public immutable POOL_ID;
    constructor(uint256 pid) {
        POOL_ID = pid;
        (CURVE_POOL,,REWARD_POOL,,) = BOOSTER.poolInfo(pid);
    }

    function enter() external payable override {
        _addLiquidity();
        _approveIfNeeded(address(CURVE_POOL), address(BOOSTER));
        BOOSTER.depositAll(POOL_ID);
    }

    function exit(uint256 liquidity) external payable override {
        REWARD_POOL.withdraw(liquidity, true);
        _removeLiquidity();
    }

    function claimRewards(address recipient) external payable override {
        IRewardPoolArbitrum(REWARD_POOL).getReward(address(this));
        uint256 rewardsAmount = IRewardPoolArbitrum(REWARD_POOL).rewardLength();
        address[] memory rewards = new address[](rewardsAmount);
        for (uint256 i = 0; i < rewardsAmount; i++) {
            (address token,,) = IRewardPoolArbitrum(REWARD_POOL).rewards(i);
            rewards[i] = token;
        }
        for (uint8 i = 0; i < rewards.length; i++) {
            _transferAll(rewards[i], recipient);
        }
    }

    function accountLiquidity(
        address account
    ) public view override returns (uint256) {
        return REWARD_POOL.balanceOf(account);
    }

    function _addLiquidity() internal virtual returns (uint256) {
        uint256[] memory amounts = new uint256[](2);
        for (uint256 i = 0; i < 2; i++) {
            address token = ICurveStablePool(CURVE_POOL).coins(i);
            amounts[i] = IERC20(token).balanceOf(address(this));
            if (amounts[i] > 0) {
                _approveIfNeeded(token, address(CURVE_POOL));
            }
        }
        return ICurveStablePool(CURVE_POOL).add_liquidity(amounts, 0);
    }

    function _removeLiquidity() internal virtual {
        uint256[] memory minAmounts = new uint256[](2);
        uint256 amount = ICurveStablePool(CURVE_POOL).balanceOf(address(this));
        ICurveStablePool(CURVE_POOL).remove_liquidity(
            amount,
            minAmounts
        );
    }

    function _exitBuildingBlockConvex() internal {
        uint256 liquidity = accountLiquidity(address(this));
        IRewardPoolArbitrum(REWARD_POOL).withdraw(liquidity, true);
    }

    function _exitBuildingBlockCurve() internal {
        _exitBuildingBlockConvex();
        _removeLiquidity();
    }
}

interface IBoosterArbitrum {
    function depositAll(uint256 pid) external;
    function poolInfo(
        uint256
    ) external view returns (ICurveStablePool, address, IRewardPoolArbitrum, bool, address);
}

interface IRewardPoolArbitrum {
    function withdraw(uint256 amount, bool claim) external;
    function getReward(address recipient) external;
    function rewardLength() external view returns(uint256);
    function rewards(uint256) external view returns(address, uint256, uint256);
    function balanceOf(address) external view returns(uint256);
}

interface ICurveStablePool is IERC20 {
    function add_liquidity(
        uint256[] memory,
        uint256
    ) external returns (uint256);
    function remove_liquidity(
        uint256,
        uint256[] memory
    ) external returns (uint256);
    function coins(uint256) external view returns (address);
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.9;
import {ConvexCurveArbitrum} from "../templates/ConvexCurveArbitrum.sol";
import {crvUSDArbitrumEmergencyExit} from "../mixins/crvUSDArbitrumEmergencyExit.sol";

import {crvUSD, USDT, USDC} from "../../constants/ethereum.sol";


contract ConvexCurveArbitrumcrvUSD is ConvexCurveArbitrum, crvUSDArbitrumEmergencyExit {
    constructor(
        uint256 poolId
    )
    ConvexCurveArbitrum(
        poolId
    )
    crvUSDArbitrumEmergencyExit()
    {}

    function exitBuildingBlock(uint256 buildingBlockId) public payable override {
        uint256 liquidity = accountLiquidity(address(this));
        if (buildingBlockId == 0) {
            _exitBuildingBlockConvex();
        }
        else if (buildingBlockId == 1) {
            _exitBuildingBlockCurve();
        }
        else if (buildingBlockId == 2) {
            _exitBuildingBlockCurveUSD();
        }
        else {
            revert WrongBuildingBlockId(buildingBlockId);
        }
    }


    function _exitBuildingBlockCurveUSD() internal {
        _exitBuildingBlockCurve();
        _redeemCurveUSD();
    }
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {SelfManagedLogic} from "@shift-defi/core/contracts/self-managed/SelfManagedLogic.sol";
import {Constants} from "@shift-defi/core/contracts/libraries/Constants.sol";

abstract contract SelfManagedLogicWithUtils is SelfManagedLogic {
    using SafeERC20 for IERC20;

    function _approveIfNeeded(address token, address recipient) internal {
        uint256 allowance = IERC20(token).allowance(address(this), recipient);
        if (allowance < type(uint256).max) {
            IERC20(token).forceApprove(recipient, type(uint256).max);
        }
    }

    function _transferAll(address token, address recipient) internal {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).safeTransfer(recipient, balance);
        }
    }
}