// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {SafeOwnable} from "prepo-shared-contracts/contracts/SafeOwnable.sol";
import {IUniswapV3Oracle, IUniswapV3OracleUintValue} from "prepo-shared-contracts/contracts/interfaces/IUniswapV3OracleUintValue.sol";

contract UniswapV3OracleUintValue is IUniswapV3OracleUintValue, SafeOwnable {
  IUniswapV3Oracle internal immutable _uniswapOracle;
  address internal immutable _baseToken;
  address internal immutable _uniswapQuoteToken;
  uint32 internal _observationPeriod;
  uint128 internal _baseAmount;

  constructor(
    IUniswapV3Oracle uniswapOracle,
    address baseToken,
    address uniswapQuoteToken
  ) {
    _uniswapOracle = uniswapOracle;
    _baseToken = baseToken;
    _uniswapQuoteToken = uniswapQuoteToken;
  }

  function setObservationPeriod(uint32 observationPeriod)
    external
    override
    onlyOwner
  {
    _observationPeriod = observationPeriod;
    emit ObservationPeriodChange(observationPeriod);
  }

  function setBaseAmount(uint128 baseAmount) external override onlyOwner {
    _baseAmount = baseAmount;
    emit BaseAmountChange(baseAmount);
  }

  function get() external view virtual override returns (uint256 quoteAmount) {
    (quoteAmount, ) = _uniswapOracle.quoteAllAvailablePoolsWithTimePeriod(
      _baseAmount,
      _baseToken,
      _uniswapQuoteToken,
      _observationPeriod
    );
  }

  function getUniswapOracle()
    external
    view
    override
    returns (IUniswapV3Oracle)
  {
    return _uniswapOracle;
  }

  function getBaseToken() external view override returns (address) {
    return _baseToken;
  }

  function getUniswapQuoteToken() external view override returns (address) {
    return _uniswapQuoteToken;
  }

  function getObservationPeriod() external view override returns (uint32) {
    return _observationPeriod;
  }

  function getBaseAmount() external view override returns (uint128) {
    return _baseAmount;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {UniswapV3OracleUintValue} from "./UniswapV3OracleUintValue.sol";
import {IPriceOracle, IUintValue, IUniswapV3Oracle, IUniswapV3ToBalancerV2OracleUintValue} from "prepo-shared-contracts/contracts/interfaces/IUniswapV3ToBalancerV2OracleUintValue.sol";

contract UniswapV3ToBalancerV2OracleUintValue is
  IUniswapV3ToBalancerV2OracleUintValue,
  UniswapV3OracleUintValue
{
  /**
   * Unlike with UniswapV3, we are not using an intermediary pool
   * aggregator contract for Balancer (Balancer doesn't have on-chain
   * pool routing anyway). Instead, we provide the Balancer pool directly
   * and thus don't need to store a token.
   */
  IPriceOracle internal immutable _balancerOracle;
  uint256 internal immutable _uniswapQuoteTokenUnit;

  constructor(
    IUniswapV3Oracle uniswapOracle,
    address baseToken,
    address uniswapQuoteToken,
    IPriceOracle balancerOracle,
    uint256 uniswapQuoteTokenDecimals
  ) UniswapV3OracleUintValue(uniswapOracle, baseToken, uniswapQuoteToken) {
    _balancerOracle = balancerOracle;
    _uniswapQuoteTokenUnit = 10**uniswapQuoteTokenDecimals;
  }

  function get()
    external
    view
    override(IUintValue, UniswapV3OracleUintValue)
    returns (uint256 balancerQuoteAmount)
  {
    (uint256 uniswapQuoteAmount, ) = _uniswapOracle
      .quoteAllAvailablePoolsWithTimePeriod(
        _baseAmount,
        _baseToken,
        _uniswapQuoteToken,
        _observationPeriod
      );
    IPriceOracle.OracleAverageQuery[]
      memory balancerQuoteParams = new IPriceOracle.OracleAverageQuery[](1);
    balancerQuoteParams[0] = IPriceOracle.OracleAverageQuery(
      // This specifies that we want the price expressed as token1 in terms of token0.
      IPriceOracle.Variable.PAIR_PRICE,
      _observationPeriod,
      /**
       * 0 seconds ago is now, and we want to look back `_observationPeriod`
       * seconds in the past.
       */
      0
    );
    uint256[] memory balancerQuoteAmounts = _balancerOracle
      .getTimeWeightedAverage(balancerQuoteParams);
    /**
     * Balancer quote is 1 unit of the Uniswap quote token in terms of the
     * Balancer quote token. So we multiply by the quote, then divide by the
     * Uniswap quote token's unit.
     */
    balancerQuoteAmount =
      (uniswapQuoteAmount * balancerQuoteAmounts[0]) /
      _uniswapQuoteTokenUnit;
  }

  function getBalancerOracle() external view override returns (IPriceOracle) {
    return _balancerOracle;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.7;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface for querying historical data from a Pool that can be used as a Price Oracle.
 *
 * This lets third parties retrieve average prices of tokens held by a Pool over a given period of time, as well as the
 * price of the Pool share token (BPT) and invariant. Since the invariant is a sensible measure of Pool liquidity, it
 * can be used to compare two different price sources, and choose the most liquid one.
 *
 * Once the oracle is fully initialized, all queries are guaranteed to succeed as long as they require no data that
 * is not older than the largest safe query window.
 */
interface IPriceOracle {
  // The three values that can be queried:
  //
  // - PAIR_PRICE: the price of the tokens in the Pool, expressed as the price of the second token in units of the
  //   first token. For example, if token A is worth $2, and token B is worth $4, the pair price will be 2.0.
  //   Note that the price is computed *including* the tokens decimals. This means that the pair price of a Pool with
  //   DAI and USDC will be close to 1.0, despite DAI having 18 decimals and USDC 6.
  //
  // - BPT_PRICE: the price of the Pool share token (BPT), in units of the first token.
  //   Note that the price is computed *including* the tokens decimals. This means that the BPT price of a Pool with
  //   USDC in which BPT is worth $5 will be 5.0, despite the BPT having 18 decimals and USDC 6.
  //
  // - INVARIANT: the value of the Pool's invariant, which serves as a measure of its liquidity.
  enum Variable {
    PAIR_PRICE,
    BPT_PRICE,
    INVARIANT
  }

  /**
   * @dev Returns the time average weighted price corresponding to each of `queries`. Prices are represented as 18
   * decimal fixed point values.
   */
  function getTimeWeightedAverage(OracleAverageQuery[] memory queries)
    external
    view
    returns (uint256[] memory results);

  /**
   * @dev Returns latest sample of `variable`. Prices are represented as 18 decimal fixed point values.
   */
  function getLatest(Variable variable) external view returns (uint256);

  /**
   * @dev Information for a Time Weighted Average query.
   *
   * Each query computes the average over a window of duration `secs` seconds that ended `ago` seconds ago. For
   * example, the average over the past 30 minutes is computed by settings secs to 1800 and ago to 0. If secs is 1800
   * and ago is 1800 as well, the average between 60 and 30 minutes ago is computed instead.
   */
  struct OracleAverageQuery {
    Variable variable;
    uint256 secs;
    uint256 ago;
  }

  /**
   * @dev Returns largest time window that can be safely queried, where 'safely' means the Oracle is guaranteed to be
   * able to produce a result and not revert.
   *
   * If a query has a non-zero `ago` value, then `secs + ago` (the oldest point in time) must be smaller than this
   * value for 'safe' queries.
   */
  function getLargestSafeQueryWindow() external view returns (uint256);

  /**
   * @dev Returns the accumulators corresponding to each of `queries`.
   */
  function getPastAccumulators(OracleAccumulatorQuery[] memory queries)
    external
    view
    returns (int256[] memory results);

  /**
   * @dev Information for an Accumulator query.
   *
   * Each query estimates the accumulator at a time `ago` seconds ago.
   */
  struct OracleAccumulatorQuery {
    Variable variable;
    uint256 ago;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

/**
 * @notice An extension of OpenZeppelin's `Ownable.sol` contract that requires
 * an address to be nominated, and then accept that nomination, before
 * ownership is transferred.
 */
interface ISafeOwnable {
  /**
   * @dev Emitted via `transferOwnership()`.
   * @param previousNominee The previous nominee
   * @param newNominee The new nominee
   */
  event NomineeUpdate(
    address indexed previousNominee,
    address indexed newNominee
  );

  /**
   * @notice Nominates an address to be owner of the contract.
   * @dev Only callable by `owner()`.
   * @param nominee The address that will be nominated
   */
  function transferOwnership(address nominee) external;

  /**
   * @notice Renounces ownership of contract and leaves the contract
   * without any owner.
   * @dev Only callable by `owner()`.
   * Sets nominee back to zero address.
   * It will not be possible to call `onlyOwner` functions anymore.
   */
  function renounceOwnership() external;

  /**
   * @notice Accepts ownership nomination.
   * @dev Only callable by the current nominee. Sets nominee back to zero
   * address.
   */
  function acceptOwnership() external;

  /// @return The current nominee
  function getNominee() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

interface IUintValue {
  function get() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {IUintValue} from "./IUintValue.sol";
import {IUniswapV3Oracle} from "../mean-finance/interfaces/IUniswapV3Oracle.sol";

interface IUniswapV3OracleUintValue is IUintValue {
  event BaseAmountChange(uint128 amount);
  event ObservationPeriodChange(uint32 period);

  function setObservationPeriod(uint32 observationPeriod) external;

  function setBaseAmount(uint128 amount) external;

  function getUniswapOracle() external view returns (IUniswapV3Oracle);

  function getBaseToken() external view returns (address);

  function getUniswapQuoteToken() external view returns (address);

  function getObservationPeriod() external view returns (uint32);

  function getBaseAmount() external view returns (uint128);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {IUintValue, IUniswapV3Oracle, IUniswapV3OracleUintValue} from "./IUniswapV3OracleUintValue.sol";
import {IPriceOracle} from "../balancer/IPriceOracle.sol";

interface IUniswapV3ToBalancerV2OracleUintValue is IUniswapV3OracleUintValue {
  function getBalancerOracle() external view returns (IPriceOracle);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.7;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

interface IUniswapV3Oracle {
  function UNISWAP_V3_FACTORY() external view returns (IUniswapV3Factory);

  function CARDINALITY_PER_MINUTE() external view returns (uint8);

  function supportedFeeTiers() external view returns (uint24[] memory);

  function isPairSupported(address tokenA, address tokenB)
    external
    view
    returns (bool);

  function getAllPoolsForPair(address tokenA, address tokenB)
    external
    view
    returns (address[] memory);

  function quoteAllAvailablePoolsWithTimePeriod(
    uint128 baseAmount,
    address baseToken,
    address quoteToken,
    uint32 period
  ) external view returns (uint256 quoteAmount, address[] memory queriedPools);

  function quoteSpecificFeeTiersWithTimePeriod(
    uint128 baseAmount,
    address baseToken,
    address quoteToken,
    uint24[] calldata feeTiers,
    uint32 period
  ) external view returns (uint256 quoteAmount, address[] memory queriedPools);

  function quoteSpecificPoolsWithTimePeriod(
    uint128 baseAmount,
    address baseToken,
    address quoteToken,
    address[] calldata pools,
    uint32 period
  ) external view returns (uint256 quoteAmount);

  function prepareAllAvailablePoolsWithTimePeriod(
    address tokenA,
    address tokenB,
    uint32 period
  ) external returns (address[] memory preparedPools);

  function prepareSpecificFeeTiersWithTimePeriod(
    address tokenA,
    address tokenB,
    uint24[] calldata feeTiers,
    uint32 period
  ) external returns (address[] memory preparedPools);

  function prepareSpecificPoolsWithTimePeriod(
    address[] calldata pools,
    uint32 period
  ) external;

  function prepareAllAvailablePoolsWithCardinality(
    address tokenA,
    address tokenB,
    uint16 cardinality
  ) external returns (address[] memory preparedPools);

  function prepareSpecificFeeTiersWithCardinality(
    address tokenA,
    address tokenB,
    uint24[] calldata feeTiers,
    uint16 cardinality
  ) external returns (address[] memory preparedPools);

  function prepareSpecificPoolsWithCardinality(
    address[] calldata pools,
    uint16 cardinality
  ) external;

  function addNewFeeTier(uint24 feeTier) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity =0.8.7;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISafeOwnable} from "./interfaces/ISafeOwnable.sol";

contract SafeOwnable is ISafeOwnable, Ownable {
  address private _nominee;

  modifier onlyNominee() {
    require(_msgSender() == _nominee, "msg.sender != nominee");
    _;
  }

  function transferOwnership(address nominee)
    public
    virtual
    override(ISafeOwnable, Ownable)
    onlyOwner
  {
    _setNominee(nominee);
  }

  function acceptOwnership() public virtual override onlyNominee {
    _transferOwnership(_nominee);
    _setNominee(address(0));
  }

  function renounceOwnership()
    public
    virtual
    override(ISafeOwnable, Ownable)
    onlyOwner
  {
    super.renounceOwnership();
    _setNominee(address(0));
  }

  function getNominee() public view virtual override returns (address) {
    return _nominee;
  }

  function _setNominee(address nominee) internal virtual {
    address _oldNominee = _nominee;
    _nominee = nominee;
    emit NomineeUpdate(_oldNominee, nominee);
  }
}