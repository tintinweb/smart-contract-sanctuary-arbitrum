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
pragma solidity 0.8.20;

error CannotAuthoriseSelf();
error ContractCallNotAllowed();
error CumulativeSlippageTooHigh(uint256 minAmount, uint256 receivedAmount);
error InformationMismatch();
error InsufficientBalance(uint256 required, uint256 balance);
error InvalidAmount();
error InvalidContract();
error InvalidIndex();
error IncorrectFeePercent();
error FeeMoreThanAmount(uint256 amount, uint256 fee);
error EmptySwapPath();
error IncorrectMsgValue();
error IncorrectWETH();
error InvalidReceiver();
error NotAllowedTo(address account, bytes4 selector);
error NativeAssetTransferFailed();
error NoSwapFromZeroBalance();
error NoTransferToNullAddress();
error NullAddrIsNotAnERC20Token();
error NullAddrIsNotAValidSpender();
error OnlyContractOwner();
error ReentrancyError();
error TokenNotSupported();
error UnsupportedChainId(uint256 chainId);

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import { Swapper } from "../utils/Swapper.sol";
import { ReentrancyGuard } from "../utils/ReentrancyGuard.sol";
import { StructInterface } from "../interfaces/StructInterface.sol";
import { LibSwap } from "../libraries/LibSwap.sol";
import { LibBridge } from "../libraries/LibBridge.sol";
import { LibAsset } from "../libraries/LibAsset.sol";
import { LibFeeCollector } from "../libraries/LibFeeCollector.sol";
import { InvalidAmount, InformationMismatch, UnsupportedChainId, TokenNotSupported, InvalidReceiver } from "../errors/GenericErrors.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { RefuelStation } from "../interfaces/RefuelStation.sol";

contract GasRefuelFacet is Swapper, ReentrancyGuard, StructInterface {
    RefuelStation immutable refuelStation;

    constructor(RefuelStation _refuelStation) {
        refuelStation = _refuelStation;
    }

    function bridgeTokensRefuel(
        uint256 _amount,
        BridgeData calldata _bridgeData
    ) external payable nonReentrant {
        if (_amount == 0) revert InvalidAmount();

        LibAsset.depositAsset(_bridgeData.sendingAsset, _amount);

        _bridge(
            _amount,
            _bridgeData
        );

        emit Bridged(
            msg.sender,
            _bridgeData.chainId,
            "refuel",
            _bridgeData.sendingAsset,
            _amount,
            ""
        );
    }

    function swapAndBridgeTokensRefuel(
        Swap calldata _swapData,
        BridgeData calldata _bridgeData,
        LibSwap.SwapData[] calldata _srcSwaps
    ) external payable nonReentrant {
        if (_swapData.amount == 0) revert InvalidAmount();

        uint256 receivedAmount = _swap(
            _swapData.amount,
            _swapData.minAmount,
            _swapData.weth,
            _srcSwaps,
            0,
            _swapData.partner
        );

        if (_srcSwaps[_srcSwaps.length - 1].toToken != _bridgeData.sendingAsset)
            revert InformationMismatch();

        _bridge(
            receivedAmount,
            _bridgeData
        );

        emit Bridged(
            msg.sender,
            _bridgeData.chainId,
            "refuel",
            _bridgeData.sendingAsset,
            receivedAmount,
            ""
        );
    }

    function _bridge(
        uint256 _amount,
        BridgeData calldata _bridgeData
    ) private {
        if (_bridgeData.receiver == address(0)) revert InvalidReceiver();
        if (!LibAsset.isNativeAsset(_bridgeData.sendingAsset)) revert TokenNotSupported();

        refuelStation.depositNativeToken{ value: _amount }(_bridgeData.chainId, _bridgeData.receiver);
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAdapter {
    struct Route {
        uint256 index; 
        address targetExchange;
        bytes payload;
    }

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        Route calldata route
    ) external payable;

    function quote(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        Route calldata route
    ) external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract IWETH {
    function deposit() external virtual payable;
    function withdraw(uint256 amount) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface RefuelStation {
    function depositNativeToken(
        uint256 destinationChainId,
        address _to
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface StructInterface {
    event Bridged(
        address sender,
        uint256 chainId,
        string bridge,
        address tokenBridged,
        uint256 tokensBridged,
        bytes payload
    );

    struct Swap {
        uint256 amount;
        uint256 minAmount;
        address weth;
        address partner;
    }

    struct BridgeData {
        address sendingAsset;
        address receiver;
        uint256 chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { InvalidContract } from '../errors/GenericErrors.sol';

/// @title LibAllowList
/// @author FormalCrypto
/// @notice Provides functionality to manage allowed contracts
library LibAllowList {
    bytes32 internal constant ALLOW_LIST_STORAGE = keccak256("allow.list.storage");

    struct AllowListStorage {
        mapping(bytes4 => bool) allowedSelector;
        mapping(address => bool) allowList;
        address[] contracts;
    }

    event ExchangeAdded(address exchange);
    event ExchangeRemoved(address exchange);

    /**
     * @dev Fetch local storage
     */
    function _getStorage() internal pure returns (AllowListStorage storage als) {
        bytes32 position = ALLOW_LIST_STORAGE;
        assembly {
            als.slot := position
        }
    } 

    /**
     * @notice Adds contract to allow list
     * @param _contract Address of the contract to be added
     */
    function addAllowedContract(address _contract) internal {
        isContract(_contract);

        AllowListStorage storage als = _getStorage();

        if (als.allowList[_contract]) return;

        als.allowList[_contract] = true;
        als.contracts.push(_contract);

        emit ExchangeAdded(_contract);
    }

    /**
     * @dev Removes contract from allow list
     * @param _contract Address of the contract to be removed from allow list
     */
    function removeAllowedContract(address _contract) internal {
        AllowListStorage storage als = _getStorage();

        if (!als.allowList[_contract]) return;

        als.allowList[_contract] = false;

        uint256 contractListLength = als.contracts.length;

        for (uint256 i = 0; i < contractListLength;) {
            if (_contract == als.contracts[i]) {
                als.contracts[i] = als.contracts[contractListLength - 1];
                als.contracts.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }
        emit ExchangeRemoved(_contract);
    }

    /**
     * @dev Checks if contract added to allow list
     * @param _contract Address of the contract to be checked
     */
    function isContractAllowed(address _contract) internal view returns (bool) {
        return _getStorage().allowList[_contract];
    }

    /**
     * @dev Returns list of all contract added to allow list
     */
    function getAllAllowedContract() internal view returns (address[] memory) {
        return _getStorage().contracts;
    }

    /**
     * @dev Checks is the contract a contract
     * @param _contract Address of the contract to be checked
     */
    function isContract(address _contract) private view {
        if (_contract == address(0)) revert InvalidContract();
        if (_contract.code.length == 0) revert InvalidContract();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import { InsufficientBalance, NullAddrIsNotAnERC20Token, NullAddrIsNotAValidSpender, NoTransferToNullAddress, InvalidAmount, NativeAssetTransferFailed } from "../errors/GenericErrors.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { LibSwap } from "./LibSwap.sol";

/**
 * @title LibAsset
 * @notice This library contains helpers for dealing with onchain transfers
 *         of assets, including accounting for the native asset `assetId`
 *         conventions and any noncompliant ERC20 transfers
 */
library LibAsset {

    address internal constant NULL_ADDRESS = address(0);

    /** 
     * @dev All native assets use the this address for their asset id
     *      by convention
     */
    address internal constant NATIVE_ASSETID = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    
    /** 
     * @notice Gets the balance of the inheriting contract for the given asset
     * @param assetId The asset identifier to get the balance of
     * @return Balance held by contracts using this library
     */
    function getOwnBalance(address assetId) internal view returns (uint256) {
        return
            isNativeAsset(assetId)
                ? address(this).balance
                : IERC20(assetId).balanceOf(address(this));
    }

    /**
     * @notice Transfers ether from the inheriting contract to a given
     *         recipient
     * @param recipient Address to send ether to
     * @param amount Amount to send to given recipient
     */
    function transferNativeAsset(
        address payable recipient,
        uint256 amount
    ) private {
        if (recipient == NULL_ADDRESS) revert NoTransferToNullAddress();
        if (amount > address(this).balance)
            revert InsufficientBalance(amount, address(this).balance);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = recipient.call{ value: amount }("");
        if (!success) revert NativeAssetTransferFailed();
    }

    /**
     * @notice Approves specified amount of tokens.
     * @param assetId Token address to transfer
     * @param spender Address to give spend approval to
     * @param amount Amount to approve for spending
     */
    function approveERC20(
        IERC20 assetId,
        address spender,
        uint256 amount
    ) internal {
        if (isNativeAsset(address(assetId))) {
            return;
        }
        if (spender == NULL_ADDRESS) {
            revert NullAddrIsNotAValidSpender();
        }

        if (assetId.allowance(address(this), spender) < amount) {
            SafeERC20.safeApprove(IERC20(assetId), spender, 0);
            SafeERC20.safeApprove(IERC20(assetId), spender, amount);
        }
    }

    /**
     * @notice Transfers tokens from the inheriting contract to a given
     *         recipient
     * @param assetId Token address to transfer
     * @param recipient Address to send token to
     * @param amount Amount to send to given recipient
     */
    function transferERC20(
        address assetId,
        address recipient,
        uint256 amount
    ) private {
        if (isNativeAsset(assetId)) {
            revert NullAddrIsNotAnERC20Token();
        }
        if (recipient == NULL_ADDRESS) {
            revert NoTransferToNullAddress();
        }

        uint256 assetBalance = IERC20(assetId).balanceOf(address(this));
        if (amount > assetBalance) {
            revert InsufficientBalance(amount, assetBalance);
        }
        SafeERC20.safeTransfer(IERC20(assetId), recipient, amount);
    }

    /**
     * @notice Transfers tokens from a sender to a given recipient
     * @param assetId Token address to transfer
     * @param from Address of sender/owner
     * @param to Address of recipient/spender
     * @param amount Amount to transfer from owner to spender
     */
    function transferFromERC20(
        address assetId,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (isNativeAsset(assetId)) {
            revert NullAddrIsNotAnERC20Token();
        }
        if (to == NULL_ADDRESS) {
            revert NoTransferToNullAddress();
        }

        IERC20 asset = IERC20(assetId);
        uint256 prevBalance = asset.balanceOf(to);
        SafeERC20.safeTransferFrom(asset, from, to, amount);
        if (asset.balanceOf(to) - prevBalance != amount) {
            revert InvalidAmount();
        }
    }

    /**
     * @notice Deposits asset
     * @param assetId Token address to deposit
     * @param amount Amount to deposit
     */
    function depositAsset(address assetId, uint256 amount) internal {
        if (amount == 0) revert InvalidAmount();
        if (isNativeAsset(assetId)) {
            if (msg.value < amount) revert InvalidAmount();
        } else {
            uint256 balance = IERC20(assetId).balanceOf(msg.sender);
            if (balance < amount) revert InsufficientBalance(amount, balance);
            transferFromERC20(assetId, msg.sender, address(this), amount);
        }
    }

    /**
     * @notice Determines whether the given assetId is the native asset
     * @param assetId The asset identifier to evaluate
     * @return Boolean indicating if the asset is the native asset
     */
    function isNativeAsset(address assetId) internal pure returns (bool) {
        return assetId == NATIVE_ASSETID;
    }

    /**
     * @notice Wrapper function to transfer a given asset (native or erc20) to
     *         some recipient. Should handle all non-compliant return value
     *         tokens as well by using the SafeERC20 contract by open zeppelin.
     * @param assetId Asset id for transfer (address(0) for native asset,
     *                token address for erc20s)
     * @param recipient Address to send asset to
     * @param amount Amount to send to given recipient
     */
    function transferAsset(
        address assetId,
        address payable recipient,
        uint256 amount
    ) internal {
        isNativeAsset(assetId)
            ? transferNativeAsset(recipient, amount)
            : transferERC20(assetId, recipient, amount);
    }

    /**
     * @dev Checks whether the given address is a contract and contains code
     */
    function isContract(address _contractAddr) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(_contractAddr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { LibFeeCollector } from './LibFeeCollector.sol';
import { LibUtil } from './LibUtil.sol';

/// @title LibBridge
/// @author FormalCrypto
/// @notice Provides functionality to manage bridge data
library LibBridge {
    bytes32 internal constant BRIDGE_STORAGE_POSITION =
        keccak256("bridge.storage.position");

    struct BridgeStorage {
        uint256 crosschainFee;
        mapping(uint256 => uint256) minFee;
        mapping(address => bool) approvedTokens;
        mapping(uint256 => address) contractTo;
    }

    event CrosschainFeeUpdated(uint256 newCrosschainFee);
    event MinFeeUpdated(uint256 chainId, uint256 minFee);
    event TokenAdded(address token);
    event TokenRemoved(address token);
    event ContractToAdded(uint256 chainId, address contractAddress);
    event ContractToRemoved(uint256 chainId);

    /**
     * @dev Fetch local storage
     */
    function _getStorage() internal pure returns (BridgeStorage storage bs) {
        bytes32 position = BRIDGE_STORAGE_POSITION;
        assembly {
            bs.slot := position
        }
    }

    /**
     * @dev Updates crosschainFee
     * @param _crosschainFee Crosschain fee
     */
    function updateCrosschainFee(uint256 _crosschainFee) internal {
        BridgeStorage storage bs = _getStorage();

        bs.crosschainFee = _crosschainFee;
        emit CrosschainFeeUpdated(_crosschainFee);

    }

    /**
     * @dev Updates minimum fee for the specified chain
     * @param _chainId Chain id
     * @param _minFee minmum fee
     */
    function updateMinFee(uint256 _chainId, uint256 _minFee) internal {
        BridgeStorage storage bs = _getStorage();

        bs.minFee[_chainId] = _minFee;
        emit MinFeeUpdated(_chainId, _minFee);
    }

    /**
     * @dev Adds approved token for crosschain
     * @param _token Address of approved token
     */
    function addApprovedToken(address _token) internal {
        BridgeStorage storage bs = _getStorage();

        bs.approvedTokens[_token] = true;
        emit TokenAdded(_token);
    }

    /**
     * Removes approved token
     * @param _token Address of token to remove
     */
    function removeApprovedToken(address _token) internal {
        BridgeStorage storage bs = _getStorage();

        bs.approvedTokens[_token] = false;
        emit TokenRemoved(_token);
    }

    /**
     * @dev Adds receiver contract for the specified chain
     * @param _chainId Chain id
     * @param _contractTo Receiver contract address
     */
    function addContractTo(uint256 _chainId, address _contractTo) internal {
        BridgeStorage storage bs = _getStorage();

        bs.contractTo[_chainId] = _contractTo;
        emit ContractToAdded(_chainId, _contractTo);
    }

    /**
     * @dev Removes receiver contract
     * @param _chainId Chain id
     */
    function removeContractTo(uint256 _chainId) internal {
        BridgeStorage storage bs = _getStorage();

        if (bs.contractTo[_chainId] == address(0)) return;

        bs.contractTo[_chainId] = address(0);
        emit ContractToRemoved(_chainId);
    }

    /**
     * @dev Returns receiver contract for the specified chain
     * @param _chainId Chain id
     */
    function getContractTo(uint256 _chainId) internal view returns (address) {
        BridgeStorage storage bs = _getStorage();

        return bs.contractTo[_chainId];
    }

    /**
     * @dev Returns crosschainFee
     */
    function getCrosschainFee() internal view returns (uint256) {
        return _getStorage().crosschainFee;
    }

    /**
     * @dev Returns minimum fee for the specified chain
     * @param _chainId Chain id
     */
    function getMinFee(uint256 _chainId) internal view returns (uint256) {
        return _getStorage().minFee[_chainId];
    }

    /**
     * @dev Checks if token added to approved list
     * @param _token Address of the token to check
     */
    function getApprovedToken(address _token) internal view returns (bool) {
        return _getStorage().approvedTokens[_token];
    }

    /**
     * @dev Returns all fee data for the specified chain
     * @param _chainId Chain id
     */
    function getFeeInfo(uint256 _chainId) internal view returns (uint256, uint256) {
        BridgeStorage storage bs = _getStorage();
        return (bs.crosschainFee, bs.minFee[_chainId]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library LibBytes {
    // solhint-disable no-inline-assembly

    // LibBytes specific errors
    error SliceOverflow();
    error SliceOutOfBounds();
    error AddressOutOfBounds();

    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    // -------------------------

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        if (_length + 31 < _length) revert SliceOverflow();
        if (_bytes.length < _start + _length) revert SliceOutOfBounds();

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (address) {
        if (_bytes.length < _start + 20) {
            revert AddressOutOfBounds();
        }
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    /// Copied from OpenZeppelin's `Strings.sol` utility library.
    /// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/8335676b0e99944eef6a742e16dcd9ff6e68e609/contracts/utils/Strings.sol
    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { LibUtil } from './LibUtil.sol';
import { IERC20Decimals } from '../interfaces/IERC20Decimals.sol';
import { FeeMoreThanAmount } from '../errors/GenericErrors.sol';

/// @title LibFeeCollector
/// @author FormalCrypto
/// @notice Provides functionality to manages fees and take it
library LibFeeCollector {
    bytes32 internal constant FEE_STORAGE_POSITION =
        keccak256("fee.collector.storage.position");

    struct FeeStorage {
        address mainPartner;
        uint256 mainFee;
        uint256 defaultPartnerFeeShare;
        mapping(address => bool) isPartner;
        mapping(address => uint256) partnerFeeSharePercent;
        mapping(address => mapping(address => uint256)) feePerToken;
    }

    event MainPartnerUpdated(address newMainPartner);
    event MainFeeUpdated(uint256 newMainFee);
    event PartnersFeeShareUpdated(uint256 newPartnerFeeShare);
    event PartnerAdded(address partner, uint256 partnerFeeShare);
    event PartnerRemoved(address partner);

    /// @dev Fetch local storage
    function _getStorage()
        internal
        pure
        returns (FeeStorage storage fs)
    {
        bytes32 position = FEE_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            fs.slot := position
        }
    }

    /**
     * @dev Updates main partner
     * @param _mainPartner Address of main partner
     */
    function updateMainPartner(address _mainPartner) internal {
        FeeStorage storage fs = _getStorage();

        fs.mainPartner = _mainPartner;
        emit MainPartnerUpdated(_mainPartner);
    }

    /**
     * @dev Updates mainFee
     * @param _mainFee Main fee
     */
    function updateMainFee(uint256 _mainFee) internal {
        FeeStorage storage fs = _getStorage();

        fs.mainFee = _mainFee;
        emit MainFeeUpdated(_mainFee);
    }

    /**
     * @dev Update default partner fee
     * @param _defaultPartnerFeeShare default partner fee
     */
    function updateDefaultPartnerFeeShare(uint256 _defaultPartnerFeeShare) internal {
        FeeStorage storage fs = _getStorage();

        fs.defaultPartnerFeeShare = _defaultPartnerFeeShare;
        emit PartnersFeeShareUpdated(_defaultPartnerFeeShare);
    }

    /**
     * @dev Adds new partner with custom fee
     * @param _partner Partner address
     * @param _partnerFeeShare partner fee
     */
    function addPartner(address _partner, uint256 _partnerFeeShare) internal {
        FeeStorage storage fs = _getStorage();

        fs.isPartner[_partner] = true;
        fs.partnerFeeSharePercent[_partner] = _partnerFeeShare;
        emit PartnerAdded(_partner, _partnerFeeShare);
    }

    /**
     * @dev Removes registred partner
     * @param _partner Partner address
     */
    function removePartner(address _partner) internal {
        FeeStorage storage fs = _getStorage();
        if (!fs.isPartner[_partner]) return;

        fs.isPartner[_partner] = false;
        fs.partnerFeeSharePercent[_partner] = 0;
        emit PartnerRemoved(_partner);
    }

    /**
     * @dev Returns main fee
     */
    function getMainFee() internal view returns (uint256) {
        return _getStorage().mainFee;
    }

    /**
     * @dev Returns main partner
     */
    function getMainPartner() internal view returns (address) {
        return _getStorage().mainPartner;
    }

    /**
     * @dev Returns partner info
     * @param _partner Partner address
     * @return isPartner true if partner exists
     * @return partnerFeeSharePercent Partner fee (if exist)
     */
    function getPartnerInfo(address _partner) internal view returns (bool isPartner, uint256 partnerFeeSharePercent) {
        FeeStorage storage fs = _getStorage();
        return (fs.isPartner[_partner], fs.partnerFeeSharePercent[_partner]);
    }

    /**
     * @dev Returns fee amount that partner has accumulated 
     * @param _token Address of the token
     * @param _partner Partner address
     */
    function getFeeAmount(address _token, address _partner) internal view returns (uint256) {
        return(_getStorage().feePerToken[_partner][_token]);
    }

    /**
     * @dev Decrease fee amount of partner
     * @param _amount Amount of  tokens
     * @param _partner Partner address
     * @param _token Token address
     */
    function decreaseFeeAmount(uint256 _amount, address _partner, address _token) internal {
        FeeStorage storage fs = _getStorage();

        fs.feePerToken[_partner][_token] -= _amount;
    } 

    /**
     * @dev Takes fee when swaps token
     * @param _amount Total amount of token to be swapped
     * @param _token Address of the token to be swapped
     * @param _partner Partner address
     */
    function takeFromTokenFee(uint256 _amount, address _token, address _partner) internal returns (uint256 newAmount) {
        FeeStorage storage fs = _getStorage();

        (uint256 mainFee, uint256 partnerFee) = _calcFees(_amount, _partner);
        registerFee(mainFee, fs.mainPartner, _token);
        if (partnerFee != 0) registerFee(partnerFee, _partner, _token);
        
        newAmount = _amount - (mainFee + partnerFee);
    }

    /**
     * @dev Take fee when crosschain tokens
     * @param _amount Total amount of the tokens to be send to another network
     * @param _partner Address of the partner
     * @param _token Address of the token to be send to another network 
     * @param _crosschainFee Crosschain fee
     * @param _minFee Minimum crosschain fee
     */
    function takeCrosschainFee(
        uint256 _amount,
        address _partner,
        address _token,
        uint256 _crosschainFee,
        uint256 _minFee
    ) internal returns (uint256 newAmount) {
        FeeStorage storage fs = _getStorage();

        (uint256 mainFee, uint256 partnerFee) = _calcCrosschainFees(_amount, _crosschainFee, _minFee, _token, _partner);
        if ((mainFee + partnerFee) > _amount) revert FeeMoreThanAmount(_amount, mainFee + partnerFee);
        registerFee(mainFee, fs.mainPartner, _token);
        if (partnerFee != 0) registerFee(partnerFee, _partner, _token);
        
        newAmount = _amount - (mainFee + partnerFee);
    }  

    /**
     * @dev Calculate fee to be paid
     * @param _amount Amount to be swapped
     * @param _partner Address of the partner
     */
    function _calcFees(uint256 _amount, address _partner) private view returns (uint256, uint256){
        FeeStorage storage fs = _getStorage();
        uint256 totalFee = _amount * fs.mainFee / 10000;

        return _splitFee(totalFee, _partner);
    }

    /**
     * @dev Calculate fee to be paid
     * @param _amount Amount to be send to anothe network 
     * @param _crosschainFee Crosschain fee
     * @param _minFee Minimum crosschain fee
     * @param _token Token to be send to another network
     * @param _partner Address of the partner
     */
    function _calcCrosschainFees(
        uint256 _amount, 
        uint256 _crosschainFee, 
        uint256 _minFee, 
        address _token,
        address _partner
    ) internal view returns (uint256, uint256) {
        uint256 percentFromAmount = _amount * _crosschainFee / 10000;
        
        uint256 decimals = IERC20Decimals(_token).decimals();
        uint256 minFee = _minFee * 10**decimals / 10000;

        uint256 totalFee = percentFromAmount < minFee ? minFee : percentFromAmount;

        return _splitFee(totalFee, _partner);
    }

    /**
     * @dev Splits fee between main partner and additional partner
     */
    function _splitFee(uint256 totalFee, address _partner) private view returns (uint256, uint256) {
        FeeStorage storage fs = _getStorage();

        uint256 mainFee;
        uint256 partnerFee;

        if (LibUtil.isZeroAddress(_partner)) {
            mainFee = totalFee;
            partnerFee = 0;
        } else {
            uint256 partnerFeePercent = fs.isPartner[_partner] 
                ? fs.partnerFeeSharePercent[_partner]
                : fs.defaultPartnerFeeShare;
            partnerFee = totalFee * partnerFeePercent / 10000;
            mainFee = totalFee - partnerFee;
        }  

        return (mainFee, partnerFee);
    }

    /**
     * @dev Registers fee to partner
     */
    function registerFee(uint256 _fee, address _partner, address _token) private {
        FeeStorage storage fs = _getStorage();
        
        fs.feePerToken[_partner][_token] += _fee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { LibAsset } from "./LibAsset.sol";
import { LibUtil } from "./LibUtil.sol";
import { InvalidContract, NoSwapFromZeroBalance, InsufficientBalance } from "../errors/GenericErrors.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAdapter } from '../interfaces/IAdapter.sol';

/// @title Lib Swap
/// @author FormalCrypto
/// @notice Provides functionality to swap tokens
library LibSwap {
    event AssetSwapped(
        address dex,
        address fromAssetId,
        address toAssetId,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 timestamp
    );

    struct SwapData {
        address fromToken;
        address toToken;
        address adapter;
        IAdapter.Route route;
    }

    function swap(uint256 _fromAmount, SwapData calldata _swap, address _weth) internal returns (uint256 receivedAmount) {
        if (_fromAmount == 0) revert NoSwapFromZeroBalance();

        uint256 initialReceivingAssetBalance = LibAsset.getOwnBalance(
            _swap.toToken
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory res) = _swap.adapter.delegatecall(
            abi.encodeWithSelector(
                IAdapter.swap.selector,
                LibAsset.isNativeAsset(_swap.fromToken) ? _weth : _swap.fromToken,
                address(0),
                _fromAmount,
                _swap.route
            )
        );
        if (!success) {
            string memory reason = LibUtil.getRevertMsg(res);
            revert(reason);
        }

        uint256 newBalance = LibAsset.getOwnBalance(_swap.toToken);
        
        receivedAmount = newBalance - initialReceivingAssetBalance;

        emit AssetSwapped(
            _swap.adapter,
            _swap.fromToken,
            _swap.toToken,
            _fromAmount,
            newBalance > initialReceivingAssetBalance
                ? newBalance - initialReceivingAssetBalance
                : newBalance,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./LibBytes.sol";
 
library LibUtil {
    using LibBytes for bytes;

    function getRevertMsg(
        bytes memory _res
    ) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_res.length < 68) return "Transaction reverted silently";
        bytes memory revertData = _res.slice(4, _res.length - 4); // Remove the selector which is the first 4 bytes
        return abi.decode(revertData, (string)); // All that remains is the revert string
    }

    /// @notice Determines whether the given address is the zero address
    /// @param addr The address to verify
    /// @return Boolean indicating if the address is the zero address
    function isZeroAddress(address addr) internal pure returns (bool) {
        return addr == address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ReentrancyGuard
/// @notice Contract to provide protection against reentrancy
abstract contract ReentrancyGuard {
    bytes32 private constant NAMESPACE = keccak256("reentrancy.guard");

    struct ReentrancyStorage {
        uint256 status;
    }

    error ReentrancyError();

    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;
 
    modifier nonReentrant() {
        ReentrancyStorage storage s = reentrancyStorage();
        if (s.status == _ENTERED) revert ReentrancyError();
        s.status = _ENTERED;
        _;
        s.status = _NOT_ENTERED;
    }
    
    /// @dev fetch local storage
    function reentrancyStorage()
        private
        pure
        returns (ReentrancyStorage storage data)
    {
        bytes32 position = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            data.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { LibSwap } from "../libraries/LibSwap.sol";
import { LibAsset } from "../libraries/LibAsset.sol";
import { LibAllowList } from "../libraries/LibAllowList.sol";
import { LibUtil } from '../libraries/LibUtil.sol';
import { CumulativeSlippageTooHigh, ContractCallNotAllowed } from "../errors/GenericErrors.sol";
import { IWETH } from '../interfaces/IWETH.sol';
import { LibFeeCollector } from '../libraries/LibFeeCollector.sol';
import { EmptySwapPath, IncorrectMsgValue, IncorrectWETH } from '../errors/GenericErrors.sol';

/// @title Swapper
/// @author FormalCrypto
/// @notice Contract that provides swap functionality
contract Swapper {
    /**
     * @dev Deposits swaps, executes swaps and perform minimum amount check 
     * @param _fromAmount Amount of tokens to be swapped
     * @param _minAmount Minimum amount of last token to receive
     * @param _weth Address of wrapped native asset(used when swapping native asset)
     * @param _swaps Array of data used to execute swaps
     * @param _nativeReserve Amout of native asset to prevent from being swapped
     * @param _partner Partner address
     */
    function _swap(
        uint256 _fromAmount,
        uint256 _minAmount,
        address _weth,
        LibSwap.SwapData[] calldata _swaps,
        uint256 _nativeReserve,
        address _partner
    ) internal returns (uint256) {
        uint256 numSwaps = _swaps.length;
        uint256 fromAmount = _fromAmount;
        address fromToken = _swaps[0].fromToken;

        if (numSwaps == 0) revert EmptySwapPath();

        address lastToken = _swaps[numSwaps - 1].toToken;
        uint256 initialBalance = LibAsset.getOwnBalance(lastToken);

        if (LibAsset.isNativeAsset(lastToken)) {
            initialBalance -= msg.value;
        }

        if (LibAsset.isNativeAsset(fromToken)) {
            if (LibUtil.isZeroAddress(_weth)) revert IncorrectWETH();
            if (fromAmount + _nativeReserve != msg.value) revert IncorrectMsgValue();
            IWETH(_weth).deposit{value: fromAmount}();
            fromToken = _weth;
        } else {
            LibAsset.depositAsset(fromToken, fromAmount);
        }

        fromAmount = LibFeeCollector.takeFromTokenFee(fromAmount, fromToken, _partner);

        _executeSwaps(_swaps, fromAmount, _weth);

        uint256 receivedAmount;
        if (LibAsset.isNativeAsset(lastToken)) {
            receivedAmount = LibAsset.getOwnBalance(_weth) - initialBalance;
            IWETH(_weth).withdraw(receivedAmount);
        } else {
            receivedAmount = LibAsset.getOwnBalance(lastToken) - initialBalance; 
        }

        if (receivedAmount < _minAmount) revert CumulativeSlippageTooHigh(_minAmount, receivedAmount);

        return receivedAmount;
    }

    /**
     * @dev Executes swaps and checks that adapter is whitelisted
     * @param _swaps Array of data used to execute swaps    
     * @param _fromAmount Amount of tokens to be swapped
     * @param _weth Address of wrapped native asset(used when swapping native asset)
     */
    function _executeSwaps(LibSwap.SwapData[] calldata _swaps, uint256 _fromAmount, address _weth) internal {
        uint256 numSwaps = _swaps.length;
        uint256 receivedAmount;
        for (uint256 i = 0; i < numSwaps; ) {
            LibSwap.SwapData calldata currentSwap = _swaps[i];

            if (
                !((LibAsset.isNativeAsset(currentSwap.fromToken) ||
                    LibAllowList.isContractAllowed(currentSwap.adapter)) &&
                    LibAllowList.isContractAllowed(currentSwap.adapter)
                )
            ) revert ContractCallNotAllowed();

            
            uint256 fromAmount = i > 0 
                ? receivedAmount
                : _fromAmount;

            receivedAmount = LibSwap.swap(
                fromAmount,
                currentSwap,
                _weth
            );

            unchecked {
                ++i;
            }
        }
    }
}