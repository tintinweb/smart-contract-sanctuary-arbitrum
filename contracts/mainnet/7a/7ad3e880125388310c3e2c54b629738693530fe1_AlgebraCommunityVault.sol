// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import './interfaces/IAlgebraFactory.sol';
import './libraries/SafeTransfer.sol';

/// @title Algebra community fee vault
/// @notice Community fee from pools is sent here, if it is enabled
contract AlgebraCommunityVault {
  event TokensWithdrawal(address indexed token, address indexed to, uint256 amount);

  /// @dev The role can be granted in AlgebraFactory
  bytes32 public constant COMMUNITY_FEE_WITHDRAWER_ROLE = keccak256('COMMUNITY_FEE_WITHDRAWER');
  address private immutable factory;

  modifier onlyWithdrawer() {
    require(IAlgebraFactory(factory).hasRoleOrOwner(COMMUNITY_FEE_WITHDRAWER_ROLE, msg.sender));
    _;
  }

  constructor() {
    factory = msg.sender;
  }

  function withdraw(address token, address to, uint256 amount) external onlyWithdrawer {
    _withdraw(token, to, amount);
  }

  struct WithdrawTokensParams {
    address token;
    address to;
    uint256 amount;
  }

  function withdrawTokens(WithdrawTokensParams[] calldata params) external onlyWithdrawer {
    uint256 paramsLength = params.length;
    unchecked {
      for (uint256 i; i < paramsLength; ++i) _withdraw(params[i].token, params[i].to, params[i].amount);
    }
  }

  function _withdraw(address token, address to, uint256 amount) private {
    SafeTransfer.safeTransfer(token, to, amount);
    emit TokensWithdrawal(token, to, amount);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

// coefficients for sigmoids: α / (1 + e^( (β-x) / γ))
// alpha1 + alpha2 + baseFee must be <= type(uint16).max
struct AlgebraFeeConfiguration {
  uint16 alpha1; // max value of the first sigmoid
  uint16 alpha2; // max value of the second sigmoid
  uint32 beta1; // shift along the x-axis for the first sigmoid
  uint32 beta2; // shift along the x-axis for the second sigmoid
  uint16 gamma1; // horizontal stretch factor for the first sigmoid
  uint16 gamma2; // horizontal stretch factor for the second sigmoid
  uint16 baseFee; // minimum possible fee
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma abicoder v2;

import '../base/AlgebraFeeConfiguration.sol';

/// @title The interface for the Algebra Factory
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraFactory {
  /// @notice Emitted when a process of ownership renounce is started
  /// @param timestamp The timestamp of event
  /// @param finishTimestamp The timestamp when ownership renounce will be possible to finish
  event RenounceOwnershipStart(uint256 timestamp, uint256 finishTimestamp);

  /// @notice Emitted when a process of ownership renounce cancelled
  /// @param timestamp The timestamp of event
  event RenounceOwnershipStop(uint256 timestamp);

  /// @notice Emitted when a process of ownership renounce finished
  /// @param timestamp The timestamp of ownership renouncement
  event RenounceOwnershipFinish(uint256 timestamp);

  /// @notice Emitted when a pool is created
  /// @param token0 The first token of the pool by address sort order
  /// @param token1 The second token of the pool by address sort order
  /// @param pool The address of the created pool
  event Pool(address indexed token0, address indexed token1, address pool);

  /// @notice Emitted when the farming address is changed
  /// @param newFarmingAddress The farming address after the address was changed
  event FarmingAddress(address indexed newFarmingAddress);

  /// @notice Emitted when the default fee configuration is changed
  /// @param newConfig The structure with dynamic fee parameters
  /// @dev See the AdaptiveFee library for more details
  event DefaultFeeConfiguration(AlgebraFeeConfiguration newConfig);

  /// @notice Emitted when the default community fee is changed
  /// @param newDefaultCommunityFee The new default community fee value
  event DefaultCommunityFee(uint8 newDefaultCommunityFee);

  /// @notice role that can change communityFee and tickspacing in pools
  function POOLS_ADMINISTRATOR_ROLE() external view returns (bytes32);

  /// @dev Returns `true` if `account` has been granted `role` or `account` is owner.
  function hasRoleOrOwner(bytes32 role, address account) external view returns (bool);

  /// @notice Returns the current owner of the factory
  /// @dev Can be changed by the current owner via transferOwnership(address newOwner)
  /// @return The address of the factory owner
  function owner() external view returns (address);

  /// @notice Returns the current poolDeployerAddress
  /// @return The address of the poolDeployer
  function poolDeployer() external view returns (address);

  /// @dev Is retrieved from the pools to restrict calling certain functions not by a tokenomics contract
  /// @return The tokenomics contract address
  function farmingAddress() external view returns (address);

  /// @notice Returns the current communityVaultAddress
  /// @return The address to which community fees are transferred
  function communityVault() external view returns (address);

  /// @notice Returns the default community fee
  /// @return Fee which will be set at the creation of the pool
  function defaultCommunityFee() external view returns (uint8);

  /// @notice Returns the pool address for a given pair of tokens, or address 0 if it does not exist
  /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
  /// @param tokenA The contract address of either token0 or token1
  /// @param tokenB The contract address of the other token
  /// @return pool The pool address
  function poolByPair(address tokenA, address tokenB) external view returns (address pool);

  /// @return timestamp The timestamp of the beginning of the renounceOwnership process
  function renounceOwnershipStartTimestamp() external view returns (uint256 timestamp);

  /// @notice Creates a pool for the given two tokens
  /// @param tokenA One of the two tokens in the desired pool
  /// @param tokenB The other of the two tokens in the desired pool
  /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0.
  /// The call will revert if the pool already exists or the token arguments are invalid.
  /// @return pool The address of the newly created pool
  function createPool(address tokenA, address tokenB) external returns (address pool);

  /// @dev updates tokenomics address on the factory
  /// @param newFarmingAddress The new tokenomics contract address
  function setFarmingAddress(address newFarmingAddress) external;

  /// @dev updates default community fee for new pools
  /// @param newDefaultCommunityFee The new community fee, _must_ be <= MAX_COMMUNITY_FEE
  function setDefaultCommunityFee(uint8 newDefaultCommunityFee) external;

  /// @notice Changes initial fee configuration for new pools
  /// @dev changes coefficients for sigmoids: α / (1 + e^( (β-x) / γ))
  /// alpha1 + alpha2 + baseFee (max possible fee) must be <= type(uint16).max and gammas must be > 0
  /// @param newConfig new default fee configuration. See the #AdaptiveFee.sol library for details
  function setDefaultFeeConfiguration(AlgebraFeeConfiguration calldata newConfig) external;

  /// @notice Starts process of renounceOwnership. After that, a certain period
  /// of time must pass before the ownership renounce can be completed.
  function startRenounceOwnership() external;

  /// @notice Stops process of renounceOwnership and removes timer.
  function stopRenounceOwnership() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4 <0.9.0;

/// @title Errors emitted by a pool
/// @notice Contains custom errors emitted by the pool
interface IAlgebraPoolErrors {
  // ####  pool errors  ####

  /// @notice Emitted by the reentrancy guard
  error locked();

  /// @notice Emitted if arithmetic error occurred
  error arithmeticError();

  /// @notice Emitted if an attempt is made to initialize the pool twice
  error alreadyInitialized();

  /// @notice Emitted if 0 is passed as amountRequired to swap function
  error zeroAmountRequired();

  /// @notice Emitted if invalid amount is passed as amountRequired to swapSupportingFeeOnInputTokens function
  error invalidAmountRequired();

  /// @notice Emitted if the pool received fewer tokens than it should have
  error insufficientInputAmount();
  /// @notice Emitted if the pool received fewer tokens than it should have to mint calculated actual liquidity
  error insufficientAmountReceivedAtMint();

  /// @notice Emitted if there was an attempt to mint zero liquidity
  error zeroLiquidityDesired();
  /// @notice Emitted if actual amount of liquidity is zero (due to insufficient amount of tokens received)
  error zeroLiquidityActual();

  /// @notice Emitted if the pool received fewer tokens{0,1} after flash than it should have
  error flashInsufficientPaid0();
  error flashInsufficientPaid1();

  /// @notice Emitted if limitSqrtPrice param is incorrect
  error invalidLimitSqrtPrice();

  /// @notice Tick must be divisible by tickspacing
  error tickIsNotSpaced();

  /// @notice Emitted if a method is called that is accessible only to the factory owner or dedicated role
  error notAllowed();
  /// @notice Emitted if a method is called that is accessible only to the farming
  error onlyFarming();

  error invalidNewTickSpacing();
  error invalidNewCommunityFee();

  // ####  LimitOrder errors  ####
  /// @notice Emitted if tick is too low/high for limit order
  error invalidTickForLimitOrder();
  /// @notice Emitted if amount is too high for limit order
  error invalidAmountForLimitOrder();

  // ####  LiquidityMath errors  ####
  /// @notice Emitted if liquidity underflows
  error liquiditySub();
  /// @notice Emitted if liquidity overflows
  error liquidityAdd();

  // ####  TickManagement errors  ####
  error topTickLowerThanBottomTick();
  error bottomTickLowerThanMIN();
  error topTickAboveMAX();
  error liquidityOverflow();
  error tickIsNotInitialized();
  error tickInvalidLinks();

  // ####  SafeTransfer errors  ####
  error transferFailed();

  // ####  TickMath errors  ####
  error tickOutOfRange();
  error priceOutOfRange();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '../interfaces/IAlgebraPoolErrors.sol';

/// @title SafeTransfer
/// @notice Safe ERC20 transfer library that gracefully handles missing return values.
/// @dev Credit to Solmate under MIT license: https://github.com/transmissions11/solmate/blob/ed67feda67b24fdeff8ad1032360f0ee6047ba0a/src/utils/SafeTransferLib.sol
/// @dev Please note that this library does not check if the token has a code! That responsibility is delegated to the caller.
library SafeTransfer {
  /// @notice Transfers tokens to a recipient
  /// @dev Calls transfer on token contract, errors with transferFailed() if transfer fails
  /// @param token The contract address of the token which will be transferred
  /// @param to The recipient of the transfer
  /// @param amount The amount of the token to transfer
  function safeTransfer(address token, address to, uint256 amount) internal {
    bool success;
    assembly {
      let freeMemoryPointer := mload(0x40) // we will need to restore 0x40 slot
      mstore(0x00, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // "transfer(address,uint256)" selector
      mstore(0x04, and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // append cleaned "to" address
      mstore(0x24, amount)
      // now we use 0x00 - 0x44 bytes (68), freeMemoryPointer is dirty
      success := call(gas(), token, 0, 0, 0x44, 0, 0x20)
      success := and(
        // set success to true if call isn't reverted and returned exactly 1 (can't just be non-zero data) or nothing
        or(and(eq(mload(0), 1), eq(returndatasize(), 32)), iszero(returndatasize())),
        success
      )
      mstore(0x40, freeMemoryPointer) // restore the freeMemoryPointer
    }

    if (!success) revert IAlgebraPoolErrors.transferFailed();
  }
}