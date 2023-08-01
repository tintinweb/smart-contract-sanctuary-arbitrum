// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// solhint-disable no-unused-import
import { BasePermit2Adapter, IPermit2, Token } from "./base/BasePermit2Adapter.sol";
import {
  IArbitraryExecutionPermit2Adapter,
  ArbitraryExecutionPermit2Adapter
} from "./base/ArbitraryExecutionPermit2Adapter.sol";
import { ISwapPermit2Adapter, SwapPermit2Adapter } from "./base/SwapPermit2Adapter.sol";
// solhint-enable no-unused-import

/**
 * @title Universal Permit2 Adapter
 * @author Sam Bugs
 * @notice This contracts adds Permit2 capabilities to existing contracts by acting as a proxy
 * @dev It's important to note that this contract should never hold any funds outside of the scope of a transaction,
 *      nor should it be granted "regular" ERC20 token approvals. This contract is meant to be used as a proxy, so
 *      the only tokens approved/transferred through Permit2 should be entirely spent in the same transaction.
 *      Any unspent allowance or remaining tokens on the contract can be transferred by anyone, so please be careful!
 */
contract UniversalPermit2Adapter is SwapPermit2Adapter, ArbitraryExecutionPermit2Adapter {
  constructor(IPermit2 _permit2) BasePermit2Adapter(_permit2) { }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import { IBasePermit2Adapter, IPermit2 } from "../interfaces/IBasePermit2Adapter.sol";
import { Token } from "../libraries/Token.sol";

/**
 * @title Base Permit2 Adapter
 * @author Sam Bugs
 * @notice The base contract for Permit2 adapters
 */
abstract contract BasePermit2Adapter is IBasePermit2Adapter {
  /// @inheritdoc IBasePermit2Adapter
  address public constant NATIVE_TOKEN = Token.NATIVE_TOKEN;
  /// @inheritdoc IBasePermit2Adapter
  // solhint-disable-next-line var-name-mixedcase
  IPermit2 public immutable PERMIT2;

  constructor(IPermit2 _permit2) {
    PERMIT2 = _permit2;
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable { }

  modifier checkDeadline(uint256 _deadline) {
    if (block.timestamp > _deadline) revert TransactionDeadlinePassed(block.timestamp, _deadline);
    _;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
// solhint-disable-next-line no-unused-import
import { Permit2Transfers, IPermit2 } from "../libraries/Permit2Transfers.sol";
import { Token, IERC20 } from "../libraries/Token.sol";
import { IArbitraryExecutionPermit2Adapter } from "../interfaces/IArbitraryExecutionPermit2Adapter.sol";
import { BasePermit2Adapter } from "./BasePermit2Adapter.sol";

/**
 * @title Arbitrary Execution Permit2 Adapter
 * @author Sam Bugs
 * @notice This contracts adds Permit2 capabilities to existing contracts by acting as a proxy
 * @dev It's important to note that this contract should never hold any funds outside of the scope of a transaction,
 *      nor should it be granted "regular" ERC20 token approvals. This contract is meant to be used as a proxy, so
 *      the only tokens approved/transferred through Permit2 should be entirely spent in the same transaction.
 *      Any unspent allowance or remaining tokens on the contract can be transferred by anyone, so please be careful!
 */
abstract contract ArbitraryExecutionPermit2Adapter is BasePermit2Adapter, IArbitraryExecutionPermit2Adapter {
  using Permit2Transfers for IPermit2;
  using Token for address;
  using Token for IERC20;
  using Address for address;

  /// @inheritdoc IArbitraryExecutionPermit2Adapter
  function executeWithPermit(
    SinglePermit calldata _permit,
    AllowanceTarget[] calldata _allowanceTargets,
    ContractCall[] calldata _contractCalls,
    TransferOut[] calldata _transferOut,
    uint256 _deadline
  )
    external
    payable
    checkDeadline(_deadline)
    returns (bytes[] memory _executionResults, uint256[] memory _tokenBalances)
  {
    PERMIT2.takeFromCaller(_permit.token, _permit.amount, _permit.nonce, _deadline, _permit.signature);
    return _approveExecuteAndTransfer(_allowanceTargets, _contractCalls, _transferOut);
  }

  /// @inheritdoc IArbitraryExecutionPermit2Adapter
  function executeWithBatchPermit(
    BatchPermit calldata _batchPermit,
    AllowanceTarget[] calldata _allowanceTargets,
    ContractCall[] calldata _contractCalls,
    TransferOut[] calldata _transferOut,
    uint256 _deadline
  )
    external
    payable
    checkDeadline(_deadline)
    returns (bytes[] memory _executionResults, uint256[] memory _tokenBalances)
  {
    PERMIT2.batchTakeFromCaller(_batchPermit.tokens, _batchPermit.nonce, _deadline, _batchPermit.signature);
    return _approveExecuteAndTransfer(_allowanceTargets, _contractCalls, _transferOut);
  }

  function _approveExecuteAndTransfer(
    AllowanceTarget[] calldata _allowanceTargets,
    ContractCall[] calldata _contractCalls,
    TransferOut[] calldata _transferOut
  )
    internal
    returns (bytes[] memory _executionResults, uint256[] memory _tokenBalances)
  {
    // Approve targets
    for (uint256 i; i < _allowanceTargets.length;) {
      IERC20(_allowanceTargets[i].token).maxApprove(_allowanceTargets[i].allowanceTarget);
      unchecked {
        ++i;
      }
    }

    // Call contracts
    _executionResults = new bytes[](_contractCalls.length);
    for (uint256 i; i < _contractCalls.length;) {
      _executionResults[i] =
        _contractCalls[i].target.functionCallWithValue(_contractCalls[i].data, _contractCalls[i].value);
      unchecked {
        ++i;
      }
    }

    // Reset allowance to prevent attacks. Also, we are setting it to 1 instead of 0 for gas optimization
    for (uint256 i; i < _allowanceTargets.length;) {
      IERC20(_allowanceTargets[i].token).setAllowance(_allowanceTargets[i].allowanceTarget, 1);
      unchecked {
        ++i;
      }
    }

    // Distribute tokens
    _tokenBalances = new uint256[](_transferOut.length);
    for (uint256 i; i < _transferOut.length;) {
      _tokenBalances[i] = _transferOut[i].token.distributeTo(_transferOut[i].distribution);
      unchecked {
        ++i;
      }
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
// solhint-disable-next-line no-unused-import
import { Permit2Transfers, IPermit2 } from "../libraries/Permit2Transfers.sol";
import { Token } from "../libraries/Token.sol";
import { ISwapPermit2Adapter } from "../interfaces/ISwapPermit2Adapter.sol";
import { BasePermit2Adapter } from "./BasePermit2Adapter.sol";

/**
 * @title Swap Permit2 Adapter
 * @author Sam Bugs
 * @notice This contracts adds Permit2 capabilities to existing token swap contracts by acting as a proxy. It performs
 *         some extra checks to guarantee that the minimum amounts are respected
 * @dev It's important to note that this contract should never hold any funds outside of the scope of a transaction,
 *      nor should it be granted "regular" ERC20 token approvals. This contract is meant to be used as a proxy, so
 *      the only tokens approved/transferred through Permit2 should be entirely spent in the same transaction.
 *      Any unspent allowance or remaining tokens on the contract can be transferred by anyone, so please be careful!
 */
abstract contract SwapPermit2Adapter is BasePermit2Adapter, ISwapPermit2Adapter {
  using Permit2Transfers for IPermit2;
  using Token for address;
  using Address for address;

  /// @inheritdoc ISwapPermit2Adapter
  function sellOrderSwap(SellOrderSwapParams calldata _params)
    public
    payable
    checkDeadline(_params.deadline)
    returns (uint256 _amountIn, uint256 _amountOut)
  {
    // Take from caller
    PERMIT2.takeFromCaller(_params.tokenIn, _params.amountIn, _params.nonce, _params.deadline, _params.signature);

    // Max approve token in
    _params.tokenIn.maxApproveIfNecessary(_params.allowanceTarget);

    // Execute swap
    _params.swapper.functionCallWithValue(_params.swapData, msg.value);

    // Distribute token out
    _amountOut = _params.tokenOut.distributeTo(_params.transferOut);

    // Check min amount
    if (_amountOut < _params.minAmountOut) revert ReceivedTooLittleTokenOut(_amountOut, _params.minAmountOut);

    // Reset allowance
    _params.tokenIn.setAllowanceIfNecessary(_params.allowanceTarget, 1);

    // Set amount in
    _amountIn = _params.amountIn;
  }

  /// @inheritdoc ISwapPermit2Adapter
  function sellOrderSwapWithGasMeasurement(SellOrderSwapParams calldata _params)
    external
    payable
    returns (uint256 _amountIn, uint256 _amountOut, uint256 _gasSpent)
  {
    uint256 _gasAtStart = gasleft();
    (_amountIn, _amountOut) = sellOrderSwap(_params);
    _gasSpent = _gasAtStart - gasleft();
  }

  /// @inheritdoc ISwapPermit2Adapter
  function buyOrderSwap(BuyOrderSwapParams calldata _params)
    public
    payable
    checkDeadline(_params.deadline)
    returns (uint256 _amountIn, uint256 _amountOut)
  {
    // Take from caller
    PERMIT2.takeFromCaller(_params.tokenIn, _params.maxAmountIn, _params.nonce, _params.deadline, _params.signature);

    // Max approve token in
    _params.tokenIn.maxApproveIfNecessary(_params.allowanceTarget);

    // Execute swap
    _params.swapper.functionCallWithValue(_params.swapData, msg.value);

    // Check balance for unspent tokens
    uint256 _unspentTokenIn = _params.tokenIn.balanceOnContract();

    // Distribute token out
    _amountOut = _params.tokenOut.distributeTo(_params.transferOut);

    // Check min amount
    if (_amountOut < _params.amountOut) revert ReceivedTooLittleTokenOut(_amountOut, _params.amountOut);

    // Send unspent to the set recipient
    _params.tokenIn.sendAmountTo(_unspentTokenIn, _params.unspentTokenInRecipient);

    // Reset allowance
    _params.tokenIn.setAllowanceIfNecessary(_params.allowanceTarget, 1);

    // Set amount in
    _amountIn = _params.maxAmountIn - _unspentTokenIn;
  }

  /// @inheritdoc ISwapPermit2Adapter
  function buyOrderSwapWithGasMeasurement(BuyOrderSwapParams calldata _params)
    external
    payable
    returns (uint256 _amountIn, uint256 _amountOut, uint256 _gasSpent)
  {
    uint256 _gasAtStart = gasleft();
    (_amountIn, _amountOut) = buyOrderSwap(_params);
    _gasSpent = _gasAtStart - gasleft();
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import { IPermit2 } from "./external/IPermit2.sol";

/// @notice The interface all Permit2 adapters should implement
interface IBasePermit2Adapter {
  /**
   * @notice Thrown when a transaction deadline has passed
   * @param current The current time
   * @param deadline The set deadline
   */
  error TransactionDeadlinePassed(uint256 current, uint256 deadline);

  /**
   * @notice Returns the address that represents the native token
   * @dev This value is constant and cannot change
   * @return The address that represents the native token
   */
  function NATIVE_TOKEN() external view returns (address);

  /**
   * @notice Returns the address of the Permit2 contract
   * @dev This value is constant and cannot change
   * @return The address of the Permit2 contract
   */
  function PERMIT2() external view returns (IPermit2);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Token Library
 * @author Sam Bugs
 * @notice A small library that contains helpers for tokens (both ERC20 and native)
 */
library Token {
  using SafeERC20 for IERC20;
  using Address for address payable;
  using Address for address;

  /// @notice A specific target to distribute tokens to
  struct DistributionTarget {
    address recipient;
    uint256 shareBps;
  }

  address public constant NATIVE_TOKEN = address(0);

  /**
   * @notice Calculates the amount of token balance held by the contract
   * @param _token The token to check
   * @return _balance The current balance held by the contract
   */
  function balanceOnContract(address _token) internal view returns (uint256 _balance) {
    return _token == NATIVE_TOKEN ? address(this).balance : IERC20(_token).balanceOf(address(this));
  }

  /**
   * @notice Performs a max approval to the allowance target, for the given token
   * @param _token The token to approve
   * @param _allowanceTarget The spender that will be approved
   */
  function maxApprove(IERC20 _token, address _allowanceTarget) internal {
    setAllowance(_token, _allowanceTarget, type(uint256).max);
  }

  /**
   * @notice Performs an approval to the allowance target, for the given token and amount
   * @param _token The token to approve
   * @param _allowanceTarget The spender that will be approved
   * @param _amount The allowance to set
   */
  function setAllowance(IERC20 _token, address _allowanceTarget, uint256 _amount) internal {
    // This helper should handle cases like USDT. Thanks OZ!
    _token.forceApprove(_allowanceTarget, _amount);
  }

  /**
   * @notice Performs a max approval to the allowance target for the given token, as long as the token is not
   *         the native token, and the allowance target is not the zero address
   * @param _token The token to approve
   * @param _allowanceTarget The spender that will be approved
   */
  function maxApproveIfNecessary(address _token, address _allowanceTarget) internal {
    setAllowanceIfNecessary(_token, _allowanceTarget, type(uint256).max);
  }

  /**
   * @notice Performs an approval to the allowance target for the given token and amount, as long as the token is not
   *         the native token, and the allowance target is not the zero address
   * @param _token The token to approve
   * @param _allowanceTarget The spender that will be approved
   * @param _amount The allowance to set
   */
  function setAllowanceIfNecessary(address _token, address _allowanceTarget, uint256 _amount) internal {
    if (_token != NATIVE_TOKEN && _allowanceTarget != address(0)) {
      setAllowance(IERC20(_token), _allowanceTarget, _amount);
    }
  }

  /**
   * @notice Distributes the available amount of the given token according to the set distribution. All tokens
   *         will be distributed according to the configured shares. The last target will get sent all unassigned
   *         tokens
   * @param _token The token to distribute
   * @param _distribution How to distribute the available amount of the token. Must have at least one target
   */
  function distributeTo(
    address _token,
    DistributionTarget[] calldata _distribution
  )
    internal
    returns (uint256 _available)
  {
    _available = balanceOnContract(_token);
    uint256 _amountLeft = _available;

    // Distribute amounts
    for (uint256 i; i < _distribution.length - 1;) {
      uint256 _toSend = _available * _distribution[i].shareBps / 10_000;
      sendAmountTo(_token, _toSend, _distribution[i].recipient);
      _amountLeft -= _toSend;
      unchecked {
        ++i;
      }
    }

    // Send amount left to the last recipient
    sendAmountTo(_token, _amountLeft, _distribution[_distribution.length - 1].recipient);
  }

  /**
   * @notice Checks if the contract has any balance of the given token, and if it does,
   *         it sends it to the given recipient
   * @param _token The token to check
   * @param _recipient The recipient of the token balance
   * @return _balance The current balance held by the contract
   */
  function sendBalanceOnContractTo(address _token, address _recipient) internal returns (uint256 _balance) {
    _balance = balanceOnContract(_token);
    sendAmountTo(_token, _balance, _recipient);
  }

  /**
   * @notice Transfers the given amount of tokens from the contract to the recipient
   * @param _token The token to check
   * @param _amount The amount to send
   * @param _recipient The recipient
   */
  function sendAmountTo(address _token, uint256 _amount, address _recipient) internal {
    if (_amount > 0) {
      if (_recipient == address(0)) _recipient = msg.sender;
      if (_token == NATIVE_TOKEN) {
        payable(_recipient).sendValue(_amount);
      } else {
        IERC20(_token).safeTransfer(_recipient, _amount);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with a
     * `customRevert` function as a fallback when `target` reverts.
     *
     * Requirements:
     *
     * - `customRevert` must be a reverting function.
     *
     * _Available since v5.0._
     */
    function functionCall(
        address target,
        bytes memory data,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, customRevert);
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
        return functionCallWithValue(target, data, value, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with a `customRevert` function as a fallback revert reason when `target` reverts.
     *
     * Requirements:
     *
     * - `customRevert` must be a reverting function.
     *
     * _Available since v5.0._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        function() internal view customRevert
    ) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, defaultRevert);
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
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, defaultRevert);
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
        function() internal view customRevert
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, customRevert);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided `customRevert`) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v5.0._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check if target is a contract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                if (target.code.length == 0) {
                    revert AddressEmptyCode(target);
                }
            }
            return returndata;
        } else {
            _revert(returndata, customRevert);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or with a default revert error.
     *
     * _Available since v5.0._
     */
    function verifyCallResult(bool success, bytes memory returndata) internal view returns (bytes memory) {
        return verifyCallResult(success, returndata, defaultRevert);
    }

    /**
     * @dev Same as {xref-Address-verifyCallResult-bool-bytes-}[`verifyCallResult`], but with a
     * `customRevert` function as a fallback when `success` is `false`.
     *
     * Requirements:
     *
     * - `customRevert` must be a reverting function.
     *
     * _Available since v5.0._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        function() internal view customRevert
    ) internal view returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, customRevert);
        }
    }

    /**
     * @dev Default reverting function when no `customRevert` is provided in a function call.
     */
    function defaultRevert() internal pure {
        revert FailedInnerCall();
    }

    function _revert(bytes memory returndata, function() internal view customRevert) private view {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            customRevert();
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import { IPermit2 } from "../interfaces/external/IPermit2.sol";
import { Token } from "./Token.sol";

/**
 * @title Permit2 Transfers Library
 * @author Sam Bugs
 * @notice A small library to call Permit2's transfer from methods
 */
library Permit2Transfers {
  /**
   * @notice Thrown when received an inexpected amount of native token
   * @param received The amount of native token received
   * @param expected The amount of token out expected
   */
  error InvalidNativeAmount(uint256 received, uint256 expected);

  /**
   * @notice Executes a transfer from using Permit2
   * @param _permit2 The Permit2 contract
   * @param _token The token to transfer
   * @param _amount The amount to transfer
   * @param _nonce The owner's nonce
   * @param _deadline The signature's expiration deadline
   * @param _signature The signature that allows the transfer
   */
  function takeFromCaller(
    IPermit2 _permit2,
    address _token,
    uint256 _amount,
    uint256 _nonce,
    uint256 _deadline,
    bytes calldata _signature
  )
    internal
  {
    if (address(_token) != Token.NATIVE_TOKEN) {
      _permit2.permitTransferFrom(
        // The permit message.
        IPermit2.PermitTransferFrom({
          permitted: IPermit2.TokenPermissions({ token: _token, amount: _amount }),
          nonce: _nonce,
          deadline: _deadline
        }),
        // The transfer recipient and amount.
        IPermit2.SignatureTransferDetails({ to: address(this), requestedAmount: _amount }),
        // The owner of the tokens, which must also be
        // the signer of the message, otherwise this call
        // will fail.
        msg.sender,
        // The packed signature that was the result of signing
        // the EIP712 hash of `permit`.
        _signature
      );
    } else if (msg.value != _amount) {
      revert InvalidNativeAmount(msg.value, _amount);
    }
  }

  /**
   * @notice Executes a batch transfer from using Permit2
   * @param _permit2 The Permit2 contract
   * @param _tokens The amount of tokens to transfer
   * @param _nonce The owner's nonce
   * @param _deadline The signature's expiration deadline
   * @param _signature The signature that allows the transfer
   */
  function batchTakeFromCaller(
    IPermit2 _permit2,
    IPermit2.TokenPermissions[] calldata _tokens,
    uint256 _nonce,
    uint256 _deadline,
    bytes calldata _signature
  )
    internal
  {
    if (_tokens.length > 0) {
      _permit2.permitTransferFrom(
        // The permit message.
        IPermit2.PermitBatchTransferFrom({ permitted: _tokens, nonce: _nonce, deadline: _deadline }),
        // The transfer recipients and amounts.
        _buildTransferDetails(_tokens),
        // The owner of the tokens, which must also be
        // the signer of the message, otherwise this call
        // will fail.
        msg.sender,
        // The packed signature that was the result of signing
        // the EIP712 hash of `permit`.
        _signature
      );
    }
  }

  function _buildTransferDetails(IPermit2.TokenPermissions[] calldata _tokens)
    private
    view
    returns (IPermit2.SignatureTransferDetails[] memory _details)
  {
    _details = new IPermit2.SignatureTransferDetails[](_tokens.length);
    for (uint256 i; i < _details.length;) {
      _details[i] = IPermit2.SignatureTransferDetails({ to: address(this), requestedAmount: _tokens[i].amount });
      unchecked {
        ++i;
      }
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import { Token } from "../libraries/Token.sol";
import { IBasePermit2Adapter, IPermit2 } from "./IBasePermit2Adapter.sol";

interface IArbitraryExecutionPermit2Adapter is IBasePermit2Adapter {
  /// @notice Data necessary to execute a single permit transfer
  struct SinglePermit {
    address token;
    uint256 amount;
    uint256 nonce;
    bytes signature;
  }

  /// @notice Data necessary to execute a batch permit transfer
  struct BatchPermit {
    IPermit2.TokenPermissions[] tokens;
    uint256 nonce;
    bytes signature;
  }

  /// @notice Allowance target for a specific token
  struct AllowanceTarget {
    address token;
    address allowanceTarget;
  }

  /// @notice A specific contract call
  struct ContractCall {
    address target;
    bytes data;
    uint256 value;
  }

  /// @notice A token and how to distribute it
  struct TransferOut {
    address token;
    Token.DistributionTarget[] distribution;
  }

  /**
   * @notice Executes arbitrary calls by proxing to another contracts, but using Permit2 to transfer tokens from the
   *         caller
   * @param permit The permit data to use to transfer tokens from the user
   * @param allowanceTargets The contracts to approve before executing calls
   * @param contractCalls The calls to execute
   * @param transferOut The tokens to transfer out of our contract after all calls have been executed. Note that each
   *                    element of the array should handle different tokens
   * @param deadline The max time where this call can be executed
   * @return executionResults The results of each contract call
   * @return tokenBalances The balances held by the contract after contract calls were executed
   */
  function executeWithPermit(
    SinglePermit calldata permit,
    AllowanceTarget[] calldata allowanceTargets,
    ContractCall[] calldata contractCalls,
    TransferOut[] calldata transferOut,
    uint256 deadline
  )
    external
    payable
    returns (bytes[] memory executionResults, uint256[] memory tokenBalances);

  /**
   * @notice Executes arbitrary calls by proxing to another contracts, but using Permit2 to transfer tokens from the
   *         caller
   * @param batchPermit The permit data to use to batch transfer tokens from the user
   * @param allowanceTargets The contracts to approve before executing calls
   * @param contractCalls The calls to execute
   * @param transferOut The tokens to transfer out of our contract after all calls have been executed
   * @param deadline The max time where this call can be executed
   * @return executionResults The results of each contract call
   * @return tokenBalances The balances held by the contract after contract calls were executed
   */
  function executeWithBatchPermit(
    BatchPermit calldata batchPermit,
    AllowanceTarget[] calldata allowanceTargets,
    ContractCall[] calldata contractCalls,
    TransferOut[] calldata transferOut,
    uint256 deadline
  )
    external
    payable
    returns (bytes[] memory executionResults, uint256[] memory tokenBalances);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import { Token } from "../libraries/Token.sol";
import { IBasePermit2Adapter } from "./IBasePermit2Adapter.sol";

interface ISwapPermit2Adapter is IBasePermit2Adapter {
  /**
   * @notice Thrown when the swap produced less token out than expected
   * @param received The amount of token out received
   * @param expected The amount of token out expected
   */
  error ReceivedTooLittleTokenOut(uint256 received, uint256 expected);

  /// @notice Swap params for a sell order
  struct SellOrderSwapParams {
    // Deadline
    uint256 deadline;
    // Take from caller
    address tokenIn;
    uint256 amountIn;
    uint256 nonce;
    bytes signature;
    // Swap approval
    address allowanceTarget;
    // Swap execution
    address swapper;
    bytes swapData;
    // Swap validation
    address tokenOut;
    uint256 minAmountOut;
    // Transfer token out
    Token.DistributionTarget[] transferOut;
  }

  // @notice Swap params for a buy order
  struct BuyOrderSwapParams {
    // Deadline
    uint256 deadline;
    // Take from caller
    address tokenIn;
    uint256 maxAmountIn;
    uint256 nonce;
    bytes signature;
    // Swap approval
    address allowanceTarget;
    // Swap execution
    address swapper;
    bytes swapData;
    // Swap validation
    address tokenOut;
    uint256 amountOut;
    // Transfer token out
    Token.DistributionTarget[] transferOut;
    // Transfer token in
    address unspentTokenInRecipient;
  }

  /**
   * @notice Executes a sell order swap by proxing to another contract, but using Permit2 to transfer tokens from the
   * caller
   * @param params The swap's data, such as tokens, amounts, recipient, etc
   * @return amountIn The amount ot `token in` spent on the swap
   * @return amountOut The amount of `token out` produced by the proxied swap
   */
  function sellOrderSwap(SellOrderSwapParams calldata params)
    external
    payable
    returns (uint256 amountIn, uint256 amountOut);

  /**
   * @notice Executes a sell order swap by proxing to another contract, but using Permit2 to transfer tokens from the
   * caller
   * @dev Not meant to be used on-chain! The idea behind this function is to have a way to simulate a swap and get
   *      amount in spent, the amount out received, and the gas spent on the swap. All in one RPC call
   * @param params The swap's data, such as tokens, amounts, recipient, etc
   * @return amountIn The amount ot `token in` spent on the swap
   * @return amountOut The amount of `token out` produced by the proxied swap
   * @return gasSpent The gas spent on the entire swap
   */
  function sellOrderSwapWithGasMeasurement(SellOrderSwapParams calldata params)
    external
    payable
    returns (uint256 amountIn, uint256 amountOut, uint256 gasSpent);

  /**
   * @notice Executes a buy order swap by proxing to another contract, but using Permit2 to transfer tokens from the
   * caller
   * @param params The swap's data, such as tokens, amounts, recipient, etc
   * @return amountIn The amount ot `token in` spent on the swap
   * @return amountOut The amount of `token out` produced by the proxied swap
   */
  function buyOrderSwap(BuyOrderSwapParams calldata params)
    external
    payable
    returns (uint256 amountIn, uint256 amountOut);

  /**
   * @notice Executes a buy order swap by proxing to another contract, but using Permit2 to transfer tokens from the
   * caller
   * @dev Not meant to be used on-chain! The idea behind this function is to have a way to simulate a swap and get
   *      amount in spent, the amount out received, and the gas spent on the swap. All in one RPC call
   * @param params The swap's data, such as tokens, amounts, recipient, etc
   * @return amountIn The amount ot `token in` spent on the swap
   * @return amountOut The amount of `token out` produced by the proxied swap
   * @return gasSpent The gas spent on the entire swap
   */
  function buyOrderSwapWithGasMeasurement(BuyOrderSwapParams calldata params)
    external
    payable
    returns (uint256 amountIn, uint256 amountOut, uint256 gasSpent);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// Minimal Permit2 interface, derived from
// https://github.com/Uniswap/permit2/blob/main/src/interfaces/ISignatureTransfer.sol
interface IPermit2 {
  struct TokenPermissions {
    address token;
    uint256 amount;
  }

  struct PermitTransferFrom {
    TokenPermissions permitted;
    uint256 nonce;
    uint256 deadline;
  }

  struct PermitBatchTransferFrom {
    TokenPermissions[] permitted;
    uint256 nonce;
    uint256 deadline;
  }

  struct SignatureTransferDetails {
    address to;
    uint256 requestedAmount;
  }

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function permitTransferFrom(
    PermitTransferFrom calldata permit,
    SignatureTransferDetails calldata transferDetails,
    address owner,
    bytes calldata signature
  )
    external;

  function permitTransferFrom(
    PermitBatchTransferFrom memory permit,
    SignatureTransferDetails[] calldata transferDetails,
    address owner,
    bytes calldata signature
  )
    external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.19;

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
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
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
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
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
        if (nonceAfter != nonceBefore + 1) {
            revert SafeERC20FailedOperation(address(token));
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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

pragma solidity ^0.8.19;

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