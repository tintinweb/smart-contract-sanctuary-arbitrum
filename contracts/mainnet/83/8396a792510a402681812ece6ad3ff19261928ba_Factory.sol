// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Kyle Scott ([email protected])
/// @author Modified from Solmate v6
/// (https://github.com/transmissions11/solmate/blob/a9e3ea26a2dc73bfa87f0cb189687d029028e0c5/src/tokens/ERC20.sol)
/// and Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
  /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

  event Transfer(address indexed from, address indexed to, uint256 amount);

  event Approval(address indexed owner, address indexed spender, uint256 amount);

  /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

  string public constant name = "Numoen Replicating Derivative";

  string public constant symbol = "NRD";

  uint8 public constant decimals = 18;

  /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

  uint256 public totalSupply;

  mapping(address => uint256) public balanceOf;

  mapping(address => mapping(address => uint256)) public allowance;

  /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

  bytes32 public constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  uint256 internal immutable INITIAL_CHAIN_ID;

  bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

  mapping(address => uint256) public nonces;

  /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor() {
    INITIAL_CHAIN_ID = block.chainid;
    INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
  }

  /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @dev changed visibility to external
  function approve(address spender, uint256 amount) external virtual returns (bool) {
    allowance[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);

    return true;
  }

  /// @dev changed visibility to external
  function transfer(address to, uint256 amount) external virtual returns (bool) {
    balanceOf[msg.sender] -= amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      balanceOf[to] += amount;
    }

    emit Transfer(msg.sender, to, amount);

    return true;
  }

  /// @dev changed visibility to external
  function transferFrom(address from, address to, uint256 amount) external virtual returns (bool) {
    uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

    if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

    balanceOf[from] -= amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      balanceOf[to] += amount;
    }

    emit Transfer(from, to, amount);

    return true;
  }

  /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external
    virtual
  {
    require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

    // Unchecked because the only math done is incrementing
    // the owner's nonce which cannot realistically overflow.
    unchecked {
      bytes32 digest = keccak256(
        abi.encodePacked(
          "\x19\x01",
          DOMAIN_SEPARATOR(),
          keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
        )
      );

      address recoveredAddress = ecrecover(digest, v, r, s);

      require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

      allowance[recoveredAddress][spender] = value;
    }

    emit Approval(owner, spender, value);
  }

  function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
    return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
  }

  function computeDomainSeparator() internal view virtual returns (bytes32) {
    return keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes(name)),
        keccak256("1"),
        block.chainid,
        address(this)
      )
    );
  }

  /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

  function _mint(address to, uint256 amount) internal virtual {
    totalSupply += amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      balanceOf[to] += amount;
    }

    emit Transfer(address(0), to, amount);
  }

  function _burn(address from, uint256 amount) internal virtual {
    balanceOf[from] -= amount;

    // Cannot underflow because a user's balance
    // will never be larger than the total supply.
    unchecked {
      totalSupply -= amount;
    }

    emit Transfer(from, address(0), amount);
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import { Lendgine } from "./Lendgine.sol";

import { IFactory } from "./interfaces/IFactory.sol";

contract Factory is IFactory {
  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event LendgineCreated(
    address indexed token0,
    address indexed token1,
    uint256 token0Exp,
    uint256 token1Exp,
    uint256 indexed upperBound,
    address lendgine
  );

  /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

  error SameTokenError();

  error ZeroAddressError();

  error DeployedError();

  error ScaleError();

  /*//////////////////////////////////////////////////////////////
                            FACTORY STORAGE
    //////////////////////////////////////////////////////////////*/

  /// @inheritdoc IFactory
  mapping(address => mapping(address => mapping(uint256 => mapping(uint256 => mapping(uint256 => address)))))
    public
    override getLendgine;

  /*//////////////////////////////////////////////////////////////
                        TEMPORARY DEPLOY STORAGE
    //////////////////////////////////////////////////////////////*/

  struct Parameters {
    address token0;
    address token1;
    uint128 token0Exp;
    uint128 token1Exp;
    uint256 upperBound;
  }

  /// @inheritdoc IFactory
  Parameters public override parameters;

  /*//////////////////////////////////////////////////////////////
                              FACTORY LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @inheritdoc IFactory
  function createLendgine(
    address token0,
    address token1,
    uint8 token0Exp,
    uint8 token1Exp,
    uint256 upperBound
  )
    external
    override
    returns (address lendgine)
  {
    if (token0 == token1) revert SameTokenError();
    if (token0 == address(0) || token1 == address(0)) revert ZeroAddressError();
    if (getLendgine[token0][token1][token0Exp][token1Exp][upperBound] != address(0)) revert DeployedError();
    if (token0Exp > 18 || token0Exp < 6 || token1Exp > 18 || token1Exp < 6) revert ScaleError();

    parameters =
      Parameters({ token0: token0, token1: token1, token0Exp: token0Exp, token1Exp: token1Exp, upperBound: upperBound });

    lendgine = address(new Lendgine{ salt: keccak256(abi.encode(token0, token1, token0Exp, token1Exp, upperBound)) }());

    delete parameters;

    getLendgine[token0][token1][token0Exp][token1Exp][upperBound] = lendgine;
    emit LendgineCreated(token0, token1, token0Exp, token1Exp, upperBound, lendgine);
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import { Factory } from "./Factory.sol";

import { IImmutableState } from "./interfaces/IImmutableState.sol";

abstract contract ImmutableState is IImmutableState {
  /// @inheritdoc IImmutableState
  address public immutable override factory;

  /// @inheritdoc IImmutableState
  address public immutable override token0;

  /// @inheritdoc IImmutableState
  address public immutable override token1;

  /// @inheritdoc IImmutableState
  uint256 public immutable override token0Scale;

  /// @inheritdoc IImmutableState
  uint256 public immutable override token1Scale;

  /// @inheritdoc IImmutableState
  uint256 public immutable override upperBound;

  constructor() {
    factory = msg.sender;

    uint128 _token0Exp;
    uint128 _token1Exp;

    (token0, token1, _token0Exp, _token1Exp, upperBound) = Factory(msg.sender).parameters();

    token0Scale = 10 ** (18 - _token0Exp);
    token1Scale = 10 ** (18 - _token1Exp);
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import { IJumpRate } from "./interfaces/IJumpRate.sol";

abstract contract JumpRate is IJumpRate {
  uint256 public constant override kink = 0.8 ether;

  uint256 public constant override multiplier = 1.375 ether;

  uint256 public constant override jumpMultiplier = 44.5 ether;

  function getBorrowRate(uint256 borrowedLiquidity, uint256 totalLiquidity) public pure override returns (uint256 rate) {
    uint256 util = utilizationRate(borrowedLiquidity, totalLiquidity);

    if (util <= kink) {
      return (util * multiplier) / 1e18;
    } else {
      uint256 normalRate = (kink * multiplier) / 1e18;
      uint256 excessUtil = util - kink;
      return ((excessUtil * jumpMultiplier) / 1e18) + normalRate;
    }
  }

  function getSupplyRate(
    uint256 borrowedLiquidity,
    uint256 totalLiquidity
  )
    external
    pure
    override
    returns (uint256 rate)
  {
    uint256 util = utilizationRate(borrowedLiquidity, totalLiquidity);
    uint256 borrowRate = getBorrowRate(borrowedLiquidity, totalLiquidity);

    return (borrowRate * util) / 1e18;
  }

  function utilizationRate(uint256 borrowedLiquidity, uint256 totalLiquidity) private pure returns (uint256 rate) {
    if (totalLiquidity == 0) return 0;
    return (borrowedLiquidity * 1e18) / totalLiquidity;
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import { ERC20 } from "./ERC20.sol";
import { JumpRate } from "./JumpRate.sol";
import { Pair } from "./Pair.sol";

import { ILendgine } from "./interfaces/ILendgine.sol";
import { IMintCallback } from "./interfaces/callback/IMintCallback.sol";

import { Balance } from "../libraries/Balance.sol";
import { FullMath } from "../libraries/FullMath.sol";
import { Position } from "./libraries/Position.sol";
import { SafeTransferLib } from "../libraries/SafeTransferLib.sol";
import { SafeCast } from "../libraries/SafeCast.sol";

contract Lendgine is ERC20, JumpRate, Pair, ILendgine {
  using Position for mapping(address => Position.Info);
  using Position for Position.Info;

  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event Mint(address indexed sender, uint256 collateral, uint256 shares, uint256 liquidity, address indexed to);

  event Burn(address indexed sender, uint256 collateral, uint256 shares, uint256 liquidity, address indexed to);

  event Deposit(address indexed sender, uint256 size, uint256 liquidity, address indexed to);

  event Withdraw(address indexed sender, uint256 size, uint256 liquidity, address indexed to);

  event AccrueInterest(uint256 timeElapsed, uint256 collateral, uint256 liquidity);

  event AccruePositionInterest(address indexed owner, uint256 rewardPerPosition);

  event Collect(address indexed owner, address indexed to, uint256 amount);

  /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

  error InputError();

  error CompleteUtilizationError();

  error InsufficientInputError();

  error InsufficientPositionError();

  /*//////////////////////////////////////////////////////////////
                          LENDGINE STORAGE
    //////////////////////////////////////////////////////////////*/

  /// @inheritdoc ILendgine
  mapping(address => Position.Info) public override positions;

  /// @inheritdoc ILendgine
  uint256 public override totalPositionSize;

  /// @inheritdoc ILendgine
  uint256 public override totalLiquidityBorrowed;

  /// @inheritdoc ILendgine
  uint256 public override rewardPerPositionStored;

  /// @inheritdoc ILendgine
  uint256 public override lastUpdate;

  /// @inheritdoc ILendgine
  function mint(
    address to,
    uint256 collateral,
    bytes calldata data
  )
    external
    override
    nonReentrant
    returns (uint256 shares)
  {
    _accrueInterest();

    uint256 liquidity = convertCollateralToLiquidity(collateral);
    shares = convertLiquidityToShare(liquidity);

    if (collateral == 0 || liquidity == 0 || shares == 0) revert InputError();
    if (liquidity > totalLiquidity) revert CompleteUtilizationError();
    // next check is for the case when liquidity is borrowed but then was completely accrued
    if (totalSupply > 0 && totalLiquidityBorrowed == 0) revert CompleteUtilizationError();

    totalLiquidityBorrowed += liquidity;
    (uint256 amount0, uint256 amount1) = burn(to, liquidity);
    _mint(to, shares);

    uint256 balanceBefore = Balance.balance(token1);
    IMintCallback(msg.sender).mintCallback(collateral, amount0, amount1, liquidity, data);
    uint256 balanceAfter = Balance.balance(token1);

    if (balanceAfter < balanceBefore + collateral) revert InsufficientInputError();

    emit Mint(msg.sender, collateral, shares, liquidity, to);
  }

  /// @inheritdoc ILendgine
  function burn(address to, bytes calldata data) external override nonReentrant returns (uint256 collateral) {
    _accrueInterest();

    uint256 shares = balanceOf[address(this)];
    uint256 liquidity = convertShareToLiquidity(shares);
    collateral = convertLiquidityToCollateral(liquidity);

    if (collateral == 0 || liquidity == 0 || shares == 0) revert InputError();

    totalLiquidityBorrowed -= liquidity;
    _burn(address(this), shares);
    SafeTransferLib.safeTransfer(token1, to, collateral); // optimistically transfer
    mint(liquidity, data);

    emit Burn(msg.sender, collateral, shares, liquidity, to);
  }

  /// @inheritdoc ILendgine
  function deposit(
    address to,
    uint256 liquidity,
    bytes calldata data
  )
    external
    override
    nonReentrant
    returns (uint256 size)
  {
    _accrueInterest();

    uint256 _totalPositionSize = totalPositionSize; // SLOAD
    uint256 totalLiquiditySupplied = totalLiquidity + totalLiquidityBorrowed;

    size = Position.convertLiquidityToPosition(liquidity, totalLiquiditySupplied, _totalPositionSize);

    if (liquidity == 0 || size == 0) revert InputError();
    // next check is for the case when liquidity is borrowed but then was completely accrued
    if (totalLiquiditySupplied == 0 && totalPositionSize > 0) revert CompleteUtilizationError();

    positions.update(to, SafeCast.toInt256(size), rewardPerPositionStored);
    totalPositionSize = _totalPositionSize + size;
    mint(liquidity, data);

    emit Deposit(msg.sender, size, liquidity, to);
  }

  /// @inheritdoc ILendgine
  function withdraw(
    address to,
    uint256 size
  )
    external
    override
    nonReentrant
    returns (uint256 amount0, uint256 amount1, uint256 liquidity)
  {
    _accrueInterest();

    uint256 _totalPositionSize = totalPositionSize; // SLOAD
    uint256 _totalLiquidity = totalLiquidity; // SLOAD
    uint256 totalLiquiditySupplied = _totalLiquidity + totalLiquidityBorrowed;

    Position.Info memory positionInfo = positions[msg.sender]; // SLOAD
    liquidity = Position.convertPositionToLiquidity(size, totalLiquiditySupplied, _totalPositionSize);

    if (liquidity == 0 || size == 0) revert InputError();

    if (size > positionInfo.size) revert InsufficientPositionError();
    if (liquidity > _totalLiquidity) revert CompleteUtilizationError();

    positions.update(msg.sender, -SafeCast.toInt256(size), rewardPerPositionStored);
    totalPositionSize -= size;
    (amount0, amount1) = burn(to, liquidity);

    emit Withdraw(msg.sender, size, liquidity, to);
  }

  /// @inheritdoc ILendgine
  function accrueInterest() external override nonReentrant {
    _accrueInterest();
  }

  /// @inheritdoc ILendgine
  function accruePositionInterest() external override nonReentrant {
    _accrueInterest();
    _accruePositionInterest(msg.sender);
  }

  /// @inheritdoc ILendgine
  function collect(address to, uint256 collateralRequested) external override nonReentrant returns (uint256 collateral) {
    Position.Info storage position = positions[msg.sender]; // SLOAD
    uint256 tokensOwed = position.tokensOwed;

    collateral = collateralRequested > tokensOwed ? tokensOwed : collateralRequested;

    if (collateral > 0) {
      position.tokensOwed = tokensOwed - collateral; // SSTORE
      SafeTransferLib.safeTransfer(token1, to, collateral);
    }

    emit Collect(msg.sender, to, collateral);
  }

  /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @inheritdoc ILendgine
  function convertLiquidityToShare(uint256 liquidity) public view override returns (uint256) {
    uint256 _totalLiquidityBorrowed = totalLiquidityBorrowed; // SLOAD
    return _totalLiquidityBorrowed == 0 ? liquidity : FullMath.mulDiv(liquidity, totalSupply, _totalLiquidityBorrowed);
  }

  /// @inheritdoc ILendgine
  function convertShareToLiquidity(uint256 shares) public view override returns (uint256) {
    return FullMath.mulDiv(totalLiquidityBorrowed, shares, totalSupply);
  }

  /// @inheritdoc ILendgine
  function convertCollateralToLiquidity(uint256 collateral) public view override returns (uint256) {
    return FullMath.mulDiv(collateral * token1Scale, 1e18, 2 * upperBound);
  }

  /// @inheritdoc ILendgine
  function convertLiquidityToCollateral(uint256 liquidity) public view override returns (uint256) {
    return FullMath.mulDiv(liquidity, 2 * upperBound, 1e18) / token1Scale;
  }

  /*//////////////////////////////////////////////////////////////
                         INTERNAL INTEREST LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Helper function for accruing lendgine interest
  function _accrueInterest() private {
    if (totalSupply == 0 || totalLiquidityBorrowed == 0) {
      lastUpdate = block.timestamp;
      return;
    }

    uint256 timeElapsed = block.timestamp - lastUpdate;
    if (timeElapsed == 0) return;

    uint256 _totalLiquidityBorrowed = totalLiquidityBorrowed; // SLOAD
    uint256 totalLiquiditySupplied = totalLiquidity + _totalLiquidityBorrowed; // SLOAD

    uint256 borrowRate = getBorrowRate(_totalLiquidityBorrowed, totalLiquiditySupplied);

    uint256 dilutionLPRequested = (FullMath.mulDiv(borrowRate * timeElapsed, _totalLiquidityBorrowed, 1e18)) / 365 days;
    uint256 dilutionLP = dilutionLPRequested > _totalLiquidityBorrowed ? _totalLiquidityBorrowed : dilutionLPRequested;
    uint256 dilutionSpeculative = convertLiquidityToCollateral(dilutionLP);

    totalLiquidityBorrowed = _totalLiquidityBorrowed - dilutionLP;
    rewardPerPositionStored += FullMath.mulDiv(dilutionSpeculative, 1e18, totalPositionSize);
    lastUpdate = block.timestamp;

    emit AccrueInterest(timeElapsed, dilutionSpeculative, dilutionLP);
  }

  /// @notice Helper function for accruing interest to a position
  /// @dev Assume the global interest is up to date
  /// @param owner The address that this position belongs to
  function _accruePositionInterest(address owner) private {
    uint256 _rewardPerPositionStored = rewardPerPositionStored; // SLOAD

    positions.update(owner, 0, _rewardPerPositionStored);

    emit AccruePositionInterest(owner, _rewardPerPositionStored);
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import { ImmutableState } from "./ImmutableState.sol";
import { ReentrancyGuard } from "./ReentrancyGuard.sol";

import { IPair } from "./interfaces/IPair.sol";
import { IPairMintCallback } from "./interfaces/callback/IPairMintCallback.sol";
import { ISwapCallback } from "./interfaces/callback/ISwapCallback.sol";

import { Balance } from "../libraries/Balance.sol";
import { FullMath } from "../libraries/FullMath.sol";
import { SafeCast } from "../libraries/SafeCast.sol";
import { SafeTransferLib } from "../libraries/SafeTransferLib.sol";

abstract contract Pair is ImmutableState, ReentrancyGuard, IPair {
  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event Mint(uint256 amount0In, uint256 amount1In, uint256 liquidity);

  event Burn(uint256 amount0Out, uint256 amount1Out, uint256 liquidity, address indexed to);

  event Swap(uint256 amount0Out, uint256 amount1Out, uint256 amount0In, uint256 amount1In, address indexed to);

  /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

  error InvariantError();

  error InsufficientOutputError();

  /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

  /// @inheritdoc IPair
  uint120 public override reserve0;

  /// @inheritdoc IPair
  uint120 public override reserve1;

  /// @inheritdoc IPair
  uint256 public override totalLiquidity;

  /*//////////////////////////////////////////////////////////////
                              PAIR LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @inheritdoc IPair
  function invariant(uint256 amount0, uint256 amount1, uint256 liquidity) public view override returns (bool) {
    if (liquidity == 0) return (amount0 == 0 && amount1 == 0);

    uint256 scale0 = FullMath.mulDiv(amount0 * token0Scale, 1e18, liquidity);
    uint256 scale1 = FullMath.mulDiv(amount1 * token1Scale, 1e18, liquidity);

    if (scale1 > 2 * upperBound) revert InvariantError();

    uint256 a = scale0 * 1e18;
    uint256 b = scale1 * upperBound;
    uint256 c = (scale1 * scale1) / 4;
    uint256 d = upperBound * upperBound;

    return a + b >= c + d;
  }

  /// @dev assumes liquidity is non-zero
  function mint(uint256 liquidity, bytes calldata data) internal {
    uint120 _reserve0 = reserve0; // SLOAD
    uint120 _reserve1 = reserve1; // SLOAD
    uint256 _totalLiquidity = totalLiquidity; // SLOAD

    uint256 balance0Before = Balance.balance(token0);
    uint256 balance1Before = Balance.balance(token1);
    IPairMintCallback(msg.sender).pairMintCallback(liquidity, data);
    uint256 amount0In = Balance.balance(token0) - balance0Before;
    uint256 amount1In = Balance.balance(token1) - balance1Before;

    if (!invariant(_reserve0 + amount0In, _reserve1 + amount1In, _totalLiquidity + liquidity)) {
      revert InvariantError();
    }

    reserve0 = _reserve0 + SafeCast.toUint120(amount0In); // SSTORE
    reserve1 = _reserve1 + SafeCast.toUint120(amount1In); // SSTORE
    totalLiquidity = _totalLiquidity + liquidity; // SSTORE

    emit Mint(amount0In, amount1In, liquidity);
  }

  /// @dev assumes liquidity is non-zero
  function burn(address to, uint256 liquidity) internal returns (uint256 amount0, uint256 amount1) {
    uint120 _reserve0 = reserve0; // SLOAD
    uint120 _reserve1 = reserve1; // SLOAD
    uint256 _totalLiquidity = totalLiquidity; // SLOAD

    amount0 = FullMath.mulDiv(_reserve0, liquidity, _totalLiquidity);
    amount1 = FullMath.mulDiv(_reserve1, liquidity, _totalLiquidity);
    if (amount0 == 0 && amount1 == 0) revert InsufficientOutputError();

    if (amount0 > 0) SafeTransferLib.safeTransfer(token0, to, amount0);
    if (amount1 > 0) SafeTransferLib.safeTransfer(token1, to, amount1);

    // Extra check of the invariant
    if (!invariant(_reserve0 - amount0, _reserve1 - amount1, _totalLiquidity - liquidity)) revert InvariantError();

    reserve0 = _reserve0 - SafeCast.toUint120(amount0); // SSTORE
    reserve1 = _reserve1 - SafeCast.toUint120(amount1); // SSTORE
    totalLiquidity = _totalLiquidity - liquidity; // SSTORE

    emit Burn(amount0, amount1, liquidity, to);
  }

  /// @inheritdoc IPair
  function swap(address to, uint256 amount0Out, uint256 amount1Out, bytes calldata data) external override nonReentrant {
    if (amount0Out == 0 && amount1Out == 0) revert InsufficientOutputError();

    uint120 _reserve0 = reserve0; // SLOAD
    uint120 _reserve1 = reserve1; // SLOAD

    if (amount0Out > 0) SafeTransferLib.safeTransfer(token0, to, amount0Out);
    if (amount1Out > 0) SafeTransferLib.safeTransfer(token1, to, amount1Out);

    uint256 balance0Before = Balance.balance(token0);
    uint256 balance1Before = Balance.balance(token1);
    ISwapCallback(msg.sender).swapCallback(amount0Out, amount1Out, data);
    uint256 amount0In = Balance.balance(token0) - balance0Before;
    uint256 amount1In = Balance.balance(token1) - balance1Before;

    if (!invariant(_reserve0 + amount0In - amount0Out, _reserve1 + amount1In - amount1Out, totalLiquidity)) {
      revert InvariantError();
    }

    reserve0 = _reserve0 + SafeCast.toUint120(amount0In) - SafeCast.toUint120(amount0Out); // SSTORE
    reserve1 = _reserve1 + SafeCast.toUint120(amount1In) - SafeCast.toUint120(amount1Out); // SSTORE

    emit Swap(amount0Out, amount1Out, amount0In, amount1In, to);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin
/// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
  uint16 private locked = 1;

  modifier nonReentrant() virtual {
    require(locked == 1, "REENTRANCY");

    locked = 2;

    _;

    locked = 1;
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0;

/// @notice Manages the recording and creation of Numoen markets
/// @author Kyle Scott (https://github.com/numoen/contracts-mono/blob/master/src/Factory.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Factory.sol)
/// and Primitive (https://github.com/primitivefinance/rmm-core/blob/main/contracts/PrimitiveFactory.sol)
interface IFactory {
  /// @notice Returns the lendgine address for a given pair of tokens and upper bound
  /// @dev returns address 0 if it doesn't exist
  function getLendgine(
    address token0,
    address token1,
    uint256 token0Exp,
    uint256 token1Exp,
    uint256 upperBound
  )
    external
    view
    returns (address lendgine);

  /// @notice Get the parameters to be used in constructing the lendgine, set
  /// transiently during lendgine creation
  /// @dev Called by the immutable state constructor to fetch the parameters of the lendgine
  function parameters()
    external
    view
    returns (address token0, address token1, uint128 token0Exp, uint128 token1Exp, uint256 upperBound);

  /// @notice Deploys a lendgine contract by transiently setting the parameters storage slots
  /// and clearing it after the lendgine has been deployed
  function createLendgine(
    address token0,
    address token1,
    uint8 token0Exp,
    uint8 token1Exp,
    uint256 upperBound
  )
    external
    returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0;

/// @notice Immutable state interface
/// @author Kyle Scott ([email protected])
interface IImmutableState {
  /// @notice The contract that deployed the lendgine
  function factory() external view returns (address);

  /// @notice The "numeraire" or "base" token in the pair
  function token0() external view returns (address);

  /// @notice The "risky" or "speculative" token in the pair
  function token1() external view returns (address);

  /// @notice Scale required to make token 0 18 decimals
  function token0Scale() external view returns (uint256);

  /// @notice Scale required to make token 1 18 decimals
  function token1Scale() external view returns (uint256);

  /// @notice Maximum exchange rate (token0/token1)
  function upperBound() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0;

/// @notice An implementation of the Jump Rate model for interest rates
/// @author Kyle Scott ([email protected])
/// @author Modified from Compound
/// (https://github.com/compound-finance/compound-protocol/blob/master/contracts/JumpRateModel.sol)
interface IJumpRate {
  function kink() external view returns (uint256 kink);

  function multiplier() external view returns (uint256 multiplier);

  function jumpMultiplier() external view returns (uint256 jumpMultiplier);

  function getBorrowRate(uint256 borrowedLiquidity, uint256 totalLiquidity) external view returns (uint256 rate);

  function getSupplyRate(uint256 borrowedLiquidity, uint256 totalLiquidity) external view returns (uint256 rate);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0;

import { IPair } from "./IPair.sol";

/// @notice Lending engine for borrowing and lending liquidity provider shares
/// @author Kyle Scott ([email protected])
interface ILendgine is IPair {
  /// @notice Returns information about a position given the controllers address
  function positions(address) external view returns (uint256, uint256, uint256);

  /// @notice The total amount of positions issued
  function totalPositionSize() external view returns (uint256);

  /// @notice The total amount of liquidity shares borrowed
  function totalLiquidityBorrowed() external view returns (uint256);

  /// @notice The amount of token1 rewarded to each unit of position
  function rewardPerPositionStored() external view returns (uint256);

  /// @notice The timestamp at which the interest was last accrued
  /// @dev don't downsize because it takes up the last slot
  function lastUpdate() external view returns (uint256);

  /// @notice Mint an option position by providing token1 as collateral and borrowing the max amount of liquidity
  /// @param to The address that receives the underlying tokens of the liquidity that is withdrawn
  /// @param collateral The amount of collateral in the position
  /// @param data The data to be passed through to the callback
  /// @return shares The amount of shares that were minted
  /// @dev A callback is invoked on the caller
  function mint(address to, uint256 collateral, bytes calldata data) external returns (uint256 shares);

  /// @notice Burn an option position by minting the required liquidity and unlocking the collateral
  /// @param to The address to send the unlocked collateral to
  /// @param data The data to be passed through to the callback
  /// @dev Send the amount to burn before calling this function
  /// @dev A callback is invoked on the caller
  function burn(address to, bytes calldata data) external returns (uint256 collateral);

  /// @notice Provide liquidity to the underlying AMM
  /// @param to The address that will control the position
  /// @param liquidity The amount of liquidity shares that will be minted
  /// @param data The data to be passed through to the callback
  /// @return size The size of the position that was minted
  /// @dev A callback is invoked on the caller
  function deposit(address to, uint256 liquidity, bytes calldata data) external returns (uint256 size);

  /// @notice Withdraw liquidity from the underlying AMM
  /// @param to The address to receive the underlying tokens of the AMM
  /// @param size The size of the position to be withdrawn
  /// @return amount0 The amount of token0 that was withdrawn
  /// @return amount1 The amount of token1 that was withdrawn
  /// @return liquidity The amount of liquidity shares that were withdrawn
  function withdraw(address to, uint256 size) external returns (uint256 amount0, uint256 amount1, uint256 liquidity);

  /// @notice Accrues the global interest by decreasing the total amount of liquidity owed by borrowers and rewarding
  /// lenders with the borrowers collateral
  function accrueInterest() external;

  /// @notice Accrues interest for the caller's liquidity position
  /// @dev Reverts if the sender doesn't have a position
  function accruePositionInterest() external;

  /// @notice Collects the interest that has been gathered to a liquidity position
  /// @param to The address that recieves the collected interest
  /// @param collateralRequested The amount of interest to collect
  /// @return collateral The amount of interest that was actually collected
  function collect(address to, uint256 collateralRequested) external returns (uint256 collateral);

  /// @notice Accounting logic for converting liquidity to share amount
  function convertLiquidityToShare(uint256 liquidity) external view returns (uint256);

  /// @notice Accounting logic for converting share amount to liqudity
  function convertShareToLiquidity(uint256 shares) external view returns (uint256);

  /// @notice Accounting logic for converting collateral amount to liquidity
  function convertCollateralToLiquidity(uint256 collateral) external view returns (uint256);

  /// @notice Accounting logic for converting liquidity to collateral amount
  function convertLiquidityToCollateral(uint256 liquidity) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0;

import { IImmutableState } from "./IImmutableState.sol";

/// @notice AMM implementing the capped power invariant
/// @author Kyle Scott ([email protected])
interface IPair is IImmutableState {
  /// @notice The amount of token0 in the pair
  function reserve0() external view returns (uint120);

  /// @notice The amount of token1 in the pair
  function reserve1() external view returns (uint120);

  /// @notice The total amount of liquidity shares in the pair
  function totalLiquidity() external view returns (uint256);

  /// @notice The implementation of the capped power invariant
  /// @return valid True if the invariant is satisfied
  function invariant(uint256 amount0, uint256 amount1, uint256 liquidity) external view returns (bool);

  /// @notice Exchange between token0 and token1, either accepts or rejects the proposed trade
  /// @param data The data to be passed through to the callback
  /// @dev A callback is invoked on the caller
  function swap(address to, uint256 amount0Out, uint256 amount1Out, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0;

interface IMintCallback {
  /// @notice Called to `msg.sender` after executing a mint via Lendgine
  /// @dev In the implementation you must pay the speculative tokens owed for the mint.
  /// The caller of this method must be checked to be a Lendgine deployed by the canonical Factory.
  /// @param data Any data passed through by the caller via the Mint call
  function mintCallback(
    uint256 collateral,
    uint256 amount0,
    uint256 amount1,
    uint256 liquidity,
    bytes calldata data
  )
    external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IPairMintCallback {
  /// @notice Called to `msg.sender` after executing a mint via Pair
  /// @dev In the implementation you must pay the pool tokens owed for the mint.
  /// The caller of this method must be checked to be a Pair deployed by the canonical Factory.
  /// @param data Any data passed through by the caller via the Mint call
  function pairMintCallback(uint256 liquidity, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface ISwapCallback {
  /// @notice Called to `msg.sender` after executing a swap via Pair
  /// @dev In the implementation you must pay the pool tokens owed for the swap.
  /// The caller of this method must be checked to be a Pair deployed by the canonical Factory.
  /// @param data Any data passed through by the caller via the Swap call
  function swapCallback(uint256 amount0Out, uint256 amount1Out, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import { PositionMath } from "./PositionMath.sol";
import { FullMath } from "../../libraries/FullMath.sol";

/// @notice Library for handling Lendgine liquidity positions
/// @author Kyle Scott ([email protected])
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/Position.sol)
library Position {
  /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

  /// @notice Error for trying to update a position with no size
  error NoPositionError();

  /*//////////////////////////////////////////////////////////////
                            POSITION STRUCT
    //////////////////////////////////////////////////////////////*/

  /**
   * @param size The size of the position
   * @param rewardPerPositionPaid The reward per unit of size as of the last update to position or tokensOwed
   * @param tokensOwed The fees owed to the position owner in `speculative` tokens
   */
  struct Info {
    uint256 size;
    uint256 rewardPerPositionPaid;
    uint256 tokensOwed;
  }

  /*//////////////////////////////////////////////////////////////
                              POSITION LOGIC
    //////////////////////////////////////////////////////////////*/

  /// @notice Helper function for updating a position by increasing/decreasing its size or accruing interest
  function update(
    mapping(address => Position.Info) storage self,
    address owner,
    int256 sizeDelta,
    uint256 rewardPerPosition
  )
    internal
  {
    Position.Info storage positionInfo = self[owner];
    Position.Info memory _positionInfo = positionInfo;

    uint256 tokensOwed;
    if (_positionInfo.size > 0) {
      tokensOwed = newTokensOwed(_positionInfo, rewardPerPosition);
    }

    uint256 sizeNext;
    if (sizeDelta == 0) {
      if (_positionInfo.size == 0) revert NoPositionError();
      sizeNext = _positionInfo.size;
    } else {
      sizeNext = PositionMath.addDelta(_positionInfo.size, sizeDelta);
    }

    if (sizeDelta != 0) positionInfo.size = sizeNext;
    positionInfo.rewardPerPositionPaid = rewardPerPosition;
    if (tokensOwed > 0) positionInfo.tokensOwed = _positionInfo.tokensOwed + tokensOwed;
  }

  /// @notice Helper function for determining the amount of tokens owed to a position
  /// @param rewardPerPosition The global accrued interest
  function newTokensOwed(Position.Info memory position, uint256 rewardPerPosition) internal pure returns (uint256) {
    return FullMath.mulDiv(position.size, rewardPerPosition - position.rewardPerPositionPaid, 1 ether);
  }

  function convertLiquidityToPosition(
    uint256 liquidity,
    uint256 totalLiquiditySupplied,
    uint256 totalPositionSize
  )
    internal
    pure
    returns (uint256)
  {
    return
      totalLiquiditySupplied == 0 ? liquidity : FullMath.mulDiv(liquidity, totalPositionSize, totalLiquiditySupplied);
  }

  function convertPositionToLiquidity(
    uint256 position,
    uint256 totalLiquiditySupplied,
    uint256 totalPositionSize
  )
    internal
    pure
    returns (uint256)
  {
    return FullMath.mulDiv(position, totalLiquiditySupplied, totalPositionSize);
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.0;

/// @notice Math library for positions
/// @author Kyle Scott ([email protected])
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/LiquidityMath.sol)
library PositionMath {
  /// @notice Add a signed size delta to size and revert if it overflows or underflows
  /// @param x The size before change
  /// @param y The delta by which size should be changed
  /// @return z The sizes delta
  function addDelta(uint256 x, int256 y) internal pure returns (uint256 z) {
    if (y < 0) {
      require((z = x - uint256(-y)) < x, "LS");
    } else {
      require((z = x + uint256(y)) >= x, "LA");
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

/// @notice Library for safely and cheaply reading balances
/// @author Kyle Scott ([email protected])
/// @author Modified from UniswapV3Pool
/// (https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Pool.sol#L140-L145)
library Balance {
  error BalanceReturnError();

  /// @notice Determine the callers balance of the specified token
  function balance(address token) internal view returns (uint256) {
    (bool success, bytes memory data) =
      token.staticcall(abi.encodeWithSelector(bytes4(keccak256(bytes("balanceOf(address)"))), address(this)));
    if (!success || data.length < 32) revert BalanceReturnError();
    return abi.decode(data, (uint256));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable max-line-length

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of
/// precision
/// @author Muffin (https://github.com/muffinfi/muffin/blob/master/contracts/libraries/math/FullMath.sol)
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256
/// bits
library FullMath {
  /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or
  /// denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
  function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
    unchecked {
      // 512-bit multiply [prod1 prod0] = a * b
      // Compute the product mod 2**256 and mod 2**256 - 1
      // then use the Chinese Remainder Theorem to reconstruct
      // the 512 bit result. The result is stored in two 256
      // variables such that product = prod1 * 2**256 + prod0
      uint256 prod0; // Least significant 256 bits of the product
      uint256 prod1; // Most significant 256 bits of the product
      assembly {
        let mm := mulmod(a, b, not(0))
        prod0 := mul(a, b)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
      }

      // Handle non-overflow cases, 256 by 256 division
      if (prod1 == 0) {
        require(denominator > 0);
        assembly {
          result := div(prod0, denominator)
        }
        return result;
      }

      // Make sure the result is less than 2**256.
      // Also prevents denominator == 0
      require(denominator > prod1);

      ///////////////////////////////////////////////
      // 512 by 256 division.
      ///////////////////////////////////////////////

      // Make division exact by subtracting the remainder from [prod1 prod0]
      // Compute remainder using mulmod
      uint256 remainder;
      assembly {
        remainder := mulmod(a, b, denominator)
      }
      // Subtract 256 bit number from 512 bit number
      assembly {
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
      }

      // Factor powers of two out of denominator
      // Compute largest power of two divisor of denominator.
      // Always >= 1.

      // [*] The next line is edited to be compatible with solidity 0.8
      // ref: https://ethereum.stackexchange.com/a/96646
      // original: uint256 twos = -denominator & denominator;
      uint256 twos = denominator & (~denominator + 1);

      // Divide denominator by power of two
      assembly {
        denominator := div(denominator, twos)
      }

      // Divide [prod1 prod0] by the factors of two
      assembly {
        prod0 := div(prod0, twos)
      }
      // Shift in bits from prod1 into prod0. For this we need
      // to flip `twos` such that it is 2**256 / twos.
      // If twos is zero, then it becomes one
      assembly {
        twos := add(div(sub(0, twos), twos), 1)
      }
      prod0 |= prod1 * twos;

      // Invert denominator mod 2**256
      // Now that denominator is an odd number, it has an inverse
      // modulo 2**256 such that denominator * inv = 1 mod 2**256.
      // Compute the inverse by starting with a seed that is correct
      // correct for four bits. That is, denominator * inv = 1 mod 2**4
      uint256 inv = (3 * denominator) ^ 2;
      // Now use Newton-Raphson iteration to improve the precision.
      // Thanks to Hensel's lifting lemma, this also works in modular
      // arithmetic, doubling the correct bits in each step.
      inv *= 2 - denominator * inv; // inverse mod 2**8
      inv *= 2 - denominator * inv; // inverse mod 2**16
      inv *= 2 - denominator * inv; // inverse mod 2**32
      inv *= 2 - denominator * inv; // inverse mod 2**64
      inv *= 2 - denominator * inv; // inverse mod 2**128
      inv *= 2 - denominator * inv; // inverse mod 2**256

      // Because the division is now exact we can divide by multiplying
      // with the modular inverse of denominator. This will give us the
      // correct result modulo 2**256. Since the precoditions guarantee
      // that the outcome is less than 2**256, this is the final result.
      // We don't need to compute the high bits of the result and prod1
      // is no longer required.
      result = prod0 * inv;
      return result;
    }
  }

  /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or
  /// denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
    result = mulDiv(a, b, denominator);
    if (mulmod(a, b, denominator) > 0) {
      result++;
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/// @notice Library for safely and cheaply casting solidity types
/// @author Kyle Scott ([email protected])
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/SafeCast.sol)
library SafeCast {
  function toUint120(uint256 y) internal pure returns (uint120 z) {
    require((z = uint120(y)) == y);
  }

  /// @notice Cast a uint256 to a int256, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt256(uint256 y) internal pure returns (int256 z) {
    require(y < 2 ** 255);
    z = int256(y);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// solhint-disable max-line-length

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Muffin (https://github.com/muffinfi/muffin/blob/master/contracts/libraries/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free
/// memory pointer.
library SafeTransferLib {
  error FailedTransferETH();
  error FailedTransfer();
  error FailedTransferFrom();
  error FailedApprove();

  /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

  function safeTransferETH(address to, uint256 amount) internal {
    bool callStatus;

    assembly {
      // Transfer the ETH and store if it succeeded or not.
      callStatus := call(gas(), to, amount, 0, 0, 0, 0)
    }

    if (!callStatus) revert FailedTransferETH();
  }

  /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

  function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
    bool callStatus;

    assembly {
      // Get a pointer to some free memory.
      let freeMemoryPointer := mload(0x40)

      // Write the abi-encoded calldata to memory piece by piece:
      mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with
      // the function selector.
      mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append
      // the "from" argument.
      mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append
      // the "to" argument.
      mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full
      // 32 byte value.

      // Call the token and store if it succeeded or not.
      // We use 100 because the calldata length is 4 + 32 * 3.
      callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
    }

    if (!didLastOptionalReturnCallSucceed(callStatus)) revert FailedTransferFrom();
  }

  function safeTransfer(address token, address to, uint256 amount) internal {
    bool callStatus;

    assembly {
      // Get a pointer to some free memory.
      let freeMemoryPointer := mload(0x40)

      // Write the abi-encoded calldata to memory piece by piece:
      mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with
      // the function selector.
      mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append
      // the "to" argument.
      mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full
      // 32 byte value.

      // Call the token and store if it succeeded or not.
      // We use 68 because the calldata length is 4 + 32 * 2.
      callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
    }

    if (!didLastOptionalReturnCallSucceed(callStatus)) revert FailedTransfer();
  }

  /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

  function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
    assembly {
      // If the call reverted:
      if iszero(callStatus) {
        // Copy the revert message into memory.
        returndatacopy(0, 0, returndatasize())

        // Revert with the same message.
        revert(0, returndatasize())
      }

      switch returndatasize()
      case 32 {
        // Copy the return data into memory.
        returndatacopy(0, 0, returndatasize())

        // Set success to whether it returned true.
        success := iszero(iszero(mload(0)))
      }
      case 0 {
        // There was no return data.
        success := 1
      }
      default {
        // It returned some malformed input.
        success := 0
      }
    }
  }
}