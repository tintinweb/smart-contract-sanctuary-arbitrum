// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {KSRescue} from 'ks-growth-utils-sc/contracts/KSRescue.sol';

import {IKSZapValidator} from 'contracts/interfaces/zap/validators/IKSZapValidator.sol';
import {IBasePositionManager} from 'contracts/interfaces/ks_elastic/IBasePositionManager.sol';
import {IUniswapv3NFT} from 'contracts/interfaces/uniswapv3/IUniswapv3NFT.sol';

import {IERC20} from 'openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Contains main logics of a validator when zapping into KyberSwap Elastic/Classic pools
///   and Uniswap v2/v3 + clones
contract KSZapValidator is IKSZapValidator, KSRescue {
  /// @notice Prepare and return validation data before zap, calling internal functions to do the work
  /// @param _dexType type of dex/pool supported by this validator
  /// @param _zapInfo related info of zap to generate data
  function prepareValidationData(
    uint8 _dexType,
    bytes calldata _zapInfo
  ) external view override returns (bytes memory) {
    if (_dexType == uint8(DexType.Elastic)) {
      return _getElasticValidationData(_zapInfo);
    }
    if (_dexType == uint8(DexType.Classic)) {
      return _getClassicValidationData(_zapInfo);
    }
    if (_dexType == uint8(DexType.Uniswapv3)) {
      return _getUniswapV3ValidationData(_zapInfo);
    }
    return new bytes(0);
  }

  /// @notice Validate result after zapping into pool, given initial data and data to validate
  /// @param _dexType type of dex/pool supported by this validator
  /// @param _extraData contains data to compares, for example: min liquidity
  /// @param _initialData contains initial data before zapping
  /// @param _zapResults contains zap results from executor
  function validateData(
    uint8 _dexType,
    bytes calldata _extraData,
    bytes calldata _initialData,
    bytes calldata _zapResults
  ) external view override returns (bool) {
    if (_dexType == uint8(DexType.Elastic)) {
      return _validateElasticResult(_extraData, _initialData);
    }
    if (_dexType == uint8(DexType.Classic)) {
      return _validateClassicResult(_extraData, _initialData);
    }
    if (_dexType == uint8(DexType.Uniswapv3)) {
      return _validateUniswapV3Result(_extraData, _initialData);
    }
    return true;
  }

  // ======================= Prepare data for validation =======================

  /// @notice Generate initial data for validation for KyberSwap Classic and Uniswap v2
  ///  in order to validate, we need to get the initial LP balance of the recipient
  /// @param zapInfo contains info of zap with KyberSwap Classic/Uniswap v2
  ///   should be (pool_address, recipient_address)
  function _getClassicValidationData(bytes calldata zapInfo) internal view returns (bytes memory) {
    ClassicValidationData memory data;
    data.initialData = abi.decode(zapInfo, (ClassicZapData));
    data.initialLiquidity =
      uint128(IERC20(data.initialData.pool).balanceOf(data.initialData.recipient));
    return abi.encode(data);
  }

  /// @notice Generate initial data for validation for KyberSwap Elastic
  ///   2 cases: minting a new position or increase liquidity
  ///   - minting a new position:
  ///     + posID in zapInfo should be 0, then replaced with the expected posID
  ///     + isNewPosition is true
  ///     + initialLiquidity is 0
  ///   - increase liquidity:
  ///     + isNewPosition is false
  ///     + initialLiquidity is the current position liquidity, fetched from Position Manager
  function _getElasticValidationData(bytes calldata zapInfo) internal view returns (bytes memory) {
    ElasticValidationData memory data;
    data.initialData = abi.decode(zapInfo, (ElasticZapData));
    if (data.initialData.posID == 0) {
      // minting new position, posID should be nextTokenId
      data.initialData.posID = IBasePositionManager(data.initialData.posManager).nextTokenId();
      data.isNewPosition = true;
      data.initialLiquidity = 0;
    } else {
      data.isNewPosition = false;
      (IBasePositionManager.Position memory pos,) =
        IBasePositionManager(data.initialData.posManager).positions((data.initialData.posID));
      data.initialLiquidity = pos.liquidity;
    }
    return abi.encode(data);
  }

  /// @notice Generate initial data for validation for Uniswap v3
  ///   2 cases: minting a new position or increase liquidity
  ///   - minting a new position:
  ///     + posID in zapInfo should be 0, then replaced with the curren totalSupply
  ///     + isNewPosition is true
  ///     + initialLiquidity is 0
  ///   - increase liquidity:
  ///     + isNewPosition is false
  ///     + initialLiquidity is the current position liquidity, fetched from Position Manager
  function _getUniswapV3ValidationData(bytes calldata zapInfo) internal view returns (bytes memory) {
    ElasticValidationData memory data;
    data.initialData = abi.decode(zapInfo, (ElasticZapData));
    if (data.initialData.posID == 0) {
      // minting new position, temporary store the total supply here
      data.initialData.posID = IUniswapv3NFT(data.initialData.posManager).totalSupply();
      data.isNewPosition = true;
      data.initialLiquidity = 0;
    } else {
      data.isNewPosition = false;
      (,,,,,,, data.initialLiquidity,,,,) =
        IUniswapv3NFT(data.initialData.posManager).positions(data.initialData.posID);
    }
    return abi.encode(data);
  }

  // ======================= Validate data after zap =======================

  /// @notice Validate result for zapping into KyberSwap Classic/Uniswap v2
  ///   - _extraData is the minLiquidity (for validation)
  ///   - to validate, fetch the current LP balance of the recipient
  ///     then compares with the initialLiquidity, make sure the increment is expected (>= minLiquidity)
  /// @param _extraData just the minLiquidity value, uint128
  /// @param _initialData contains initial data before zap, including initialLiquidity
  function _validateClassicResult(
    bytes calldata _extraData,
    bytes calldata _initialData
  ) internal view returns (bool) {
    ClassicValidationData memory data = abi.decode(_initialData, (ClassicValidationData));
    // getting new lp balance, make sure it should be increased
    uint256 lpBalanceAfter = IERC20(data.initialData.pool).balanceOf(data.initialData.recipient);
    if (lpBalanceAfter < data.initialLiquidity) return false;
    // validate increment in liquidity with min expectation
    uint256 minLiquidity = uint256(abi.decode(_extraData, (uint128)));
    require(minLiquidity > 0, 'zero min_liquidity');
    return (lpBalanceAfter - data.initialLiquidity) >= minLiquidity;
  }

  /// @notice Validate result for zapping into KyberSwap Elastic
  ///   2 cases:
  ///     - new position:
  ///       + _extraData contains (recipient, posTickLower, posTickLower, minLiquidity) where:
  ///         (+) recipient is the owner of the posID
  ///         (+) posTickLower, posTickUpper are matched with position's tickLower/tickUpper
  ///         (+) pool is matched with position's pool
  ///         (+) minLiquidity <= pos.liquidity
  ///     - increase liquidity:
  ///       + _extraData contains minLiquidity, where:
  ///         (+) minLiquidity <= (pos.liquidity - initialLiquidity)
  function _validateElasticResult(
    bytes calldata _extraData,
    bytes calldata _initialData
  ) internal view returns (bool) {
    ElasticValidationData memory data = abi.decode(_initialData, (ElasticValidationData));
    IBasePositionManager posManager = IBasePositionManager(data.initialData.posManager);
    if (data.isNewPosition) {
      // minting a new position, need to validate many data
      ElasticExtraData memory extraData = abi.decode(_extraData, (ElasticExtraData));
      // require owner of the pos id is the recipient
      if (posManager.ownerOf(data.initialData.posID) != extraData.recipient) return false;
      // getting pos info from Position Manager
      (IBasePositionManager.Position memory pos,) = posManager.positions((data.initialData.posID));
      // tick ranges should match
      if (extraData.posTickLower != pos.tickLower || extraData.posTickUpper != pos.tickUpper) {
        return false;
      }
      // poolId should correspond to the pool address
      if (posManager.addressToPoolId(data.initialData.pool) != pos.poolId) return false;
      // new liquidity should match expectation
      require(extraData.minLiquidity > 0, 'zero min_liquidity');
      return pos.liquidity >= extraData.minLiquidity;
    } else {
      // not a new position, only need to verify liquidty increment
      // getting new position liquidity, make sure it is increased
      (IBasePositionManager.Position memory pos,) = posManager.positions((data.initialData.posID));
      if (pos.liquidity < data.initialLiquidity) return false;
      // validate increment in liquidity with min expectation
      uint128 minLiquidity = abi.decode(_extraData, (uint128));
      require(minLiquidity > 0, 'zero min_liquidity');
      return pos.liquidity - data.initialLiquidity >= minLiquidity;
    }
  }

  /// @notice Validate result for zapping into Uniswap V3
  ///   2 cases:
  ///     - new position:
  ///       + posID is the totalSupply, need to fetch the corresponding posID
  ///       + _extraData contains (recipient, posTickLower, posTickLower, minLiquidity) where:
  ///         (+) recipient is the owner of the posID
  ///         (+) posTickLower, posTickUpper are matched with position's tickLower/tickUpper
  ///         (+) pool is matched with position's pool
  ///         (+) minLiquidity <= pos.liquidity
  ///     - increase liquidity:
  ///       + _extraData contains minLiquidity, where:
  ///         (+) minLiquidity <= (pos.liquidity - initialLiquidity)
  function _validateUniswapV3Result(
    bytes calldata _extraData,
    bytes calldata _initialData
  ) internal view returns (bool) {
    ElasticValidationData memory data = abi.decode(_initialData, (ElasticValidationData));
    IUniswapv3NFT posManager = IUniswapv3NFT(data.initialData.posManager);
    if (data.isNewPosition) {
      // minting a new position, need to validate many data
      // Calculate the posID and replace, it should be the last index
      data.initialData.posID = posManager.tokenByIndex(data.initialData.posID);
      ElasticExtraData memory extraData = abi.decode(_extraData, (ElasticExtraData));
      // require owner of the pos id is the recipient
      if (posManager.ownerOf(data.initialData.posID) != extraData.recipient) return false;
      // getting pos info from Position Manager
      (,,,,, int24 tickLower, int24 tickUpper, uint128 liquidity,,,,) =
        posManager.positions(data.initialData.posID);
      // tick ranges should match
      if (extraData.posTickLower != tickLower || extraData.posTickUpper != tickUpper) {
        return false;
      }
      // TODO: poolId should correspond to the pool address
      // if (posManager.addressToPoolId(data.initialData.pool) != pos.poolId) return false;
      // new liquidity should match expectation
      require(extraData.minLiquidity > 0, 'zero min_liquidity');
      return liquidity >= extraData.minLiquidity;
    } else {
      // not a new position, only need to verify liquidty increment
      // getting new position liquidity, make sure it is increased
      (,,,,,,, uint128 newLiquidity,,,,) = posManager.positions(data.initialData.posID);
      if (newLiquidity < data.initialLiquidity) return false;
      // validate increment in liquidity with min expectation
      uint128 minLiquidity = abi.decode(_extraData, (uint128));
      require(minLiquidity > 0, 'zero min_liquidity');
      return newLiquidity - data.initialLiquidity >= minLiquidity;
    }
  }
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
pragma solidity 0.8.9;

import {IZapValidator} from 'contracts/interfaces/zap/validators/IZapValidator.sol';

interface IKSZapValidator is IZapValidator {
  /// @notice Only need pool address and recipient to get data
  struct ClassicZapData {
    address pool;
    address recipient;
  }

  /// @notice Return KS Classic Zap Data, and initial liquidity of the recipient
  struct ClassicValidationData {
    ClassicZapData initialData;
    uint128 initialLiquidity;
  }

  /// @notice Contains pool, posManage address
  /// posID = 0 -> minting a new position, otherwise increasing to existing one
  struct ElasticZapData {
    address pool;
    address posManager;
    uint256 posID;
  }

  /// @notice Return data for validation purpose
  /// In case minting a new position:
  ///    - In case Elastic: it calculates the expected posID and update the value
  ///    - In case Uniswap v3: it calculates the current total supply
  struct ElasticValidationData {
    ElasticZapData initialData;
    bool isNewPosition;
    uint128 initialLiquidity;
  }

  /// @notice Extra data to be used for validation after zapping
  struct ElasticExtraData {
    address recipient;
    int24 posTickLower;
    int24 posTickUpper;
    uint128 minLiquidity;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IBasePositionManager {
  struct Position {
    // the nonce for permits
    uint96 nonce;
    // the address that is approved for spending this token
    address operator;
    // the ID of the pool with which this token is connected
    uint80 poolId;
    // the tick range of the position
    int24 tickLower;
    int24 tickUpper;
    // the liquidity of the position
    uint128 liquidity;
    // the current rToken that the position owed
    uint256 rTokenOwed;
    // fee growth per unit of liquidity as of the last update to liquidity
    uint256 feeGrowthInsideLast;
  }

  struct PoolInfo {
    address token0;
    uint16 fee;
    address token1;
  }

  struct MintParams {
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    int24[2] ticksPrevious;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    address recipient;
    uint256 deadline;
  }

  struct IncreaseLiquidityParams {
    uint256 tokenId;
    int24[2] ticksPrevious;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  struct RemoveLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  struct BurnRTokenParams {
    uint256 tokenId;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  function nextTokenId() external view returns (uint256);

  function ownerOf(uint256 tokenId) external view returns (address);

  function positions(uint256 tokenId)
    external
    view
    returns (Position memory pos, PoolInfo memory info);

  function addressToPoolId(address pool) external view returns (uint80);

  function WETH() external view returns (address);

  function tokenByIndex(uint256 index) external view returns (uint256);
  function totalSupply() external view returns (uint256);

  function mint(MintParams calldata params)
    external
    payable
    returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

  function addLiquidity(IncreaseLiquidityParams calldata params)
    external
    payable
    returns (uint128 liquidity, uint256 amount0, uint256 amount1, uint256 additionalRTokenOwed);

  function removeLiquidity(RemoveLiquidityParams calldata params)
    external
    returns (uint256 amount0, uint256 amount1, uint256 additionalRTokenOwed);

  function syncFeeGrowth(uint256 tokenId) external returns (uint256 additionalRTokenOwed);

  function burnRTokens(BurnRTokenParams calldata params)
    external
    returns (uint256 rTokenQty, uint256 amount0, uint256 amount1);

  function transferAllTokens(address token, uint256 minAmount, address recipient) external payable;

  function unwrapWeth(uint256 minAmount, address recipient) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IUniswapv3NFT {
  function positions(uint256 tokenId)
    external
    view
    returns (
      uint96 nonce,
      address operator,
      address token0,
      address token1,
      uint24 fee,
      int24 tickLower,
      int24 tickUpper,
      uint128 liquidity,
      uint256 feeGrowthInside0LastX128,
      uint256 feeGrowthInside1LastX128,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    );

  struct MintParams {
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    address recipient;
    uint256 deadline;
  }

  function mint(MintParams calldata params)
    external
    payable
    returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

  struct IncreaseLiquidityParams {
    uint256 tokenId;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  function increaseLiquidity(IncreaseLiquidityParams calldata params)
    external
    payable
    returns (uint128 liquidity, uint256 amount0, uint256 amount1);

  struct DecreaseLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  function decreaseLiquidity(DecreaseLiquidityParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);

  struct CollectParams {
    uint256 tokenId;
    address recipient;
    uint128 amount0Max;
    uint128 amount1Max;
  }

  function WETH9() external view returns (address);

  function ownerOf(uint256 tokenId) external view returns (address);

  function tokenByIndex(uint256 index) external view returns (uint256);
  function totalSupply() external view returns (uint256);
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
pragma solidity >= 0.8.0;

interface IZapDexEnum {
  enum DexType {
    Elastic,
    Classic,
    Uniswapv3
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