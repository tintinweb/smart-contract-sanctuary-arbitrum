// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title Library for errors
/// @author Timeswap Labs
/// @dev Common error messages
library Error {
  /// @dev Reverts when input is zero.
  error ZeroInput();

  /// @dev Reverts when output is zero.
  error ZeroOutput();

  /// @dev Reverts when a value cannot be zero.
  error CannotBeZero();

  /// @dev Reverts when a pool already have liquidity.
  /// @param liquidity The liquidity amount that already existed in the pool.
  error AlreadyHaveLiquidity(uint160 liquidity);

  /// @dev Reverts when a pool requires liquidity.
  error RequireLiquidity();

  /// @dev Reverts when a given address is the zero address.
  error ZeroAddress();

  /// @dev Reverts when the maturity given is not withing uint96.
  /// @param maturity The maturity being inquired.
  error IncorrectMaturity(uint256 maturity);

  /// @dev Reverts when an option of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  error InactiveOption(uint256 strike, uint256 maturity);

  /// @dev Reverts when a pool of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  error InactivePool(uint256 strike, uint256 maturity);

  /// @dev Reverts when a liquidity token is inactive.
  error InactiveLiquidityTokenChoice();

  /// @dev Reverts when the square root interest rate is zero.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  error ZeroSqrtInterestRate(uint256 strike, uint256 maturity);

  /// @dev Reverts when the maturity is already matured.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  error AlreadyMatured(uint256 maturity, uint96 blockTimestamp);

  /// @dev Reverts when the maturity is still active.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  error StillActive(uint256 maturity, uint96 blockTimestamp);

  /// @dev Token amount not received.
  /// @param minuend The amount being subtracted.
  /// @param subtrahend The amount subtracting.
  error NotEnoughReceived(uint256 minuend, uint256 subtrahend);

  /// @dev The deadline of a transaction has been reached.
  /// @param deadline The deadline set.
  error DeadlineReached(uint256 deadline);

  /// @dev Reverts when input is zero.
  function zeroInput() internal pure {
    revert ZeroInput();
  }

  /// @dev Reverts when output is zero.
  function zeroOutput() internal pure {
    revert ZeroOutput();
  }

  /// @dev Reverts when a value cannot be zero.
  function cannotBeZero() internal pure {
    revert CannotBeZero();
  }

  /// @dev Reverts when a pool already have liquidity.
  /// @param liquidity The liquidity amount that already existed in the pool.
  function alreadyHaveLiquidity(uint160 liquidity) internal pure {
    revert AlreadyHaveLiquidity(liquidity);
  }

  /// @dev Reverts when a pool requires liquidity.
  function requireLiquidity() internal pure {
    revert RequireLiquidity();
  }

  /// @dev Reverts when a given address is the zero address.
  function zeroAddress() internal pure {
    revert ZeroAddress();
  }

  /// @dev Reverts when the maturity given is not withing uint96.
  /// @param maturity The maturity being inquired.
  function incorrectMaturity(uint256 maturity) internal pure {
    revert IncorrectMaturity(maturity);
  }

  /// @dev Reverts when the maturity is already matured.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  function alreadyMatured(uint256 maturity, uint96 blockTimestamp) internal pure {
    revert AlreadyMatured(maturity, blockTimestamp);
  }

  /// @dev Reverts when the maturity is still active.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  function stillActive(uint256 maturity, uint96 blockTimestamp) internal pure {
    revert StillActive(maturity, blockTimestamp);
  }

  /// @dev The deadline of a transaction has been reached.
  /// @param deadline The deadline set.
  function deadlineReached(uint256 deadline) internal pure {
    revert DeadlineReached(deadline);
  }

  /// @dev Reverts when an option of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  function inactiveOptionChoice(uint256 strike, uint256 maturity) internal pure {
    revert InactiveOption(strike, maturity);
  }

  /// @dev Reverts when a pool of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  function inactivePoolChoice(uint256 strike, uint256 maturity) internal pure {
    revert InactivePool(strike, maturity);
  }

  /// @dev Reverts when the square root interest rate is zero.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  function zeroSqrtInterestRate(uint256 strike, uint256 maturity) internal pure {
    revert ZeroSqrtInterestRate(strike, maturity);
  }

  /// @dev Reverts when a liquidity token is inactive.
  function inactiveLiquidityTokenChoice() internal pure {
    revert InactiveLiquidityTokenChoice();
  }

  /// @dev Reverts when token amount not received.
  /// @param balance The balance amount being subtracted.
  /// @param balanceTarget The amount target.
  function checkEnough(uint256 balance, uint256 balanceTarget) internal pure {
    if (balance < balanceTarget) revert NotEnoughReceived(balance, balanceTarget);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2OptionMintCallbackParam} from "../../structs/CallbackParam.sol";

/// @title Callback for ITimeswapV2Option#mint
/// @notice Any contract that calls ITimeswapV2Option#mint must implement this interface.
interface ITimeswapV2OptionMintCallback {
  /// @notice Called to `msg.sender` after initiating a mint from ITimeswapV2Option#mint.
  /// @dev In the implementation, you must transfer token0 and token1 for the mint transaction.
  /// The caller of this method must be checked to be a Timeswap V2 Option pair deployed by the canonical Timeswap V2 Factory.
  /// @dev The long0 positions, long1 positions, and/or short positions will already minted to the recipients.
  /// @param param The parameter of the callback.
  /// @return data The bytes code returned from the callback.
  function timeswapV2OptionMintCallback(
    TimeswapV2OptionMintCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2OptionSwapCallbackParam} from "../../structs/CallbackParam.sol";

/// @title Callback for ITimeswapV2Option#swap
/// @notice Any contract that calls ITimeswapV2Option#swap must implement this interface.
interface ITimeswapV2OptionSwapCallback {
  /// @notice Called to `msg.sender` after initiating a swap from ITimeswapV2Option#swap.
  /// @dev In the implementation, you must transfer token0 for the swap transaction.
  /// The caller of this method must be checked to be a Timeswap V2 Option pair deployed by the canonical Timeswap V2 Factory.
  /// @dev The long0 positions or long1 positions will already minted to the recipients.
  /// @param param The param of the swap callback.
  /// @return data The bytes code returned from the callback.
  function timeswapV2OptionSwapCallback(
    TimeswapV2OptionSwapCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title The interface for the contract that deploys Timeswap V2 Option pair contracts
/// @notice The Timeswap V2 Option Factory facilitates creation of Timeswap V2 Options pair.
interface ITimeswapV2OptionFactory {
  /* ===== EVENT ===== */

  /// @dev Emits when a new Timeswap V2 Option contract is created.
  /// @param caller The address of the caller of create function.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the Timeswap V2 Option contract created.
  event Create(address indexed caller, address indexed token0, address indexed token1, address optionPair);

  /* ===== VIEW ===== */

  /// @dev Returns the address of a Timeswap V2 Option.
  /// @dev Returns a zero address if the Timeswap V2 Option does not exist.
  /// @notice The token0 address must be smaller than token1 address.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @return optionPair The address of the Timeswap V2 Option contract or a zero address.
  function get(address token0, address token1) external view returns (address optionPair);

  /// @dev Get the address of the option pair in the option pair enumeration list.
  /// @param id The chosen index.
  function getByIndex(uint256 id) external view returns (address optionPair);

  /// @dev The number of option pairs deployed.
  function numberOfPairs() external view returns (uint256);

  /* ===== UPDATE ===== */

  /// @dev Creates a Timeswap V2 Option based on pair parameters.
  /// @dev Cannot create a duplicate Timeswap V2 Option with the same pair parameters.
  /// @notice The token0 address must be smaller than token1 address.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the Timeswap V2 Option contract created.
  function create(address token0, address token1) external returns (address optionPair);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

import {OptionPairLibrary} from "./OptionPair.sol";

import {ITimeswapV2OptionFactory} from "../interfaces/ITimeswapV2OptionFactory.sol";

/// @title library for option utils
/// @author Timeswap Labs
library OptionFactoryLibrary {
  using OptionPairLibrary for address;

  /// @dev reverts if the factory is the zero address.
  error ZeroFactoryAddress();

  /// @dev check if the factory address is not zero.
  /// @param optionFactory The factory address.
  function checkNotZeroFactory(address optionFactory) internal pure {
    if (optionFactory == address(0)) revert ZeroFactoryAddress();
  }

  /// @dev Helper function to get the option pair address.
  /// @param optionFactory The address of the option factory.
  /// @param token0 The smaller ERC20 address of the pair.
  /// @param token1 The larger ERC20 address of the pair.
  /// @return optionPair The result option pair address.
  function get(address optionFactory, address token0, address token1) internal view returns (address optionPair) {
    optionPair = ITimeswapV2OptionFactory(optionFactory).get(token0, token1);
  }

  /// @dev Helper function to get the option pair address.
  /// @notice reverts when the option pair does not exist.
  /// @param optionFactory The address of the option factory.
  /// @param token0 The smaller ERC20 address of the pair.
  /// @param token1 The larger ERC20 address of the pair.
  /// @return optionPair The result option pair address.
  function getWithCheck(
    address optionFactory,
    address token0,
    address token1
  ) internal view returns (address optionPair) {
    optionPair = get(optionFactory, token0, token1);
    if (optionPair == address(0)) Error.zeroAddress();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title library for optionPair utils
/// @author Timeswap Labs
library OptionPairLibrary {
  /// @dev Reverts when option address is zero.
  error ZeroOptionAddress();

  /// @dev Reverts when the pair has incorrect format.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  error InvalidOptionPair(address token0, address token1);

  /// @dev Reverts when the Timeswap V2 Option already exist.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the existed Pair contract.
  error OptionPairAlreadyExisted(address token0, address token1, address optionPair);

  /// @dev Checks if option address is not zero.
  /// @param optionPair The option pair address being inquired.
  function checkNotZeroAddress(address optionPair) internal pure {
    if (optionPair == address(0)) revert ZeroOptionAddress();
  }

  /// @dev Check if the pair tokens is in correct format.
  /// @notice Reverts if token0 is greater than or equal token1.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  function checkCorrectFormat(address token0, address token1) internal pure {
    if (token0 >= token1) revert InvalidOptionPair(token0, token1);
  }

  /// @dev Check if the pair already existed.
  /// @notice Reverts if the pair is not a zero address.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  /// @param optionPair The address of the existed Pair contract.
  function checkDoesNotExist(address token0, address token1, address optionPair) internal pure {
    if (optionPair != address(0)) revert OptionPairAlreadyExisted(token0, token1, optionPair);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev Parameter for the mint callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param token0AndLong0Amount The token0 amount to be deposited and the long0 amount minted.
/// @param token1AndLong1Amount The token1 amount to be deposited and the long1 amount minted.
/// @param shortAmount The short amount minted.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionMintCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev Parameter for the burn callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param token0AndLong0Amount The token0 amount to be withdrawn and the long0 amount burnt.
/// @param token1AndLong1Amount The token1 amount to be withdrawn and the long1 amount burnt.
/// @param shortAmount The short amount burnt.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionBurnCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev Parameter for the swap callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param isLong0ToLong1 True when swapping long0 for long1. False when swapping long1 for long0.
/// @param token0AndLong0Amount If isLong0ToLong1 is true, the amount of long0 burnt and token0 to be withdrawn.
/// If isLong0ToLong1 is false, the amount of long0 minted and token0 to be deposited.
/// @param token1AndLong1Amount If isLong0ToLong1 is true, the amount of long1 withdrawn and token0 to be deposited.
/// If isLong0ToLong1 is false, the amount of long1 burnt and token1 to be withdrawn.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionSwapCallbackParam {
  uint256 strike;
  uint256 maturity;
  bool isLong0ToLong1;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
  bytes data;
}

/// @dev Parameter for the collect callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param token0Amount The token0 amount to be withdrawn.
/// @param token1Amount The token1 amount to be withdrawn.
/// @param shortAmount The short amount burnt.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionCollectCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 token0Amount;
  uint256 token1Amount;
  uint256 shortAmount;
  bytes data;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.8;

import "../interfaces/IMulticall.sol";

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
  /// @inheritdoc IMulticall
  function multicall(bytes[] calldata data) public payable override returns (bytes[] memory results) {
    results = new bytes[](data.length);
    for (uint256 i = 0; i < data.length; i++) {
      (bool success, bytes memory result) = address(this).delegatecall(data[i]);

      if (!success) {
        // Next 5 lines from https://ethereum.stackexchange.com/a/83577
        if (result.length < 68) revert MulticallFailed("Invalid Result");
        assembly {
          result := add(result, 0x04)
        }
        revert MulticallFailed(abi.decode(result, (string)));
      }

      results[i] = result;
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.8;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
  /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
  /// @dev The `msg.value` should not be trusted for any method callable from multicall.
  /// @param data The encoded function data for each of the calls to make to this contract
  /// @return results The results from each of the calls passed in via data
  function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);

  error MulticallFailed(string revertString);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ITimeswapV2OptionMintCallback} from "@timeswap-labs/v2-option/contracts/interfaces/callbacks/ITimeswapV2OptionMintCallback.sol";
import {ITimeswapV2OptionSwapCallback} from "@timeswap-labs/v2-option/contracts/interfaces/callbacks/ITimeswapV2OptionSwapCallback.sol";

import {ITimeswapV2PoolMintCallback} from "@timeswap-labs/v2-pool/contracts/interfaces/callbacks/ITimeswapV2PoolMintCallback.sol";
import {ITimeswapV2PoolBurnCallback} from "@timeswap-labs/v2-pool/contracts/interfaces/callbacks/ITimeswapV2PoolBurnCallback.sol";
import {ITimeswapV2PoolDeleverageCallback} from "@timeswap-labs/v2-pool/contracts/interfaces/callbacks/ITimeswapV2PoolDeleverageCallback.sol";
import {ITimeswapV2PoolLeverageCallback} from "@timeswap-labs/v2-pool/contracts/interfaces/callbacks/ITimeswapV2PoolLeverageCallback.sol";
import {IMulticall} from "./IMulticall.sol";

/// @title An interface for TS-V2 Periphery
interface ITimeswapV2Periphery is IMulticall {
  error RequireDeploymentOfOption(address token0, address token1);

  error RequireDeploymentOfPool(address token0, address token1);

  /// @dev Returns the option factory address.
  /// @return optionFactory The option factory address.
  function optionFactory() external returns (address);

  /// @dev Returns the pool factory address.
  /// @return poolFactory The pool factory address.
  function poolFactory() external returns (address);

  /// @dev Returns the option pair address.
  /// @param token0 Address of token0
  /// @param token1 Address of token1
  /// @return optionPair The option pair address.
  function getOption(address token0, address token1) external view returns (address optionPair);

  /// @dev Returns the pool pair address.
  /// @param token0 Address of token0
  /// @param token1 Address of token1
  /// @return optionPair The option pair address.
  /// @return poolPair The pool pair address.
  function getPool(address token0, address token1) external view returns (address optionPair, address poolPair);

  /// @dev Deploys the option pair contract.
  /// @param token0 Address of token0
  /// @param token1 Address of token1
  /// @return optionPair The option pair address.
  function deployOption(address token0, address token1) external returns (address optionPair);

  /// @dev Deploys the pool pair contract.
  /// @param token0 Address of token0
  /// @param token1 Address of token1
  /// @return poolPair The pool pair address.
  function deployPool(address token0, address token1) external returns (address poolPair);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {ITimeswapV2OptionFactory} from "@timeswap-labs/v2-option/contracts/interfaces/ITimeswapV2OptionFactory.sol";

import {OptionFactoryLibrary} from "@timeswap-labs/v2-option/contracts/libraries/OptionFactory.sol";

import {ITimeswapV2PoolFactory} from "@timeswap-labs/v2-pool/contracts/interfaces/ITimeswapV2PoolFactory.sol";

import {PoolFactoryLibrary} from "@timeswap-labs/v2-pool/contracts/libraries/PoolFactory.sol";

import {ITimeswapV2Periphery} from "./interfaces/ITimeswapV2Periphery.sol";

import {Multicall} from "./base/Multicall.sol";

/// @title Contract which specifies functions that are required getters/deployers for pool/option addresses
contract TimeswapV2Periphery is ITimeswapV2Periphery, Multicall {
  using OptionFactoryLibrary for address;
  using PoolFactoryLibrary for address;
  /* ===== MODEL ===== */
  /// @inheritdoc ITimeswapV2Periphery
  address public immutable override optionFactory;
  /// @inheritdoc ITimeswapV2Periphery
  address public immutable override poolFactory;

  /* ===== INIT ===== */

  constructor(address chosenOptionFactory, address chosenPoolFactory) {
    optionFactory = chosenOptionFactory;
    poolFactory = chosenPoolFactory;
  }

  ///@notice function to get option contract address given token0, token1
  ///@param token0 address of token0
  ///@param token1 address of token1
  ///@return optionPair address of optionPair
  function getOption(address token0, address token1) external view returns (address optionPair) {
    optionPair = OptionFactoryLibrary.get(optionFactory, token0, token1);
  }

  ///@notice function to get pool contract address given token0, token1
  ///@param token0 address of token0
  ///@param token1 address of token1
  ///@return optionPair address of optionPair
  ///@return poolPair address of poolPair
  function getPool(address token0, address token1) external view returns (address optionPair, address poolPair) {
    (optionPair, poolPair) = PoolFactoryLibrary.get(optionFactory, poolFactory, token0, token1);
  }

  ///@notice function to deploy option contract address given token0, token1
  ///@param token0 address of token0
  ///@param token1 address of token1
  ///@return optionPair address of optionPair
  function deployOption(address token0, address token1) external returns (address optionPair) {
    optionPair = ITimeswapV2OptionFactory(optionFactory).create(token0, token1);
  }

  ///@notice function to deploy pool contract address given token0, token1
  ///@param token0 address of token0
  ///@param token1 address of token1
  ///@return poolPair address of poolPair
  function deployPool(address token0, address token1) external returns (address poolPair) {
    poolPair = ITimeswapV2PoolFactory(poolFactory).create(token0, token1);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2PoolBurnChoiceCallbackParam, TimeswapV2PoolBurnCallbackParam} from "../../structs/CallbackParam.sol";

/// @dev The interface that needs to be implemented by a contract calling the burn function.
interface ITimeswapV2PoolBurnCallback {
  /// @dev Returns the amount of long0 position and long1 positions chosen to be withdrawn.
  /// @notice The StrikeConversion.combine of long0 position and long1 position must be less than or equal to long amount.
  /// @return long0Amount Amount of long0 position to be withdrawn.
  /// @return long1Amount Amount of long1 position to be withdrawn.
  /// @return data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolBurnChoiceCallback(
    TimeswapV2PoolBurnChoiceCallbackParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data);

  /// @dev Require enough liquidity position by the msg.sender.
  /// @return data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolBurnCallback(
    TimeswapV2PoolBurnCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2PoolDeleverageChoiceCallbackParam, TimeswapV2PoolDeleverageCallbackParam} from "../../structs/CallbackParam.sol";

/// @dev The interface that needs to be implemented by a contract calling the deleverage function.
interface ITimeswapV2PoolDeleverageCallback {
  /// @dev Returns the amount of long0 position and long1 positions chosen to be deposited to the pool.
  /// @notice The StrikeConversion.combine of long0 position and long1 position must be greater than or equal to long amount.
  /// @dev The short positions will already be minted to the recipient.
  /// @return long0Amount Amount of long0 position to be deposited.
  /// @return long1Amount Amount of long1 position to be deposited.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolDeleverageChoiceCallback(
    TimeswapV2PoolDeleverageChoiceCallbackParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data);

  /// @dev Require the transfer of long0 position and long1 position into the pool.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolDeleverageCallback(
    TimeswapV2PoolDeleverageCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2PoolLeverageChoiceCallbackParam, TimeswapV2PoolLeverageCallbackParam} from "../../structs/CallbackParam.sol";

/// @dev The interface that needs to be implemented by a contract calling the leverage function.
interface ITimeswapV2PoolLeverageCallback {
  /// @dev Returns the amount of long0 position and long1 positions chosen to be withdrawn.
  /// @notice The StrikeConversion.combine of long0 position and long1 position must be less than or equal to long amount.
  /// @dev The long0 positions and long1 positions will already be minted to the recipients.
  /// @return long0Amount Amount of long0 position to be withdrawn.
  /// @return long1Amount Amount of long1 position to be withdrawn.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolLeverageChoiceCallback(
    TimeswapV2PoolLeverageChoiceCallbackParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data);

  /// @dev Require the transfer of short position into the pool.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolLeverageCallback(
    TimeswapV2PoolLeverageCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2PoolMintChoiceCallbackParam, TimeswapV2PoolMintCallbackParam} from "../../structs/CallbackParam.sol";

/// @dev The interface that needs to be implemented by a contract calling the mint function.
interface ITimeswapV2PoolMintCallback {
  /// @dev Returns the amount of long0 position and long1 positions chosen to be deposited to the pool.
  /// @notice The StrikeConversion.combine of long0 position and long1 position must be greater than or equal to long amount.
  /// @dev The liquidity positions will already be minted to the recipient.
  /// @return long0Amount Amount of long0 position to be deposited.
  /// @return long1Amount Amount of long1 position to be deposited.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolMintChoiceCallback(
    TimeswapV2PoolMintChoiceCallbackParam calldata param
  ) external returns (uint256 long0Amount, uint256 long1Amount, bytes memory data);

  /// @dev Require the transfer of long0 position, long1 position, and short position into the pool.
  /// @param data The bytes of data to be sent to msg.sender.
  function timeswapV2PoolMintCallback(
    TimeswapV2PoolMintCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

interface IOwnableTwoSteps {
  /// @dev Emits when the pending owner is chosen.
  /// @param pendingOwner The new pending owner.
  event SetOwner(address pendingOwner);

  /// @dev Emits when the pending owner accepted and become the new owner.
  /// @param owner The new owner.
  event AcceptOwner(address owner);

  /// @dev The address of the current owner.
  /// @return address
  function owner() external view returns (address);

  /// @dev The address of the current pending owner.
  /// @notice The address can be zero which signifies no pending owner.
  /// @return address
  function pendingOwner() external view returns (address);

  /// @dev The owner sets the new pending owner.
  /// @notice Can only be called by the owner.
  /// @param chosenPendingOwner The newly chosen pending owner.
  function setPendingOwner(address chosenPendingOwner) external;

  /// @dev The pending owner accepts being the new owner.
  /// @notice Can only be called by the pending owner.
  function acceptOwner() external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IOwnableTwoSteps} from "./IOwnableTwoSteps.sol";

/// @title The interface for the contract that deploys Timeswap V2 Pool pair contracts
/// @notice The Timeswap V2 Pool Factory facilitates creation of Timeswap V2 Pool pair.
interface ITimeswapV2PoolFactory is IOwnableTwoSteps {
  /* ===== EVENT ===== */

  /// @dev Emits when a new Timeswap V2 Pool contract is created.
  /// @param caller The address of the caller of create function.
  /// @param option The address of the option contract used by the pool.
  /// @param poolPair The address of the Timeswap V2 Pool contract created.
  event Create(address indexed caller, address indexed option, address indexed poolPair);

  /* ===== VIEW ===== */

  /// @dev Returns the address of the Timeswap V2 Option factory contract utilized by Timeswap V2 Pool factory contract.
  function optionFactory() external view returns (address);

  /// @dev Returns the fixed transaction fee used by all created Timeswap V2 Pool contract.
  function transactionFee() external view returns (uint256);

  /// @dev Returns the fixed protocol fee used by all created Timeswap V2 Pool contract.
  function protocolFee() external view returns (uint256);

  /// @dev Returns the address of a Timeswap V2 Pool.
  /// @dev Returns a zero address if the Timeswap V2 Pool does not exist.
  /// @param option The address of the option contract used by the pool.
  /// @return poolPair The address of the Timeswap V2 Pool contract or a zero address.
  function get(address option) external view returns (address poolPair);

  /// @dev Returns the address of a Timeswap V2 Pool.
  /// @dev Returns a zero address if the Timeswap V2 Pool does not exist.
  /// @param token0 The address of the smaller sized address of ERC20.
  /// @param token1 The address of the larger sized address of ERC20.
  /// @return poolPair The address of the Timeswap V2 Pool contract or a zero address.
  function get(address token0, address token1) external view returns (address poolPair);

  function getByIndex(uint256 id) external view returns (address optionPair);

  function numberOfPairs() external view returns (uint256);

  /* ===== UPDATE ===== */

  /// @dev Creates a Timeswap V2 Pool based on option parameter.
  /// @dev Cannot create a duplicate Timeswap V2 Pool with the same option parameter.
  /// @param token0 The address of the smaller sized address of ERC20.
  /// @param token1 The address of the larger sized address of ERC20.
  /// @param poolPair The address of the Timeswap V2 Pool contract created.
  function create(address token0, address token1) external returns (address poolPair);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {OptionFactoryLibrary} from "@timeswap-labs/v2-option/contracts/libraries/OptionFactory.sol";

import {ITimeswapV2PoolFactory} from "../interfaces/ITimeswapV2PoolFactory.sol";

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

/// @title library for calculating poolFactory functions
/// @author Timeswap Labs
library PoolFactoryLibrary {
  using OptionFactoryLibrary for address;

  /// @dev Reverts when pool factory address is zero.
  error ZeroFactoryAddress();

  /// @dev Checks if the pool factory address is zero.
  /// @param poolFactory The pool factory address which is needed to be checked.
  function checkNotZeroFactory(address poolFactory) internal pure {
    if (poolFactory == address(0)) revert ZeroFactoryAddress();
  }

  /// @dev Get the option pair address and pool pair address.
  /// @param optionFactory The option factory contract address.
  /// @param poolFactory The pool factory contract address.
  /// @param token0 The address of the smaller address ERC20 token contract.
  /// @param token1 The address of the larger address ERC20 token contract.
  /// @return optionPair The retrieved option pair address. Zero address if not deployed.
  /// @return poolPair The retrieved pool pair address. Zero address if not deployed.
  function get(
    address optionFactory,
    address poolFactory,
    address token0,
    address token1
  ) internal view returns (address optionPair, address poolPair) {
    optionPair = optionFactory.get(token0, token1);

    poolPair = ITimeswapV2PoolFactory(poolFactory).get(optionPair);
  }

  /// @dev Get the option pair address and pool pair address.
  /// @notice Reverts when the option or the pool is not deployed.
  /// @param optionFactory The option factory contract address.
  /// @param poolFactory The pool factory contract address.
  /// @param token0 The address of the smaller address ERC20 token contract.
  /// @param token1 The address of the larger address ERC20 token contract.
  /// @return optionPair The retrieved option pair address.
  /// @return poolPair The retrieved pool pair address.
  function getWithCheck(
    address optionFactory,
    address poolFactory,
    address token0,
    address token1
  ) internal view returns (address optionPair, address poolPair) {
    optionPair = optionFactory.getWithCheck(token0, token1);

    poolPair = ITimeswapV2PoolFactory(poolFactory).get(optionPair);

    if (poolPair == address(0)) Error.zeroAddress();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev The parameters for the add fees callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Fees The amount of long0 position required by the pool from msg.sender.
/// @param long1Fees The amount of long1 position required by the pool from msg.sender.
/// @param shortFees The amount of short position required by the pool from msg.sender.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolAddFeesCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Fees;
  uint256 long1Fees;
  uint256 shortFees;
  bytes data;
}

/// @dev The parameters for the mint choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param longAmount The amount of long position in base denomination required by the pool from msg.sender.
/// @param shortAmount The amount of short position required by the pool from msg.sender.
/// @param liquidityAmount The amount of liquidity position minted.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolMintChoiceCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 longAmount;
  uint256 shortAmount;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev The parameters for the mint callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Amount The amount of long0 position required by the pool from msg.sender.
/// @param long1Amount The amount of long1 position required by the pool from msg.sender.
/// @param shortAmount The amount of short position required by the pool from msg.sender.
/// @param liquidityAmount The amount of liquidity position minted.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolMintCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev The parameters for the burn choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Balance The amount of long0 position that can be withdrawn from the pool.
/// @param long1Balance The amount of long1 position that can be withdrawn from the pool.
/// @param longAmount The amount of long position in base denomination that will be withdrawn.
/// @param shortAmount The amount of short position that will be withdrawn.
/// @param liquidityAmount The amount of liquidity position burnt.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolBurnChoiceCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Balance;
  uint256 long1Balance;
  uint256 longAmount;
  uint256 shortAmount;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev The parameters for the burn callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Amount The amount of long0 position that will be withdrawn.
/// @param long1Amount The amount of long1 position that will be withdrawn.
/// @param shortAmount The amount of short position that will be withdrawn.
/// @param liquidityAmount The amount of liquidity position burnt.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolBurnCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  uint160 liquidityAmount;
  bytes data;
}

/// @dev The parameters for the deleverage choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Amount The amount of long0 position required by the pool from msg.sender.
/// @param long1Amount The amount of long1 position required by the pool from msg.sender.
/// @param shortAmount The amount of short position that will be withdrawn.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolDeleverageChoiceCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 longAmount;
  uint256 shortAmount;
  bytes data;
}

/// @dev The parameters for the deleverage callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param longAmount The amount of long position in base denomination required by the pool from msg.sender.
/// @param shortAmount The amount of short position that will be withdrawn.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolDeleverageCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev The parameters for the leverage choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Balance The amount of long0 position that can be withdrawn from the pool.
/// @param long1Balance The amount of long1 position that can be withdrawn from the pool.
/// @param longAmount The amount of long position in base denomination that will be withdrawn.
/// @param shortAmount The amount of short position required by the pool from msg.sender.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolLeverageChoiceCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Balance;
  uint256 long1Balance;
  uint256 longAmount;
  uint256 shortAmount;
  bytes data;
}

/// @dev The parameters for the leverage choice callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param long0Amount The amount of long0 position that can be withdrawn.
/// @param long1Amount The amount of long1 position that can be withdrawn.
/// @param shortAmount The amount of short position required by the pool from msg.sender.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolLeverageCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 long0Amount;
  uint256 long1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev The parameters for the rebalance callback.
/// @param strike The strike price of the pool.
/// @param maturity The maturity of the pool.
/// @param isLong0ToLong1 Long0ToLong1 when true. Long1ToLong0 when false.
/// @param long0Amount When Long0ToLong1, the amount of long0 position required by the pool from msg.sender.
/// When Long1ToLong0, the amount of long0 position that can be withdrawn.
/// @param long1Amount When Long0ToLong1, the amount of long1 position that can be withdrawn.
/// When Long1ToLong0, the amount of long1 position required by the pool from msg.sender.
/// @param data The bytes of data to be sent to msg.sender.
struct TimeswapV2PoolRebalanceCallbackParam {
  uint256 strike;
  uint256 maturity;
  bool isLong0ToLong1;
  uint256 long0Amount;
  uint256 long1Amount;
  bytes data;
}