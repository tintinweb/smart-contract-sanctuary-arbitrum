// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

abstract contract Admin {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.FRACT10N.admin')) - 1)
   */
  bytes32 constant _adminSlot = 0xce00b027a69a53c861af45595a8cf45803b5ac2b4ac1de9fc600df4275db0c38;

  modifier onlyAdmin() {
    require(msg.sender == getAdmin(), "FRACT10N: admin only function");
    _;
  }

  constructor() {}

  function admin() public view returns (address) {
    return getAdmin();
  }

  function getAdmin() public view returns (address adminAddress) {
    assembly {
      adminAddress := sload(_adminSlot)
    }
  }

  function setAdmin(address adminAddress) public onlyAdmin {
    assembly {
      sstore(_adminSlot, adminAddress)
    }
  }

  function adminCall(address target, bytes calldata data) external payable onlyAdmin {
    assembly {
      calldatacopy(0, data.offset, data.length)
      let result := call(gas(), target, callvalue(), 0, data.length, 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  function adminDelegateCall(address target, bytes calldata data) external payable onlyAdmin {
    assembly {
      calldatacopy(0, data.offset, data.length)
      let result := delegatecall(gas(), target, 0, data.length, 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  function adminStaticCall(address target, bytes calldata data) external view onlyAdmin {
    assembly {
      calldatacopy(0, data.offset, data.length)
      let result := staticcall(gas(), target, 0, data.length, 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import {InitializableInterface} from "../interface/InitializableInterface.sol";

abstract contract Initializable is InitializableInterface {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.FRACT10N.initialized')) - 1)
   */
  bytes32 constant _initializedSlot = 0xea16ca35b2bc1c07977062f4d8e3e28f8f6d9d37576ddf51150bf265f8912f29;

  /**
   * @dev Constructor is left empty and init is used instead
   */
  constructor() {}

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract
   * @param initPayload abi encoded payload to use for contract initilaization
   */
  function init(bytes memory initPayload) external virtual returns (bytes4);

  function _isInitialized() internal view returns (bool initialized) {
    assembly {
      initialized := sload(_initializedSlot)
    }
  }

  function _setInitialized() internal {
    assembly {
      sstore(_initializedSlot, 0x0000000000000000000000000000000000000000000000000000000000000001)
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
/*

                         ┌───────────┐
                         │ HOLOGRAPH │
                         └───────────┘
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║                            / ^ \                            ║
║                            ~~*~~            ¸               ║
║                         [ '<>:<>' ]         │░░░            ║
║               ╔╗           _/"\_           ╔╣               ║
║             ┌─╬╬─┐          """          ┌─╬╬─┐             ║
║          ┌─┬┘ ╠╣ └┬─┐       \_/       ┌─┬┘ ╠╣ └┬─┐          ║
║       ┌─┬┘ │  ╠╣  │ └┬─┐           ┌─┬┘ │  ╠╣  │ └┬─┐       ║
║    ┌─┬┘ │  │  ╠╣  │  │ └┬─┐     ┌─┬┘ │  │  ╠╣  │  │ └┬─┐    ║
║ ┌─┬┘ │  │  │  ╠╣  │  │  │ └┬┐ ┌┬┘ │  │  │  ╠╣  │  │  │ └┬─┐ ║
╠┬┘ │  │  │  │  ╠╣  │  │  │  │└¤┘│  │  │  │  ╠╣  │  │  │  │ └┬╣
║│  │  │  │  │  ╠╣  │  │  │  │   │  │  │  │  ╠╣  │  │  │  │  │║
╠╩══╩══╩══╩══╩══╬╬══╩══╩══╩══╩═══╩══╩══╩══╩══╬╬══╩══╩══╩══╩══╩╣
╠┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╣
║               ╠╣                           ╠╣               ║
║               ╠╣                           ╠╣               ║
║    ,          ╠╣     ,        ,'      *    ╠╣               ║
║~~~~~^~~~~~~~~┌╬╬┐~~~^~~~~~~~~^^~~~~~~~~^~~┌╬╬┐~~~~~~~^~~~~~~║
╚══════════════╩╩╩╩═════════════════════════╩╩╩╩══════════════╝
     - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

import {Admin} from "../../abstract/Admin.sol";
import {IByte3IncOnChainServices} from "../interface/IByte3IncOnChainServices.sol";
import {IFractionToken} from "../../interface/IFractionToken.sol";
import {InitializableInterface, Initializable} from "../../abstract/Initializable.sol";

abstract contract Byte3IncOnChainServices is Admin, Initializable, IByte3IncOnChainServices {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.BYTE3.fractionToken')) - 1)
   */
  bytes32 constant _fractionTokenSlot = 0xabbde9d588642a8feacb536d35c2f63246a01aeb35d1c74374133210bbc3cd94;

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract
   * @param initPayload abi encoded payload to use for contract initilaization
   */
  function init(bytes memory initPayload) external virtual override returns (bytes4) {
    return _init(initPayload);
  }

  function _init(bytes memory) internal returns (bytes4) {
    require(!_isInitialized(), "BYTE3: already initialized");
    assembly {
      let currentAdmin := sload(_adminSlot)
      switch eq(currentAdmin, 0x0000000000000000000000000000000000000000000000000000000000000000)
      case 1 {
        sstore(_adminSlot, origin())
      }
    }
    _setInitialized();
    return InitializableInterface.init.selector;
  }

  function approve() external virtual;

  function convertUsdToWei(uint256 usdAmount) external view virtual returns (uint256 weiAmount);

  function getUSDC() external pure virtual returns (address);

  function getWETH() external pure virtual returns (address);

  function needsApproval() external view virtual returns (bool);

  function purchaseFractionToken(
    address recipient,
    uint256 usdAmount
  ) external payable virtual returns (uint256 remainder);

  function _fractionToken() internal view returns (IFractionToken fractionToken) {
    assembly {
      fractionToken := sload(_fractionTokenSlot)
    }
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import {Byte3IncOnChainServices} from "./abstract/Byte3IncOnChainServices.sol";

import {ERC20} from "../interface/ERC20.sol";
import {HolographerInterface} from "../interface/HolographerInterface.sol";
import {IUniswapV2Pair} from "./interface/IUniswapV2Pair.sol";
import {IUniswapV3Pair} from "./interface/IUniswapV3Pair.sol";
import {IWETH} from "./interface/IWETH.sol";

contract Byte3IncOnChainServicesArbitrumOne is Byte3IncOnChainServices {
  uint256 internal constant Q96 = 0x1000000000000000000000000; // Uniswap V3 FixedPoint96

  address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; // 18 decimals
  address constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8; // 6 decimals

  uint256 constant serviceFee = 100000; // $0.10 Byte3 service fee / per transaction

  IUniswapV2Pair constant SushiSwapV2UsdcPool = IUniswapV2Pair(0x905dfCD5649217c42684f23958568e533C711Aa3);
  IUniswapV3Pair constant UniswapV3UsdcPool = IUniswapV3Pair(0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443);

  uint256 internal _expectingCallback;
  uint256 internal _updatedBalance;

  constructor() {}

  function init(bytes memory data) external override returns (bytes4) {
    return _init(data);
  }

  function approve() external override onlyAdmin {
    // approve FractionToken for USDC
    ERC20(USDC).approve(address(_fractionToken()), type(uint256).max);
    // approve FractionToken SourceContract for USDC
    ERC20(USDC).approve(HolographerInterface(address(_fractionToken())).getSourceContract(), type(uint256).max);
  }

  function convertUsdToWei(uint256 usdAmount) external view override returns (uint256 weiAmount) {
    usdAmount += serviceFee;
    (uint256 uniswapWeiAmount, ) = _getUniswapUSDC(usdAmount);
    weiAmount = (_getSushiSwapUSDC(usdAmount) + uniswapWeiAmount) / 2;
    // add 1% overhead
    weiAmount += weiAmount / 100;
  }

  function getUSDC() external pure override returns (address) {
    return USDC;
  }

  function getWETH() external pure override returns (address) {
    return WETH;
  }

  function needsApproval() external view override returns (bool) {
    if (
      ERC20(USDC).allowance(address(this), address(_fractionToken())) == 0 ||
      ERC20(USDC).allowance(address(this), HolographerInterface(address(_fractionToken())).getSourceContract()) == 0
    ) {
      return true;
    }
    return false;
  }

  function purchaseFractionToken(
    address recipient,
    uint256 usdAmount
  ) external payable override returns (uint256 remainder) {
    usdAmount += serviceFee;
    // get amount sent
    uint256 value = msg.value;
    // buy USDC with WETH
    (uint256 _amountIn1, uint160 _amountIn1sqrtPrice) = _getUniswapUSDC(usdAmount);
    uint256 _amountIn2 = _getSushiSwapUSDC(usdAmount);
    uint256 amountIn = _amountIn1 < _amountIn2 ? _amountIn1 : _amountIn2;
    require(value >= amountIn, "BYTE3: insufficient msg.value");
    if (amountIn == _amountIn1) {
      amountIn = _uniswapSwap(address(this), amountIn, usdAmount, _amountIn1sqrtPrice);
    } else {
      _sushiswapSwap(address(this), amountIn, usdAmount);
    }
    // mint FRACT10N for USDC
    uint256 fractionAmount = (usdAmount - serviceFee) * (10 ** (18 - 6));
    _fractionToken().mint(recipient, fractionAmount);
    // get remainder
    remainder = value - amountIn;
    if (remainder > 0) {
      payable(msg.sender).transfer(remainder);
    }
    return remainder;
  }

  function _sushiswapSwap(address recipient, uint256 nativeAmount, uint256 usdAmount) internal {
    IWETH weth = IWETH(WETH);
    // wrap the native gas token
    weth.deposit{value: nativeAmount}();
    // transfer to token pool
    weth.transfer(address(SushiSwapV2UsdcPool), nativeAmount);
    // execute swap
    SushiSwapV2UsdcPool.swap(0, usdAmount, recipient, "");
  }

  function _uniswapSwap(
    address recipient,
    uint256 nativeAmount,
    uint256 usdAmount,
    uint160 sqrtPrice
  ) internal returns (uint256) {
    _expectingCallback = 1;
    UniswapV3UsdcPool.swap(
      // recipient The address to receive the output of the swap
      recipient,
      // zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
      true,
      // amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
      -int256(usdAmount),
      // sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this value after the swap. If one for zero, the price cannot be greater than this value after the swap
      ((sqrtPrice / (10 ** 21)) - 1) * (10 ** 21),
      //       sqrtPrice - 1,
      // data Any data to be passed through to the callback
      abi.encode(nativeAmount)
    );
    return _updatedBalance;
  }

  function uniswapV3SwapCallback(int256 amount0Delta, int256, bytes calldata data) external {
    require(msg.sender == address(UniswapV3UsdcPool), "BYTE3: UniswapV3Pair call only");
    require(_expectingCallback == 1, "BYTE3: unexpected callback");
    _expectingCallback = 0;
    uint256 nativeAmount = abi.decode(data, (uint256));
    uint256 amountIn = uint256(amount0Delta);
    if (amountIn > nativeAmount) {
      uint256 ratio = (nativeAmount * (10 ** 18)) / amountIn;
      // allow a maximum difference of 0.8999999999999999%
      require(ratio < 1009000000000000000, "BYTE3: Uniswap too greedy");
    }
    IWETH weth = IWETH(WETH);
    // wrap the native gas token
    weth.deposit{value: amountIn}();
    // transfer to token pool
    weth.transfer(address(UniswapV3UsdcPool), amountIn);
    _updatedBalance = amountIn;
  }

  function _getSushiSwapUSDC(uint256 usdAmount) internal view returns (uint256 weiAmount) {
    // add decimal places for amount IF decimals are above 6!
    //usdAmount = usdAmount * (10**(18 - 6));
    (uint112 _reserve0, uint112 _reserve1, ) = SushiSwapV2UsdcPool.getReserves();
    // x is always native token / WETH
    uint256 x = uint256(_reserve0);
    // y is always USD token / USDC
    uint256 y = uint256(_reserve1);

    uint256 numerator = (x * usdAmount) * 1000;
    uint256 denominator = (y - usdAmount) * 997;

    weiAmount = (numerator / denominator) + 1;
  }

  function _getUniswapUSDC(uint256 usdAmount) internal view returns (uint256 weiAmount, uint160 sqrtPrice) {
    // token0 = WETH
    // token1 = USDC
    uint32 fee = 500;
    (uint160 sqrtPriceX96, , , , , , ) = UniswapV3UsdcPool.slot0();
    sqrtPrice = sqrtPriceX96;
    uint128 liquidity = UniswapV3UsdcPool.liquidity();
    uint256 amount0 = (liquidity * Q96) / sqrtPrice;
    uint256 amount1 = (liquidity * sqrtPrice) / Q96;
    uint256 price = amount0 / amount1;
    usdAmount += (usdAmount * fee) / (10 ** 6);
    weiAmount = price * usdAmount;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IByte3IncOnChainServices {
  function approve() external;

  function convertUsdToWei(uint256 usdAmount) external view returns (uint256 weiAmount);

  function getUSDC() external pure returns (address);

  function getWETH() external pure returns (address);

  function needsApproval() external view returns (bool);

  function purchaseFractionToken(address recipient, uint256 usdAmount) external payable returns (uint256 remainder);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IUniswapV3PoolImmutables {
  /// @notice The first of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token0() external view returns (address);

  /// @notice The second of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token1() external view returns (address);

  /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
  /// @return The fee
  function fee() external view returns (uint24);
}

interface IUniswapV3PoolState {
  /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
  /// when accessed externally.
  /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
  /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
  /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
  /// boundary.
  /// observationIndex The index of the last oracle observation that was written,
  /// observationCardinality The current maximum number of observations stored in the pool,
  /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
  /// feeProtocol The protocol fee for both tokens of the pool.
  /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
  /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
  /// unlocked Whether the pool is currently locked to reentrancy
  function slot0()
    external
    view
    returns (
      uint160 sqrtPriceX96,
      int24 tick,
      uint16 observationIndex,
      uint16 observationCardinality,
      uint16 observationCardinalityNext,
      uint8 feeProtocol,
      bool unlocked
    );

  /// @notice The currently in range liquidity available to the pool
  /// @dev This value has no relationship to the total liquidity across all ticks
  function liquidity() external view returns (uint128);
}

interface IUniswapV3PoolActions {
  /// @notice Swap token0 for token1, or token1 for token0
  /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
  /// @param recipient The address to receive the output of the swap
  /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
  /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
  /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
  /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
  /// @param data Any data to be passed through to the callback
  /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
  /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
  function swap(
    address recipient,
    bool zeroForOne,
    int256 amountSpecified,
    uint160 sqrtPriceLimitX96,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);
}

interface IUniswapV3Pool is IUniswapV3PoolImmutables, IUniswapV3PoolState, IUniswapV3PoolActions {}

interface IUniswapV3Pair is IUniswapV3Pool {}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IWETH {
  function allowance(address src, address guy) external view returns (uint256);

  function approve(address guy, uint256 wad) external returns (bool);

  function balanceOf(address guy) external view returns (uint256);

  function decimals() external view returns (uint8);

  function deposit() external payable;

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function totalSupply() external;

  function transfer(address dst, uint256 wad) external returns (bool);

  function transferFrom(address src, address dst, uint256 wad) external;

  function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

interface ERC165 {
  /// @notice Query if a contract implements an interface
  /// @param interfaceID The interface identifier, as specified in ERC-165
  /// @dev Interface identification is specified in ERC-165. This function
  ///  uses less than 30,000 gas.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceID` is not 0xffffffff, `false` otherwise
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

interface ERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address _owner) external view returns (uint256 balance);

  function transfer(address _to, uint256 _value) external returns (bool success);

  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

  function approve(address _spender, uint256 _value) external returns (bool success);

  function allowance(address _owner, address _spender) external view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

interface ERC20Burnable {
  function burn(uint256 amount) external;

  function burnFrom(address account, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

interface ERC20Metadata {
  function decimals() external view returns (uint8);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity 0.8.13;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface ERC20Permit {
  /**
   * @dev Sets `value` as the allowance of `spender` over ``account``'s tokens,
   * given ``account``'s signed approval.
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
   * - `v`, `r` and `s` must be a valid `secp256k1` signature from `account`
   * over the EIP712-formatted function arguments.
   * - the signature must use ``account``'s current nonce (see {nonces}).
   *
   * For more information on the signature format, see the
   * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
   * section].
   */
  function permit(
    address account,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Returns the current nonce for `account`. This value must be
   * included whenever a signature is generated for {permit}.
   *
   * Every successful call to {permit} increases ``account``'s nonce by one. This
   * prevents a signature from being used multiple times.
   */
  function nonces(address account) external view returns (uint256);

  /**
   * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
   */
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

interface ERC20Receiver {
  function onERC20Received(
    address account,
    address recipient,
    uint256 amount,
    bytes memory data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

interface ERC20Safer {
  function safeTransfer(address recipient, uint256 amount) external returns (bool);

  function safeTransfer(address recipient, uint256 amount, bytes memory data) external returns (bool);

  function safeTransferFrom(address account, address recipient, uint256 amount) external returns (bool);

  function safeTransferFrom(
    address account,
    address recipient,
    uint256 amount,
    bytes memory data
  ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
/*

                         ┌───────────┐
                         │ HOLOGRAPH │
                         └───────────┘
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║                            / ^ \                            ║
║                            ~~*~~            ¸               ║
║                         [ '<>:<>' ]         │░░░            ║
║               ╔╗           _/"\_           ╔╣               ║
║             ┌─╬╬─┐          """          ┌─╬╬─┐             ║
║          ┌─┬┘ ╠╣ └┬─┐       \_/       ┌─┬┘ ╠╣ └┬─┐          ║
║       ┌─┬┘ │  ╠╣  │ └┬─┐           ┌─┬┘ │  ╠╣  │ └┬─┐       ║
║    ┌─┬┘ │  │  ╠╣  │  │ └┬─┐     ┌─┬┘ │  │  ╠╣  │  │ └┬─┐    ║
║ ┌─┬┘ │  │  │  ╠╣  │  │  │ └┬┐ ┌┬┘ │  │  │  ╠╣  │  │  │ └┬─┐ ║
╠┬┘ │  │  │  │  ╠╣  │  │  │  │└¤┘│  │  │  │  ╠╣  │  │  │  │ └┬╣
║│  │  │  │  │  ╠╣  │  │  │  │   │  │  │  │  ╠╣  │  │  │  │  │║
╠╩══╩══╩══╩══╩══╬╬══╩══╩══╩══╩═══╩══╩══╩══╩══╬╬══╩══╩══╩══╩══╩╣
╠┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╣
║               ╠╣                           ╠╣               ║
║               ╠╣                           ╠╣               ║
║    ,          ╠╣     ,        ,'      *    ╠╣               ║
║~~~~~^~~~~~~~~┌╬╬┐~~~^~~~~~~~~^^~~~~~~~~^~~┌╬╬┐~~~~~~~^~~~~~~║
╚══════════════╩╩╩╩═════════════════════════╩╩╩╩══════════════╝
     - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

interface Holographable {
  function bridgeIn(uint32 fromChain, bytes calldata payload) external returns (bytes4);

  function bridgeOut(
    uint32 toChain,
    address sender,
    bytes calldata payload
  ) external returns (bytes4 selector, bytes memory data);
}

// SPDX-License-Identifier: UNLICENSED
/*

                         ┌───────────┐
                         │ HOLOGRAPH │
                         └───────────┘
╔═════════════════════════════════════════════════════════════╗
║                                                             ║
║                            / ^ \                            ║
║                            ~~*~~            ¸               ║
║                         [ '<>:<>' ]         │░░░            ║
║               ╔╗           _/"\_           ╔╣               ║
║             ┌─╬╬─┐          """          ┌─╬╬─┐             ║
║          ┌─┬┘ ╠╣ └┬─┐       \_/       ┌─┬┘ ╠╣ └┬─┐          ║
║       ┌─┬┘ │  ╠╣  │ └┬─┐           ┌─┬┘ │  ╠╣  │ └┬─┐       ║
║    ┌─┬┘ │  │  ╠╣  │  │ └┬─┐     ┌─┬┘ │  │  ╠╣  │  │ └┬─┐    ║
║ ┌─┬┘ │  │  │  ╠╣  │  │  │ └┬┐ ┌┬┘ │  │  │  ╠╣  │  │  │ └┬─┐ ║
╠┬┘ │  │  │  │  ╠╣  │  │  │  │└¤┘│  │  │  │  ╠╣  │  │  │  │ └┬╣
║│  │  │  │  │  ╠╣  │  │  │  │   │  │  │  │  ╠╣  │  │  │  │  │║
╠╩══╩══╩══╩══╩══╬╬══╩══╩══╩══╩═══╩══╩══╩══╩══╬╬══╩══╩══╩══╩══╩╣
╠┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╬╬┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴╣
║               ╠╣                           ╠╣               ║
║               ╠╣                           ╠╣               ║
║    ,          ╠╣     ,        ,'      *    ╠╣               ║
║~~~~~^~~~~~~~~┌╬╬┐~~~^~~~~~~~~^^~~~~~~~~^~~┌╬╬┐~~~~~~~^~~~~~~║
╚══════════════╩╩╩╩═════════════════════════╩╩╩╩══════════════╝
     - one protocol, one bridge = infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.13;

interface HolographerInterface {
  function getContractType() external view returns (bytes32 contractType);

  function getDeploymentBlock() external view returns (uint256 deploymentBlock);

  function getHolograph() external view returns (address holograph);

  function getHolographEnforcer() external view returns (address);

  function getOriginChain() external view returns (uint32 originChain);

  function getSourceContract() external view returns (address sourceContract);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Metadata.sol";
import "./ERC20Permit.sol";
import "./ERC20Receiver.sol";
import "./ERC20Safer.sol";
import "./ERC165.sol";
import "./Holographable.sol";

interface IFractionToken is
  ERC165,
  ERC20,
  ERC20Burnable,
  ERC20Metadata,
  ERC20Receiver,
  ERC20Safer,
  ERC20Permit,
  Holographable
{
  function mint(address recipient, uint256 amount) external;

  function burn(address collateralRecipient, uint256 amount) external;

  function afterBurn(address collateralRecipient, uint256 amount) external returns (bool success);

  function onAllowance(address account, address operator, uint256 amount) external view returns (bool success);

  function isApprovedOperator(address operator) external view returns (bool approved);

  function getBurnFeeBp() external view returns (uint256 burnFeeBp);

  function getCollateral() external view returns (address collateral);

  function setApproveOperator(address operator, bool approved) external;

  function setBurnFeeBp(uint256 burnFeeBp) external;

  function setCollateral(address collateralAddress) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

interface InitializableInterface {
  function init(bytes memory initPayload) external returns (bytes4);
}