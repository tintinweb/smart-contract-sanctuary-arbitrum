// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';
import {DenominatedOracle} from '@contracts/oracles/DenominatedOracle.sol';
import {FactoryChild} from '@contracts/factories/FactoryChild.sol';

contract DenominatedOracleChild is DenominatedOracle, FactoryChild {
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
pragma solidity 0.7.6;

/**
 * @title IBaseOracle
 * @dev Basic interface for a system price feed
 *         All price feeds should be translated into an 18 decimals format
 */
interface IBaseOracle {
  /**
   * @dev Symbol of the quote: token / baseToken (e.g. 'ETH / USD')
   */
  function symbol() external view returns (string memory _symbol);

  /**
   * @dev Fetch the latest oracle result and whether it is valid or not
   * @dev    This method should never revert
   */
  function getResultWithValidity() external view returns (uint256 _result, bool _validity);

  /**
   * @dev Fetch the latest oracle result
   * @dev    Will revert if is the price feed is invalid
   */
  function read() external view returns (uint256 _value);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';
import {Math, WAD} from '@libraries/Math.sol';

/**
 * @notice Transforms two price feeds with a shared token into a new denominated price feed between the other two tokens of the feeds
 * @dev    Requires an external base price feed with a shared token between the price source and the denomination price source
 */
contract DenominatedOracle {
  using Math for uint256;

  bool public immutable INVERTED;

  // --- Registry ---
  IBaseOracle public priceSource;
  IBaseOracle public denominationPriceSource;

  // --- Data ---
  string public symbol;

  /**
   *
   * @param  _priceSource Address of the base price source that is used to calculate the price
   * @param  _denominationPriceSource Address of the denomination price source that is used to calculate price
   * @param  _inverted Flag that indicates whether the price source quote should be INVERTED or not
   */
  constructor(IBaseOracle _priceSource, IBaseOracle _denominationPriceSource, bool _inverted) {
    require(address(_priceSource) != address(0));
    require(address(_denominationPriceSource) != address(0));

    priceSource = _priceSource;
    denominationPriceSource = _denominationPriceSource;
    INVERTED = _inverted;

    if (_inverted) {
      symbol = string(abi.encodePacked('(', priceSource.symbol(), ')^-1 / (', denominationPriceSource.symbol(), ')'));
    } else {
      symbol = string(abi.encodePacked('(', priceSource.symbol(), ') * (', denominationPriceSource.symbol(), ')'));
    }
  }

  function getResultWithValidity() external view returns (uint256 _result, bool _validity) {
    (uint256 _priceSourceValue, bool _priceSourceValidity) = priceSource.getResultWithValidity();
    (uint256 _denominationPriceSourceValue, bool _denominationPriceSourceValidity) =
      denominationPriceSource.getResultWithValidity();

    if (INVERTED) {
      if (_priceSourceValue == 0) return (0, false);
      _result = WAD.wmul(_denominationPriceSourceValue).wdiv(_priceSourceValue);
    } else {
      _result = _priceSourceValue.wmul(_denominationPriceSourceValue);
    }

    _validity = _priceSourceValidity && _denominationPriceSourceValidity;
  }

  function read() external view returns (uint256 _result) {
    uint256 _priceSourceValue = priceSource.read();
    uint256 _denominationPriceSourceValue = denominationPriceSource.read();

    if (INVERTED) {
      if (_priceSourceValue == 0) revert('InvalidPriceFeed');
      _priceSourceValue = WAD.wdiv(_priceSourceValue);
    }

    return _priceSourceValue.wmul(_denominationPriceSourceValue);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

abstract contract FactoryChild {
  // --- Registry ---
  address public factory;

  // --- Init ---

  /// @dev Verifies that the contract is being deployed by a contract address
  constructor() {
    factory = msg.sender;
  }

  // --- Modifiers ---

  ///@dev Verifies that the caller is the factory
  modifier onlyFactory() {
    require(msg.sender == factory, 'CallerNotFactory');
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

uint256 constant WAD = 1e18;

library Math {
  function wdiv(uint256 _x, uint256 _y) internal pure returns (uint256 _wdiv) {
    return (_x * WAD) / _y;
  }

  function wmul(uint256 _x, uint256 _y) internal pure returns (uint256 _wmul) {
    uint256 result = (_x * _y);
    require(result / _x == _y, 'wmul overflow error detected');

    return result / WAD;
  }
}