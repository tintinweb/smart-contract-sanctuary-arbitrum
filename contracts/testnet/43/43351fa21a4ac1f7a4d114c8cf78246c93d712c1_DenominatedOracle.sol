// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';
import {IDenominatedOracle} from '@interfaces/oracles/IDenominatedOracle.sol';

import {Math, WAD} from '@libraries/Math.sol';

/**
 * @title DenominatedOracle
 * @notice Transforms a price feed between two tokens into a price feed denominated by a third token
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
   * @notice Concatenated symbols of the two price sources used for quoting
   *         (e.g. '(WBTC / ETH) * (ETH / USD)')
   * @dev    The order of the symbols must follow a continuous chain of tokens
   * @inheritdoc IBaseOracle
   */
  string public symbol;

  /// @inheritdoc IDenominatedOracle
  bool public inverted;

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

interface IDenominatedOracle is IBaseOracle {
  // --- Errors ---
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

uint256 constant MAX_RAD = type(uint256).max / RAY;
uint256 constant RAD = 10 ** 45;
uint256 constant RAY = 10 ** 27;
uint256 constant WAD = 10 ** 18;
uint256 constant HOUR = 3600;
uint256 constant YEAR = 365 days;
uint256 constant HUNDRED = 100;

library Math {
  error IntOverflow();

  function add(uint256 _x, int256 _y) internal pure returns (uint256 _add) {
    if (_y >= 0) {
      return _x + uint256(_y);
    } else {
      return _x - uint256(-_y);
    }
  }

  function sub(uint256 _x, int256 _y) internal pure returns (uint256 _sub) {
    if (_y >= 0) {
      return _x - uint256(_y);
    } else {
      return _x + uint256(-_y);
    }
  }

  function sub(uint256 _x, uint256 _y) internal pure returns (int256 _sub) {
    return toInt(_x) - toInt(_y);
  }

  function mul(uint256 _x, int256 _y) internal pure returns (int256 _mul) {
    return toInt(_x) * _y;
  }

  function rmul(uint256 _x, uint256 _y) internal pure returns (uint256 _rmul) {
    return (_x * _y) / RAY;
  }

  function rmul(uint256 _x, int256 y) internal pure returns (int256 _rmul) {
    return (toInt(_x) * y) / int256(RAY);
  }

  function wmul(uint256 _x, uint256 _y) internal pure returns (uint256 _wmul) {
    return (_x * _y) / WAD;
  }

  function wmul(uint256 _x, int256 _y) internal pure returns (int256 _wmul) {
    return (toInt(_x) * _y) / int256(WAD);
  }

  function wmul(int256 _x, int256 _y) internal pure returns (int256 _wmul) {
    return (_x * _y) / int256(WAD);
  }

  function rdiv(uint256 _x, uint256 _y) internal pure returns (uint256 _rdiv) {
    return (_x * RAY) / _y;
  }

  function rdiv(int256 _x, int256 _y) internal pure returns (int256 _rdiv) {
    return (_x * int256(RAY)) / _y;
  }

  function wdiv(uint256 _x, uint256 _y) internal pure returns (uint256 _wdiv) {
    return (_x * WAD) / _y;
  }

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

  function max(uint256 _x, uint256 _y) internal pure returns (uint256 _max) {
    _max = (_x >= _y) ? _x : _y;
  }

  function min(uint256 _x, uint256 _y) internal pure returns (uint256 _min) {
    _min = (_x <= _y) ? _x : _y;
  }

  function toInt(uint256 _x) internal pure returns (int256 _int) {
    _int = int256(_x);
    if (_int < 0) revert IntOverflow();
  }

  // --- PI Specific Math ---
  function riemannSum(int256 _x, int256 _y) internal pure returns (int256 _riemannSum) {
    return (_x + _y) / 2;
  }

  function absolute(int256 _x) internal pure returns (uint256 _z) {
    _z = (_x < 0) ? uint256(-_x) : uint256(_x);
  }
}