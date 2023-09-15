// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IDenominatedOracleChild} from '@interfaces/factories/IDenominatedOracleChild.sol';
import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';

import {DenominatedOracle} from '@contracts/oracles/DenominatedOracle.sol';

import {FactoryChild} from '@contracts/factories/FactoryChild.sol';

/**
 * @title  DenominatedOracleChild
 * @notice This contract inherits all the functionality of DenominatedOracle to be factory deployed
 */
contract DenominatedOracleChild is DenominatedOracle, FactoryChild, IDenominatedOracleChild {
  // --- Init ---

  /**
   * @param  _priceSource Address of the price source
   * @param  _denominationPriceSource Address of the denomination price source
   * @param  _inverted Boolean indicating if the denomination quote should be inverted
   */
  constructor(
    IBaseOracle _priceSource,
    IBaseOracle _denominationPriceSource,
    bool _inverted
  ) DenominatedOracle(_priceSource, _denominationPriceSource, _inverted) {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IDenominatedOracle} from '@interfaces/oracles/IDenominatedOracle.sol';

import {IFactoryChild} from '@interfaces/factories/IFactoryChild.sol';

interface IDenominatedOracleChild is IDenominatedOracle, IFactoryChild {}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/**
 * @title IBaseOracle
 * @notice Basic interface for a system price feed
 *         All price feeds should be translated into an 18 decimals format
 */
interface IBaseOracle {
  // --- Errors ---
  error InvalidPriceFeed();

  /**
   * @notice Symbol of the quote: token / baseToken (e.g. 'ETH / USD')
   */
  function symbol() external view returns (string memory _symbol);

  /**
   * @notice Fetch the latest oracle result and whether it is valid or not
   * @dev    This method should never revert
   */
  function getResultWithValidity() external view returns (uint256 _result, bool _validity);

  /**
   * @notice Fetch the latest oracle result
   * @dev    Will revert if is the price feed is invalid
   */
  function read() external view returns (uint256 _value);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';
import {IDenominatedOracle} from '@interfaces/oracles/IDenominatedOracle.sol';

import {Math, WAD} from '@libraries/Math.sol';

/**
 * @title  DenominatedOracle
 * @notice Transforms two price feeds with a shared token into a new denominated price feed between the other two tokens of the feeds
 * @dev    Requires an external base price feed with a shared token between the price source and the denomination price source
 */
contract DenominatedOracle is IBaseOracle, IDenominatedOracle {
  using Math for uint256;

  // --- Registry ---

  /// @inheritdoc IDenominatedOracle
  IBaseOracle public priceSource;
  /// @inheritdoc IDenominatedOracle
  IBaseOracle public denominationPriceSource;

  // --- Data ---

  /**
   * @notice Concatenated symbols of the two price sources used for quoting (e.g. '(WBTC / ETH) * (ETH / USD)')
   * @dev    The order of the symbols must follow a continuous chain of tokens
   * @inheritdoc IBaseOracle
   */
  string public symbol;

  /// @inheritdoc IDenominatedOracle
  bool public inverted;

  // --- Init ---

  /**
   *
   * @param  _priceSource Address of the base price source that is used to calculate the price
   * @param  _denominationPriceSource Address of the denomination price source that is used to calculate price
   * @param  _inverted Flag that indicates whether the price source quote should be inverted or not
   */
  constructor(IBaseOracle _priceSource, IBaseOracle _denominationPriceSource, bool _inverted) {
    if (address(_priceSource) == address(0)) revert DenominatedOracle_NullPriceSource();
    if (address(_denominationPriceSource) == address(0)) revert DenominatedOracle_NullPriceSource();

    priceSource = _priceSource;
    denominationPriceSource = _denominationPriceSource;
    inverted = _inverted;

    if (_inverted) {
      symbol = string(abi.encodePacked('(', priceSource.symbol(), ')^-1 / (', denominationPriceSource.symbol(), ')'));
    } else {
      symbol = string(abi.encodePacked('(', priceSource.symbol(), ') * (', denominationPriceSource.symbol(), ')'));
    }
  }

  /// @inheritdoc IBaseOracle
  function getResultWithValidity() external view returns (uint256 _result, bool _validity) {
    (uint256 _priceSourceValue, bool _priceSourceValidity) = priceSource.getResultWithValidity();
    (uint256 _denominationPriceSourceValue, bool _denominationPriceSourceValidity) =
      denominationPriceSource.getResultWithValidity();

    _priceSourceValue = inverted ? WAD.wdiv(_priceSourceValue) : _priceSourceValue;

    _result = _priceSourceValue.wmul(_denominationPriceSourceValue);
    _validity = _priceSourceValidity && _denominationPriceSourceValidity;
  }

  /// @inheritdoc IBaseOracle
  function read() external view returns (uint256 _result) {
    uint256 _priceSourceValue = priceSource.read();
    uint256 _denominationPriceSourceValue = denominationPriceSource.read();

    _priceSourceValue = inverted ? WAD.wdiv(_priceSourceValue) : _priceSourceValue;

    return _priceSourceValue.wmul(_denominationPriceSourceValue);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IFactoryChild} from '@interfaces/factories/IFactoryChild.sol';

/**
 * @title  FactoryChild
 * @notice This abstract contract adds a factory address and modifier to the inheriting contract
 */
abstract contract FactoryChild is IFactoryChild {
  // --- Registry ---

  /// @inheritdoc IFactoryChild
  address public factory;

  // --- Init ---

  /// @dev Verifies that the contract is being deployed by a contract address
  constructor() {
    factory = msg.sender;
    if (factory.code.length == 0) revert NotFactoryDeployment();
  }

  // --- Modifiers ---

  /// @notice Verifies that the caller is the factory
  modifier onlyFactory() {
    if (msg.sender != factory) revert CallerNotFactory();
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';

interface IDenominatedOracle is IBaseOracle {
  // --- Errors ---

  /// @notice Throws if either the provided price source or denominated price source are null
  error DenominatedOracle_NullPriceSource();

  /**
   * @notice Address of the base price source that is used to calculate the price
   * @dev    Assumes that the price source is a valid IBaseOracle
   */
  function priceSource() external view returns (IBaseOracle _priceSource);

  /**
   * @notice Address of the base price source that is used to calculate the denominated price
   * @dev    Assumes that the price source is a valid IBaseOracle
   */
  function denominationPriceSource() external view returns (IBaseOracle _denominationPriceSource);

  /**
   * @notice Whether the price source quote should be inverted or not
   * @dev    Used to fix an inverted path of token quotes into a continuous chain of tokens (e.g. '(ETH / WBTC)^-1 * (ETH / USD)')
   */
  function inverted() external view returns (bool _inverted);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IFactoryChild {
  // --- Errors ---

  /// @dev Throws when the contract is being deployed by a non-contract address
  error NotFactoryDeployment();
  /// @dev Throws when trying to call an onlyFactory function from a non-factory address
  error CallerNotFactory();

  // --- Registry ---

  /**
   * @notice Getter for the address of the factory that deployed the inheriting contract
   * @return _factory Factory address
   */
  function factory() external view returns (address _factory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/// @dev Max uint256 value that a RAD can represent without overflowing
uint256 constant MAX_RAD = type(uint256).max / RAY;
/// @dev Uint256 representation of 1 RAD
uint256 constant RAD = 10 ** 45;
/// @dev Uint256 representation of 1 RAY
uint256 constant RAY = 10 ** 27;
/// @dev Uint256 representation of 1 WAD
uint256 constant WAD = 10 ** 18;
/// @dev Uint256 representation of 1 year in seconds
uint256 constant YEAR = 365 days;
/// @dev Uint256 representation of 1 hour in seconds
uint256 constant HOUR = 3600;

/**
 * @title Math
 * @notice This library contains common math functions
 */
library Math {
  // --- Errors ---

  /// @dev Throws when trying to cast a uint256 to an int256 that overflows
  error IntOverflow();

  // --- Math ---

  /**
   * @notice Calculates the sum of an unsigned integer and a signed integer
   * @param  _x Unsigned integer
   * @param  _y Signed integer
   * @return _add Unsigned sum of `_x` and `_y`
   */
  function add(uint256 _x, int256 _y) internal pure returns (uint256 _add) {
    if (_y >= 0) {
      return _x + uint256(_y);
    } else {
      return _x - uint256(-_y);
    }
  }

  /**
   * @notice Calculates the substraction of an unsigned integer and a signed integer
   * @param  _x Unsigned integer
   * @param  _y Signed integer
   * @return _sub Unsigned substraction of `_x` and `_y`
   */
  function sub(uint256 _x, int256 _y) internal pure returns (uint256 _sub) {
    if (_y >= 0) {
      return _x - uint256(_y);
    } else {
      return _x + uint256(-_y);
    }
  }

  /**
   * @notice Calculates the substraction of two unsigned integers
   * @param  _x Unsigned integer
   * @param  _y Unsigned integer
   * @return _sub Signed substraction of `_x` and `_y`
   */
  function sub(uint256 _x, uint256 _y) internal pure returns (int256 _sub) {
    return toInt(_x) - toInt(_y);
  }

  /**
   * @notice Calculates the multiplication of an unsigned integer and a signed integer
   * @param  _x Unsigned integer
   * @param  _y Signed integer
   * @return _mul Signed multiplication of `_x` and `_y`
   */
  function mul(uint256 _x, int256 _y) internal pure returns (int256 _mul) {
    return toInt(_x) * _y;
  }

  /**
   * @notice Calculates the multiplication of two unsigned RAY integers
   * @param  _x Unsigned RAY integer
   * @param  _y Unsigned RAY integer
   * @return _rmul Unsigned multiplication of `_x` and `_y` in RAY precision
   */
  function rmul(uint256 _x, uint256 _y) internal pure returns (uint256 _rmul) {
    return (_x * _y) / RAY;
  }

  /**
   * @notice Calculates the multiplication of an unsigned and a signed RAY integers
   * @param  _x Unsigned RAY integer
   * @param  _y Signed RAY integer
   * @return _rmul Signed multiplication of `_x` and `_y` in RAY precision
   */
  function rmul(uint256 _x, int256 _y) internal pure returns (int256 _rmul) {
    return (toInt(_x) * _y) / int256(RAY);
  }

  /**
   * @notice Calculates the multiplication of two unsigned WAD integers
   * @param  _x Unsigned WAD integer
   * @param  _y Unsigned WAD integer
   * @return _wmul Unsigned multiplication of `_x` and `_y` in WAD precision
   */
  function wmul(uint256 _x, uint256 _y) internal pure returns (uint256 _wmul) {
    return (_x * _y) / WAD;
  }

  /**
   * @notice Calculates the multiplication of an unsigned and a signed WAD integers
   * @param  _x Unsigned WAD integer
   * @param  _y Signed WAD integer
   * @return _wmul Signed multiplication of `_x` and `_y` in WAD precision
   */
  function wmul(uint256 _x, int256 _y) internal pure returns (int256 _wmul) {
    return (toInt(_x) * _y) / int256(WAD);
  }

  /**
   * @notice Calculates the multiplication of two signed WAD integers
   * @param  _x Signed WAD integer
   * @param  _y Signed WAD integer
   * @return _wmul Signed multiplication of `_x` and `_y` in WAD precision
   */
  function wmul(int256 _x, int256 _y) internal pure returns (int256 _wmul) {
    return (_x * _y) / int256(WAD);
  }

  /**
   * @notice Calculates the division of two unsigned RAY integers
   * @param  _x Unsigned RAY integer
   * @param  _y Unsigned RAY integer
   * @return _rdiv Unsigned division of `_x` by `_y` in RAY precision
   */
  function rdiv(uint256 _x, uint256 _y) internal pure returns (uint256 _rdiv) {
    return (_x * RAY) / _y;
  }

  /**
   * @notice Calculates the division of two signed RAY integers
   * @param  _x Signed RAY integer
   * @param  _y Signed RAY integer
   * @return _rdiv Signed division of `_x` by `_y` in RAY precision
   */
  function rdiv(int256 _x, int256 _y) internal pure returns (int256 _rdiv) {
    return (_x * int256(RAY)) / _y;
  }

  /**
   * @notice Calculates the division of two unsigned WAD integers
   * @param  _x Unsigned WAD integer
   * @param  _y Unsigned WAD integer
   * @return _wdiv Unsigned division of `_x` by `_y` in WAD precision
   */
  function wdiv(uint256 _x, uint256 _y) internal pure returns (uint256 _wdiv) {
    return (_x * WAD) / _y;
  }

  /**
   * @notice Calculates the power of an unsigned RAY integer to an unsigned integer
   * @param  _x Unsigned RAY integer
   * @param  _n Unsigned integer exponent
   * @return _rpow Unsigned `_x` to the power of `_n` in RAY precision
   */
  function rpow(uint256 _x, uint256 _n) internal pure returns (uint256 _rpow) {
    assembly {
      switch _x
      case 0 {
        switch _n
        case 0 { _rpow := RAY }
        default { _rpow := 0 }
      }
      default {
        switch mod(_n, 2)
        case 0 { _rpow := RAY }
        default { _rpow := _x }
        let half := div(RAY, 2) // for rounding.
        for { _n := div(_n, 2) } _n { _n := div(_n, 2) } {
          let _xx := mul(_x, _x)
          if iszero(eq(div(_xx, _x), _x)) { revert(0, 0) }
          let _xxRound := add(_xx, half)
          if lt(_xxRound, _xx) { revert(0, 0) }
          _x := div(_xxRound, RAY)
          if mod(_n, 2) {
            let _zx := mul(_rpow, _x)
            if and(iszero(iszero(_x)), iszero(eq(div(_zx, _x), _rpow))) { revert(0, 0) }
            let _zxRound := add(_zx, half)
            if lt(_zxRound, _zx) { revert(0, 0) }
            _rpow := div(_zxRound, RAY)
          }
        }
      }
    }
  }

  /**
   * @notice Calculates the maximum of two unsigned integers
   * @param  _x Unsigned integer
   * @param  _y Unsigned integer
   * @return _max Unsigned maximum of `_x` and `_y`
   */
  function max(uint256 _x, uint256 _y) internal pure returns (uint256 _max) {
    _max = (_x >= _y) ? _x : _y;
  }

  /**
   * @notice Calculates the minimum of two unsigned integers
   * @param  _x Unsigned integer
   * @param  _y Unsigned integer
   * @return _min Unsigned minimum of `_x` and `_y`
   */
  function min(uint256 _x, uint256 _y) internal pure returns (uint256 _min) {
    _min = (_x <= _y) ? _x : _y;
  }

  /**
   * @notice Casts an unsigned integer to a signed integer
   * @param  _x Unsigned integer
   * @return _int Signed integer
   * @dev    Throws if `_x` is too large to fit in an int256
   */
  function toInt(uint256 _x) internal pure returns (int256 _int) {
    _int = int256(_x);
    if (_int < 0) revert IntOverflow();
  }

  // --- PI Specific Math ---

  /**
   * @notice Calculates the Riemann sum of two signed integers
   * @param  _x Signed integer
   * @param  _y Signed integer
   * @return _riemannSum Riemann sum of `_x` and `_y`
   */
  function riemannSum(int256 _x, int256 _y) internal pure returns (int256 _riemannSum) {
    return (_x + _y) / 2;
  }

  /**
   * @notice Calculates the absolute value of a signed integer
   * @param  _x Signed integer
   * @return _z Unsigned absolute value of `_x`
   */
  function absolute(int256 _x) internal pure returns (uint256 _z) {
    _z = (_x < 0) ? uint256(-_x) : uint256(_x);
  }
}