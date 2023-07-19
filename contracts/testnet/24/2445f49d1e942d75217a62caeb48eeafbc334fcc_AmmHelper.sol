// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC20 } from 'oz-contracts/token/ERC20/IERC20.sol';
import { SafeERC20 } from 'oz-contracts/token/ERC20/utils/SafeERC20.sol';
import { IUniswapV2Router02 } from './interfaces/IUniswapV2Router02.sol';
import { ISwapRouter } from './interfaces/ISwapRouter.sol';
import { IQuoterV2 } from './interfaces/IQuoterV2.sol';
import { AmmHelperBase } from './AmmHelperBase.sol';
import { IKresko } from 'kresko-helpers/interfaces/IKresko.sol';
import { ProxyConnector } from 'redstone/core/ProxyConnector.sol';

/** 
* @title AmmHelper Contract
* @author Kresko
* @dev Swaps tokens to kresko amm suported tokens using univ3 router 
     - Uses Kresko amm router to swap tokens to krassets
*/
contract AmmHelper is AmmHelperBase, ProxyConnector {
  using SafeERC20 for IERC20;

  struct UniV2ExactOutput {
    uint256 amountInMax;
    uint256 amountOut;
    address[] path;
    uint256 deadline;
  }

  /* -------------------------------------------------------------------------- */
  /*                                 IMMUTABLES                                 */
  /* -------------------------------------------------------------------------- */

  IUniswapV2Router02 public immutable kreskoRouter;

  ISwapRouter public immutable swapRouter;

  IQuoterV2 public immutable quoter;

  IKresko public immutable kresko;

  /* -------------------------------------------------------------------------- */
  /*                               STATE VARIABLES                              */
  /* -------------------------------------------------------------------------- */

  mapping(address => bool) public isSupportedToken;

  function(address, uint256, bytes memory) internal callbackLogic;

  /* -------------------------------------------------------------------------- */
  /*                                   EVENTS                                   */
  /* -------------------------------------------------------------------------- */

  event Swapped(
    address indexed fromAsset,
    address indexed toAsset,
    uint256 fromAmount,
    uint256 receivedAmount
  );

  /**
   * @notice Constructor
   * @param _safe Address where the rescued tokens will be sent
   * @param _owner Address of the owner of the contract
   * @param _kreskoRouter Address of the kresko router
   * @param _swapRouter Address of the uniV3 swap router
   * @param _quoter Address of the uniV3 quoter
   * @param _tokens Array of supported tokens
   * @param _values Array of supported tokens values to set
   */
  constructor(
    address _safe,
    address _owner,
    address _kreskoRouter,
    address _swapRouter,
    address _quoter,
    address _kresko,
    address[] memory _tokens,
    bool[] memory _values
  ) AmmHelperBase(_safe, _owner) {
    kreskoRouter = IUniswapV2Router02(_kreskoRouter);
    swapRouter = ISwapRouter(_swapRouter);
    quoter = IQuoterV2(_quoter);
    kresko = IKresko(_kresko);

    _setSupportedTokens(_tokens, _values);
  }

  /**
   * @dev Swaps tokens to krassets using univ3 router
   * @param params ExactInputParams struct from univ3 router
   * - path: path should be abi.encode(tokenIn, poolFee(uint24), tokenOut)
   * - recipient: should be the address of AmmHelper contract
   * @param fromAsset Address of the token to swap from
   * @param amountOutMin Minimum amount of krassets to receive
   * @param path Path of the swap in kresko router
   * @param to Address to send the krassets
   * @param deadline Deadline for the swap
   */
  function swapTokensToKrAssets(
    ISwapRouter.ExactInputParams memory params,
    address fromAsset,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) public whenNotPaused {
    require(!isBlacklistedToken[fromAsset], 'BLACKLISTED_TOKEN');
    require(isSupportedToken[path[0]], 'INVALID_TOKEN');

    IERC20(fromAsset).safeTransferFrom(msg.sender, address(this), params.amountIn);
    IERC20(fromAsset).approve(address(swapRouter), params.amountIn);
    uint256 tokensReceived = swapRouter.exactInput(params);

    address[] memory forcedPath = forcedKreskoPath[path[0]]; // saves an SLOAD if path is forced
    if (forcedPath.length != 0) {
      path = forcedPath;
    }

    IERC20(path[0]).approve(address(kreskoRouter), tokensReceived);
    uint256[] memory amounts = kreskoRouter.swapExactTokensForTokens(
      tokensReceived,
      amountOutMin,
      path,
      to,
      deadline
    );

    emit Swapped(fromAsset, path[path.length - 1], params.amountIn, amounts[amounts.length - 1]);
  }

  /**
   * @dev Swaps krassets to tokens
   * @param params ExactInputParams struct from univ3 router
   * - path: path should be abi.encode(tokenIn, poolFee(uint24), tokenOut)
   * - recipient: should be the address of user
   * - amountIn: should be 0 (this would be set by the contract itself)
   * - amountOutMinimum: should be the minimum amount of tokens to receive (value of call to function getAmountsFromKrAssetstoTokens)
   * @param toAsset Address of the token to swap to
   * @param amountOutMin Minimum amount of intermediate assets to receive from kresko router
   * @param path Path of the swap in kresko router
   * @param deadline Deadline for the swap
   */
  function swapKrAssetsToTokens(
    ISwapRouter.ExactInputParams memory params,
    address toAsset,
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    uint256 deadline
  ) public whenNotPaused {
    require(!isBlacklistedToken[toAsset], 'BLACKLISTED_TOKEN');

    address[] memory forcedPath = forcedKreskoPath[path[0]]; // saves an SLOAD if path is forced
    if (forcedPath.length != 0) {
      path = forcedPath;
    }

    IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);
    IERC20(path[0]).approve(address(kreskoRouter), amountIn);
    uint[] memory amounts = kreskoRouter.swapExactTokensForTokens(
      amountIn,
      amountOutMin,
      path,
      address(this),
      deadline
    );

    IERC20(path[path.length - 1]).approve(address(swapRouter), amounts[amounts.length - 1]);
    params.amountIn = amounts[amounts.length - 1];
    uint256 amountOut = swapRouter.exactInput(params);

    emit Swapped(path[0], toAsset, amountIn, amountOut);
  }

  /**
   * @dev repays the exact debt amount of an account
   * * @param params ExactInputParams struct from univ3 router
   *          - path: path should be abi.encode(tokenIn, poolFee(uint24), tokenOut)
   *          - recipient: should be the address of AmmHelper contract
   * @param uniV2Params UniV2ExactOutput struct params for univ2 swap
   * @param fromAsset Address of the token to swap from
   * @param account Account whose debt is to be repaid
   * @param krAsset Address of the krAsset
   * @param krAssetAmount Amount of krAsset to repay
   */
  function repayExactDebt(
    ISwapRouter.ExactInputParamsNoDeadline memory params,
    UniV2ExactOutput memory uniV2Params,
    address fromAsset,
    address account,
    address krAsset,
    uint256 krAssetAmount
  ) public whenNotPaused {
    if (params.amountIn != 0) {
      require(uniV2Params.path[uniV2Params.path.length - 1] == krAsset, 'INVALID_PATH');
      IERC20(fromAsset).safeTransferFrom(msg.sender, address(this), params.amountIn);
      IERC20(fromAsset).approve(address(swapRouter), params.amountIn);
      uint256 intermediateTokenAmountOut = swapRouter.exactInput(params);
      IERC20(uniV2Params.path[0]).approve(address(kreskoRouter), intermediateTokenAmountOut);
      kreskoRouter.swapTokensForExactTokens(
        uniV2Params.amountOut,
        intermediateTokenAmountOut,
        uniV2Params.path,
        address(this),
        uniV2Params.deadline
      );

      // there maybe some leftover path[0] tokens
      _handleDust(uniV2Params.path[0]);
    }

    _repayExactDebt(account, krAsset, krAssetAmount);
  }

  /**
   * @dev repays the exact debt amount of an account just using univ2 router
   * @param params UniV2ExactOutput struct params for univ2 swap
   * @param account Account whose debt is to be repaid
   * @param krAsset Address of the krAsset
   * @param krAssetAmount Amount of krAsset to repay
   */
  function repayExactDebt(
    UniV2ExactOutput memory params,
    address account,
    address krAsset,
    uint256 krAssetAmount
  ) public whenNotPaused {
    if (params.amountInMax != 0) {
      require(params.path[params.path.length - 1] == krAsset, 'INVALID_PATH');
      IERC20(params.path[0]).safeTransferFrom(msg.sender, address(this), params.amountInMax);
      IERC20(params.path[0]).approve(address(kreskoRouter), params.amountInMax);
      kreskoRouter.swapTokensForExactTokens(
        params.amountOut,
        params.amountInMax,
        params.path,
        address(this),
        params.deadline
      );

      // there maybe some leftover path[0] tokens
      _handleDust(params.path[0]);
    }

    _repayExactDebt(account, krAsset, krAssetAmount);
  }

  /**
   * @dev Swaps from KrAsset collateral to KrAsset collateral using kresko router
   * @param amountIn Amount of krAsset to swap
   * @param amountOutMin Minimum amount of swapped krAsset to receive
   * @param path Path of the swap in kresko router
   * @param deadline Deadline for the swap
   */
  function swapCollateral(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    uint256 deadline
  ) public whenNotPaused {
    require(!isBlacklistedToken[path[path.length - 1]], 'BLACKLISTED_TOKEN');

    bytes memory data = abi.encode(amountIn, amountOutMin, path, deadline);
    callbackLogic = logicSwapKrAssetsToKrAssetsCollateral;
    _execute(path[0], amountIn, data);
  }

  /**
   * @dev Swaps from Token collateral to KrAsset collateral using uniV3 -> kresko router
   * @param params ExactInputParams struct from univ3 router
   *        - recipient: should be the address of AmmHelper contract
   * @param fromAsset Address of the token to swap from
   * @param amountOutMin Minimum amount of swapped krAsset to receive
   * @param path Path of the swap in kresko router
   * @param deadline Deadline for the swap
   */
  function swapCollateral(
    ISwapRouter.ExactInputParamsNoDeadline memory params,
    address fromAsset,
    uint256 amountOutMin,
    address[] memory path,
    uint256 deadline
  ) public whenNotPaused {
    bytes memory data = abi.encode(params, fromAsset, amountOutMin, path, deadline);
    callbackLogic = logicSwapTokensToKrAssetsCollateral;
    _execute(fromAsset, params.amountIn, data);
  }

  /**
   * @dev Swaps from KrAsset collateral to Token collateral using kresko -> uniV3 router
   * @param params ExactInputParams struct from univ3 router
   *        - recipient: should be the address of AmmHelper contract
   * @param toAsset Address of the token to swap to
   * @param amountIn Amount of krAsset to swap
   * @param amountOutMin Minimum amount of intermediate token to receive
   * @param path Path of the swap in kresko router
   * @param deadline Deadline for the swap
   */
  function swapCollateral(
    ISwapRouter.ExactInputParamsNoDeadline memory params,
    address toAsset,
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    uint256 deadline
  ) public whenNotPaused {
    bytes memory data = abi.encode(params, toAsset, amountIn, amountOutMin, path, deadline);
    callbackLogic = logicSwapKrAssetsToTokensCollateral;
    _execute(path[0], amountIn, data);
  }

  /**
   * @dev Swaps from Token collateral to Token collateral using uniV3 router
   * @param params ExactInputParamsNoDeadline struct from univ3 router
   *        - recipient: should be the address of AmmHelper contract
   * @param fromAsset Address of the token to swap from
   * @param toAsset Address of the token to swap to
   */
  function swapCollateral(
    ISwapRouter.ExactInputParamsNoDeadline memory params,
    address fromAsset,
    address toAsset
  ) public whenNotPaused {
    require(!isBlacklistedToken[toAsset], 'BLACKLISTED_TOKEN');

    bytes memory data = abi.encode(params, fromAsset, toAsset);
    callbackLogic = logicSwapTokensToTokensCollateral;
    _execute(fromAsset, params.amountIn, data);
  }

  /**
   * @dev called by the Kresko contract when withdrawCollateralUnchecked is called
   * @param _account Account whose collateral is being withdrawn
   * @param _collateralAsset Address of the collateral asset
   * @param _withdrawalAmount Amount of collateral asset to withdrawn
   * @param _depositedCollateralAssetIndex Index of the collateral asset in the deposited collateral asset array
   * @param _userData Data passed by the Kresko contract
   */
  function onUncheckedCollateralWithdraw(
    address _account,
    address _collateralAsset,
    uint256 _withdrawalAmount,
    uint256 _depositedCollateralAssetIndex,
    bytes memory _userData
  ) external returns (bytes memory) {
    _collateralAsset; // unused
    _depositedCollateralAssetIndex; // unused

    require(msg.sender == address(kresko), 'CALLER_NOT_KRESKO');
    callbackLogic(_account, _withdrawalAmount, _userData);
    return '';
  }

  /**
   * @dev gets the amount of tokens to swap for a given amount of krassets
   * @param uniV3Path Path of the swap in univ3 router (reversed)
   * @param amountOut Amount of krAsset
   * @param kresoRouterPath Path of the swap in kresko router
   * retuns amountIn Amount of tokens required to get amountOut krassets
   */
  function getExactTokensInForKrAssets(
    bytes memory uniV3Path,
    uint256 amountOut,
    address[] calldata kresoRouterPath
  ) public returns (uint256 amountIn) {
    uint[] memory amounts = kreskoRouter.getAmountsIn(amountOut, kresoRouterPath);
    (amountIn, , , ) = quoter.quoteExactOutput(uniV3Path, amounts[0]);
  }

  /**
   * @dev Gets the amount of krassets to receive from a swap
   * should be called using staticcall.
   * @param uniV3Path Path of the swap in univ3 router
   * @param amountIn Amount of tokens to swap
   * @param kresoRouterPath Path of the swap in kresko router
   */
  function getAmountsFromTokensToKrAssets(
    bytes memory uniV3Path,
    uint256 amountIn,
    address[] calldata kresoRouterPath
  ) public returns (uint[] memory amounts) {
    (uint intermediateTokenAmountOut, , , ) = quoter.quoteExactInput(uniV3Path, amountIn);
    amounts = kreskoRouter.getAmountsOut(intermediateTokenAmountOut, kresoRouterPath);
  }

  /**
   * @dev Gets the amount of tokens to receive from a swap
   * should be called using staticcall.
   * @param uniV3Path Path of the swap in univ3 router
   * @param amountIn Amount of tokens to swap
   * @param kresoRouterPath Path of the swap in kresko router
   */
  function getAmountsFromKrAssetsToTokens(
    bytes memory uniV3Path,
    uint256 amountIn,
    address[] calldata kresoRouterPath
  ) public returns (uint amount) {
    uint[] memory amounts = kreskoRouter.getAmountsOut(amountIn, kresoRouterPath);
    (amount, , , ) = quoter.quoteExactInput(uniV3Path, amounts[amounts.length - 1]);
  }

  /**
   * @dev Sets the supported tokens by kresko amm. Only callable by admin
   * @param _tokens Array of tokens to set
   * @param _value Array of bools to set
   */
  function setSupportedTokens(
    address[] calldata _tokens,
    bool[] calldata _value
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setSupportedTokens(_tokens, _value);
  }

  /* -------------------------------------------------------------------------- */
  /*                             INTERNAL FUNCTIONS                             */
  /* -------------------------------------------------------------------------- */

  /**
   * @dev Sets the supported tokens by kresko amm.
   * @param _tokens Array of tokens to set
   * @param _value Array of bools to set
   */
  function _setSupportedTokens(address[] memory _tokens, bool[] memory _value) internal {
    require(_tokens.length == _value.length, 'INVALID_INPUTS');
    uint256 length = _tokens.length;
    for (uint256 i; i < length; ) {
      isSupportedToken[_tokens[i]] = _value[i];
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Repays the exact debt amount of an _account
   * @param _account Account whose debt is to be repaid
   * @param _krAsset Address of the krAsset debt
   * @param _krAssetAmount Amount of krAsset to get from user
   */
  function _repayExactDebt(address _account, address _krAsset, uint256 _krAssetAmount) internal {
    if (_krAssetAmount != 0) {
      IERC20(_krAsset).safeTransferFrom(msg.sender, address(this), _krAssetAmount);
    }

    proxyCalldata(
      address(kresko),
      abi.encodeWithSelector(
        kresko.burnKreskoAsset.selector,
        _account,
        _krAsset,
        type(uint256).max,
        kresko.getMintedKreskoAssetsIndex(_account, _krAsset)
      ),
      false
    );

    // there maybe some leftover krAssets tokens if the user had transferred extra krAssets tokens
    _handleDust(_krAsset);
  }

  /**
   * @dev sends the tokens remaining from swap to the user
   * @param _token address of the token
   */
  function _handleDust(address _token) internal {
    uint256 remainingTokens = IERC20(_token).balanceOf(address(this));
    if (remainingTokens != 0) {
      IERC20(_token).safeTransfer(msg.sender, remainingTokens);
    }
  }

  /**
   * @dev Executes the withdrawCollateralUnchecked for msg.sender
   * @param _collateralAsset Address of the collateral asset
   * @param _amount Amount of collateral to withdraw
   * @param data Data to be passed to the callback
   */
  function _execute(address _collateralAsset, uint256 _amount, bytes memory data) internal {
    proxyCalldata(
      address(kresko),
      abi.encodeWithSelector(
        kresko.withdrawCollateralUnchecked.selector,
        msg.sender,
        _collateralAsset,
        _amount,
        kresko.getDepositedCollateralAssetIndex(msg.sender, address(_collateralAsset)),
        data
      ),
      false
    );
  }

  /**
   * @dev Redeposits the collateral back in kresko for user
   * @param _account Account whose collateral is to be withdrawn
   * @param _collateral Address of the collateral asset
   * @param _amount Amount of collateral to deposit
   */
  function _depositCollateral(address _account, address _collateral, uint256 _amount) internal {
    // redeposit all
    IERC20(_collateral).approve(address(kresko), _amount);
    kresko.depositCollateral(_account, _collateral, _amount);
  }

  /* -------------------------------------------------------------------------- */
  /*                             Callback Execution                             */
  /* -------------------------------------------------------------------------- */

  /**
   * @notice logic to swap KrAssets collateral to Token collateral
   * @param _account address of the user
   * @param _withdrawalAmount amount of collateral withdrawn
   * @param _userData data passed by Kresko contract
   */
  function logicSwapKrAssetsToTokensCollateral(
    address _account,
    uint256 _withdrawalAmount,
    bytes memory _userData
  ) internal {
    (
      ISwapRouter.ExactInputParamsNoDeadline memory params,
      address toAsset,
      uint256 amountIn,
      uint256 amountOutMin,
      address[] memory path,
      uint256 deadline
    ) = abi.decode(
        _userData,
        (ISwapRouter.ExactInputParamsNoDeadline, address, uint256, uint256, address[], uint256)
      );
    amountIn = _withdrawalAmount;

    require(!isBlacklistedToken[toAsset], 'BLACKLISTED_TOKEN');
    address[] memory forcedPath = forcedKreskoPath[path[0]]; // saves an SLOAD if path is forced
    if (forcedPath.length != 0) {
      path = forcedPath;
    }
    IERC20(path[0]).approve(address(kreskoRouter), amountIn);
    uint[] memory amounts = kreskoRouter.swapExactTokensForTokens(
      amountIn,
      amountOutMin,
      path,
      address(this),
      deadline
    );

    IERC20(path[path.length - 1]).approve(address(swapRouter), amounts[amounts.length - 1]);
    params.amountIn = amounts[amounts.length - 1];
    uint256 amountOut = swapRouter.exactInput(params);

    _depositCollateral(_account, toAsset, amountOut);
  }

  /**
   * @notice logic to swap Tokens collateral to KrAssets collateral
   * @param _account address of the user
   * @param _withdrawalAmount amount of collateral withdrawn
   * @param _userData data passed by Kresko contract
   */
  function logicSwapTokensToKrAssetsCollateral(
    address _account,
    uint256 _withdrawalAmount,
    bytes memory _userData
  ) internal {
    (
      ISwapRouter.ExactInputParamsNoDeadline memory params,
      address fromAsset,
      uint256 amountOutMin,
      address[] memory path,
      uint256 deadline
    ) = abi.decode(
        _userData,
        (ISwapRouter.ExactInputParamsNoDeadline, address, uint256, address[], uint256)
      );
    params.amountIn = _withdrawalAmount;

    IERC20(fromAsset).safeApprove(address(swapRouter), params.amountIn);
    uint256 tokensReceived = swapRouter.exactInput(params);
    address[] memory forcedPath = forcedKreskoPath[path[0]]; // saves an SLOAD if path is forced
    if (forcedPath.length != 0) {
      path = forcedPath;
    }
    IERC20(path[0]).approve(address(kreskoRouter), tokensReceived);
    uint256[] memory amounts = kreskoRouter.swapExactTokensForTokens(
      tokensReceived,
      amountOutMin,
      path,
      address(this),
      deadline
    );

    _depositCollateral(_account, path[path.length - 1], amounts[amounts.length - 1]);
  }

  /**
   * @notice logic to swap KrAssets collateral to KrAssets collateral
   * @param _account address of the user
   * @param _withdrawalAmount amount of collateral withdrawn
   * @param _userData data passed by Kresko contract
   */
  function logicSwapKrAssetsToKrAssetsCollateral(
    address _account,
    uint256 _withdrawalAmount,
    bytes memory _userData
  ) internal {
    (uint256 amountIn, uint256 amountOutMin, address[] memory path, uint256 deadline) = abi.decode(
      _userData,
      (uint256, uint256, address[], uint256)
    );
    amountIn = _withdrawalAmount;
    IERC20(path[0]).approve(address(kreskoRouter), amountIn);
    uint[] memory amounts = kreskoRouter.swapExactTokensForTokens(
      amountIn,
      amountOutMin,
      path,
      address(this),
      deadline
    );

    _depositCollateral(_account, path[path.length - 1], amounts[amounts.length - 1]);
  }

  /**
   * @notice logic to swap Tokens collateral to Tokens collateral
   * @param _account address of the user
   * @param _withdrawalAmount amount of collateral withdrawn
   * @param _userData data passed by Kresko contract
   */
  function logicSwapTokensToTokensCollateral(
    address _account,
    uint256 _withdrawalAmount,
    bytes memory _userData
  ) internal {
    (ISwapRouter.ExactInputParamsNoDeadline memory params, address fromAsset, address toAsset) = abi
      .decode(_userData, (ISwapRouter.ExactInputParamsNoDeadline, address, address));
    params.amountIn = _withdrawalAmount;
    IERC20(fromAsset).approve(address(swapRouter), params.amountIn);
    uint256 amountOut = swapRouter.exactInput(params);

    _depositCollateral(_account, toAsset, amountOut);
  }
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

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import { IUniswapV3SwapCallback } from './IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
  struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
  }

  /// @notice Swaps `amountIn` of one token for as much as possible of another token
  /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
  /// @return amountOut The amount of the received token
  function exactInputSingle(
    ExactInputSingleParams calldata params
  ) external payable returns (uint256 amountOut);

  struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
  }

  struct ExactInputParamsNoDeadline {
    bytes path;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
  }

  /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
  /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
  /// @return amountOut The amount of the received token
  function exactInput(
    ExactInputParams calldata params
  ) external payable returns (uint256 amountOut);

  function exactInput(
    ExactInputParamsNoDeadline calldata params
  ) external payable returns (uint256 amountOut);

  struct ExactOutputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 deadline;
    uint256 amountOut;
    uint256 amountInMaximum;
    uint160 sqrtPriceLimitX96;
  }

  /// @notice Swaps as little as possible of one token for `amountOut` of another token
  /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
  /// @return amountIn The amount of the input token
  function exactOutputSingle(
    ExactOutputSingleParams calldata params
  ) external payable returns (uint256 amountIn);

  struct ExactOutputParams {
    bytes path;
    address recipient;
    uint256 deadline;
    uint256 amountOut;
    uint256 amountInMaximum;
  }

  /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
  /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
  /// @return amountIn The amount of the input token
  function exactOutput(
    ExactOutputParams calldata params
  ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title QuoterV2 Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps.
/// @notice For each pool also tells you the number of initialized ticks crossed and the sqrt price of the pool after the swap.
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoterV2 {
  /// @notice Returns the amount out received for a given exact input swap without executing the swap
  /// @param path The path of the swap, i.e. each token pair and the pool fee
  /// @param amountIn The amount of the first token to swap
  /// @return amountOut The amount of the last token that would be received
  /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
  /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
  /// @return gasEstimate The estimate of the gas that the swap consumes
  function quoteExactInput(
    bytes memory path,
    uint256 amountIn
  )
    external
    returns (
      uint256 amountOut,
      uint160[] memory sqrtPriceX96AfterList,
      uint32[] memory initializedTicksCrossedList,
      uint256 gasEstimate
    );

  struct QuoteExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
    uint24 fee;
    uint160 sqrtPriceLimitX96;
  }

  /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
  /// @param params The params for the quote, encoded as `QuoteExactInputSingleParams`
  /// tokenIn The token being swapped in
  /// tokenOut The token being swapped out
  /// fee The fee of the token pool to consider for the pair
  /// amountIn The desired input amount
  /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
  /// @return amountOut The amount of `tokenOut` that would be received
  /// @return sqrtPriceX96After The sqrt price of the pool after the swap
  /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
  /// @return gasEstimate The estimate of the gas that the swap consumes
  function quoteExactInputSingle(
    QuoteExactInputSingleParams memory params
  )
    external
    returns (
      uint256 amountOut,
      uint160 sqrtPriceX96After,
      uint32 initializedTicksCrossed,
      uint256 gasEstimate
    );

  /// @notice Returns the amount in required for a given exact output swap without executing the swap
  /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
  /// @param amountOut The amount of the last token to receive
  /// @return amountIn The amount of first token required to be paid
  /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
  /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
  /// @return gasEstimate The estimate of the gas that the swap consumes
  function quoteExactOutput(
    bytes memory path,
    uint256 amountOut
  )
    external
    returns (
      uint256 amountIn,
      uint160[] memory sqrtPriceX96AfterList,
      uint32[] memory initializedTicksCrossedList,
      uint256 gasEstimate
    );

  struct QuoteExactOutputSingleParams {
    address tokenIn;
    address tokenOut;
    uint256 amount;
    uint24 fee;
    uint160 sqrtPriceLimitX96;
  }

  /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
  /// @param params The params for the quote, encoded as `QuoteExactOutputSingleParams`
  /// tokenIn The token being swapped in
  /// tokenOut The token being swapped out
  /// fee The fee of the token pool to consider for the pair
  /// amountOut The desired output amount
  /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
  /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
  /// @return sqrtPriceX96After The sqrt price of the pool after the swap
  /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
  /// @return gasEstimate The estimate of the gas that the swap consumes
  function quoteExactOutputSingle(
    QuoteExactOutputSingleParams memory params
  )
    external
    returns (
      uint256 amountIn,
      uint160 sqrtPriceX96After,
      uint32 initializedTicksCrossed,
      uint256 gasEstimate
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC20 } from 'oz-contracts/token/ERC20/IERC20.sol';
import { SafeERC20 } from 'oz-contracts/token/ERC20/utils/SafeERC20.sol';
import { AccessControl } from 'oz-contracts/access/AccessControl.sol';
import { Pausable } from 'oz-contracts/security/Pausable.sol';

/**
 * @title AmmHelperBase Contract
 * @author Kresko
 * @dev Base contract for AmmHelper with pause/unpause and rescue functions
 */
contract AmmHelperBase is AccessControl, Pausable {
  using SafeERC20 for IERC20;

  /* -------------------------------------------------------------------------- */
  /*                                 IMMUTABLES                                 */
  /* -------------------------------------------------------------------------- */

  // address where the rescued tokens will be sent
  address public immutable safe;

  /* -------------------------------------------------------------------------- */
  /*                               STATE VARIABLES                              */
  /* -------------------------------------------------------------------------- */

  mapping(address => bool) public isBlacklistedToken;

  mapping(address => address[]) public forcedKreskoPath;

  /**
   * @notice Constructor
   * @param _safe Address where the rescued tokens will be sent
   * @param _owner Address of the owner of the contract
   */
  constructor(address _safe, address _owner) {
    safe = _safe;

    _grantRole(DEFAULT_ADMIN_ROLE, _owner);
  }

  /**
   * @dev Pauses the contract only callable by the DEFAULT_ADMIN_ROLE
   */
  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  /**
   * @dev Unpauses the contract only callable by the DEFAULT_ADMIN_ROLE
   */
  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  /**
   * @dev Sets forced kresko path
   * - Only callable by the DEFAULT_ADMIN_ROLE
   * @param _token token to set path for
   * @param _path Path of swap
   */
  function setForcedKreskoPath(
    address _token,
    address[] calldata _path
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    forcedKreskoPath[_token] = _path;
  }

  /**
   * @dev Sets the blacklisted tokens
   * - Only callable by the DEFAULT_ADMIN_ROLE
   * @param _tokens Array of tokens to set
   * @param _value Array of values to set
   */
  function setBlacklistedTokens(
    address[] calldata _tokens,
    bool[] calldata _value
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_tokens.length == _value.length, 'INVALID_INPUTS');
    uint256 length = _tokens.length;
    for (uint i; i < length; ) {
      isBlacklistedToken[_tokens[i]] = _value[i];
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Emergency rescue for token stucked on this contract, as failsafe mechanism
   * - Funds should never remain in this contract more time than during transactions
   * - Only callable by the DEFAULT_ADMIN_ROLE
   * @param _token Address of the token to rescue.
   */
  function rescueTokens(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_token == address(0)) payable(safe).transfer(address(this).balance);
    else IERC20(_token).safeTransfer(safe, IERC20(_token).balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

import {MinterInitArgs, KrAsset, CollateralAsset, MinterParams, Action, SafetyState} from "../types/MinterTypes.sol";
import {FixedPoint} from "../libs/FixedPoint.sol";
import {StabilityRateParams, StabilityRateConfig} from "../types/StabilityRateTypes.sol";

interface IKresko {
    function initialize(MinterInitArgs calldata args) external;

    function toggleAssetsPaused(
        address[] memory _assets,
        Action _action,
        bool _withDuration,
        uint256 _duration
    ) external;

    function safetyStateSet() external view returns (bool);

    function safetyStateFor(
        address _asset,
        Action _action
    ) external view returns (SafetyState memory);

    function burnKreskoAsset(
        address _account,
        address _kreskoAsset,
        uint256 _amount,
        uint256 _mintedKreskoAssetIndex
    ) external;

    function batchCloseKrAssetDebtPositions(address _account) external;

    function closeKrAssetDebtPosition(
        address _account,
        address _kreskoAsset
    ) external;

    function domainSeparator() external view returns (bytes32);

    function minterInitializations() external view returns (uint256);

    function mintKreskoAsset(
        address _account,
        address _kreskoAsset,
        uint256 _mintAmount
    ) external;

    function feeRecipient() external view returns (address);

    function ammOracle() external view returns (address);

    function extOracleDecimals() external view returns (uint8);

    function liquidationThreshold()
        external
        view
        returns (FixedPoint.Unsigned memory);

    function liquidationIncentiveMultiplier()
        external
        view
        returns (FixedPoint.Unsigned memory);

    function minimumCollateralizationRatio()
        external
        view
        returns (FixedPoint.Unsigned memory);

    function minimumDebtValue()
        external
        view
        returns (FixedPoint.Unsigned memory);

    function krAssetExists(address _krAsset) external view returns (bool);

    function kreskoAsset(address _asset) external view returns (KrAsset memory);

    function collateralDeposits(
        address _account,
        address _asset
    ) external view returns (uint256);

    /**
     * @notice Get `_account` interest amount for `_asset`
     * @param _account The account to query amount for
     * @return kissAmount the interest denominated in KISS, ignores K-factor
     */
    function kreskoAssetDebtInterestTotal(
        address _account
    ) external view returns (uint256 kissAmount);

    function getAccountSingleCollateralValueAndRealValue(
        address _account,
        address _asset
    )
        external
        view
        returns (
            FixedPoint.Unsigned memory value,
            FixedPoint.Unsigned memory realValue
        );

    /**
     * @notice Gets an index for the Kresko asset the account has minted.
     * @param _account The account to get the minted Kresko assets for.
     * @param _kreskoAsset The asset lookup address.
     * @return index of the minted Kresko asset.
     */
    function getMintedKreskoAssetsIndex(
        address _account,
        address _kreskoAsset
    ) external view returns (uint256);

    /**
     * @notice Gets an array of Kresko assets the account has minted.
     * @param _account The account to get the minted Kresko assets for.
     * @return An array of addresses of Kresko assets the account has minted.
     */
    function getMintedKreskoAssets(
        address _account
    ) external view returns (address[] memory);

    /**
     * @notice Gets the Kresko asset value in USD of a particular account.
     * @param _account The account to calculate the Kresko asset value for.
     * @return The Kresko asset value of a particular account.
     */
    function getAccountKrAssetValue(
        address _account
    ) external view returns (FixedPoint.Unsigned memory);

    function getDepositedCollateralAssets(
        address _account
    ) external view returns (address[] memory);

    function getAccountMinimumCollateralValueAtRatio(
        address _account,
        FixedPoint.Unsigned memory _ratio
    ) external view returns (FixedPoint.Unsigned memory);

    /**
     * @notice Get `_account` debt amount for `_asset`
     * @param _asset The asset address
     * @param _account The account to query amount for
     * @return Amount of debt for `_asset`
     */
    function kreskoAssetDebt(
        address _account,
        address _asset
    ) external view returns (uint256);

    /**
     * @notice Get `_account` interest amount for `_asset`
     * @param _asset The asset address
     * @param _account The account to query amount for
     * @return assetAmount the interest denominated in _asset
     * @return kissAmount the interest denominated in KISS, ignores K-factor
     */
    function kreskoAssetDebtInterest(
        address _account,
        address _asset
    ) external view returns (uint256 assetAmount, uint256 kissAmount);

    /**
     * @notice Calculates the expected fee to be taken from a user's deposited collateral assets,
     *         by imitating calcFee without modifying state.
     * @param _account The account to charge the open fee from.
     * @param _kreskoAsset The address of the kresko asset being burned.
     * @param _kreskoAssetAmount The amount of the kresko asset being minted.
     * @param _feeType The fee type (open, close, etc).
     * @return assets The collateral types as an array of addresses.
     * @return amounts The collateral amounts as an array of uint256.
     */
    function calcExpectedFee(
        address _account,
        address _kreskoAsset,
        uint256 _kreskoAssetAmount,
        uint256 _feeType
    ) external view returns (address[] memory, uint256[] memory);

    function getDepositedCollateralAssetIndex(
        address _account,
        address _collateralAsset
    ) external view returns (uint256 i);

    function getAccountCollateralRatio(
        address _account
    ) external view returns (FixedPoint.Unsigned memory ratio);

    function getAccountCollateralValue(
        address _account
    ) external view returns (FixedPoint.Unsigned memory);

    function collateralAsset(
        address _asset
    ) external view returns (CollateralAsset memory);

    function collateralExists(
        address _collateralAsset
    ) external view returns (bool);

    function getAllParams() external view returns (MinterParams memory);

    /**
     * @notice Get `_account` principal debt amount for `_asset`
     * @param _asset The asset address
     * @param _account The account to query amount for
     * @return Amount of principal debt for `_asset`
     */
    function kreskoAssetDebtPrincipal(
        address _account,
        address _asset
    ) external view returns (uint256);

    function getCollateralValueAndOraclePrice(
        address _collateralAsset,
        uint256 _amount,
        bool _ignoreCollateralFactor
    )
        external
        view
        returns (FixedPoint.Unsigned memory, FixedPoint.Unsigned memory);

    function getKrAssetValue(
        address _kreskoAsset,
        uint256 _amount,
        bool _ignoreKFactor
    ) external view returns (FixedPoint.Unsigned memory);

    function addCollateralAsset(
        address _collateralAsset,
        address _anchor,
        uint256 _factor,
        address _oracle,
        address _marketStatusOracle
    ) external;

    function addKreskoAsset(
        address _krAsset,
        address _anchor,
        uint256 _kFactor,
        address _oracle,
        address _marketStatusOracle,
        uint256 _supplyLimit,
        uint256 _closeFee,
        uint256 _openFee
    ) external;

    function updateCollateralAsset(
        address _collateralAsset,
        address _anchor,
        uint256 _factor,
        address _oracle,
        address _marketStatusOracle
    ) external;

    function updateFeeRecipient(address _feeRecipient) external;

    function updateKreskoAsset(
        address _krAsset,
        address _anchor,
        uint256 _kFactor,
        address _oracle,
        address _marketStatusOracle,
        uint256 _supplyLimit,
        uint256 _closeFee,
        uint256 _openFee
    ) external;

    function updateLiquidationIncentiveMultiplier(
        uint256 _liquidationIncentiveMultiplier
    ) external;

    function updateMinimumCollateralizationRatio(
        uint256 _minimumCollateralizationRatio
    ) external;

    function updateMinimumDebtValue(uint256 _minimumDebtValue) external;

    function updateLiquidationThreshold(uint256 _minimumDebtValue) external;

    function updateAMMOracle(address _ammOracle) external;

    function updateExtOracleDecimals(uint8 _decimals) external;

    function depositCollateral(
        address _account,
        address _collateralAsset,
        uint256 _amount
    ) external;

    function withdrawCollateral(
        address _account,
        address _collateralAsset,
        uint256 _amount,
        uint256 _depositedCollateralAssetIndex
    ) external;

    function withdrawCollateralUnchecked(
        address _account,
        address _collateralAsset,
        uint256 _withdrawAmount,
        uint256 _depositedCollateralAssetIndex,
        bytes memory _userData
    ) external;

    function batchLiquidateInterest(
        address _account,
        address _collateralAssetToSeize
    ) external;

    function liquidateInterest(
        address _account,
        address _repayKreskoAsset,
        address _collateralAssetToSeize
    ) external;

    function calculateMaxLiquidatableValueForAssets(
        address _account,
        address _repayKreskoAsset,
        address _collateralAssetToSeize
    ) external view returns (FixedPoint.Unsigned memory maxLiquidatableUSD);

    function isAccountLiquidatable(
        address _account
    ) external view returns (bool);

    function liquidate(
        address _account,
        address _repayKreskoAsset,
        uint256 _repayAmount,
        address _collateralAssetToSeize,
        uint256 _mintedKreskoAssetIndex,
        uint256 _depositedCollateralAssetIndex
    ) external;

    function setupStabilityRateParams(
        address _asset,
        StabilityRateParams memory _setup
    ) external;

    function updateStabilityRateParams(
        address _asset,
        StabilityRateParams memory _setup
    ) external;

    function updateStabilityRateAndIndexForAsset(address _asset) external;

    function updateKiss(address _kiss) external;

    function repayStabilityRateInterestPartial(
        address _account,
        address _kreskoAsset,
        uint256 _kissRepayAmount
    ) external;

    function repayFullStabilityRateInterest(
        address _account,
        address _kreskoAsset
    ) external returns (uint256 kissRepayAmount);

    function batchRepayFullStabilityRateInterest(
        address _account
    ) external returns (uint256 kissRepayAmount);

    function getStabilityRateForAsset(
        address _asset
    ) external view returns (uint256 stabilityRate);

    function getPriceRateForAsset(
        address _asset
    ) external view returns (uint256 priceRate);

    function getDebtIndexForAsset(
        address _asset
    ) external view returns (uint256 debtIndex);

    function getStabilityRateConfigurationForAsset(
        address _asset
    ) external view returns (StabilityRateConfig memory);

    function kiss() external view returns (address);

    function getLastDebtIndexForAccount(
        address _account,
        address _asset
    ) external view returns (uint128 lastDebtIndex);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./RedstoneConstants.sol";
import "./CalldataExtractor.sol";

/**
 * @title The base contract for forwarding redstone payload to other contracts
 * @author The Redstone Oracles team
 */
contract ProxyConnector is RedstoneConstants, CalldataExtractor {
  function proxyCalldata(address contractAddress, bytes memory encodedFunction, bool forwardValue) internal returns (bytes memory) {
    bool success;
    bytes memory result;
    bytes memory message = _prepareMessage(encodedFunction);

    if (forwardValue == true) {
      (success, result) = contractAddress.call{value: msg.value}(message);
    } else {
      (success, result) = contractAddress.call(message);
    }
    return _prepareReturnValue(success, result);
  }

  function proxyDelegateCalldata(address contractAddress, bytes memory encodedFunction) internal returns (bytes memory) {
    bytes memory message = _prepareMessage(encodedFunction);
    (bool success, bytes memory result) = contractAddress.delegatecall(message);
    return _prepareReturnValue(success, result);
  }

  function proxyCalldataView(address contractAddress, bytes memory encodedFunction) internal view returns (bytes memory)
{
    bytes memory message = _prepareMessage(encodedFunction);
    (bool success, bytes memory result) = contractAddress.staticcall(message);
    return _prepareReturnValue(success, result);
  }

  function _prepareMessage(bytes memory encodedFunction) private pure returns (bytes memory) {
    uint256 encodedFunctionBytesCount = encodedFunction.length;
    uint256 redstonePayloadByteSize = _getRedstonePayloadByteSize();
    uint256 resultMessageByteSize = encodedFunctionBytesCount + redstonePayloadByteSize;

    uint256 encodedFunctionOffset;
    bytes memory message;

    assembly {
      message := mload(FREE_MEMORY_PTR) // sets message pointer to first free place in memory

      // Saving the byte size of the result message (it's a standard in EVM)
      mstore(message, resultMessageByteSize)

      // Copying function and its arguments
      for { encodedFunctionOffset := 0 } lt(encodedFunctionOffset, encodedFunctionBytesCount) {
        encodedFunctionOffset := add(encodedFunctionOffset, STANDARD_SLOT_BS) // going with 32 bytes steps
      } {
        // Copying data from encodedFunction to message 32 bytes at a time
        mstore(
          add(add(BYTES_ARR_LEN_VAR_BS, message), encodedFunctionOffset), // address in memory
          mload(add(add(BYTES_ARR_LEN_VAR_BS, encodedFunction), encodedFunctionOffset)) // 32 bytes to copy
        )
      }

      // Copying redstone payload to the message bytes
      calldatacopy(
        add(message, add(BYTES_ARR_LEN_VAR_BS, encodedFunctionBytesCount)), // address
        sub(calldatasize(), redstonePayloadByteSize), // offset
        redstonePayloadByteSize // bytes length to copy
      )

      // Updating free memory pointer
      mstore(
        FREE_MEMORY_PTR, add(
          add(message, add(redstonePayloadByteSize, encodedFunctionBytesCount)),
          BYTES_ARR_LEN_VAR_BS
        )
      )
    }

    return message;
  }

  function _getRedstonePayloadByteSize() private pure returns (uint256) {
    uint256 calldataNegativeOffset = _extractByteSizeOfUnsignedMetadata();
    uint256 dataPackagesCount = _extractDataPackagesCountFromCalldata(calldataNegativeOffset);
    calldataNegativeOffset += DATA_PACKAGES_COUNT_BS;
    for (uint256 dataPackageIndex = 0; dataPackageIndex < dataPackagesCount; dataPackageIndex++) {
      uint256 dataPackageByteSize = _getDataPackageByteSize(calldataNegativeOffset);
      calldataNegativeOffset += dataPackageByteSize;
    }

    return calldataNegativeOffset;
  }

  function _getDataPackageByteSize(uint256 calldataNegativeOffset) private pure returns (uint256) {
    (
      uint256 dataPointsCount,
      uint256 eachDataPointValueByteSize
    ) = _extractDataPointsDetailsForDataPackage(calldataNegativeOffset);

    return
      dataPointsCount *
      (DATA_POINT_SYMBOL_BS + eachDataPointValueByteSize) +
      DATA_PACKAGE_WITHOUT_DATA_POINTS_BS;
  }

  function _prepareReturnValue(bool success, bytes memory result)
    internal
    pure
    returns (bytes memory)
  {
    if (!success) {
      if (result.length > 0) {
        assembly {
          let result_size := mload(result)
          revert(add(32, result), result_size)
        }
      } else {
        revert("Proxy calldata failed");
      }
    }

    return result;
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
  /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
  /// @dev In the implementation you must pay the pool tokens owed for the swap.
  /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
  /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
  /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
  /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
  /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
  function uniswapV3SwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
pragma solidity >=0.8.14;

import {AggregatorV2V3Interface} from "../vendor/flux/IFlux.sol";
import {FixedPoint} from "../libs/FixedPoint.sol";
import {IKreskoAssetAnchor} from "../interfaces/IKreskoAssetAnchor.sol";

/* solhint-disable state-visibility */

/* -------------------------------------------------------------------------- */
/*                                  CONSTANTS                                 */
/* -------------------------------------------------------------------------- */

library Constants {
    uint256 constant ONE_HUNDRED_PERCENT = 1e18;

    /// @dev The maximum configurable close fee.
    uint256 constant MAX_CLOSE_FEE = 10e16; // 10%

    /// @dev The maximum configurable open fee.
    uint256 constant MAX_OPEN_FEE = 10e16; // 10%

    /// @dev The minimum configurable minimum collateralization ratio.
    uint256 constant MIN_COLLATERALIZATION_RATIO = ONE_HUNDRED_PERCENT;

    /// @dev The minimum configurable liquidation incentive multiplier.
    /// This means liquidator only receives equal amount of collateral to debt repaid.
    uint256 constant MIN_LIQUIDATION_INCENTIVE_MULTIPLIER = ONE_HUNDRED_PERCENT;

    /// @dev The maximum configurable liquidation incentive multiplier.
    /// This means liquidator receives 25% bonus collateral compared to the debt repaid.
    uint256 constant MAX_LIQUIDATION_INCENTIVE_MULTIPLIER = 1.25e18; // 125%

    /// @dev The maximum configurable minimum debt USD value.
    uint256 constant MAX_DEBT_VALUE = 1000e18; // $1,000
}

/* -------------------------------------------------------------------------- */
/*                                    ENUM                                    */
/* -------------------------------------------------------------------------- */

/**
 * @dev Protocol user facing actions
 *
 * Deposit = 0
 * Withdraw = 1,
 * Repay = 2,
 * Borrow = 3,
 * Liquidate = 4
 */
enum Action {
    Deposit,
    Withdraw,
    Repay,
    Borrow,
    Liquidation
}
/**
 * @dev Fee types
 *
 * Open = 0
 * Close = 1
 */
enum Fee {
    Open,
    Close
}

/* ========================================================================== */
/*                                   STRUCTS                                  */
/* ========================================================================== */

/**
 * @notice Initialization arguments for the protocol
 */
struct MinterInitArgs {
    address admin;
    address council;
    address treasury;
    uint8 extOracleDecimals;
    uint256 liquidationIncentiveMultiplier;
    uint256 minimumCollateralizationRatio;
    uint256 minimumDebtValue;
    uint256 liquidationThreshold;
}

/**
 * @notice Configurable parameters within the protocol
 */

struct MinterParams {
    FixedPoint.Unsigned minimumCollateralizationRatio;
    FixedPoint.Unsigned liquidationIncentiveMultiplier;
    FixedPoint.Unsigned minimumDebtValue;
    FixedPoint.Unsigned liquidationThreshold;
    address feeRecipient;
    uint8 extOracleDecimals;
}

/**
 * @notice Information on a token that is a KreskoAsset.
 * @dev Each KreskoAsset has 18 decimals.
 * @param kFactor The k-factor used for calculating the required collateral value for KreskoAsset debt.
 * @param oracle The oracle that provides the USD price of one KreskoAsset.
 * @param supplyLimit The total supply limit of the KreskoAsset.
 * @param anchor The anchor address
 * @param closeFee The percentage paid in fees when closing a debt position of this type.
 * @param openFee The percentage paid in fees when opening a debt position of this type.
 * @param exists Whether the KreskoAsset exists within the protocol.
 */
struct KrAsset {
    FixedPoint.Unsigned kFactor;
    AggregatorV2V3Interface oracle;
    AggregatorV2V3Interface marketStatusOracle;
    uint256 supplyLimit;
    address anchor;
    FixedPoint.Unsigned closeFee;
    FixedPoint.Unsigned openFee;
    bool exists;
}

/**
 * @notice Information on a token that can be used as collateral.
 * @dev Setting the factor to zero effectively makes the asset useless as collateral while still allowing
 * it to be deposited and withdrawn.
 * @param factor The collateral factor used for calculating the value of the collateral.
 * @param oracle The oracle that provides the USD price of one collateral asset.
 * @param anchor If the collateral is a KreskoAsset, the anchor address
 * @param decimals The decimals for the token, stored here to avoid repetitive external calls.
 * @param exists Whether the collateral asset exists within the protocol.
 */
struct CollateralAsset {
    FixedPoint.Unsigned factor;
    AggregatorV2V3Interface oracle;
    AggregatorV2V3Interface marketStatusOracle;
    address anchor;
    uint8 decimals;
    bool exists;
}

/// @notice Configuration for pausing `Action`
struct Pause {
    bool enabled;
    uint256 timestamp0;
    uint256 timestamp1;
}

/// @notice Safety configuration for assets
struct SafetyState {
    Pause pause;
}

/**
 * @title Storage layout for the minter state
 * @author Kresko
 */
struct MinterState {
    /* -------------------------------------------------------------------------- */
    /*                               Initialization                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Initialization version
    uint256 initializations;
    bytes32 domainSeparator;
    /* -------------------------------------------------------------------------- */
    /*                           Configurable Parameters                          */
    /* -------------------------------------------------------------------------- */

    /// @notice The recipient of protocol fees.
    address feeRecipient;
    /// @notice The factor used to calculate the incentive a liquidator receives in the form of seized collateral.
    FixedPoint.Unsigned liquidationIncentiveMultiplier;
    /// @notice The absolute minimum ratio of collateral value to debt value used to calculate collateral requirements.
    FixedPoint.Unsigned minimumCollateralizationRatio;
    /// @notice The minimum USD value of an individual synthetic asset debt position.
    FixedPoint.Unsigned minimumDebtValue;
    /// @notice The collateralization ratio at which positions may be liquidated.
    FixedPoint.Unsigned liquidationThreshold;
    /// @notice Flag tells if there is a need to perform safety checks on user actions
    bool safetyStateSet;
    /// @notice asset -> action -> state
    mapping(address => mapping(Action => SafetyState)) safetyState;
    /* -------------------------------------------------------------------------- */
    /*                              Collateral Assets                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Mapping of collateral asset token address to information on the collateral asset.
    mapping(address => CollateralAsset) collateralAssets;
    /**
     * @notice Mapping of account -> asset -> deposit amount
     */
    mapping(address => mapping(address => uint256)) collateralDeposits;
    /// @notice Mapping of account -> collateral asset addresses deposited
    mapping(address => address[]) depositedCollateralAssets;
    /* -------------------------------------------------------------------------- */
    /*                                Kresko Assets                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Mapping of kresko asset token address to information on the Kresko asset.
    mapping(address => KrAsset) kreskoAssets;
    /// @notice Mapping of account -> krAsset -> debt amount owed to the protocol
    mapping(address => mapping(address => uint256)) kreskoAssetDebt;
    /// @notice Mapping of account -> addresses of borrowed krAssets
    mapping(address => address[]) mintedKreskoAssets;
    /// @notice The AMM oracle address.
    address ammOracle;
    /// @notice Offchain oracle decimals
    uint8 extOracleDecimals;
}

// Storage position
bytes32 constant MINTER_STORAGE_POSITION = keccak256("kresko.minter.storage");

function ms() pure returns (MinterState storage state) {
    bytes32 position = MINTER_STORAGE_POSITION;
    assembly {
        state.slot := position
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

import {SafeMathUpgradeable} from "oz-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {SignedSafeMathUpgradeable} from "oz-upgradeable/utils/math/SignedSafeMathUpgradeable.sol";

/* solhint-disable  func-name-mixedcase */

/**
 * @title Library for fixed point arithmetic on uints
 */

library FixedPoint {
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;

    uint256 internal constant FP_DECIMALS = 18;
    uint256 internal constant FP_SCALING_FACTOR = 10 ** FP_DECIMALS;
    int256 internal constant SFP_SCALING_FACTOR = 10 ** 18;

    struct Unsigned {
        uint256 rawValue;
    }

    struct Signed {
        int256 rawValue;
    }

    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.

    // --------------------------------------- UNSIGNED ---------------------------------------------------------------

    /**
     * @notice Constructs an `Unsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a uint to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledUint(
        uint256 a
    ) internal pure returns (Unsigned memory) {
        return Unsigned(a.mul(FP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if equal, or False.
     */
    function isEqual(
        Unsigned memory a,
        uint256 b
    ) internal pure returns (bool) {
        return a.rawValue == fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if equal, or False.
     */
    function isEqual(
        Unsigned memory a,
        Unsigned memory b
    ) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(
        Unsigned memory a,
        Unsigned memory b
    ) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(
        Unsigned memory a,
        uint256 b
    ) internal pure returns (bool) {
        return a.rawValue > fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(
        uint256 a,
        Unsigned memory b
    ) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(
        Unsigned memory a,
        Unsigned memory b
    ) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(
        Unsigned memory a,
        uint256 b
    ) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(
        uint256 a,
        Unsigned memory b
    ) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(
        Unsigned memory a,
        Unsigned memory b
    ) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(
        Unsigned memory a,
        uint256 b
    ) internal pure returns (bool) {
        return a.rawValue < fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(
        uint256 a,
        Unsigned memory b
    ) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(
        Unsigned memory a,
        Unsigned memory b
    ) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(
        Unsigned memory a,
        uint256 b
    ) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(
        uint256 a,
        Unsigned memory b
    ) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the minimum of `a` and `b`.
     */
    function min(
        Unsigned memory a,
        Unsigned memory b
    ) internal pure returns (Unsigned memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the maximum of `a` and `b`.
     */
    function max(
        Unsigned memory a,
        Unsigned memory b
    ) internal pure returns (Unsigned memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the sum of `a` and `b`.
     */
    function add(
        Unsigned memory a,
        Unsigned memory b
    ) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Unsigned` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(
        Unsigned memory a,
        uint256 b
    ) internal pure returns (Unsigned memory) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(
        Unsigned memory a,
        Unsigned memory b
    ) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled uint256 from an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(
        Unsigned memory a,
        uint256 b
    ) internal pure returns (Unsigned memory) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from an unscaled uint256, reverting on overflow.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(
        uint256 a,
        Unsigned memory b
    ) internal pure returns (Unsigned memory) {
        return sub(fromUnscaledUint(a), b);
    }

    /**
     * @notice Multiplies two `Unsigned`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mul(
        Unsigned memory a,
        Unsigned memory b
    ) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as a uint256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because FP_SCALING_FACTOR != 0.
        return Unsigned(a.rawValue.mul(b.rawValue) / FP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(
        Unsigned memory a,
        uint256 b
    ) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Unsigned`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(
        Unsigned memory a,
        Unsigned memory b
    ) internal pure returns (Unsigned memory) {
        uint256 mulRaw = a.rawValue.mul(b.rawValue);
        uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
        uint256 mod = mulRaw.mod(FP_SCALING_FACTOR);
        if (mod != 0) {
            return Unsigned(mulFloor.add(1));
        } else {
            return Unsigned(mulFloor);
        }
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mulCeil(
        Unsigned memory a,
        uint256 b
    ) internal pure returns (Unsigned memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(
        Unsigned memory a,
        Unsigned memory b
    ) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as a uint256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Unsigned(a.rawValue.mul(FP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(
        Unsigned memory a,
        uint256 b
    ) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled uint256 by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a uint256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(
        uint256 a,
        Unsigned memory b
    ) internal pure returns (Unsigned memory) {
        return div(fromUnscaledUint(a), b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned` and "ceil's" the quotient, reverting on overflow or
     * division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(
        Unsigned memory a,
        Unsigned memory b
    ) internal pure returns (Unsigned memory) {
        uint256 aScaled = a.rawValue.mul(FP_SCALING_FACTOR);
        uint256 divFloor = aScaled.div(b.rawValue);
        uint256 mod = aScaled.mod(b.rawValue);
        if (mod != 0) {
            return Unsigned(divFloor.add(1));
        } else {
            return Unsigned(divFloor);
        }
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256 and "ceil's" the quotient, reverting on overflow or
     * division by 0.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(
        Unsigned memory a,
        uint256 b
    ) internal pure returns (Unsigned memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Unsigned(a.rawValue.div(b))"
        // similarly to mulCeil with a uint256 as the second parameter. Therefore we need to convert b into an Unsigned.
        // This creates the possibility of overflow if b is very large.
        return divCeil(a, fromUnscaledUint(b));
    }

    /**
     * @notice Raises an `Unsigned` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return output is `a` to the power of `b`.
     */
    function pow(
        Unsigned memory a,
        uint256 b
    ) internal pure returns (Unsigned memory output) {
        output = fromUnscaledUint(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }

    // ------------------------------------------------- SIGNED ------------------------------------------------------
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored
    //   internally as int256 10^76.

    function fromSigned(
        Signed memory a
    ) internal pure returns (Unsigned memory) {
        require(a.rawValue >= 0, "Negative value provided");
        return Unsigned(uint256(a.rawValue));
    }

    function fromUnsigned(
        Unsigned memory a
    ) internal pure returns (Signed memory) {
        require(a.rawValue <= uint256(type(int256).max), "Unsigned too large");
        return Signed(int256(a.rawValue));
    }

    /**
     * @notice Constructs a `Signed` from an unscaled int, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a int to convert into a FixedPoint.Signed.
     * @return the converted FixedPoint.Signed.
     */
    function fromUnscaledInt(int256 a) internal pure returns (Signed memory) {
        return Signed(a.mul(SFP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a int256.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if equal, or False.
     */
    function isEqual(
        Signed memory a,
        Signed memory b
    ) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(
        Signed memory a,
        Signed memory b
    ) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(
        Signed memory a,
        int256 b
    ) internal pure returns (bool) {
        return a.rawValue > fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(
        int256 a,
        Signed memory b
    ) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(
        Signed memory a,
        Signed memory b
    ) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(
        Signed memory a,
        int256 b
    ) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(
        int256 a,
        Signed memory b
    ) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(
        Signed memory a,
        Signed memory b
    ) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(
        Signed memory a,
        int256 b
    ) internal pure returns (bool) {
        return a.rawValue < fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(
        int256 a,
        Signed memory b
    ) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(
        Signed memory a,
        Signed memory b
    ) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(
        Signed memory a,
        int256 b
    ) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(
        int256 a,
        Signed memory b
    ) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the minimum of `a` and `b`.
     */
    function min(
        Signed memory a,
        Signed memory b
    ) internal pure returns (Signed memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the maximum of `a` and `b`.
     */
    function max(
        Signed memory a,
        Signed memory b
    ) internal pure returns (Signed memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the sum of `a` and `b`.
     */
    function add(
        Signed memory a,
        Signed memory b
    ) internal pure returns (Signed memory) {
        return Signed(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Signed` to an unscaled int, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the sum of `a` and `b`.
     */
    function add(
        Signed memory a,
        int256 b
    ) internal pure returns (Signed memory) {
        return add(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(
        Signed memory a,
        Signed memory b
    ) internal pure returns (Signed memory) {
        return Signed(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled int256 from an `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the difference of `a` and `b`.
     */
    function sub(
        Signed memory a,
        int256 b
    ) internal pure returns (Signed memory) {
        return sub(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts an `Signed` from an unscaled int256, reverting on overflow.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(
        int256 a,
        Signed memory b
    ) internal pure returns (Signed memory) {
        return sub(fromUnscaledInt(a), b);
    }

    /**
     * @notice Multiplies two `Signed`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mul(
        Signed memory a,
        Signed memory b
    ) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as an int256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because SFP_SCALING_FACTOR != 0.
        return Signed(a.rawValue.mul(b.rawValue) / SFP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the product of `a` and `b`.
     */
    function mul(
        Signed memory a,
        int256 b
    ) internal pure returns (Signed memory) {
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Signed`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(
        Signed memory a,
        Signed memory b
    ) internal pure returns (Signed memory) {
        int256 mulRaw = a.rawValue.mul(b.rawValue);
        int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = mulRaw % SFP_SCALING_FACTOR;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(mulTowardsZero.add(valueToAdd));
        } else {
            return Signed(mulTowardsZero);
        }
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(
        Signed memory a,
        int256 b
    ) internal pure returns (Signed memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Signed` by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(
        Signed memory a,
        Signed memory b
    ) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as an int256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Signed(a.rawValue.mul(SFP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(
        Signed memory a,
        int256 b
    ) internal pure returns (Signed memory) {
        return Signed(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled int256 by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a an int256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(
        int256 a,
        Signed memory b
    ) internal pure returns (Signed memory) {
        return div(fromUnscaledInt(a), b);
    }

    /**
     * @notice Divides one `Signed` by an `Signed` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(
        Signed memory a,
        Signed memory b
    ) internal pure returns (Signed memory) {
        int256 aScaled = a.rawValue.mul(SFP_SCALING_FACTOR);
        int256 divTowardsZero = aScaled.div(b.rawValue);
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = aScaled % b.rawValue;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(divTowardsZero.add(valueToAdd));
        } else {
            return Signed(divTowardsZero);
        }
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256 and "ceil's" the quotient, reverting on overflow or
     * division by 0.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(
        Signed memory a,
        int256 b
    ) internal pure returns (Signed memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Signed(a.rawValue.div(b))"
        // similarly to mulCeil with an int256 as the second parameter. Therefore we need to convert b into an Signed.
        // This creates the possibility of overflow if b is very large.
        return divAwayFromZero(a, fromUnscaledInt(b));
    }

    /**
     * @notice Raises an `Signed` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint.Signed.
     * @param b a uint256 (negative exponents are not allowed).
     * @return output is `a` to the power of `b`.
     */
    function pow(
        Signed memory a,
        uint256 b
    ) internal pure returns (Signed memory output) {
        output = fromUnscaledInt(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }

    // ------------------- Additional Fixed Point math functions specific to Kresko protocol -------------------

    function ONE_HUNDRED_PERCENT() internal pure returns (Unsigned memory) {
        return FixedPoint.Unsigned(1e18);
    }

    function ONE_USD() internal pure returns (Unsigned memory) {
        return FixedPoint.Unsigned(1e18);
    }

    function toFixedPoint(
        uint256 value
    ) internal pure returns (Unsigned memory) {
        return FixedPoint.Unsigned(value);
    }

    function toFixedPoint(
        uint128 value
    ) internal pure returns (Unsigned memory) {
        return FixedPoint.Unsigned(value);
    }

    function toFixedPoint(
        int256 value
    ) internal pure returns (Unsigned memory) {
        return FixedPoint.Unsigned(uint256(value));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

/* solhint-disable var-name-mixedcase */
// Stability Rate setup params
struct StabilityRateParams {
    uint128 stabilityRateBase;
    uint128 rateSlope1;
    uint128 rateSlope2;
    uint128 optimalPriceRate;
    uint128 priceRateDelta;
}

// Asset data
struct StabilityRateConfig {
    // Interest index for debt
    uint128 debtIndex;
    // Represents the optimal price rate between an oracle report and an AMM twap
    uint128 optimalPriceRate;
    // Slope of the variable interest curve when rate > 0 and <= optimalPriceRate.
    // Expressed in ray
    uint128 rateSlope1;
    // Slope of the variable interest curve when rate > optimalPriceRate.
    // Expressed in ray
    uint128 rateSlope2;
    /**
     * Represents the excess price premium in either direction.
     * Expressed in ray
     * Eg. 1/20 ray = 5% price premium in either direction is considered excess
     */
    uint128 priceRateDelta;
    // Current accrual rate for debt
    uint128 stabilityRate;
    // Base accrual rate for debt
    uint128 stabilityRateBase;
    // Asset to configure
    address asset;
    // Last update for the asset
    uint40 lastUpdateTimestamp;
}

// User data
struct StabilityRateUser {
    uint128 debtScaled;
    uint128 lastDebtIndex;
}

// Storage layout
struct InterestRateState {
    // asset address -> asset data
    mapping(address => StabilityRateConfig) srAssets;
    // account address -> asset address -> user data
    mapping(address => mapping(address => StabilityRateUser)) srUserInfo;
    // interest repayment token is KISS
    address kiss;
}

// Storage position
bytes32 constant INTEREST_RATE_STORAGE_POSITION = keccak256(
    "kresko.interest.rate.storage"
);

// solhint-disable func-visibility
function irs() pure returns (InterestRateState storage state) {
    bytes32 position = INTEREST_RATE_STORAGE_POSITION;
    assembly {
        state.slot := position
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title The base contract with helpful constants
 * @author The Redstone Oracles team
 * @dev It mainly contains redstone-related values, which improve readability
 * of other contracts (e.g. CalldataExtractor and RedstoneConsumerBase)
 */
contract RedstoneConstants {
  // === Abbreviations ===
  // BS - Bytes size
  // PTR - Pointer (memory location)
  // SIG - Signature

  // Solidity and YUL constants
  uint256 constant STANDARD_SLOT_BS = 32;
  uint256 constant FREE_MEMORY_PTR = 0x40;
  uint256 constant BYTES_ARR_LEN_VAR_BS = 32;
  uint256 constant FUNCTION_SIGNATURE_BS = 4;

  // RedStone protocol consts
  uint256 constant SIG_BS = 65;
  uint256 constant TIMESTAMP_BS = 6;
  uint256 constant DATA_PACKAGES_COUNT_BS = 2;
  uint256 constant DATA_POINTS_COUNT_BS = 3;
  uint256 constant DATA_POINT_VALUE_BYTE_SIZE_BS = 4;
  uint256 constant DATA_POINT_SYMBOL_BS = 32;
  uint256 constant DEFAULT_DATA_POINT_VALUE_BS = 32;
  uint256 constant UNSGINED_METADATA_BYTE_SIZE_BS = 3;
  uint256 constant REDSTONE_MARKER_BS = 9; // byte size of 0x000002ed57011e0000

  // "Dynamic" values (based on consts)
  uint256 constant TIMESTAMP_NEGATIVE_OFFSET_IN_DATA_PACKAGE = 72; // SIG_BS + DATA_POINTS_COUNT_BS + DATA_POINT_VALUE_BYTE_SIZE_BS
  uint256 constant DATA_PACKAGE_WITHOUT_DATA_POINTS_BS = 78; // DATA_POINT_VALUE_BYTE_SIZE_BS + TIMESTAMP_BS + DATA_POINTS_COUNT_BS + SIG_BS
  uint256 constant DATA_PACKAGE_WITHOUT_DATA_POINTS_AND_SIG_BS = 13; // DATA_POINT_VALUE_BYTE_SIZE_BS + TIMESTAMP_BS + DATA_POINTS_COUNT_BS
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./RedstoneConstants.sol";

/**
 * @title The base contract with the main logic of data extraction from calldata
 * @author The Redstone Oracles team
 * @dev This contract was created to reuse the same logic in the RedstoneConsumerBase
 * and the ProxyConnector contracts
 */
contract CalldataExtractor is RedstoneConstants {
  function _extractByteSizeOfUnsignedMetadata() internal pure returns (uint256) {
    // Using uint24, because unsigned metadata byte size number has 3 bytes
    uint24 unsignedMetadataByteSize;
    assembly {
      let calldataOffset := sub(calldatasize(), REDSTONE_MARKER_BS)
      unsignedMetadataByteSize := calldataload(sub(calldataOffset, STANDARD_SLOT_BS))
    }
    return unsignedMetadataByteSize + UNSGINED_METADATA_BYTE_SIZE_BS + REDSTONE_MARKER_BS;
  }

  function _extractDataPackagesCountFromCalldata(uint256 calldataNegativeOffset) internal pure returns (uint256) {
    // Using uint16, because unsigned metadata byte size number has 2 bytes
    uint16 dataPackagesCount;
    assembly {
      let calldataOffset := sub(calldatasize(), calldataNegativeOffset)
      dataPackagesCount := calldataload(sub(calldataOffset, STANDARD_SLOT_BS))
    }
    return dataPackagesCount;
  }

  function _extractDataPointValueAndDataFeedId(
    uint256 calldataNegativeOffsetForDataPackage,
    uint256 defaultDataPointValueByteSize,
    uint256 dataPointIndex
  ) internal pure virtual returns (bytes32 dataPointDataFeedId, uint256 dataPointValue) {
    assembly {
      let negativeOffsetToDataPoints := add(
        calldataNegativeOffsetForDataPackage,
        DATA_PACKAGE_WITHOUT_DATA_POINTS_BS
      )
      let dataPointCalldataOffset := sub(
        calldatasize(),
        add(
          negativeOffsetToDataPoints,
          mul(add(1, dataPointIndex), add(defaultDataPointValueByteSize, DATA_POINT_SYMBOL_BS))
        )
      )
      dataPointDataFeedId := calldataload(dataPointCalldataOffset)
      dataPointValue := calldataload(add(dataPointCalldataOffset, DATA_POINT_SYMBOL_BS))
    }
  }

  function _extractDataPointsDetailsForDataPackage(uint256 calldataNegativeOffsetForDataPackage)
    internal
    pure
    returns (uint256 dataPointsCount, uint256 eachDataPointValueByteSize)
  {
    // Using uint24, because data points count byte size number has 3 bytes
    uint24 _dataPointsCount;

    // Using uint32, because data point value byte size has 4 bytes
    uint32 _eachDataPointValueByteSize;

    assembly {
      // Extract data points count
      let negativeCalldataOffset := add(calldataNegativeOffsetForDataPackage, SIG_BS)
      _dataPointsCount := extractFromCalldata(negativeCalldataOffset)

      // Extract each data point value size
      negativeCalldataOffset := add(negativeCalldataOffset, DATA_POINTS_COUNT_BS)
      _eachDataPointValueByteSize := extractFromCalldata(negativeCalldataOffset)

      function extractFromCalldata(negativeOffset) -> extractedValue {
        extractedValue := calldataload(sub(calldatasize(), add(negativeOffset, STANDARD_SLOT_BS)))
      }
    }

    // Prepare returned values
    dataPointsCount = uint256(_dataPointsCount);
    eachDataPointValueByteSize = uint256(_eachDataPointValueByteSize);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            bool marketOpen,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            bool marketOpen,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestMarketOpen() external view returns (bool);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    function getMarketOpen(uint256 roundId) external view returns (bool);

    event AnswerUpdated(
        int256 indexed current,
        bool marketOpen,
        uint256 indexed roundId,
        uint256 updatedAt
    );
    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );
}

interface AggregatorV2V3Interface is
    AggregatorInterface,
    AggregatorV3Interface
{}

/**
 * @dev EIP2362 Interface for pull oracles
 * https://github.com/tellor-io/EIP-2362
 */
interface IERC2362 {
    /**
     * @dev Exposed function pertaining to EIP standards
     * @param _id bytes32 ID of the query
     * @return int,uint,uint returns the value, timestamp, and status code of query
     */
    function valueFor(
        bytes32 _id
    ) external view returns (int256, uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;
import {IAccessControlEnumerableUpgradeable} from "../vendor/IAccessControl.sol";
import {IERC165} from "../vendor/IERC165.sol";
import {IERC20} from "../vendor/IERC20.sol";
import {IKreskoAssetIssuer} from "./IKreskoAssetIssuer.sol";

interface IKreskoAssetAnchor is
    IKreskoAssetIssuer,
    IERC20,
    IAccessControlEnumerableUpgradeable,
    IERC165
{
    function asset() external view returns (address);

    function deposit(uint256, address) external returns (uint256);

    function withdraw(uint256, address, address) external returns (uint256);

    function initialize(
        address _asset,
        string memory _name,
        string memory _symbol,
        address _admin
    ) external;

    function maxDeposit(address) external view returns (uint256);

    function maxMint(address) external view returns (uint256);

    function maxRedeem(address owner) external view returns (uint256);

    function maxWithdraw(address owner) external view returns (uint256);

    function mint(
        uint256 _shares,
        address _receiver
    ) external returns (uint256 assets);

    function previewDeposit(uint256 assets) external view returns (uint256);

    function previewMint(uint256 shares) external view returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);

    function previewWithdraw(uint256 assets) external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function reinitializeERC20(
        string memory _name,
        string memory _symbol,
        uint8 _version
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMathUpgradeable {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

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
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(
        bytes32 role,
        uint256 index
    ) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.16;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

/// @title KreskoAsset issuer interface
/// @author Kresko
/// @notice Contract that can issue/destroy Kresko Assets through Kresko
/// @dev This interface is used by KISS & KreskoAssetAnchor
interface IKreskoAssetIssuer {
    function issue(
        uint256 _assets,
        address _to
    ) external returns (uint256 shares);

    function destroy(
        uint256 _assets,
        address _from
    ) external returns (uint256 shares);

    function convertToShares(uint256 assets) external view returns (uint256);

    function convertToAssets(uint256 shares) external view returns (uint256);
}