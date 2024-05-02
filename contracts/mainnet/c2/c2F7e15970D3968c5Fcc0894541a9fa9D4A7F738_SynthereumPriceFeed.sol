// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

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
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {AggregatorV3Interface} from '../../../@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import {SynthereumPriceFeedImplementation} from './PriceFeedImplementation.sol';

/**
 * @title Chainlink implementation for synthereum price-feed
 */
contract SynthereumChainlinkPriceFeed is SynthereumPriceFeedImplementation {
  //----------------------------------------
  // Constructor
  //----------------------------------------
  /**
   * @notice Constructs the SynthereumChainlinkPriceFeed contract
   * @param _synthereumFinder Synthereum finder contract
   * @param _roles Admin and Mainteiner roles
   */
  constructor(ISynthereumFinder _synthereumFinder, Roles memory _roles)
    SynthereumPriceFeedImplementation(_synthereumFinder, _roles)
  {}

  //----------------------------------------
  // External functions
  //----------------------------------------
  /**
   * @notice Add support for a chainlink pair
   * @notice Only maintainer can call this function
   * @param _priceId Name of the pair identifier
   * @param _kind Type of the pair (standard or reversed)
   * @param _source Contract from which get the price
   * @param _conversionUnit Conversion factor to be applied on price get from source (if 0 no conversion)
   * @param _extraData Extra-data needed for getting the price from source
   */
  function setPair(
    string calldata _priceId,
    Type _kind,
    address _source,
    uint256 _conversionUnit,
    bytes calldata _extraData,
    uint64 _maxSpread
  ) public override {
    super.setPair(
      _priceId,
      _kind,
      _source,
      _conversionUnit,
      _extraData,
      _maxSpread
    );
    require(_maxSpread > 0, 'Max spread can not be dynamic');
  }

  //----------------------------------------
  // Internal view functions
  //----------------------------------------
  /**
   * @notice Get last chainlink oracle price for an input source
   * @param _source Source contract from which get the price
   * @return price Price get from the source oracle
   * @return decimals Decimals of the price
   */
  function _getOracleLatestRoundPrice(
    bytes32,
    address _source,
    bytes memory
  ) internal view override returns (uint256 price, uint8 decimals) {
    AggregatorV3Interface aggregator = AggregatorV3Interface(_source);
    (, int256 unconvertedPrice, , , ) = aggregator.latestRoundData();
    require(unconvertedPrice >= 0, 'Negative value');
    price = uint256(unconvertedPrice);
    decimals = aggregator.decimals();
  }

  /**
   * @notice No dynamic spread supported
   */
  function _getDynamicMaxSpread(
    bytes32,
    address,
    bytes memory
  ) internal view virtual override returns (uint64) {
    revert('Dynamic max spread not supported');
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Provides addresses of the contracts implementing certain interfaces.
 */
interface ISynthereumFinder {
  /**
   * @notice Updates the address of the contract that implements `interfaceName`.
   * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
   * @param implementationAddress address of the deployed contract that implements the interface.
   */
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external;

  /**
   * @notice Gets the address of the contract that implements the given `interfaceName`.
   * @param interfaceName queried interface.
   * @return implementationAddress Address of the deployed contract that implements the interface.
   */
  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {ISynthereumPriceFeedImplementation} from './interfaces/IPriceFeedImplementation.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {PreciseUnitMath} from '../../base/utils/PreciseUnitMath.sol';
import {Address} from '../../../@openzeppelin/contracts/utils/Address.sol';
import {StringUtils} from '../../base/utils/StringUtils.sol';
import {StandardAccessControlEnumerable} from '../../common/roles/StandardAccessControlEnumerable.sol';

/**
 * @title Abstarct contract inherited by the price-feed implementations
 */
abstract contract SynthereumPriceFeedImplementation is
  ISynthereumPriceFeedImplementation,
  StandardAccessControlEnumerable
{
  using PreciseUnitMath for uint256;
  using Address for address;
  using StringUtils for string;

  enum Type {
    UNSUPPORTED,
    NORMAL,
    REVERSE
  }

  struct PairData {
    Type priceType;
    address source;
    uint64 maxSpread;
    uint256 conversionUnit;
    bytes extraData;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------
  ISynthereumFinder public immutable synthereumFinder;
  mapping(bytes32 => PairData) private pairs;

  //----------------------------------------
  // Events
  //----------------------------------------
  event SetPair(
    bytes32 indexed priceIdentifier,
    Type kind,
    address source,
    uint256 conversionUnit,
    bytes extraData,
    uint64 maxSpread
  );

  event RemovePair(bytes32 indexed priceIdentifier);

  //----------------------------------------
  // Modifiers
  //----------------------------------------
  modifier onlyPriceFeed() {
    if (msg.sender != tx.origin) {
      address priceFeed = synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.PriceFeed
      );
      require(msg.sender == priceFeed, 'Only price-feed');
    }
    _;
  }

  modifier onlyCall() {
    require(msg.sender == tx.origin, 'Only off-chain call');
    _;
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------
  /**
   * @notice Constructs the SynthereumPriceFeedImplementation contract
   * @param _synthereumFinder Synthereum finder contract
   * @param _roles Admin and Mainteiner roles
   */
  constructor(ISynthereumFinder _synthereumFinder, Roles memory _roles) {
    synthereumFinder = _synthereumFinder;
    _setAdmin(_roles.admin);
    _setMaintainer(_roles.maintainer);
  }

  //----------------------------------------
  // Public functions
  //----------------------------------------
  /**
   * @notice Add support for a pair
   * @notice Only maintainer can call this function
   * @param _priceId Name of the pair identifier
   * @param _kind Type of the pair (standard or reversed)
   * @param _source Contract from which get the price
   * @param _conversionUnit Conversion factor to be applied on price get from source (if 0 no conversion)
   * @param _extraData Extra-data needed for getting the price from source
   */
  function setPair(
    string calldata _priceId,
    Type _kind,
    address _source,
    uint256 _conversionUnit,
    bytes calldata _extraData,
    uint64 _maxSpread
  ) public virtual onlyMaintainer {
    bytes32 priceIdentifierHex = _priceId.stringToBytes32();
    require(priceIdentifierHex != 0x0, 'Null identifier');
    if (_kind == Type.NORMAL || _kind == Type.REVERSE) {
      require(_source.isContract(), 'Source is not a contract');
    } else {
      revert('No type passed');
    }
    require(
      _maxSpread < PreciseUnitMath.PRECISE_UNIT,
      'Spread must be less than 100%'
    );

    pairs[priceIdentifierHex] = PairData(
      _kind,
      _source,
      _maxSpread,
      _conversionUnit,
      _extraData
    );

    emit SetPair(
      priceIdentifierHex,
      _kind,
      _source,
      _conversionUnit,
      _extraData,
      _maxSpread
    );
  }

  /**
   * @notice Remove support for a pair
   * @notice Only maintainer can call this function
   * @param _priceId Name of the pair identifier
   */
  function removePair(string calldata _priceId) public virtual onlyMaintainer {
    bytes32 priceIdentifierHex = _priceId.stringToBytes32();
    require(
      pairs[priceIdentifierHex].priceType != Type.UNSUPPORTED,
      'Price identifier not supported'
    );
    delete pairs[priceIdentifierHex];
    emit RemovePair(priceIdentifierHex);
  }

  //----------------------------------------
  // Public view functions
  //----------------------------------------
  /**
   * @notice Get the pair data for a given pair identifier, revert if not supported
   * @param _identifier HexName of the pair identifier
   * @return Pair data
   */
  function pair(bytes32 _identifier)
    public
    view
    virtual
    returns (PairData memory)
  {
    return _pair(_identifier);
  }

  /**
   * @notice Get the pair data for a given pair identifier, revert if not supported
   * @param _identifier Name of the pair identifier
   * @return Pair data
   */
  function pair(string calldata _identifier)
    public
    view
    virtual
    returns (PairData memory)
  {
    return _pair(_identifier.stringToBytes32());
  }

  /**
   * @notice Return if a price identifier is supported
   * @param _priceId HexName of price identifier
   * @return isSupported True fi supporteed, otherwise false
   */
  function isPriceSupported(bytes32 _priceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return pairs[_priceId].priceType != Type.UNSUPPORTED;
  }

  /**
   * @notice Return if a price identifier is supported
   * @param _priceId Name of price identifier
   * @return isSupported True fi supported, otherwise false
   */
  function isPriceSupported(string calldata _priceId)
    public
    view
    virtual
    returns (bool)
  {
    return pairs[_priceId.stringToBytes32()].priceType != Type.UNSUPPORTED;
  }

  /**
   * @notice Get last price for a given price identifier
   * @notice Only synthereum price-feed and off-chain calls can call this function
   * @param _priceId HexName of price identifier
   * @return Oracle price
   */
  function getLatestPrice(bytes32 _priceId)
    public
    view
    virtual
    override
    onlyPriceFeed
    returns (uint256)
  {
    return _getLatestPrice(_priceId);
  }

  /**
   * @notice Get last price for a given price identifier
   * @notice This function can be called just for off-chain use
   * @param _priceId Name of price identifier
   * @return Oracle price
   */
  function getLatestPrice(string calldata _priceId)
    public
    view
    virtual
    onlyCall
    returns (uint256)
  {
    return _getLatestPrice(_priceId.stringToBytes32());
  }

  /**
   * @notice Get the max update spread for a given price identifier
   * @param _priceId HexName of price identifier
   * @return Max spread
   */
  function getMaxSpread(bytes32 _priceId)
    public
    view
    virtual
    override
    returns (uint64)
  {
    return _getMaxSpread(_priceId);
  }

  /**
   * @notice Get the max update spread for a given price identifier
   * @param _priceId Name of price identifier
   * @return Max spread
   */
  function getMaxSpread(string calldata _priceId)
    public
    view
    virtual
    returns (uint64)
  {
    return _getMaxSpread(_priceId.stringToBytes32());
  }

  //----------------------------------------
  // Internal view functions
  //----------------------------------------
  /**
   * @notice Get the pair data for a given pair identifier, revert if not supported
   * @param _identifier HexName of the pair identifier
   * @return pairData Pair data
   */
  function _pair(bytes32 _identifier)
    internal
    view
    virtual
    returns (PairData memory pairData)
  {
    pairData = pairs[_identifier];
    require(pairData.priceType != Type.UNSUPPORTED, 'Pair not supported');
  }

  /**
   * @notice Get last price for a given price identifier
   * @param _priceId HexName of price identifier
   * @return price Oracle price
   */
  function _getLatestPrice(bytes32 _priceId)
    internal
    view
    virtual
    returns (uint256 price)
  {
    PairData storage pairData = pairs[_priceId];
    if (pairs[_priceId].priceType == Type.NORMAL) {
      price = _getStandardPrice(
        _priceId,
        pairData.source,
        pairData.conversionUnit,
        pairData.extraData
      );
    } else if (pairs[_priceId].priceType == Type.REVERSE) {
      price = _getReversePrice(
        _priceId,
        pairData.source,
        pairData.conversionUnit,
        pairData.extraData
      );
    } else {
      revert('Pair not supported');
    }
  }

  /**
   * @notice Retrieve from a source the standard price of a given pair
   * @param _priceId HexName of price identifier
   * @param _source Source contract from which get the price
   * @param _conversionUnit Conversion rate
   * @param _extraData Extra data of the pair for getting info
   * @return 18 decimals scaled price of the pair
   */
  function _getStandardPrice(
    bytes32 _priceId,
    address _source,
    uint256 _conversionUnit,
    bytes memory _extraData
  ) internal view virtual returns (uint256) {
    (uint256 unscaledPrice, uint8 decimals) = _getOracleLatestRoundPrice(
      _priceId,
      _source,
      _extraData
    );
    return _getScaledValue(unscaledPrice, decimals, _conversionUnit);
  }

  /**
   * @notice Retrieve from a source the reverse price of a given pair
   * @param _priceId HexName of price identifier
   * @param _source Source contract from which get the price
   * @param _conversionUnit Conversion rate
   * @param _extraData Extra data of the pair for getting info
   * @return 18 decimals scaled price of the pair
   */
  function _getReversePrice(
    bytes32 _priceId,
    address _source,
    uint256 _conversionUnit,
    bytes memory _extraData
  ) internal view virtual returns (uint256) {
    (uint256 unscaledPrice, uint8 decimals) = _getOracleLatestRoundPrice(
      _priceId,
      _source,
      _extraData
    );
    return
      PreciseUnitMath.DOUBLE_PRECISE_UNIT /
      _getScaledValue(unscaledPrice, decimals, _conversionUnit);
  }

  /**
   * @notice Get last oracle price for an input source
   * @param _priceId HexName of price identifier
   * @param _source Source contract from which get the price
   * @param _extraData Extra data of the pair for getting info
   * @return price Price get from the source oracle
   * @return decimals Decimals of the price
   */
  function _getOracleLatestRoundPrice(
    bytes32 _priceId,
    address _source,
    bytes memory _extraData
  ) internal view virtual returns (uint256 price, uint8 decimals);

  /**
   * @notice Get the max update spread for a given price identifier
   * @param _priceId HexName of price identifier
   * @return Max spread
   */
  function _getMaxSpread(bytes32 _priceId)
    internal
    view
    virtual
    returns (uint64)
  {
    PairData storage pairData = pairs[_priceId];
    require(
      pairData.priceType != Type.UNSUPPORTED,
      'Price identifier not supported'
    );
    uint64 pairMaxSpread = pairData.maxSpread;
    return
      pairMaxSpread != 0
        ? pairMaxSpread
        : _getDynamicMaxSpread(_priceId, pairData.source, pairData.extraData);
  }

  /**
   * @notice Get the max update spread for a given price identifier dinamically
   * @param _priceId HexName of price identifier
   * @param _source Source contract from which get the price
   * @param _extraData Extra data of the pair for getting info
   * @return Max spread
   */
  function _getDynamicMaxSpread(
    bytes32 _priceId,
    address _source,
    bytes memory _extraData
  ) internal view virtual returns (uint64);

  //----------------------------------------
  // Internal pure functions
  //----------------------------------------
  /**
   * @notice Covert the price to a integer with 18 decimals
   * @param _unscaledPrice Price before conversion
   * @param _decimals Number of decimals of unconverted price
   * @return price Price after conversion
   */
  function _getScaledValue(
    uint256 _unscaledPrice,
    uint8 _decimals,
    uint256 _convertionUnit
  ) internal pure virtual returns (uint256 price) {
    price = _unscaledPrice * (10**(18 - _decimals));
    if (_convertionUnit != 0) {
      price = _convertMetricUnitPrice(price, _convertionUnit);
    }
  }

  /**
   * @notice Covert the price to a different metric unit - example troyounce to grams
   * @param _price Scaled price before convertion
   * @param _conversionUnit The metric unit convertion rate
   * @return Price after conversion
   */
  function _convertMetricUnitPrice(uint256 _price, uint256 _conversionUnit)
    internal
    pure
    virtual
    returns (uint256)
  {
    return _price.div(_conversionUnit);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ISynthereumPriceFeedImplementation {
  /**
   * @notice Return if a price identifier is supported
   * @param _priceId HexName of price identifier
   * @return True fi supporteed, otherwise false
   */
  function isPriceSupported(bytes32 _priceId) external view returns (bool);

  /**
   * @notice Get last price for a given price identifier
   * @param _priceId HexName of price identifier
   * @return Oracle price
   */
  function getLatestPrice(bytes32 _priceId) external view returns (uint256);

  /**
   * @notice Get the max update spread for a given price identifier
   * @param _priceId HexName of price identifier
   * @return Max spread
   */
  function getMaxSpread(bytes32 _priceId) external view returns (uint64);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title Stores common interface names used throughout Synthereum.
 */
library SynthereumInterfaces {
  bytes32 public constant Deployer = 'Deployer';
  bytes32 public constant PoolRegistry = 'PoolRegistry';
  bytes32 public constant SelfMintingRegistry = 'SelfMintingRegistry';
  bytes32 public constant FixedRateRegistry = 'FixedRateRegistry';
  bytes32 public constant VaultRegistry = 'VaultRegistry';
  bytes32 public constant StakingLPVaultRegistry = 'StakingLPVaultRegistry';
  bytes32 public constant FactoryVersioning = 'FactoryVersioning';
  bytes32 public constant Manager = 'Manager';
  bytes32 public constant TokenFactory = 'TokenFactory';
  bytes32 public constant CreditLineController = 'CreditLineController';
  bytes32 public constant CollateralWhitelist = 'CollateralWhitelist';
  bytes32 public constant IdentifierWhitelist = 'IdentifierWhitelist';
  bytes32 public constant LendingManager = 'LendingManager';
  bytes32 public constant LendingStorageManager = 'LendingStorageManager';
  bytes32 public constant CommissionReceiver = 'CommissionReceiver';
  bytes32 public constant BuybackProgramReceiver = 'BuybackProgramReceiver';
  bytes32 public constant LendingRewardsReceiver = 'LendingRewardsReceiver';
  bytes32 public constant StakingRewardsReceiver = 'StakingRewardsReceiver';
  bytes32 public constant JarvisToken = 'JarvisToken';
  bytes32 public constant DebtTokenFactory = 'DebtTokenFactory';
  bytes32 public constant VaultFactory = 'VaultFactory';
  bytes32 public constant StakingLPVaultFactory = 'StakingLPVaultFactory';
  bytes32 public constant PriceFeed = 'PriceFeed';
  bytes32 public constant StakedJarvisToken = 'StakedJarvisToken';
  bytes32 public constant StakingLPVaultData = 'StakingLPVaultData';
  bytes32 public constant JarvisBrrrrr = 'JarvisBrrrrr';
  bytes32 public constant MoneyMarketManager = 'MoneyMarketManager';
  bytes32 public constant CrossChainBridge = 'CrossChainBridge';
  bytes32 public constant TrustedForwarder = 'TrustedForwarder';
}

library FactoryInterfaces {
  bytes32 public constant PoolFactory = 'PoolFactory';
  bytes32 public constant SelfMintingFactory = 'SelfMintingFactory';
  bytes32 public constant FixedRateFactory = 'FixedRateFactory';
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title PreciseUnitMath
 * @author Synthereum Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision.
 *
 */
library PreciseUnitMath {
  // The number One in precise units.
  uint256 internal constant PRECISE_UNIT = 10**18;

  // The number One in precise units multiplied for 10^18.
  uint256 internal constant DOUBLE_PRECISE_UNIT = 10**36;

  // Max unsigned integer value
  uint256 internal constant MAX_UINT_256 = type(uint256).max;

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function preciseUnit() internal pure returns (uint256) {
    return PRECISE_UNIT;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function maxUint256() internal pure returns (uint256) {
    return MAX_UINT_256;
  }

  /**
   * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
   * of a number with 18 decimals precision.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * b) / PRECISE_UNIT;
  }

  /**
   * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
   * of a number with 18 decimals precision.
   */
  function mulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (((a * b) - 1) / PRECISE_UNIT) + 1;
  }

  /**
   * @dev Divides value a by value b (result is rounded down).
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * PRECISE_UNIT) / b;
  }

  /**
   * @dev Divides value a by value b (result is rounded up or away from 0).
   */
  function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Cant divide by 0');

    return a > 0 ? (((a * PRECISE_UNIT) - 1) / b) + 1 : 0;
  }

  /**
   * @dev Performs the power on a specified value, reverts on overflow.
   */
  function safePower(uint256 a, uint256 pow) internal pure returns (uint256) {
    require(a > 0, 'Value must be positive');

    uint256 result = 1;
    for (uint256 i = 0; i < pow; i++) {
      uint256 previousResult = result;

      result = previousResult * a;
    }

    return result;
  }

  /**
   * @dev The minimum of `a` and `b`.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev The maximum of `a` and `b`.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title Library for strings
 */
library StringUtils {
  /**
   * @notice Convert string in 32bytes
   * @param _string string to convert
   * @return result string converted in 32bytes
   */
  function stringToBytes32(string memory _string)
    internal
    pure
    returns (bytes32 result)
  {
    bytes memory source = bytes(_string);
    if (source.length == 0) {
      return 0x0;
    } else if (source.length > 32) {
      revert('Bytes length bigger than 32');
    } else {
      assembly {
        result := mload(add(source, 32))
      }
    }
  }

  /**
   * @notice Conevert bytes32 in string
   * @param _bytes32 32bytes to convert
   * @return 32bytes converted in string
   */
  function bytes32ToString(bytes32 _bytes32)
    internal
    pure
    returns (string memory)
  {
    uint8 i = 0;
    while (i < 32 && _bytes32[i] != 0) {
      i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
      bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {AccessControlEnumerable} from '../../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 * @dev Extension of {AccessControlEnumerable} that offer support for maintainer role.
 */
contract StandardAccessControlEnumerable is AccessControlEnumerable {
  struct Roles {
    address admin;
    address maintainer;
  }

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  function _setAdmin(address _account) internal {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _account);
  }

  function _setMaintainer(address _account) internal {
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(MAINTAINER_ROLE, _account);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

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
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
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
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
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
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {SynthereumPriceFeedImplementation} from './PriceFeedImplementation.sol';
import {IERC4626} from '../../base/interfaces/IERC4626.sol';

/**
 * @title Implementation for synthereum price-feed reading from a ERC4626 vault
 */
contract SynthereumERC4626PriceFeed is SynthereumPriceFeedImplementation {
  //----------------------------------------
  // Constructor
  //----------------------------------------
  /**
   * @notice Constructs the SynthereumChainlinkPriceFeed contract
   * @param _synthereumFinder Synthereum finder contract
   * @param _roles Admin and Mainteiner roles
   */
  constructor(ISynthereumFinder _synthereumFinder, Roles memory _roles)
    SynthereumPriceFeedImplementation(_synthereumFinder, _roles)
  {}

  //----------------------------------------
  // External functions
  //----------------------------------------
  /**
   * @notice Add support for a ERC4626 vault
   * @notice Only maintainer can call this function
   * @param _priceId Name of the pair identifier
   * @param _kind Type of the pair (standard or reversed)
   * @param _source Contract from which get the price
   * @param _conversionUnit Conversion factor to be applied on price get from source (if 0 no conversion)
   * @param _extraData Extra-data needed for getting the price from source
   */
  function setPair(
    string calldata _priceId,
    Type _kind,
    address _source,
    uint256 _conversionUnit,
    bytes calldata _extraData,
    uint64 _maxSpread
  ) public override {
    super.setPair(
      _priceId,
      _kind,
      _source,
      _conversionUnit,
      _extraData,
      _maxSpread
    );
    require(_maxSpread > 0, 'Max spread can not be dynamic');
  }

  //----------------------------------------
  // Internal view functions
  //----------------------------------------
  /**
   * @notice Get price as vault.convertToAssets(baseUnit)
   * @param _source Source contract (MUST be a 4626 vault) from which get the price
   * @return price Collateral equivalent on 1 share
   * @return decimals Decimals of the conversion
   */
  function _getOracleLatestRoundPrice(
    bytes32,
    address _source,
    bytes memory
  ) internal view override returns (uint256 price, uint8 decimals) {
    IERC4626 vault = IERC4626(_source);
    decimals = vault.decimals();
    price = vault.convertToAssets(10**decimals);
  }

  /**
   * @notice No dynamic spread supported
   */
  function _getDynamicMaxSpread(
    bytes32,
    address,
    bytes memory
  ) internal view virtual override returns (uint64) {
    revert('Dynamic max spread not supported');
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

pragma solidity 0.8.9;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC20Metadata} from '../../../@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 */
interface IERC4626 is IERC20, IERC20Metadata {
  event Deposit(
    address indexed sender,
    address indexed owner,
    uint256 assets,
    uint256 shares
  );

  event Withdraw(
    address indexed sender,
    address indexed receiver,
    address indexed owner,
    uint256 assets,
    uint256 shares
  );

  /**
   * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
   *
   * - MUST be an ERC-20 token contract.
   * - MUST NOT revert.
   */
  function asset() external view returns (address assetTokenAddress);

  /**
   * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
   *
   * - SHOULD include any compounding that occurs from yield.
   * - MUST be inclusive of any fees that are charged against assets in the Vault.
   * - MUST NOT revert.
   */
  function totalAssets() external view returns (uint256 totalManagedAssets);

  /**
   * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
   * scenario where all the conditions are met.
   *
   * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
   * - MUST NOT show any variations depending on the caller.
   * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
   * - MUST NOT revert.
   *
   * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
   * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
   * from.
   */
  function convertToShares(uint256 assets)
    external
    view
    returns (uint256 shares);

  /**
   * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
   * scenario where all the conditions are met.
   *
   * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
   * - MUST NOT show any variations depending on the caller.
   * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
   * - MUST NOT revert.
   *
   * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
   * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
   * from.
   */
  function convertToAssets(uint256 shares)
    external
    view
    returns (uint256 assets);

  /**
   * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
   * through a deposit call.
   *
   * - MUST return a limited value if receiver is subject to some deposit limit.
   * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
   * - MUST NOT revert.
   */
  function maxDeposit(address receiver)
    external
    view
    returns (uint256 maxAssets);

  /**
   * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
   * current on-chain conditions.
   *
   * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
   *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
   *   in the same transaction.
   * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
   *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
   * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
   * - MUST NOT revert.
   *
   * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
   * share price or some other type of condition, meaning the depositor will lose assets by depositing.
   */
  function previewDeposit(uint256 assets)
    external
    view
    returns (uint256 shares);

  /**
   * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
   *
   * - MUST emit the Deposit event.
   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
   *   deposit execution, and are accounted for during deposit.
   * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
   *   approving enough underlying tokens to the Vault contract, etc).
   *
   * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
   */
  function deposit(uint256 assets, address receiver)
    external
    returns (uint256 shares);

  /**
   * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
   * - MUST return a limited value if receiver is subject to some mint limit.
   * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
   * - MUST NOT revert.
   */
  function maxMint(address receiver) external view returns (uint256 maxShares);

  /**
   * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
   * current on-chain conditions.
   *
   * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
   *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
   *   same transaction.
   * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
   *   would be accepted, regardless if the user has enough tokens approved, etc.
   * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
   * - MUST NOT revert.
   *
   * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
   * share price or some other type of condition, meaning the depositor will lose assets by minting.
   */
  function previewMint(uint256 shares) external view returns (uint256 assets);

  /**
   * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
   *
   * - MUST emit the Deposit event.
   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
   *   execution, and are accounted for during mint.
   * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
   *   approving enough underlying tokens to the Vault contract, etc).
   *
   * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
   */
  function mint(uint256 shares, address receiver)
    external
    returns (uint256 assets);

  /**
   * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
   * Vault, through a withdraw call.
   *
   * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
   * - MUST NOT revert.
   */
  function maxWithdraw(address owner) external view returns (uint256 maxAssets);

  /**
   * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
   * given current on-chain conditions.
   *
   * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
   *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
   *   called
   *   in the same transaction.
   * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
   *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
   * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
   * - MUST NOT revert.
   *
   * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
   * share price or some other type of condition, meaning the depositor will lose assets by depositing.
   */
  function previewWithdraw(uint256 assets)
    external
    view
    returns (uint256 shares);

  /**
   * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
   *
   * - MUST emit the Withdraw event.
   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
   *   withdraw execution, and are accounted for during withdraw.
   * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
   *   not having enough shares, etc).
   *
   * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
   * Those methods should be performed separately.
   */
  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) external returns (uint256 shares);

  /**
   * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
   * through a redeem call.
   *
   * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
   * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
   * - MUST NOT revert.
   */
  function maxRedeem(address owner) external view returns (uint256 maxShares);

  /**
   * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
   * given current on-chain conditions.
   *
   * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
   *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
   *   same transaction.
   * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
   *   redemption would be accepted, regardless if the user has enough shares, etc.
   * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
   * - MUST NOT revert.
   *
   * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
   * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
   */
  function previewRedeem(uint256 shares) external view returns (uint256 assets);

  /**
   * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
   *
   * - MUST emit the Withdraw event.
   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
   *   redeem execution, and are accounted for during redeem.
   * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
   *   not having enough shares, etc).
   *
   * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
   * Those methods should be performed separately.
   */
  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) external returns (uint256 assets);
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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title Provides interface with functions of SynthereumRegistry
 */

interface ISynthereumRegistry {
  /**
   * @notice Allow the deployer to register an element
   * @param syntheticTokenSymbol Symbol of the syntheticToken of the element to register
   * @param collateralToken Collateral ERC20 token of the element to register
   * @param version Version of the element to register
   * @param element Address of the element to register
   */
  function register(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version,
    address element
  ) external;

  /**
   * @notice Allow the deployer to unregister an element
   * @param syntheticTokenSymbol Symbol of the syntheticToken of the element to unregister
   * @param collateralToken Collateral ERC20 token of the element to unregister
   * @param version Version of the element  to unregister
   * @param element Address of the element  to unregister
   */
  function unregister(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version,
    address element
  ) external;

  /**
   * @notice Returns if a particular element exists or not
   * @param syntheticTokenSymbol Synthetic token symbol of the element
   * @param collateralToken ERC20 contract of collateral currency
   * @param version Version of the element
   * @param element Contract of the element to check
   * @return isElementDeployed Returns true if a particular element exists, otherwise false
   */
  function isDeployed(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version,
    address element
  ) external view returns (bool isElementDeployed);

  /**
   * @notice Returns all the elements with partcular symbol, collateral and version
   * @param syntheticTokenSymbol Synthetic token symbol of the element
   * @param collateralToken ERC20 contract of collateral currency
   * @param version Version of the element
   * @return List of all elements
   */
  function getElements(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version
  ) external view returns (address[] memory);

  /**
   * @notice Returns all the synthetic token symbol used
   * @return List of all synthetic token symbol
   */
  function getSyntheticTokens() external view returns (string[] memory);

  /**
   * @notice Returns all the versions used
   * @return List of all versions
   */
  function getVersions() external view returns (uint8[] memory);

  /**
   * @notice Returns all the collaterals used
   * @return List of all collaterals
   */
  function getCollaterals() external view returns (address[] memory);
}

// SPDX-License-_identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumPriceFeed} from './interfaces/IPriceFeed.sol';
import {ISynthereumFinder} from '../core/interfaces/IFinder.sol';
import {ISynthereumPriceFeedImplementation} from './implementations/interfaces/IPriceFeedImplementation.sol';
import {ISynthereumRegistry} from '../core/registries/interfaces/IRegistry.sol';
import {ISynthereumDeployment} from '../common/interfaces/IDeployment.sol';
import {ITypology} from '../common/interfaces/ITypology.sol';
import {SynthereumInterfaces} from '../core/Constants.sol';
import {PreciseUnitMath} from '../base/utils/PreciseUnitMath.sol';
import {EnumerableSet} from '../../@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {Address} from '../../@openzeppelin/contracts/utils/Address.sol';
import {StringUtils} from '../base/utils/StringUtils.sol';
import {StandardAccessControlEnumerable} from '../common/roles/StandardAccessControlEnumerable.sol';

/**
 * @title Synthereum price-feed contract for multi-protocol support
 */
contract SynthereumPriceFeed is
  ISynthereumPriceFeed,
  StandardAccessControlEnumerable
{
  using EnumerableSet for EnumerableSet.Bytes32Set;
  using Address for address;
  using StringUtils for string;
  using StringUtils for bytes32;
  using PreciseUnitMath for uint256;

  enum Type {
    UNSUPPORTED,
    STANDARD,
    COMPUTED
  }

  enum SpreadType {
    LONG,
    SHORT
  }

  struct Pair {
    Type priceType;
    bytes32 oracle;
    bytes32[] intermediatePairs;
  }

  struct PairOutput {
    Type priceType;
    string oracle;
    string[] intermediatePairs;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------
  ISynthereumFinder public immutable synthereumFinder;
  EnumerableSet.Bytes32Set private oracles;
  EnumerableSet.Bytes32Set private identifiers;
  mapping(bytes32 => address) private oracleToImplementation;
  mapping(bytes32 => Pair) private pairs;

  //----------------------------------------
  // Events
  //----------------------------------------
  event OracleAdded(bytes32 indexed priceId, address indexed oracleContract);
  event OracleUpdated(bytes32 indexed priceId, address indexed oracleContract);
  event OracleRemoved(bytes32 indexed priceId);
  event PairSet(
    bytes32 indexed priceId,
    Type indexed kind,
    bytes32 oracle,
    bytes32[] intermediatePairs
  );
  event PairRemoved(bytes32 indexed priceId);

  //----------------------------------------
  // Modifiers
  //----------------------------------------
  modifier onlyPoolsOrSelfMinting() {
    if (msg.sender != tx.origin) {
      ISynthereumRegistry registry;
      try ITypology(msg.sender).typology() returns (
        string memory typologyString
      ) {
        bytes32 typology = keccak256(abi.encodePacked(typologyString));
        if (typology == keccak256(abi.encodePacked('POOL'))) {
          registry = ISynthereumRegistry(
            synthereumFinder.getImplementationAddress(
              SynthereumInterfaces.PoolRegistry
            )
          );
        } else if (typology == keccak256(abi.encodePacked('SELF-MINTING'))) {
          registry = ISynthereumRegistry(
            synthereumFinder.getImplementationAddress(
              SynthereumInterfaces.SelfMintingRegistry
            )
          );
        } else {
          revert('Typology not supported');
        }
      } catch {
        registry = ISynthereumRegistry(
          synthereumFinder.getImplementationAddress(
            SynthereumInterfaces.PoolRegistry
          )
        );
      }
      ISynthereumDeployment callingContract = ISynthereumDeployment(msg.sender);
      require(
        registry.isDeployed(
          callingContract.syntheticTokenSymbol(),
          callingContract.collateralToken(),
          callingContract.version(),
          msg.sender
        ),
        'Calling contract not registered'
      );
    }
    _;
  }

  modifier onlyCall() {
    require(msg.sender == tx.origin, 'Only off-chain call');
    _;
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------
  /**
   * @notice Constructs the SynthereumPriceFeed contract
   * @param _synthereumFinder Synthereum finder contract
   * @param _roles Admin and Mainteiner roles
   */
  constructor(ISynthereumFinder _synthereumFinder, Roles memory _roles) {
    synthereumFinder = _synthereumFinder;
    _setAdmin(_roles.admin);
    _setMaintainer(_roles.maintainer);
  }

  //----------------------------------------
  // External functions
  //----------------------------------------
  /**
   * @notice Add support for an oracle protocol
   * @notice Only maintainer can call this function
   * @param _oracle Name of the oracle protocol
   * @param _moduleImpl Address of the sythereum implementation of the oracle
   */
  function addOracle(string calldata _oracle, address _moduleImpl)
    external
    onlyMaintainer
  {
    bytes32 oracleNameHex = _oracle.stringToBytes32();
    require(_moduleImpl.isContract(), 'Implementation is not a contract');
    require(oracles.add(oracleNameHex), 'Oracle already added');
    oracleToImplementation[oracleNameHex] = _moduleImpl;
    emit OracleAdded(oracleNameHex, _moduleImpl);
  }

  /**
   * @notice Update a supported oracle protocol
   * @notice Only maintainer can call this function
   * @param _oracle Name of the oracle protocol
   * @param _moduleImpl Address of the sythereum implementation of the oracle
   */
  function updateOracle(string calldata _oracle, address _moduleImpl)
    external
    onlyMaintainer
  {
    bytes32 oracleNameHex = _oracle.stringToBytes32();
    require(_moduleImpl.isContract(), 'Implementation is not a contract');
    require(oracles.contains(oracleNameHex), 'Oracle not added');
    require(
      oracleToImplementation[oracleNameHex] != _moduleImpl,
      'Same implementation set'
    );
    oracleToImplementation[oracleNameHex] = _moduleImpl;
    emit OracleUpdated(oracleNameHex, _moduleImpl);
  }

  /**
   * @notice Remove an oracle protocol
   * @notice Only maintainer can call this function
   * @param _oracle Name of the oracle protocol
   */
  function removeOracle(string calldata _oracle) external onlyMaintainer {
    bytes32 oracleNameHex = _oracle.stringToBytes32();
    require(oracles.remove(oracleNameHex), 'Oracle not supported');
    delete oracleToImplementation[oracleNameHex];
    emit OracleRemoved(oracleNameHex);
  }

  /**
   * @notice Add support for a pair
   * @notice Only maintainer can call this function
   * @param _priceId Name of the pair identifier
   * @param _kind Type of the pair (standard or computed)
   * @param _oracle Name of the oracle protocol (if standard)
   * @param _intermediatePairs Path with pair names (if computed)
   */
  function setPair(
    string calldata _priceId,
    Type _kind,
    string calldata _oracle,
    string[] calldata _intermediatePairs
  ) external onlyMaintainer {
    bytes32 priceIdentifierHex = _priceId.stringToBytes32();
    require(priceIdentifierHex != 0x0, 'Null identifier');
    bytes32 oracleHex = _oracle.stringToBytes32();
    uint256 intermediatePairsNumber = _intermediatePairs.length;
    bytes32[] memory intermediatePairsHex = new bytes32[](
      intermediatePairsNumber
    );
    for (uint256 j = 0; j < intermediatePairsNumber; ) {
      intermediatePairsHex[j] = _intermediatePairs[j].stringToBytes32();
      unchecked {
        j++;
      }
    }
    _checkPair(
      priceIdentifierHex,
      _kind,
      oracleHex,
      intermediatePairsHex,
      intermediatePairsNumber
    );
    identifiers.add(priceIdentifierHex);
    pairs[priceIdentifierHex] = Pair(_kind, oracleHex, intermediatePairsHex);
    emit PairSet(priceIdentifierHex, _kind, oracleHex, intermediatePairsHex);
  }

  /**
   * @notice Remove support for a pair
   * @notice Only maintainer can call this function
   * @param _priceId Name of the pair identifier
   */
  function removePair(string calldata _priceId) external onlyMaintainer {
    bytes32 priceIdentifierHex = _priceId.stringToBytes32();
    require(identifiers.remove(priceIdentifierHex), 'Identifier not supported');
    delete pairs[priceIdentifierHex];
    emit PairRemoved(priceIdentifierHex);
  }

  //----------------------------------------
  // External view functions
  //----------------------------------------
  /**
   * @notice Get list of the supported oracles
   * @return List of names of the supported oracles
   */
  function getOracles() external view returns (string[] memory) {
    uint256 oracleNumber = oracles.length();
    string[] memory oracleList = new string[](oracleNumber);
    for (uint256 j = 0; j < oracleNumber; ) {
      oracleList[j] = oracles.at(j).bytes32ToString();
      unchecked {
        j++;
      }
    }
    return oracleList;
  }

  /**
   * @notice Get list of the supported identifiers for pairs
   * @return List of names of the supported identifiers
   */
  function getIdentifiers() external view returns (string[] memory) {
    uint256 identifierNumber = identifiers.length();
    string[] memory identifierList = new string[](identifierNumber);
    for (uint256 j = 0; j < identifierNumber; ) {
      identifierList[j] = identifiers.at(j).bytes32ToString();
      unchecked {
        j++;
      }
    }
    return identifierList;
  }

  /**
   * @notice Get the address of the synthereum oracle implemantation for a given oracle, revert if not supported
   * @param _oracle HexName of the oracle protocol
   * @return Address of the implementation
   */
  function oracleImplementation(bytes32 _oracle)
    external
    view
    returns (address)
  {
    return _oracleImplementation(_oracle);
  }

  /**
   * @notice Get the address of the synthereum oracle implemantation for a given oracle, revert if not supported
   * @param _oracle Name of the oracle protocol
   * @return Address of the implementation
   */
  function oracleImplementation(string calldata _oracle)
    external
    view
    returns (address)
  {
    return _oracleImplementation(_oracle.stringToBytes32());
  }

  /**
   * @notice Get the pair data for a given pair identifier, revert if not supported
   * @param _identifier HexName of the pair identifier
   * @return Pair data
   */
  function pair(bytes32 _identifier) external view returns (PairOutput memory) {
    return _pair(_identifier);
  }

  /**
   * @notice Get the pair data for a given pair identifier, revert if not supported
   * @param _identifier Name of the pair identifier
   * @return Pair data
   */
  function pair(string calldata _identifier)
    external
    view
    returns (PairOutput memory)
  {
    return _pair(_identifier.stringToBytes32());
  }

  /**
   * @notice Return if a price identifier is supported
   * @param _priceId HexName of price identifier
   * @return True fi supported, otherwise false
   */
  function isPriceSupported(bytes32 _priceId)
    external
    view
    override
    returns (bool)
  {
    return _isPriceSupported(_priceId);
  }

  /**
   * @notice Return if a price identifier is supported
   * @param _priceId Name of price identifier
   * @return True fi supported, otherwise false
   */
  function isPriceSupported(string calldata _priceId)
    external
    view
    returns (bool)
  {
    return _isPriceSupported(_priceId.stringToBytes32());
  }

  /**
   * @notice Get last price for a given price identifier
   * @notice Only registered pools, registered self-minting derivatives and off-chain calls can call this function
   * @param _priceId HexName of price identifier
   * @return Oracle price
   */
  function getLatestPrice(bytes32 _priceId)
    external
    view
    override
    onlyPoolsOrSelfMinting
    returns (uint256)
  {
    return _getLatestPrice(_priceId);
  }

  /**
   * @notice Get last price for a given price identifier
   * @notice This function can be called just for off-chain use
   * @param _priceId Name of price identifier
   * @return Oracle price
   */
  function getLatestPrice(string calldata _priceId)
    external
    view
    onlyCall
    returns (uint256)
  {
    return _getLatestPrice(_priceId.stringToBytes32());
  }

  /**
   * @notice Get last prices for a given list of price identifiers
   * @notice Only registered pools, registered self-minting derivatives and off-chain calls can call this function
   * @param _priceIdentifiers List containing HexNames of price identifiers
   * @return Oracle prices
   */
  function getLatestPrices(bytes32[] calldata _priceIdentifiers)
    external
    view
    onlyPoolsOrSelfMinting
    returns (uint256[] memory)
  {
    uint256 identifiersNumber = _priceIdentifiers.length;
    uint256[] memory prices = new uint256[](identifiersNumber);
    for (uint256 j = 0; j < identifiersNumber; ) {
      prices[j] = _getLatestPrice(_priceIdentifiers[j]);
      unchecked {
        j++;
      }
    }
    return prices;
  }

  /**
   * @notice Get last prices for a given list of price identifiers
   * @notice This function can be called just for off-chain use
   * @param _priceIdentifiers List containing names of price identifiers
   * @return Oracle prices
   */
  function getLatestPrices(string[] calldata _priceIdentifiers)
    external
    view
    onlyCall
    returns (uint256[] memory)
  {
    uint256 identifiersNumber = _priceIdentifiers.length;
    uint256[] memory prices = new uint256[](identifiersNumber);
    for (uint256 j = 0; j < identifiersNumber; ) {
      prices[j] = _getLatestPrice(_priceIdentifiers[j].stringToBytes32());
      unchecked {
        j++;
      }
    }
    return prices;
  }

  /**
   * @notice Get the max update spread for a given price identifier when price increases
   * @param _priceId HexName of price identifier
   * @return Max spread
   */
  function longMaxSpread(bytes32 _priceId)
    external
    view
    override
    returns (uint256)
  {
    return _getMaxSpread(_priceId, SpreadType.LONG);
  }

  /**
   * @notice Get the max update spread for a given price identifier when price increases
   * @param _priceId Name of price identifier
   * @return Max spread
   */
  function longMaxSpread(string calldata _priceId)
    external
    view
    returns (uint256)
  {
    return _getMaxSpread(_priceId.stringToBytes32(), SpreadType.LONG);
  }

  /**
   * @notice Get the max update spread for a given price identifier when price decreases
   * @param _priceId HexName of price identifier
   * @return Max spread
   */
  function shortMaxSpread(bytes32 _priceId)
    external
    view
    override
    returns (uint256)
  {
    return _getMaxSpread(_priceId, SpreadType.SHORT);
  }

  /**
   * @notice Get the max update spread for a given price identifier when price decreases
   * @param _priceId Name of price identifier
   * @return Max spread
   */
  function shortMaxSpread(string calldata _priceId)
    external
    view
    returns (uint256)
  {
    return _getMaxSpread(_priceId.stringToBytes32(), SpreadType.SHORT);
  }

  //----------------------------------------
  // Internal view functions
  //----------------------------------------
  /**
   * @notice Check support conditions for a pair
   * @param _priceIdHex Name of the pair identifier
   * @param _kind Type of the pair (standard or computed)
   * @param _oracleHex HexName of the oracle protocol (if standard)
   * @param _intermediatePairsHex Path with pair HexNames (if computed)
   * @param _intermediatePairsNumber Number of elements in _intermediatePairs
   */
  function _checkPair(
    bytes32 _priceIdHex,
    Type _kind,
    bytes32 _oracleHex,
    bytes32[] memory _intermediatePairsHex,
    uint256 _intermediatePairsNumber
  ) internal view {
    if (_kind == Type.STANDARD) {
      require(
        _intermediatePairsHex.length == 0,
        'No intermediate pairs should be specified'
      );
      require(
        oracleToImplementation[_oracleHex] != address(0),
        'Oracle not supported'
      );
      require(
        ISynthereumPriceFeedImplementation(oracleToImplementation[_oracleHex])
          .isPriceSupported(_priceIdHex),
        'Price not supported by implementation'
      );
    } else if (_kind == Type.COMPUTED) {
      require(_oracleHex == 0x0, 'Oracle must not be set');
      require(_intermediatePairsNumber > 1, 'No intermediate pairs set');
      bytes32 intermediatePairHex;
      for (uint256 j = 0; j < _intermediatePairsNumber; ) {
        intermediatePairHex = _intermediatePairsHex[j];
        _checkPair(
          intermediatePairHex,
          pairs[intermediatePairHex].priceType,
          pairs[intermediatePairHex].oracle,
          pairs[intermediatePairHex].intermediatePairs,
          pairs[intermediatePairHex].intermediatePairs.length
        );
        unchecked {
          j++;
        }
      }
    } else {
      revert('Pair not supported');
    }
  }

  /**
   * @notice Get the address of the synthereum oracle implemantation for a given oracle, revert if not supported
   * @param _oracle HexName of the oracle protocol
   * @return implementation Address of the implementation
   */
  function _oracleImplementation(bytes32 _oracle)
    internal
    view
    returns (address implementation)
  {
    implementation = oracleToImplementation[_oracle];
    require(implementation != address(0), 'Oracle not supported');
  }

  /**
   * @notice Get the pair data for a given pair identifier, revert if not supported
   * @param _identifier HexName of the pair identifier
   * @return Pair data
   */
  function _pair(bytes32 _identifier)
    internal
    view
    returns (PairOutput memory)
  {
    Pair storage pairHex = pairs[_identifier];
    PairOutput memory pairData;
    pairData.priceType = pairHex.priceType;
    require(pairData.priceType != Type.UNSUPPORTED, 'Pair not supported');
    pairData.oracle = pairHex.oracle.bytes32ToString();
    uint256 intermediatePairsNumber = pairHex.intermediatePairs.length;
    pairData.intermediatePairs = new string[](intermediatePairsNumber);
    for (uint256 j = 0; j < intermediatePairsNumber; ) {
      pairData.intermediatePairs[j] = pairHex
        .intermediatePairs[j]
        .bytes32ToString();
      unchecked {
        j++;
      }
    }
    return pairData;
  }

  /**
   * @notice Return if a price identifier is supported
   * @param _priceId HexName of price identifier
   * @return isSupported True fi supported, otherwise false
   */
  function _isPriceSupported(bytes32 _priceId)
    internal
    view
    returns (bool isSupported)
  {
    if (pairs[_priceId].priceType == Type.STANDARD) {
      address implementation = oracleToImplementation[pairs[_priceId].oracle];
      if (
        implementation != address(0) &&
        ISynthereumPriceFeedImplementation(implementation).isPriceSupported(
          _priceId
        )
      ) {
        isSupported = true;
      }
    } else if (pairs[_priceId].priceType == Type.COMPUTED) {
      uint256 pairsNumber = pairs[_priceId].intermediatePairs.length;
      for (uint256 j = 0; j < pairsNumber; ) {
        if (!_isPriceSupported(pairs[_priceId].intermediatePairs[j])) {
          return false;
        }
        unchecked {
          j++;
        }
      }
      isSupported = true;
    } else {
      isSupported = false;
    }
  }

  /**
   * @notice Get last price for a given price identifier
   * @param _priceId HexName of price identifier
   * @return Oracle price
   */
  function _getLatestPrice(bytes32 _priceId) internal view returns (uint256) {
    Type priceType = pairs[_priceId].priceType;
    if (priceType == Type.STANDARD) {
      return
        _getStandardPrice(
          _priceId,
          oracleToImplementation[pairs[_priceId].oracle]
        );
    } else if (priceType == Type.COMPUTED) {
      return _getComputedPrice(pairs[_priceId].intermediatePairs);
    } else {
      revert('Pair not supported');
    }
  }

  /**
   * @notice Retrieve the price of a given standard pair
   * @param _priceId HexName of price identifier
   * @param _oracleImpl Synthereum implementation of the oracle
   * @return 18 decimals scaled price of the pair
   */
  function _getStandardPrice(bytes32 _priceId, address _oracleImpl)
    internal
    view
    returns (uint256)
  {
    return
      ISynthereumPriceFeedImplementation(_oracleImpl).getLatestPrice(_priceId);
  }

  /**
   * @notice Retrieve the price of a given computed pair
   * @param _intermediatePairs Path with pair HexNames
   * @return price 18 decimals scaled price of the pair
   */
  function _getComputedPrice(bytes32[] memory _intermediatePairs)
    internal
    view
    returns (uint256 price)
  {
    price = PreciseUnitMath.PRECISE_UNIT;
    for (uint256 j = 0; j < _intermediatePairs.length; ) {
      price = price.mul(_getLatestPrice(_intermediatePairs[j]));
      unchecked {
        j++;
      }
    }
  }

  /**
   * @notice Get the max update spread for a given price identifier
   * @param _priceId HexName of price identifier
   * @param _spreadType Long or short
   * @return Max spread
   */
  function _getMaxSpread(bytes32 _priceId, SpreadType _spreadType)
    internal
    view
    returns (uint256)
  {
    Type priceType = pairs[_priceId].priceType;
    if (priceType == Type.STANDARD) {
      return
        _getStandardMaxSpread(
          _priceId,
          oracleToImplementation[pairs[_priceId].oracle]
        );
    } else if (priceType == Type.COMPUTED) {
      return
        _spreadType == SpreadType.SHORT
          ? _getComputedShortMaxSpread(pairs[_priceId].intermediatePairs)
          : _getComputedLongMaxSpread(pairs[_priceId].intermediatePairs);
    } else {
      revert('Pair not supported');
    }
  }

  /**
   * @notice Get the max update spread for a given standard price identifier
   * @param _priceId HexName of price identifier
   * @param _oracleImpl Synthereum implementation of the oracle
   * @return Max spread
   */
  function _getStandardMaxSpread(bytes32 _priceId, address _oracleImpl)
    internal
    view
    returns (uint256)
  {
    return
      uint256(
        ISynthereumPriceFeedImplementation(_oracleImpl).getMaxSpread(_priceId)
      );
  }

  /**
   * @notice Get the max update spread for a given computed price identifier when price decreases
   * @param _intermediatePairs Path with pair HexNames
   * @return price 18 decimals scaled price of the pair
   */
  function _getComputedShortMaxSpread(bytes32[] memory _intermediatePairs)
    internal
    view
    returns (uint256)
  {
    uint256 reducedValue = PreciseUnitMath.PRECISE_UNIT;
    for (uint256 j = 0; j < _intermediatePairs.length; ) {
      reducedValue = reducedValue.mul(
        PreciseUnitMath.PRECISE_UNIT -
          uint256(_getMaxSpread(_intermediatePairs[j], SpreadType.SHORT))
      );
      unchecked {
        j++;
      }
    }
    return PreciseUnitMath.PRECISE_UNIT - reducedValue;
  }

  /**
   * @notice Get the max update spread for a given computed price identifier when price increases
   * @param _intermediatePairs Path with pair HexNames
   * @return price 18 decimals scaled price of the pair
   */
  function _getComputedLongMaxSpread(bytes32[] memory _intermediatePairs)
    internal
    view
    returns (uint256)
  {
    uint256 reducedValue = PreciseUnitMath.PRECISE_UNIT;
    for (uint256 j = 0; j < _intermediatePairs.length; ) {
      reducedValue = reducedValue.mul(
        PreciseUnitMath.PRECISE_UNIT +
          uint256(_getMaxSpread(_intermediatePairs[j], SpreadType.LONG))
      );
      unchecked {
        j++;
      }
    }
    return reducedValue - PreciseUnitMath.PRECISE_UNIT;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ISynthereumPriceFeed {
  /**
   * @notice Return if a price identifier is supported
   * @param _priceId Name of price identifier
   * @return True fi supporteed, otherwise false
   */
  function isPriceSupported(bytes32 _priceId) external view returns (bool);

  /**
   * @notice Get last price for a given price identifier
   * @notice Only registered pools and registered self-minting derivatives can call this function
   * @param _priceId HexName of price identifier
   * @return Oracle price
   */
  function getLatestPrice(bytes32 _priceId) external view returns (uint256);

  /**
   * @notice Get the max update spread for a given price identifier when price increases
   * @param _priceId HexName of price identifier
   * @return Max spread
   */
  function longMaxSpread(bytes32 _priceId) external view returns (uint256);

  /**
   * @notice Get the max update spread for a given price identifier when price decreases
   * @param _priceId HexName of price identifier
   * @return Max spread
   */
  function shortMaxSpread(bytes32 _priceId) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';

/**
 * @title Interface that a pool MUST have in order to be included in the deployer
 */
interface ISynthereumDeployment {
  /**
   * @notice Get Synthereum finder of the pool/self-minting derivative
   * @return finder Returns finder contract
   */
  function synthereumFinder() external view returns (ISynthereumFinder finder);

  /**
   * @notice Get Synthereum version
   * @return contractVersion Returns the version of this pool/self-minting derivative
   */
  function version() external view returns (uint8 contractVersion);

  /**
   * @notice Get the collateral token of this pool/self-minting derivative
   * @return collateralCurrency The ERC20 collateral token
   */
  function collateralToken() external view returns (IERC20 collateralCurrency);

  /**
   * @notice Get the synthetic token associated to this pool/self-minting derivative
   * @return syntheticCurrency The ERC20 synthetic token
   */
  function syntheticToken() external view returns (IERC20 syntheticCurrency);

  /**
   * @notice Get the synthetic token symbol associated to this pool/self-minting derivative
   * @return symbol The ERC20 synthetic token symbol
   */
  function syntheticTokenSymbol() external view returns (string memory symbol);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ITypology {
  /**
   * @notice Return typology of the contract
   */
  function typology() external view returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from './interfaces/IFinder.sol';
import {AccessControlEnumerable} from '../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 * @title Provides addresses of contracts implementing certain interfaces.
 */
contract SynthereumFinder is ISynthereumFinder, AccessControlEnumerable {
  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------

  mapping(bytes32 => address) public interfacesImplemented;

  //----------------------------------------
  // Events
  //----------------------------------------

  event InterfaceImplementationChanged(
    bytes32 indexed interfaceName,
    address indexed newImplementationAddress
  );

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  //----------------------------------------
  // Constructors
  //----------------------------------------

  constructor(Roles memory roles) {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, roles.admin);
    _setupRole(MAINTAINER_ROLE, roles.maintainer);
  }

  //----------------------------------------
  // External view
  //----------------------------------------

  /**
   * @notice Updates the address of the contract that implements `interfaceName`.
   * @param interfaceName bytes32 of the interface name that is either changed or registered.
   * @param implementationAddress address of the implementation contract.
   */
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external override onlyMaintainer {
    interfacesImplemented[interfaceName] = implementationAddress;

    emit InterfaceImplementationChanged(interfaceName, implementationAddress);
  }

  /**
   * @notice Gets the address of the contract that implements the given `interfaceName`.
   * @param interfaceName queried interface.
   * @return implementationAddress Address of the defined interface.
   */
  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    override
    returns (address)
  {
    address implementationAddress = interfacesImplemented[interfaceName];
    require(implementationAddress != address(0x0), 'Implementation not found');
    return implementationAddress;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {IDiaPriceFeed} from './interfaces/IDiaPriceFeed.sol';
import {StringUtils} from '../../base/utils/StringUtils.sol';
import {SynthereumPriceFeedImplementation} from './PriceFeedImplementation.sol';

/**
 * @title DIA implementation for synthereum price-feed
 */
contract SynthereumDiaPriceFeed is SynthereumPriceFeedImplementation {
  using StringUtils for bytes32;

  //----------------------------------------
  // Constructor
  //----------------------------------------
  /**
   * @notice Constructs the SynthereumDiaPriceFeed contract
   * @param _synthereumFinder Synthereum finder contract
   * @param _roles Admin and Mainteiner roles
   */
  constructor(ISynthereumFinder _synthereumFinder, Roles memory _roles)
    SynthereumPriceFeedImplementation(_synthereumFinder, _roles)
  {}

  //----------------------------------------
  // External functions
  //----------------------------------------
  /**
   * @notice Add support for a DIA pair
   * @notice Only maintainer can call this function
   * @param _priceId Name of the pair identifier
   * @param _kind Type of the pair (standard or reversed)
   * @param _source Contract from which get the price
   * @param _conversionUnit Conversion factor to be applied on price get from source (if 0 no conversion)
   * @param _extraData Extra-data needed for getting the price from source
   */
  function setPair(
    string calldata _priceId,
    Type _kind,
    address _source,
    uint256 _conversionUnit,
    bytes calldata _extraData,
    uint64 _maxSpread
  ) public override {
    super.setPair(
      _priceId,
      _kind,
      _source,
      _conversionUnit,
      _extraData,
      _maxSpread
    );
    require(_maxSpread > 0, 'Max spread can not be dynamic');
  }

  //----------------------------------------
  // Internal view functions
  //----------------------------------------
  /**
  /**
   * @notice Get last DIA oracle price for an input source
   * @param _priceIdentifier Price feed identifier
   * @param _source Source contract from which get the price
   * @return price Price get from the source oracle
   * @return decimals Decimals of the price
   */
  function _getOracleLatestRoundPrice(
    bytes32 _priceIdentifier,
    address _source,
    bytes memory
  ) internal view override returns (uint256 price, uint8 decimals) {
    IDiaPriceFeed priceFeed = IDiaPriceFeed(_source);
    (price, ) = priceFeed.getValue(_priceIdentifier.bytes32ToString());
    decimals = 8;
  }

  /**
   * @notice No dynamic spread supported
   */
  function _getDynamicMaxSpread(
    bytes32,
    address,
    bytes memory
  ) internal view virtual override returns (uint64) {
    revert('Dynamic max spread not supported');
  }
}

pragma solidity >=0.8.0;

interface IDiaPriceFeed {
  function getValue(string memory key) external view returns (uint128, uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {IDapiServer} from './interfaces/IDapiServer.sol';
import {SynthereumPriceFeedImplementation} from './PriceFeedImplementation.sol';

/**
 * @title API3 implementation for synthereum price-feed
 */
contract SynthereumApi3PriceFeed is SynthereumPriceFeedImplementation {
  //----------------------------------------
  // Constructor
  //----------------------------------------
  /**
   * @notice Constructs the SynthereumApi3PriceFeed contract
   * @param _synthereumFinder Synthereum finder contract
   * @param _roles Admin and Mainteiner roles
   */
  constructor(ISynthereumFinder _synthereumFinder, Roles memory _roles)
    SynthereumPriceFeedImplementation(_synthereumFinder, _roles)
  {}

  //----------------------------------------
  // External functions
  //----------------------------------------
  /**
   * @notice Add support for a API3 pair
   * @notice Only maintainer can call this function
   * @param _priceId Name of the pair identifier
   * @param _kind Type of the pair (standard or reversed)
   * @param _source Contract from which get the price
   * @param _conversionUnit Conversion factor to be applied on price get from source (if 0 no conversion)
   * @param _extraData Extra-data needed for getting the price from source
   */
  function setPair(
    string calldata _priceId,
    Type _kind,
    address _source,
    uint256 _conversionUnit,
    bytes calldata _extraData,
    uint64 _maxSpread
  ) public override {
    super.setPair(
      _priceId,
      _kind,
      _source,
      _conversionUnit,
      _extraData,
      _maxSpread
    );
    require(_maxSpread > 0, 'Max spread can not be dynamic');
  }

  //----------------------------------------
  // Internal view functions
  //----------------------------------------
  /**
  /**
   * @notice Get last API3 oracle price for an input source
   * @param _priceIdentifier Price feed identifier
   * @param _source Source contract from which get the price
   * @return price Price get from the source oracle
   * @return decimals Decimals of the price
   */
  function _getOracleLatestRoundPrice(
    bytes32 _priceIdentifier,
    address _source,
    bytes memory
  ) internal view override returns (uint256 price, uint8 decimals) {
    IDapiServer priceFeed = IDapiServer(_source);
    int224 unconvertedPrice = priceFeed.readDataFeedValueWithId(
      _priceIdentifier
    );
    require(unconvertedPrice >= 0, 'Negative value');
    price = uint256(uint224(unconvertedPrice));
    decimals = 18;
  }

  /**
   * @notice No dynamic spread supported
   */
  function _getDynamicMaxSpread(
    bytes32,
    address,
    bytes memory
  ) internal view virtual override returns (uint64) {
    revert('Dynamic max spread not supported');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// mimics API3 server interface
interface IDapiServer {
  function readDataFeedValueWithId(bytes32 priceFeedId)
    external
    view
    returns (int224 value);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {SafeMath} from '../../@openzeppelin/contracts/utils/math/SafeMath.sol';
import {SignedSafeMath} from '../../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';
import {Ownable} from '../../@openzeppelin/contracts/access/Ownable.sol';
import {MockAggregator} from './MockAggregator.sol';

contract MockRandomAggregator is Ownable, MockAggregator {
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  uint256 public maxSpreadForSecond;

  constructor(int256 _initialAnswer, uint256 _maxSpreadForSecond)
    MockAggregator(18, _initialAnswer)
  {
    maxSpreadForSecond = _maxSpreadForSecond;
  }

  function latestRoundData()
    public
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    uint256 randomNumber = getRandomNumber();
    answer = calculateNewPrice(randomNumber);
    (roundId, , startedAt, updatedAt, answeredInRound) = super
      .latestRoundData();
  }

  function updateAnswer(int256 _answer) public override onlyOwner {
    super.updateAnswer(_answer);
  }

  function updateRoundData(
    uint80 _roundId,
    int256 _answer,
    uint256 _timestamp,
    uint256 _startedAt
  ) public override onlyOwner {
    super.updateRoundData(_roundId, _answer, _timestamp, _startedAt);
  }

  function calculateNewPrice(uint256 randomNumber)
    internal
    view
    returns (int256 newPrice)
  {
    int256 lastPrice = latestAnswer;
    int256 difference = lastPrice
      .mul(int256(block.timestamp.sub(latestTimestamp)))
      .mul(int256(maxSpreadForSecond))
      .div(10**18)
      .mul(int256(randomNumber))
      .div(10**18);
    newPrice = (randomNumber.mod(2) == 0)
      ? latestAnswer.sub(difference)
      : latestAnswer.add(difference);
  }

  function getRandomNumber() internal view returns (uint256) {
    return uint256(blockhash(block.number - 1)).mod(10**18);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

contract MockAggregator {
  uint256 public constant version = 0;

  uint8 public decimals;
  int256 public latestAnswer;
  uint256 public latestTimestamp;
  uint256 public latestRound;

  mapping(uint256 => int256) public getAnswer;
  mapping(uint256 => uint256) public getTimestamp;
  mapping(uint256 => uint256) private getStartedAt;

  constructor(uint8 _decimals, int256 _initialAnswer) {
    decimals = _decimals;
    updateAnswer(_initialAnswer);
  }

  function updateAnswer(int256 _answer) public virtual {
    latestAnswer = _answer;
    latestTimestamp = block.timestamp;
    latestRound++;
    getAnswer[latestRound] = _answer;
    getTimestamp[latestRound] = block.timestamp;
    getStartedAt[latestRound] = block.timestamp;
  }

  function updateRoundData(
    uint80 _roundId,
    int256 _answer,
    uint256 _timestamp,
    uint256 _startedAt
  ) public virtual {
    latestRound = _roundId;
    latestAnswer = _answer;
    latestTimestamp = _timestamp;
    getAnswer[latestRound] = _answer;
    getTimestamp[latestRound] = _timestamp;
    getStartedAt[latestRound] = _startedAt;
  }

  function getRoundData(uint80 _roundId)
    public
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (
      _roundId,
      getAnswer[_roundId],
      getStartedAt[_roundId],
      getTimestamp[_roundId],
      _roundId
    );
  }

  function latestRoundData()
    public
    view
    virtual
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return (
      uint80(latestRound),
      getAnswer[latestRound],
      getStartedAt[latestRound],
      getTimestamp[latestRound],
      uint80(latestRound)
    );
  }

  function description() external pure returns (string memory) {
    return 'MockAggregator.sol';
  }
}