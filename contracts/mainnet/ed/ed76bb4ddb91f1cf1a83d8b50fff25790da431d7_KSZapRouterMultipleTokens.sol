// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {KSZapRouter, IZapExecutor, IZapValidator} from './KSZapRouter.sol';
import {IKSZapRouterMultipleTokens} from './interfaces/IKSZapRouterMultipleTokens.sol';

/// @notice Main KyberSwap Zap Router to allow users zapping into any dexes with multiple tokens
/// @dev Improved version of KSZapRouter that supports zap in with multiple tokens
contract KSZapRouterMultipleTokens is KSZapRouter, IKSZapRouterMultipleTokens {
  /// @dev convention for native token address
  address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

  /// @inheritdoc	IKSZapRouterMultipleTokens
  function zapInMultiple(
    ZapMultipleDescription calldata _desc,
    ZapExecutionData calldata _exe
  )
    external
    override
    whenNotPaused
    nonReentrant
    checkDeadline(_exe.deadline)
    returns (bytes memory zapResults)
  {
    uint256 len = _desc.srcTokens.length;
    require(len == _desc.srcAmounts.length && len > 0, 'Invalid token length');
    require(_desc.permitData.length == 0 || _desc.permitData.length == len, 'Invalid permit length');

    for (uint256 i; i < len;) {
      _handleCollectToken(
        _desc.srcTokens[i],
        _desc.srcAmounts[i],
        _exe.executor,
        false,
        _desc.permitData.length == 0 ? new bytes(0) : _desc.permitData[i]
      );

      unchecked {
        ++i;
      }
    }

    zapResults = _executeZapMultiple(_desc, _exe);
  }

  /// @inheritdoc	IKSZapRouterMultipleTokens
  function zapInMultipleWithNative(
    ZapMultipleDescription calldata _desc,
    ZapExecutionData calldata _exe
  )
    external
    payable
    override
    whenNotPaused
    nonReentrant
    checkDeadline(_exe.deadline)
    returns (bytes memory zapResults)
  {
    uint256 remainningValue = msg.value;
    uint256 len = _desc.srcTokens.length;
    require(len == _desc.srcAmounts.length && len > 0, 'Invalid token length');
    require(_desc.permitData.length == 0 || _desc.permitData.length == len, 'Invalid permit length');

    for (uint256 i; i < len;) {
      bool isNative = address(_desc.srcTokens[i]) == ETH_ADDRESS;
      if (isNative) {
        // There wont be more than 1 srcToken which is ETH_ADDRESS and has srcAmount > 0
        require(
          _desc.srcAmounts[i] == remainningValue && _desc.srcAmounts[i] > 0, 'Invalid source amount'
        );
        remainningValue = 0;
      }
      _handleCollectToken(
        _desc.srcTokens[i],
        _desc.srcAmounts[i],
        _exe.executor,
        isNative,
        (isNative || _desc.permitData.length == 0) ? new bytes(0) : _desc.permitData[i]
      );

      unchecked {
        ++i;
      }
    }

    // By this check, it is enforced that caller should either use correct native token amount or not use native token at all
    require(remainningValue == 0, 'Invalid ETH amount');

    zapResults = _executeZapMultiple(_desc, _exe);
  }

  function _executeZapMultiple(
    ZapMultipleDescription calldata _desc,
    ZapExecutionData calldata _exe
  ) internal returns (bytes memory zapResults) {
    // getting initial data before zapping
    bytes memory initialData;
    if (_exe.validator != address(0)) {
      require(whitelistedValidator[_exe.validator], 'none whitelist validator');
      initialData =
        IZapValidator(_exe.validator).prepareValidationData(_desc.dexType, _desc.zapInfo);
    }

    // calling executor to execute the zap logic
    zapResults = IZapExecutor(_exe.executor).executeZapIn{value: msg.value}(_exe.executorData);

    // validate data after zapping if needed
    if (_exe.validator != address(0)) {
      bool isValid = IZapValidator(_exe.validator).validateData(
        _desc.dexType, _desc.extraData, initialData, zapResults
      );
      require(isValid, 'validation failed');
    }

    emit ZapMultipleExecuted(
      _desc.dexType,
      _desc.srcTokens,
      _desc.srcAmounts,
      _exe.validator,
      _exe.executor,
      _desc.zapInfo,
      _desc.extraData,
      initialData,
      zapResults
    );
    emit ClientData(_exe.clientData);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {KSRescue} from 'ks-growth-utils-sc/contracts/KSRescue.sol';

import {Permitable} from 'contracts/common/Permitable.sol';
import {IKSZapRouter} from 'contracts/interfaces/IKSZapRouter.sol';
import {IZapValidator} from 'contracts/interfaces/zap/validators/IZapValidator.sol';
import {IZapExecutor} from 'contracts/interfaces/zap/executors/IZapExecutor.sol';

import {IERC20} from 'openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from 'openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ReentrancyGuard} from 'openzeppelin/contracts/security/ReentrancyGuard.sol';

/// @notice Main KyberSwap Zap Router to allow users zapping into any dexes
/// It uses Validator to validate the zap result with flexibility, to enable adding more dexes
contract KSZapRouter is IKSZapRouter, Permitable, KSRescue, ReentrancyGuard {
  using SafeERC20 for IERC20;

  mapping(address => bool) public whitelistedExecutor;
  mapping(address => bool) public whitelistedValidator;

  modifier checkDeadline(uint32 _deadline) {
    require(block.timestamp <= _deadline, 'expired');
    _;
  }

  constructor() {}

  /// ==================== Owner ====================
  /// @notice Whitelist executors by the owner, can grant or revoke
  function whitelistExecutors(
    address[] calldata _executors,
    bool _grantOrRevoke
  ) external onlyOwner {
    for (uint256 i = 0; i < _executors.length; i++) {
      whitelistedExecutor[_executors[i]] = _grantOrRevoke;
      emit ExecutorWhitelisted(_executors[i], _grantOrRevoke);
    }
  }

  /// @notice Whitelist validators by the owner, can grant or revoke
  function whitelistValidators(
    address[] calldata _validators,
    bool _grantOrRevoke
  ) external onlyOwner {
    for (uint256 i = 0; i < _validators.length; i++) {
      whitelistedValidator[_validators[i]] = _grantOrRevoke;
      emit ValidatorWhitelisted(_validators[i], _grantOrRevoke);
    }
  }

  /// @inheritdoc IKSZapRouter
  function zapIn(
    ZapDescription calldata _desc,
    ZapExecutionData calldata _exe
  )
    external
    override
    whenNotPaused
    nonReentrant
    checkDeadline(_exe.deadline)
    returns (bytes memory zapResults)
  {
    _handleCollectToken(_desc.srcToken, _desc.srcAmount, _exe.executor, false, _desc.permitData);
    zapResults = _executeZap(_desc, _exe);
  }

  /// @inheritdoc IKSZapRouter
  function zapInWithNative(
    ZapDescription calldata _desc,
    ZapExecutionData calldata _exe
  )
    external
    payable
    override
    whenNotPaused
    nonReentrant
    checkDeadline(_exe.deadline)
    returns (bytes memory zapResults)
  {
    _handleCollectToken(_desc.srcToken, _desc.srcAmount, _exe.executor, true, new bytes(0));
    zapResults = _executeZap(_desc, _exe);
  }

  function _executeZap(
    ZapDescription calldata _desc,
    ZapExecutionData calldata _exe
  ) internal returns (bytes memory zapResults) {
    // getting initial data before zapping
    bytes memory initialData;
    if (_exe.validator != address(0)) {
      require(whitelistedValidator[_exe.validator], 'none whitelist validator');
      initialData =
        IZapValidator(_exe.validator).prepareValidationData(_desc.dexType, _desc.zapInfo);
    }

    // calling executor to execute the zap logic
    zapResults = IZapExecutor(_exe.executor).executeZapIn{value: msg.value}(_exe.executorData);

    // validate data after zapping if needed
    if (_exe.validator != address(0)) {
      bool isValid = IZapValidator(_exe.validator).validateData(
        _desc.dexType, _desc.extraData, initialData, zapResults
      );
      require(isValid, 'validation failed');
    }

    emit ZapExecuted(
      _desc.dexType,
      _desc.srcToken,
      _desc.srcAmount,
      _exe.validator,
      _exe.executor,
      _desc.zapInfo,
      _desc.extraData,
      initialData,
      zapResults
    );
    emit ClientData(_exe.clientData);
  }

  /// @notice Handle collecting token and transfer to executor
  function _handleCollectToken(
    IERC20 _token,
    uint256 _amount,
    address _executor,
    bool _isNative,
    bytes memory _permitData
  ) internal {
    // executor should be whitelisted
    require(whitelistedExecutor[_executor], 'none whitelist executor');
    if (!_isNative) {
      // not using native
      if (_permitData.length > 0) {
        // possibly using permit
        _permit(_token, _amount, _permitData);
      }
      // now collecting token to the recipient, i.e executor
      _token.safeTransferFrom(msg.sender, _executor, _amount);
      // event (token, amount, isNative, isPermit)
      emit TokenCollected(_token, _amount, false, _permitData.length > 0);
      return;
    }

    // using native, validate amount, token address should be validated in the Executor
    require(msg.value == _amount, 'wrong msg.value');
    emit TokenCollected(_token, _amount, true, false);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IERC20} from 'openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IKSZapRouter} from './IKSZapRouter.sol';

interface IKSZapRouterMultipleTokens is IKSZapRouter {
  event ZapMultipleExecuted(
    uint8 indexed _dexType,
    IERC20[] indexed _srcToken,
    uint256[] indexed _srcAmount,
    address _validator,
    address _executor,
    bytes _zapInfo,
    bytes _extraData,
    bytes _initialData,
    bytes _zapResults
  );

  /// @notice Contains general data for zapping and validation
  /// @dev `srcTokens` and `srcAmounts` must have length > 0 and have equal length.
  /// Set list `permitData` empty when no permit usage, otherwise its length must equal to length of `srcTokens`.
  /// @param dexType dex id to interact with, following DexType in IZapDexEnum
  /// @param srcTokens list of tokens to be used for zapping
  /// @param srcAmounts list of amounts to be used for zapping
  /// @param zapInfo extra info, depends on each dex type
  /// @param extraData extra data to be used for validation
  /// @param permitData list of permit data only when using permit for corresponding src tokens.
  struct ZapMultipleDescription {
    uint8 dexType;
    IERC20[] srcTokens;
    uint256[] srcAmounts;
    bytes zapInfo;
    bytes extraData;
    bytes[] permitData;
  }

  /// @notice Zap In with given data
  /// @dev `_desc.permitData` should have length of 0 or equal to `_desc.srcTokens`
  /// @param _desc See struct `IKSZapRouterMultipleTokens#ZapMultipleDescription`
  /// @param _exe See struct `IKSZapRouter#ZapExecutionData`
  /// @return zapResults result from execution
  function zapInMultiple(
    ZapMultipleDescription calldata _desc,
    ZapExecutionData calldata _exe
  ) external returns (bytes memory zapResults);

  /// @notice Zap In with given data using native token as one of tokens in the list, returns the zapResults from execution
  /// @dev `srcTokens` and `srcAmounts` must have length > 0 and have equal length.
  /// Set list `permitData` empty when no permit usage, otherwise its length must equal to length of `srcTokens`.
  /// Use `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` to specify native token.
  /// @param _desc See struct `IKSZapRouterMultipleTokens#ZapMultipleDescription`
  /// @param _exe See struct `IKSZapRouter#ZapExecutionData`
  /// @return zapResults result from execution
  function zapInMultipleWithNative(
    ZapMultipleDescription calldata _desc,
    ZapExecutionData calldata _exe
  ) external payable returns (bytes memory zapResults);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {KyberSwapRole} from '@src/KyberSwapRole.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

abstract contract KSRescue is KyberSwapRole {
  using SafeERC20 for IERC20;

  address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

  function rescueFunds(address token, uint256 amount, address recipient) external onlyOwner {
    require(recipient != address(0), 'KSRescue: invalid recipient');
    if (amount == 0) amount = _getAvailableAmount(token);
    if (amount > 0) {
      if (_isETH(token)) {
        (bool success,) = recipient.call{value: amount}('');
        require(success, 'KSRescue: ETH_TRANSFER_FAILED');
      } else {
        IERC20(token).safeTransfer(recipient, amount);
      }
    }
  }

  function _getAvailableAmount(address token) internal view virtual returns (uint256 amount) {
    if (_isETH(token)) {
      amount = address(this).balance;
    } else {
      amount = IERC20(token).balanceOf(address(this));
    }
    if (amount > 0) --amount;
  }

  function _isETH(address token) internal pure returns (bool) {
    return (token == ETH_ADDRESS);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from 'openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC20Permit} from 'openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol';

import {RevertReasonParser} from 'contracts/common/RevertReasonParser.sol';

/*
“Copyright (c) 2019-2021 1inch 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions: 
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software. 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE”.
*/

contract Permitable {
  event Error(string reason);

  function _permit(IERC20 token, uint256 amount, bytes memory permit) internal {
    if (permit.length == 32 * 7) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory result) =
        address(token).call(abi.encodePacked(IERC20Permit.permit.selector, permit));
      if (!success) {
        string memory reason = RevertReasonParser.parse(result, 'Permit call failed: ');
        if (token.allowance(msg.sender, address(this)) < amount) {
          revert(reason);
        } else {
          emit Error(reason);
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IERC20} from 'openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IKSZapRouter {
  event ClientData(bytes _clientData);
  event ZapExecuted(
    uint8 indexed _dexType,
    IERC20 indexed _srcToken,
    uint256 indexed _srcAmount,
    address _validator,
    address _executor,
    bytes _zapInfo,
    bytes _extraData,
    bytes _initialData,
    bytes _zapResults
  );
  event ExecutorWhitelisted(address indexed _executor, bool indexed _grantOrRevoke);
  event ValidatorWhitelisted(address indexed _validator, bool indexed _grantOrRevoke);
  event TokenCollected(IERC20 _token, uint256 _amount, bool _isNative, bool _isPermit);

  /// @notice Contains general data for zapping and validation
  /// @param dexType dex id to interact with, following DexType in IZapDexEnum
  /// @param srcToken token to be used for zapping
  /// @param srcAmount amount to be used for zapping
  /// @param zapInfo extra info, depends on each dex type
  /// @param extraData extra data to be used for validation
  /// @param permitData only when using permit for src token
  struct ZapDescription {
    uint8 dexType;
    IERC20 srcToken;
    uint256 srcAmount;
    bytes zapInfo;
    bytes extraData;
    bytes permitData;
  }

  /// @notice Contains execution data for zapping
  /// @param validator validator address, must be whitelisted one
  /// @param executor zap executor address, must be whitelisted one
  /// @param deadline make sure the request is not expired yet
  /// @param executorData data for zap execution
  /// @param clientData for events and tracking purposes
  struct ZapExecutionData {
    address validator;
    address executor;
    uint32 deadline;
    bytes executorData;
    bytes clientData;
  }

  /// @notice Zap In with given data, returns the zapResults from execution
  function zapIn(
    ZapDescription calldata _desc,
    ZapExecutionData calldata _exe
  ) external returns (bytes memory zapResults);

  /// @notice Zap In with given data using native token, returns the zapResults from execution
  function zapInWithNative(
    ZapDescription calldata _desc,
    ZapExecutionData calldata _exe
  ) external payable returns (bytes memory zapResults);

  function whitelistExecutors(address[] calldata _executors, bool _grantOrRevoke) external;
  function whitelistValidators(address[] calldata _validators, bool _grantOrRevoke) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IZapDexEnum} from 'contracts/interfaces/zap/common/IZapDexEnum.sol';

interface IZapValidator is IZapDexEnum {
  function prepareValidationData(
    uint8 _dexType,
    bytes calldata _zapInfo
  ) external view returns (bytes memory validationData);

  function validateData(
    uint8 _dexType,
    bytes calldata _extraData,
    bytes calldata _initialData,
    bytes calldata _zapResults
  ) external view returns (bool isValid);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IZapDexEnum} from 'contracts/interfaces/zap/common/IZapDexEnum.sol';
import {IERC20} from 'openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IZapExecutor is IZapDexEnum {
  event SwappedWithAggregator(
    address srcToken, address dstToken, uint256 amountIn, uint256 amountOut
  );
  event SwappedWithElastic(
    address pool, address srcToken, address dstToken, uint256 spentAmount, uint256 returnedAmount
  );
  event SwappedWithUniswapv3(
    address pool, address srcToken, address dstToken, uint256 spentAmount, uint256 returnedAmount
  );
  event MintedPosition(
    uint256 posID,
    int24 tickLower,
    int24 tickUpper,
    uint128 liquidity,
    uint256 usedAmount0,
    uint256 usedAmount1
  );
  event AddLiquidityPosition(
    uint256 posID, uint128 liquidity, uint256 usedAmount0, uint256 usedAmount1
  );

  event ZapExecuted(
    uint8 indexed _dexType,
    address indexed _srcToken,
    uint256 indexed _srcAmount,
    bool _useAggregator,
    bytes _zapResults
  );
  event KSElasticZapExecuted(
    address indexed _pool, uint256 indexed _posID, address indexed _recipient, uint128 _liquidity
  );
  event Uniswapv3ZapExecuted(
    address indexed _pool,
    uint256 indexed _posID,
    address indexed _recipient,
    uint128 _liquidity,
    uint256 usedAmount,
    uint256 remainAmount0,
    uint256 remmainAmount1
  );
  /// @notice Event for collecting fees, it may collect dust tokens in the contract as well
  /// @param _token token to collect
  /// @param _totalAmount the total amount has been collected
  /// @param _protocolFeeRecipient protocol fee recipient
  /// @param _protocolFeeAmount protocol fee amount
  /// @param _partnerFeeRecipient partner fee recipient
  /// @param _partnerFeeAmount partner fee amount
  event FeeCollected(
    address _token,
    uint256 _totalAmount,
    address _protocolFeeRecipient,
    uint256 _protocolFeeAmount,
    address _partnerFeeRecipient,
    uint256 _partnerFeeAmount
  );

  struct FeeInfo {
    address partnerAddr;
    uint24 partnerPercent;
    //first bit is selection (0 for amount, 1 for percent), next 255 bits is amount/percent
    uint256 protocolFee;
  }

  struct FeeConfig {
    address feeRecipient;
    uint24 minPercent;
    uint24 maxPercent;
  }

  /// @notice Simple data for dex aggregator, including router address and swap data
  struct AggregatorData {
    address aggregator;
    uint256 swapAmount;
    bytes aggregatorData;
  }

  /// @notice Zap Excutor general data
  /// @param dexType type of dex to be used
  /// @param srcToken token to be used at first
  /// @param srcAmount amount of token to be used
  /// @param feeInfo fee sharing and collect data, encode of FeeData
  /// @param aggregatorInfo data for aggregator if need to swap, encode of AggregatorData
  /// @param zapExecutionData bytes data for execution, depends on dex type
  struct ZapExecutorData {
    uint8 dexType;
    IERC20 srcToken;
    uint256 srcAmount;
    bytes feeInfo;
    bytes aggregatorInfo;
    bytes zapExecutionData;
  }

  /// @notice result when zapping with KS Elastic, incluing position ID and liquidity increment
  struct ZapElasticResults {
    uint256 posID;
    uint128 liquidity;
    uint256 remainAmount0;
    uint256 remainAmount1;
  }

  struct ZapUniswapv3Results {
    uint256 posID;
    uint128 liquidity;
    uint256 remainAmount0;
    uint256 remainAmount1;
  }

  /// @dev pool's information
  /// @param token0 address of token0
  /// @param fee pool's fee
  /// @param token1 address of token1
  struct PoolInfo {
    address token0;
    uint24 fee;
    address token1;
  }

  /// @param posManager address of position manager
  /// @param pool elastic pool
  /// @param posId id of the position to zap, 0 means minting a new position
  /// @param recipient the address that received new position and remaining tokens
  /// @param precisions contains precisions of token0 and token1
  /// @param minZapAmounts min amount to zap into back in case remaining
  /// @param minRefundAmounts transfer remain tokens only if pass this threshold
  /// @param tickLower position's lower tick
  /// @param tickUpper position's upper tick
  /// @param ticksPrevious the nearest initialized ticks which is lower than or equal tickLower, tickUpper
  /// @param minLiquidity the min liquidity should be added for the position
  /// @param offchainData data passing from offchain for swap amount, if the pool's states haven't changed
  ///   should be able to use the offchain calculation instead
  struct ElasticZapParams {
    address posManager;
    address pool;
    PoolInfo poolInfo;
    uint256 posID;
    address recipient;
    uint256 precisions;
    uint256 minZapAmounts;
    uint256 minRefundAmounts;
    int24 tickLower;
    int24 tickUpper;
    int24[2] ticksPrevious;
    uint128 minLiquidity;
    bytes offchainData;
  }

  struct Uniswapv3ZapParams {
    address posManager;
    address pool;
    PoolInfo poolInfo;
    uint256 posID;
    address recipient;
    uint256 precisions;
    uint256 minZapAmounts;
    uint256 minRefundAmounts;
    int24 tickLower;
    int24 tickUpper;
    uint160 limitSqrtP0;
    uint160 limitSqrtP1;
    uint128 minLiquidity;
    bytes offchainData;
  }

  struct ElasticZapOffchainData {
    uint128 swapAmount;
    uint160 sqrtP;
    int24 currentTick;
    int24 nearestCurrentTick;
    uint128 baseL;
    uint128 reinvestL;
    uint128 reinvestLLast;
  }

  struct Uniswapv3ZapOffchainData {
    uint128 swapAmount;
    uint160 sqrtP;
    int24 currentTick;
    uint128 liquidity;
  }

  struct ClassicZapParams {
    address pool;
    address recipient;
    address tokenOut;
  }

  /// @notice Function to execute general zap in logic
  /// @param _executorData bytes data and will be decoded into corresponding data depends on dex type
  /// @return zapResults result of the zap, depend on dex type
  function executeZapIn(bytes calldata _executorData)
    external
    payable
    returns (bytes memory zapResults);
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
pragma solidity ^0.8.0;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';

abstract contract KyberSwapRole is Ownable, Pausable {
  mapping(address => bool) public operators;
  mapping(address => bool) public guardians;

  /**
   * @dev Emitted when the an user was grant or revoke operator role.
   */
  event UpdateOperator(address user, bool grantOrRevoke);

  /**
   * @dev Emitted when the an user was grant or revoke guardian role.
   */
  event UpdateGuardian(address user, bool grantOrRevoke);

  /**
   * @dev Modifier to make a function callable only when caller is operator.
   *
   * Requirements:
   *
   * - Caller must have operator role.
   */
  modifier onlyOperator() {
    require(operators[msg.sender], 'KyberSwapRole: not operator');
    _;
  }

  /**
   * @dev Modifier to make a function callable only when caller is guardian.
   *
   * Requirements:
   *
   * - Caller must have guardian role.
   */
  modifier onlyGuardian() {
    require(guardians[msg.sender], 'KyberSwapRole: not guardian');
    _;
  }

  /**
   * @dev Update Operator role for user.
   * Can only be called by the current owner.
   */
  function updateOperator(address user, bool grantOrRevoke) external onlyOwner {
    operators[user] = grantOrRevoke;
    emit UpdateOperator(user, grantOrRevoke);
  }

  /**
   * @dev Update Guardian role for user.
   * Can only be called by the current owner.
   */
  function updateGuardian(address user, bool grantOrRevoke) external onlyOwner {
    guardians[user] = grantOrRevoke;
    emit UpdateGuardian(user, grantOrRevoke);
  }

  /**
   * @dev Enable logic for contract.
   * Can only be called by the current owner.
   */
  function enableLogic() external onlyOwner {
    _unpause();
  }

  /**
   * @dev Disable logic for contract.
   * Can only be called by the guardians.
   */
  function disableLogic() external onlyGuardian {
    _pause();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

// EIP-2612 is Final as of 2022-11-01. This file is deprecated.

import "./IERC20Permit.sol";

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.6;

/*
“Copyright (c) 2019-2021 1inch 
Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions: 
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software. 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE”.
*/

library RevertReasonParser {
  function parse(bytes memory data, string memory prefix) internal pure returns (string memory) {
    // https://solidity.readthedocs.io/en/latest/control-structures.html#revert
    // We assume that revert reason is abi-encoded as Error(string)

    // 68 = 4-byte selector 0x08c379a0 + 32 bytes offset + 32 bytes length
    if (
      data.length >= 68 && data[0] == '\x08' && data[1] == '\xc3' && data[2] == '\x79'
        && data[3] == '\xa0'
    ) {
      string memory reason;
      // solhint-disable no-inline-assembly
      assembly {
        // 68 = 32 bytes data length + 4-byte selector + 32 bytes offset
        reason := add(data, 68)
      }
      /*
                revert reason is padded up to 32 bytes with ABI encoder: Error(string)
                also sometimes there is extra 32 bytes of zeros padded in the end:
                https://github.com/ethereum/solidity/issues/10170
                because of that we can't check for equality and instead check
                that string length + extra 68 bytes is less than overall data length
            */
      require(data.length >= 68 + bytes(reason).length, 'Invalid revert reason');
      return string(abi.encodePacked(prefix, 'Error(', reason, ')'));
    }
    // 36 = 4-byte selector 0x4e487b71 + 32 bytes integer
    else if (
      data.length == 36 && data[0] == '\x4e' && data[1] == '\x48' && data[2] == '\x7b'
        && data[3] == '\x71'
    ) {
      uint256 code;
      // solhint-disable no-inline-assembly
      assembly {
        // 36 = 32 bytes data length + 4-byte selector
        code := mload(add(data, 36))
      }
      return string(abi.encodePacked(prefix, 'Panic(', _toHex(code), ')'));
    }

    return string(abi.encodePacked(prefix, 'Unknown(', _toHex(data), ')'));
  }

  function _toHex(uint256 value) private pure returns (string memory) {
    return _toHex(abi.encodePacked(value));
  }

  function _toHex(bytes memory data) private pure returns (string memory) {
    bytes16 alphabet = 0x30313233343536373839616263646566;
    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = '0';
    str[1] = 'x';
    for (uint256 i = 0; i < data.length; i++) {
      str[2 * i + 2] = alphabet[uint8(data[i] >> 4)];
      str[2 * i + 3] = alphabet[uint8(data[i] & 0x0f)];
    }
    return string(str);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IZapDexEnum {
  enum DexType {
    Elastic,
    Classic,
    Uniswapv3
  }
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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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