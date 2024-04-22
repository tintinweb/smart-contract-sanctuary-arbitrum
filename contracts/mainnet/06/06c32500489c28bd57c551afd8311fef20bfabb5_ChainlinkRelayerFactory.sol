// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';
import {ChainlinkRelayerChild} from '@contracts/factories/ChainlinkRelayerChild.sol';
import {ChainlinkRelayerChildWithL2Validity} from '@contracts/factories/ChainlinkRelayerChildWithL2Validity.sol';
import {Authorizable} from '@contracts/utils/Authorizable.sol';

contract ChainlinkRelayerFactory is Authorizable {
  uint256 public relayerId;
  uint256 public relayerWithL2ValidityId;

  // --- Events ---
  event NewChainlinkRelayer(address indexed _chainlinkRelayer, address _aggregator, uint256 _staleThreshold);
  event NewChainlinkRelayerWithL2Validity(
    address indexed _chainlinkRelayer,
    address _priceAggregator,
    address _sequencerAggregator,
    uint256 _staleThreshold,
    uint256 _gracePeriod
  );

  // --- Data ---
  mapping(uint256 => address) public relayerById;
  mapping(uint256 => address) public relayerWithL2ValidityById;

  // --- Init ---
  constructor() Authorizable(msg.sender) {}

  // --- Methods ---

  function deployChainlinkRelayer(
    address _aggregator,
    uint256 _staleThreshold
  ) external isAuthorized returns (IBaseOracle _chainlinkRelayer) {
    _chainlinkRelayer = IBaseOracle(address(new ChainlinkRelayerChild(_aggregator, _staleThreshold)));
    relayerId++;
    relayerById[relayerId] = address(_chainlinkRelayer);
    emit NewChainlinkRelayer(address(_chainlinkRelayer), _aggregator, _staleThreshold);
  }

  function deployChainlinkRelayerWithL2Validity(
    address _priceAggregator,
    address _sequencerAggregator,
    uint256 _staleThreshold,
    uint256 _gracePeriod
  ) external isAuthorized returns (IBaseOracle _chainlinkRelayer) {
    _chainlinkRelayer = IBaseOracle(
      address(
        new ChainlinkRelayerChildWithL2Validity(_priceAggregator, _sequencerAggregator, _staleThreshold, _gracePeriod)
      )
    );
    relayerWithL2ValidityId++;
    relayerWithL2ValidityById[relayerWithL2ValidityId] = address(_chainlinkRelayer);
    emit NewChainlinkRelayerWithL2Validity(
      address(_chainlinkRelayer), _priceAggregator, _sequencerAggregator, _staleThreshold, _gracePeriod
    );
  }
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

import {ChainlinkRelayer} from '@contracts/oracles/ChainlinkRelayer.sol';
import {FactoryChild} from '@contracts/factories/FactoryChild.sol';

contract ChainlinkRelayerChild is ChainlinkRelayer, FactoryChild {
  // --- Init ---

  /**
   * @param  _aggregator The address of the aggregator to relay
   * @param  _staleThreshold The threshold in seconds to consider the aggregator stale
   */
  constructor(address _aggregator, uint256 _staleThreshold) ChainlinkRelayer(_aggregator, _staleThreshold) {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import {ChainlinkRelayerWithL2Validity} from '@contracts/oracles/ChainlinkRelayerWithL2Validity.sol';
import {FactoryChild} from '@contracts/factories/FactoryChild.sol';

contract ChainlinkRelayerChildWithL2Validity is ChainlinkRelayerWithL2Validity, FactoryChild {
  // --- Init ---

  /**
   * @param  _priceAggregator The address of the price aggregator to relay
   * @param  _sequencerAggregator The address of the sequencer aggregator to relay
   * @param  _staleThreshold The threshold in seconds to consider the aggregator stale
   * @param  _gracePeriod The period in seconds to consider the sequencer valid after outage
   */
  constructor(
    address _priceAggregator,
    address _sequencerAggregator,
    uint256 _staleThreshold,
    uint256 _gracePeriod
  ) ChainlinkRelayerWithL2Validity(_priceAggregator, _sequencerAggregator, _staleThreshold, _gracePeriod) {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import {EnumerableSet} from '@openzeppelin/contracts/utils/EnumerableSet.sol';

/**
 * @title  Authorizable
 * @notice Implements authorization control for contracts
 * @dev    Authorization control is boolean and handled by `onlyAuthorized` modifier
 */
abstract contract Authorizable {
  // --- Events ---

  /**
   * @notice Emitted when an account is authorized
   * @param _account Account that is authorized
   */
  event AddAuthorization(address _account);

  /**
   * @notice Emitted when an account is unauthorized
   * @param _account Account that is unauthorized
   */
  event RemoveAuthorization(address _account);

  using EnumerableSet for EnumerableSet.AddressSet;

  // --- Data ---

  EnumerableSet.AddressSet internal _authorizedAccounts;

  // --- Init ---

  /**
   * @param  _account Initial account to add authorization to
   */
  constructor(address _account) {
    _addAuthorization(_account);
  }

  // --- Views ---

  /**
   * @notice Checks whether an account is authorized
   * @return _authorized Whether the account is authorized or not
   */
  function authorizedAccounts(address _account) external view returns (bool _authorized) {
    return _isAuthorized(_account);
  }

  /**
   * @notice Getter for the authorized accounts
   * @return _accounts Array of authorized accounts
   * ONLY use as view function as can be very expensive
   */
  function authorizedAccounts() external view returns (address[] memory _accounts) {
    bytes32[] memory store = _authorizedAccounts._inner._values;
    address[] memory result;

    assembly {
      result := store
    }
    return result;
  }

  // --- Methods ---

  /**
   * @notice Add auth to an account
   * @param  _account Account to add auth to
   */
  function addAuthorization(address _account) external virtual isAuthorized {
    _addAuthorization(_account);
  }

  /**
   * @notice Remove auth from an account
   * @param  _account Account to remove auth from
   */
  function removeAuthorization(address _account) external virtual isAuthorized {
    _removeAuthorization(_account);
  }

  // --- Internal methods ---
  function _addAuthorization(address _account) internal {
    require(!_isAuthorized(_account), 'AlreadyAuthorized');
    _authorizedAccounts.add(_account);
    emit AddAuthorization(_account);
  }

  function _removeAuthorization(address _account) internal {
    require(_isAuthorized(_account), 'NotAuthorized');
    _authorizedAccounts.remove(_account);
    emit RemoveAuthorization(_account);
  }

  function _isAuthorized(address _account) internal view virtual returns (bool _authorized) {
    return _authorizedAccounts.contains(_account);
  }

  // --- Modifiers ---

  /**
   * @notice Checks whether msg.sender can call an authed function
   * @dev    Will revert with `Unauthorized` if the sender is not authorized
   */
  modifier isAuthorized() {
    require(_isAuthorized(msg.sender), 'Unauthorized');
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import {IChainlinkOracle} from '@interfaces/oracles/IChainlinkOracle.sol';

/**
 * @title  ChainlinkRelayer
 * @notice This contracts transforms a Chainlink price feed into a standard IBaseOracle feed
 *         It also verifies that the reading is new enough, compared to a STALE_THRESHOLD
 */
contract ChainlinkRelayer {
  uint256 public immutable STALE_THRESHOLD;
  int256 public immutable MULTIPLIER;

  // --- Registry ---
  IChainlinkOracle public chainlinkFeed;

  // --- Data ---
  string public symbol;

  /**
   * @param  _aggregator The address of the Chainlink aggregator
   * @param  _staleThreshold The threshold after which the price is considered stale
   */
  constructor(address _aggregator, uint256 _staleThreshold) {
    require(_aggregator != address(0)); // error msg will not show from constructor revert
    require(_staleThreshold != 0);

    STALE_THRESHOLD = _staleThreshold;
    chainlinkFeed = IChainlinkOracle(_aggregator);

    MULTIPLIER = int256(18) - int256(uint256(chainlinkFeed.decimals()));
    symbol = chainlinkFeed.description();
  }

  function getResultWithValidity() public view virtual returns (uint256 _result, bool _validity) {
    // Fetch values from Chainlink
    (, int256 _aggregatorResult,, uint256 _aggregatorTimestamp,) = chainlinkFeed.latestRoundData();

    // Parse the quote into 18 decimals format
    _result = _parseResult(_aggregatorResult);

    // Check if the price is valid
    _validity = _aggregatorResult > 0 && _isValidFeed(_aggregatorTimestamp);
  }

  function read() public view virtual returns (uint256 _result) {
    // Fetch values from Chainlink
    (, int256 _aggregatorResult,, uint256 _aggregatorTimestamp,) = chainlinkFeed.latestRoundData();

    // Revert if price is invalid
    require(_aggregatorResult != 0 && _isValidFeed(_aggregatorTimestamp), 'InvalidPriceFeed');

    // Parse the quote into 18 decimals format
    _result = _parseResult(_aggregatorResult);
  }

  /// @notice Parses the result from the aggregator into 18 decimals format
  function _parseResult(int256 _chainlinkResult) internal view returns (uint256 _result) {
    require(_chainlinkResult >= 0, 'Negative price value not allowed');

    if (MULTIPLIER == 0) {
      return uint256(_chainlinkResult);
    } else if (MULTIPLIER > 0) {
      return uint256(_chainlinkResult) * (10 ** uint256(MULTIPLIER));
    } else {
      return uint256(_chainlinkResult) / (10 ** _abs(MULTIPLIER));
    }
  }

  /// @notice Checks if the feed is valid, considering the STALE_THRESHOLD and the feed timestamp
  function _isValidFeed(uint256 _feedTimestamp) internal view returns (bool _valid) {
    uint256 _now = block.timestamp;
    if (_feedTimestamp > _now) return false;
    return _now - _feedTimestamp <= STALE_THRESHOLD;
  }

  /// @notice Return the absolute value of a signed integer as an unsigned integer
  function _abs(int256 x) internal pure returns (uint256) {
    x >= 0 ? x : -x;
    return uint256(x);
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

import {ChainlinkRelayer} from '@contracts/oracles/ChainlinkRelayer.sol';
import {DataConsumerSequencerCheck} from '@contracts/oracles/DataConsumerSequencerCheck.sol';

contract ChainlinkRelayerWithL2Validity is ChainlinkRelayer, DataConsumerSequencerCheck {
  constructor(
    address _priceAggregator,
    address _sequencerAggregator,
    uint256 _staleThreshold,
    uint256 _gracePeriod
  ) ChainlinkRelayer(_priceAggregator, _staleThreshold) DataConsumerSequencerCheck(_sequencerAggregator, _gracePeriod) {}

  function getResultWithValidity() public view override returns (uint256 _result, bool _validity) {
    (_result, _validity) = super.getResultWithValidity();
    if (_validity) {
      _validity = getSequencerFeedValidation();
    }
  }

  function read() public view override returns (uint256 _result) {
    require(getSequencerFeedValidation(), 'SequencerDown');
    _result = super.read();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IChainlinkOracle {
  function decimals() external view returns (uint8 _decimals);
  function description() external view returns (string memory _description);
  function getAnswer(uint256 _roundId) external view returns (int256 _answer);
  function getRoundData(uint256 __roundId)
    external
    view
    returns (uint256 _roundId, int256 _answer, uint256 _startedAt, uint256 _updatedAt, uint256 _answeredInRound);
  function getTimestamp(uint256 _roundId) external view returns (uint256 _timestamp);
  function latestAnswer() external view returns (int256 _latestAnswer);
  function latestRound() external view returns (uint256 _latestRound);
  function latestRoundData()
    external
    view
    returns (uint256 _roundId, int256 _answer, uint256 _startedAt, uint256 _updatedAt, uint256 _answeredInRound);
  function latestTimestamp() external view returns (uint256 _latestTimestamp);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import {IChainlinkOracle} from '@interfaces/oracles/IChainlinkOracle.sol';

contract DataConsumerSequencerCheck {
  uint256 public immutable GRACE_PERIOD;

  // --- Registry ---
  IChainlinkOracle public immutable SEQUENCER_UPTIME_FEED;

  /**
   * @param  _aggregator The address of the Chainlink aggregator
   * @param  _gracePeriod The threshold before accepting answers after an outage
   */
  constructor(address _aggregator, uint256 _gracePeriod) {
    require(_aggregator != address(0)); // error msg will not show from constructor revert
    require(_gracePeriod != 0);

    SEQUENCER_UPTIME_FEED = IChainlinkOracle(_aggregator);
    GRACE_PERIOD = _gracePeriod;
  }

  /// @notice return false for invalid sequencer, true for valid sequencer
  function getSequencerFeedValidation() public view returns (bool) {
    (uint256 _roundId, int256 _answer, uint256 _startedAt, uint256 _updatedAt, uint256 _answeredInRound) =
      SEQUENCER_UPTIME_FEED.latestRoundData();
    if (_answeredInRound < _roundId) return false;
    // If the answer is 1, the sequencer is down
    if (_answer != 0) return false;
    if (_updatedAt == 0) return false;

    uint256 timeSinceOnline = block.timestamp - _startedAt;
    if (timeSinceOnline < GRACE_PERIOD) return false;
    else return true;
  }
}