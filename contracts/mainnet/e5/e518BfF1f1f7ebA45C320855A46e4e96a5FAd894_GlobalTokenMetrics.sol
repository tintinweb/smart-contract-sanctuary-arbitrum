// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IGloballyStakedTokenCalculator.sol";
import "../Manager/ManagerModifier.sol";
import "../ERC20/ITokenMinter.sol";
import "../ERC20/ITokenSpender.sol";
import "../Utils/EpochConfigurable.sol";
import "../Utils/Totals.sol";
import "./IGlobalTokenMetrics.sol";

contract GlobalTokenMetrics is EpochConfigurable, IGlobalTokenMetrics {
  IGloballyStakedTokenCalculator public GLOBALLY_STAKED_TOKEN_CALCULATOR;
  ITokenMinter public TOKEN_MINTER;
  ITokenSpender public TOKEN_SPENDER;

  constructor(
    address _manager,
    address _stakingCalculator,
    address _tokenMinter,
    address _tokenSpender
  ) EpochConfigurable(_manager, 1 days, 0 hours) {
    GLOBALLY_STAKED_TOKEN_CALCULATOR = IGloballyStakedTokenCalculator(
      _stakingCalculator
    );
    TOKEN_MINTER = ITokenMinter(_tokenMinter);
    TOKEN_SPENDER = ITokenSpender(_tokenSpender);
  }

  function historyMetrics(
    uint _startEpoch,
    uint _endEpoch
  ) public view returns (HistoryData memory result) {
    result.mints = TOKEN_MINTER.getEpochValueBatch(_startEpoch, _endEpoch);
    result.burns = TOKEN_SPENDER.getEpochValueBatch(_startEpoch, _endEpoch);
    result.supply = GLOBALLY_STAKED_TOKEN_CALCULATOR.circulatingSupplyBatch(
      _startEpoch,
      _endEpoch
    );
    (
      result.stakingAddresses,
      result.stakedPerAddress
    ) = GLOBALLY_STAKED_TOKEN_CALCULATOR.stakedAmountsBatch(
      _startEpoch,
      _endEpoch
    );

    result.epochs = new uint[](_endEpoch - _startEpoch + 1);
    result.totalStaked = new uint[](_endEpoch - _startEpoch + 1);
    for (uint i = 0; i < result.epochs.length; i++) {
      result.epochs[i] = _startEpoch + i;
      for (uint j = 0; j < result.stakingAddresses.length; j++) {
        result.totalStaked[i] += result.stakedPerAddress[j][i];
      }
    }
  }

  function currentStakedRatio(
    uint _epochSpan
  )
    public
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    )
  {
    return
      GLOBALLY_STAKED_TOKEN_CALCULATOR.currentGloballyStakedAverage(_epochSpan);
  }

  function currentStakedRatioView(
    uint _epochSpan
  )
    public
    view
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    )
  {
    return
      GLOBALLY_STAKED_TOKEN_CALCULATOR.globallyStakedAverageView(
        currentEpoch(),
        _epochSpan,
        true
      );
  }

  function stakedRatioAtEpoch(
    uint _epoch,
    uint _epochSpan
  )
    public
    view
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    )
  {
    return
      GLOBALLY_STAKED_TOKEN_CALCULATOR.globallyStakedAverageView(
        _epoch,
        _epochSpan,
        false
      );
  }

  function stakedRatioAtEpochBatch(
    uint _startEpoch,
    uint _endEpoch,
    uint _epochSpan
  )
    public
    view
    returns (
      uint[] memory rawTotalStaked,
      int[] memory totalStaked,
      uint[] memory circulatingSupply,
      int[] memory effectiveSupply,
      uint[] memory percentage
    )
  {
    return
      GLOBALLY_STAKED_TOKEN_CALCULATOR.globallyStakedAverageBatch(
        _startEpoch,
        _endEpoch,
        _epochSpan
      );
  }

  function currentBurnRatio(
    uint _epochSpan
  ) public view returns (uint burnRatio, uint totalBurns, uint totalMints) {
    return burnRatioAtEpoch(currentEpoch(), _epochSpan);
  }

  function burnRatioAtEpoch(
    uint _epoch,
    uint _epochSpan
  ) public view returns (uint burnRatio, uint totalBurns, uint totalMints) {
    uint epochStart = _epoch - _epochSpan;
    uint[] memory mints = tokenMints(epochStart, _epoch);
    uint[] memory burns = tokenBurns(epochStart, _epoch);
    return _burnRatioInternal(mints, burns);
  }

  function burnRatiosAtEpochBatch(
    uint _epochStart,
    uint _epochEnd,
    uint _epochSpan
  )
    public
    view
    returns (
      uint[] memory ratios,
      uint[] memory totalBurns,
      uint[] memory totalMints
    )
  {
    require(_epochStart < _epochEnd, "GlobalTokenMetrics: Invalid epoch range");
    uint historyStart = _epochStart - _epochSpan;
    uint[] memory mints = tokenMints(historyStart, _epochEnd);
    uint[] memory burns = tokenBurns(historyStart, _epochEnd);

    uint numberOfEpochsToCalculate = _epochEnd - _epochStart + 1;
    ratios = new uint[](numberOfEpochsToCalculate);
    totalBurns = new uint[](numberOfEpochsToCalculate);
    totalMints = new uint[](numberOfEpochsToCalculate);
    for (uint i = 0; i < numberOfEpochsToCalculate; i++) {
      (ratios[i], totalBurns[i], totalMints[i]) = _burnSubRatioInternal(
        mints,
        burns,
        i,
        i + _epochSpan
      );
    }
  }

  function _burnRatioInternal(
    uint[] memory _mints,
    uint[] memory _burns
  ) private pure returns (uint burnRatio, uint totalBurns, uint totalMints) {
    return _burnSubRatioInternal(_mints, _burns, 0, _mints.length);
  }

  function _burnSubRatioInternal(
    uint[] memory _mints,
    uint[] memory _burns,
    uint indexStart,
    uint indexEnd
  ) private pure returns (uint burnRation, uint totalBurns, uint totalMints) {
    totalMints = 1 + Totals.calculateSubTotal(_mints, indexStart, indexEnd);
    totalBurns = Totals.calculateSubTotal(_burns, indexStart, indexEnd);
    return ((ONE_HUNDRED * totalBurns) / totalMints, totalBurns, totalMints);
  }

  function currentBucketBurnRatio(
    uint _bucket,
    uint _epochSpan
  ) public view returns (uint burnRatio, uint totalBurns, uint totalMints) {
    return bucketBurnRatioAtEpoch(_bucket, currentEpoch(), _epochSpan);
  }

  function bucketBurnRatioAtEpoch(
    uint _bucket,
    uint _epoch,
    uint _epochSpan
  ) public view returns (uint burnRatio, uint totalBurns, uint totalMints) {
    uint epochStart = _epoch - _epochSpan;
    uint[] memory mints = tokenBucketMints(_bucket, epochStart, _epoch);
    uint[] memory burns = tokenBucketBurns(_bucket, epochStart, _epoch);
    return _burnRatioInternal(mints, burns);
  }

  function bucketBurnRatiosAtEpochBatch(
    uint _bucket,
    uint _epochStart,
    uint _epochEnd,
    uint _epochSpan
  )
    public
    view
    returns (
      uint[] memory ratios,
      uint[] memory totalBurns,
      uint[] memory totalMints
    )
  {
    require(_epochStart < _epochEnd, "GlobalTokenMetrics: Invalid epoch range");
    uint historyStart = _epochStart - _epochSpan;
    uint[] memory mints = tokenBucketMints(_bucket, historyStart, _epochEnd);
    uint[] memory burns = tokenBucketBurns(_bucket, historyStart, _epochEnd);

    uint numberOfEpochsToCalculate = _epochEnd - _epochStart + 1;
    ratios = new uint[](numberOfEpochsToCalculate);
    totalBurns = new uint[](numberOfEpochsToCalculate);
    totalMints = new uint[](numberOfEpochsToCalculate);
    for (uint i = 0; i < numberOfEpochsToCalculate; i++) {
      (ratios[i], totalBurns[i], totalMints[i]) = _burnSubRatioInternal(
        mints,
        burns,
        i,
        i + _epochSpan
      );
    }
  }

  function epochCirculatingBatch(
    uint _epochStart,
    uint _epochEnd
  ) external view returns (uint[] memory) {
    return
      GLOBALLY_STAKED_TOKEN_CALCULATOR.circulatingSupplyBatch(
        _epochStart,
        _epochEnd
      );
  }

  function currentAverageInCirculation(
    uint _epochSpan
  ) public returns (uint result) {
    (, , result, , ) = GLOBALLY_STAKED_TOKEN_CALCULATOR
      .currentGloballyStakedAverage(_epochSpan);
  }

  function currentAverageInCirculationView(
    uint _epochSpan
  ) public view returns (uint result) {
    (, , result, , ) = GLOBALLY_STAKED_TOKEN_CALCULATOR
      .globallyStakedAverageView(currentEpoch(), _epochSpan, true);
  }

  function averageInCirculation(
    uint _epoch,
    uint _epochSpan
  ) public view returns (uint result) {
    (, , result, , ) = GLOBALLY_STAKED_TOKEN_CALCULATOR
      .globallyStakedAverageView(_epoch, _epochSpan, false);
  }

  function averageInCirculationBatch(
    uint _epochStart,
    uint _epochEnd,
    uint _epochSpan
  ) public view returns (uint[] memory result) {
    (, , result, , ) = GLOBALLY_STAKED_TOKEN_CALCULATOR
      .globallyStakedAverageBatch(_epochStart, _epochEnd, _epochSpan);
  }

  function tokenMints(
    uint epochStart,
    uint epochEnd
  ) public view returns (uint[] memory) {
    return TOKEN_MINTER.getEpochValueBatch(epochStart, epochEnd);
  }

  function tokenBurns(
    uint epochStart,
    uint epochEnd
  ) public view returns (uint[] memory) {
    return TOKEN_SPENDER.getEpochValueBatch(epochStart, epochEnd);
  }

  function tokenBucketMints(
    uint _bucket,
    uint epochStart,
    uint epochEnd
  ) public view returns (uint[] memory) {
    return TOKEN_MINTER.getBucketEpochValueBatch(epochStart, epochEnd, _bucket);
  }

  function tokenBucketBurns(
    uint _bucket,
    uint _epochStart,
    uint _epochEnd
  ) public view returns (uint[] memory) {
    return
      TOKEN_SPENDER.getBucketEpochValueBatch(_epochStart, _epochEnd, _bucket);
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IGloballyStakedTokenCalculator {
  function currentGloballyStakedAverage(
    uint _epochSpan
  )
    external
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    );

  function globallyStakedAverageView(
    uint _epoch,
    uint _epochSpan,
    bool _includeCurrent
  )
    external
    view
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    );

  function globallyStakedAverageBatch(
    uint _epochStart,
    uint _epochEnd,
    uint _epochSpan
  )
    external
    view
    returns (
      uint[] memory rawTotalStaked,
      int[] memory totalStaked,
      uint[] memory circulatingSupply,
      int[] memory effectiveSupply,
      uint[] memory percentage
    );

  function stakedAmountsBatch(
    uint _epochStart,
    uint _epochEnd
  )
    external
    view
    returns (address[] memory stakingAddresses, uint[][] memory stakedAmounts);

  function circulatingSupplyBatch(
    uint _epochStart,
    uint _epochEnd
  ) external view returns (uint[] memory circulatingSupplies);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IGloballyStakedTokenCalculator.sol";
import "../Manager/ManagerModifier.sol";
import "../ERC20/ITokenMinter.sol";
import "../ERC20/ITokenSpender.sol";
import "../Utils/EpochConfigurable.sol";
import "../Utils/Totals.sol";

struct HistoryData {
  uint[] epochs;
  uint[] mints;
  uint[] burns;
  uint[] supply;
  uint[] totalStaked;
  address[] stakingAddresses;
  uint[][] stakedPerAddress;
}

interface IGlobalTokenMetrics {
  function historyMetrics(
    uint _startEpoch,
    uint _endEpoch
  ) external view returns (HistoryData memory result);

  function epochCirculatingBatch(
    uint _epochStart,
    uint _epochEnd
  ) external view returns (uint[] memory);

  function currentAverageInCirculation(uint _epochSpan) external returns (uint);

  function currentAverageInCirculationView(
    uint _epochSpan
  ) external view returns (uint);

  function averageInCirculation(
    uint _epoch,
    uint _epochSpan
  ) external view returns (uint);

  function averageInCirculationBatch(
    uint _epochStart,
    uint _epochEnd,
    uint _epochSpan
  ) external view returns (uint[] memory result);

  function currentStakedRatio(
    uint _epochSpan
  )
    external
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    );

  function currentStakedRatioView(
    uint _epochSpan
  )
    external
    view
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    );

  function stakedRatioAtEpoch(
    uint _epoch,
    uint _epochSpan
  )
    external
    view
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    );

  function stakedRatioAtEpochBatch(
    uint _startEpoch,
    uint _endEpoch,
    uint _epochSpan
  )
    external
    view
    returns (
      uint[] memory rawTotalStaked,
      int[] memory totalStaked,
      uint[] memory circulatingSupply,
      int[] memory effectiveSupply,
      uint[] memory percentage
    );

  function currentBurnRatio(
    uint _epochSpan
  ) external view returns (uint burnRatio, uint totalBurns, uint totalMints);

  function burnRatioAtEpoch(
    uint _epoch,
    uint _epochSpan
  ) external view returns (uint burnRatio, uint totalBurns, uint totalMints);

  function burnRatiosAtEpochBatch(
    uint _epochStart,
    uint _epochEnd,
    uint _epochSpan
  )
    external
    view
    returns (
      uint[] memory ratios,
      uint[] memory totalBurns,
      uint[] memory totalMints
    );

  function tokenMints(
    uint epochStart,
    uint epochEnd
  ) external view returns (uint[] memory);

  function tokenBurns(
    uint epochStart,
    uint epochEnd
  ) external view returns (uint[] memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Utils/IEpochConfigurable.sol";

uint constant MINTER_ADVENTURER_BUCKET = 1;
uint constant MINTER_REALM_BUCKET = 2;
uint constant MINTER_STAKER_BUCKET = 3;

interface ITokenMinter is IEpochConfigurable {
  function getEpochValue(uint _epoch) external view returns (uint);

  function getEpochValueBatch(
    uint startEpoch,
    uint endEpoch
  ) external view returns (uint[] memory result);

  function getBucketEpochValueBatch(
    uint _startEpoch,
    uint _endEpoch,
    uint _bucket
  ) external view returns (uint[] memory result);

  function getEpochValueBatchTotal(
    uint startEpoch,
    uint endEpoch
  ) external view returns (uint result);

  function getBucketEpochValueBatchTotal(
    uint _startEpoch,
    uint _endEpoch,
    uint _bucket
  ) external view returns (uint result);

  function mint(address _owner, uint _amount, uint _bucket) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "../Utils/IEpochConfigurable.sol";

uint constant SPENDER_ADVENTURER_BUCKET = 1;
uint constant SPENDER_REALM_BUCKET = 2;

interface ITokenSpender is IEpochConfigurable {
  function getEpochValue(uint _epoch) external view returns (uint);

  function getEpochValueBatch(
    uint startEpoch,
    uint endEpoch
  ) external view returns (uint[] memory result);

  function getBucketEpochValueBatch(
    uint _startEpoch,
    uint _endEpoch,
    uint _bucket
  ) external view returns (uint[] memory result);

  function getEpochValueBatchTotal(
    uint startEpoch,
    uint endEpoch
  ) external view returns (uint result);

  function getBucketEpochValueBatchTotal(
    uint _startEpoch,
    uint _endEpoch,
    uint _bucket
  ) external view returns (uint result);

  function spend(address _owner, uint _amount, uint _bucket) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint256 constant DECIMAL_POINT = 10 ** 3;
uint256 constant ROUNDING_ADJUSTER = DECIMAL_POINT - 1;

int256 constant SIGNED_DECIMAL_POINT = int256(DECIMAL_POINT);

uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;
uint256 constant ONE_HUNDRED_SQUARE = ONE_HUNDRED * ONE_HUNDRED;
int256 constant SIGNED_ONE_HUNDRED = 100 * SIGNED_DECIMAL_POINT;
int256 constant SIGNED_ONE_HUNDRED_SQUARE = SIGNED_ONE_HUNDRED * SIGNED_ONE_HUNDRED;

int256 constant SIGNED_ZERO = 0;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IManager {
  function isAdmin(address _addr) external view returns (bool);

  function isManager(address _addr, uint256 _type) external view returns (bool);

  function addManager(address _addr, uint256 _type) external;

  function removeManager(address _addr, uint256 _type) external;

  function addAdmin(address _addr) external;

  function removeAdmin(address _addr) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../Manager/IManager.sol";

abstract contract ManagerModifier {
  //=======================================
  // Immutables
  //=======================================
  IManager public immutable MANAGER;

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) {
    MANAGER = IManager(_manager);
  }

  //=======================================
  // Modifiers
  //=======================================
  modifier onlyAdmin() {
    require(MANAGER.isAdmin(msg.sender), "Manager: Not an Admin");
    _;
  }

  modifier onlyManager() {
    require(MANAGER.isManager(msg.sender, 0), "Manager: Not manager");
    _;
  }

  modifier onlyMinter() {
    require(MANAGER.isManager(msg.sender, 1), "Manager: Not minter");
    _;
  }

  modifier onlyTokenMinter() {
    require(MANAGER.isManager(msg.sender, 2), "Manager: Not token minter");
    _;
  }

  modifier onlyBinder() {
    require(MANAGER.isManager(msg.sender, 3), "Manager: Not binder");
    _;
  }

  modifier onlyConfigManager() {
    require(MANAGER.isManager(msg.sender, 4), "Manager: Not config manager");
    _;
  }

  modifier onlyTokenSpender() {
    require(MANAGER.isManager(msg.sender, 5), "Manager: Not token spender");
    _;
  }

  modifier onlyTokenEmitter() {
    require(MANAGER.isManager(msg.sender, 6), "Manager: Not token emitter");
    _;
  }

  modifier onlyPauser() {
    require(
      MANAGER.isAdmin(msg.sender) || MANAGER.isManager(msg.sender, 6),
      "Manager: Not pauser"
    );
    _;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

library ArrayUtils {
  error ArrayLengthMismatch(uint _length1, uint _length2);
  error InvalidArrayOrder(uint index);

  function ensureSameLength(uint _l1, uint _l2) internal pure {
    if (_l1 != _l2) {
      revert ArrayLengthMismatch(_l1, _l2);
    }
  }

  function ensureSameLength(uint _l1, uint _l2, uint _l3) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
  }

  function ensureSameLength(
    uint _l1,
    uint _l2,
    uint _l3,
    uint _l4
  ) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
    ensureSameLength(_l1, _l4);
  }

  function ensureSameLength(
    uint _l1,
    uint _l2,
    uint _l3,
    uint _l4,
    uint _l5
  ) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
    ensureSameLength(_l1, _l4);
    ensureSameLength(_l1, _l5);
  }

  function checkAddressesForDuplicates(
    address[] memory _tokenAddrs
  ) internal pure {
    address lastAddress;
    for (uint i = 0; i < _tokenAddrs.length; i++) {
      if (lastAddress > _tokenAddrs[i]) {
        revert InvalidArrayOrder(i);
      }
      lastAddress = _tokenAddrs[i];
    }
  }

  function checkForDuplicates(uint[] memory _ids) internal pure {
    uint lastId;
    for (uint i = 0; i < _ids.length; i++) {
      if (lastId > _ids[i]) {
        revert InvalidArrayOrder(i);
      }
      lastId = _ids[i];
    }
  }

  function checkForDuplicates(
    address[] memory _tokenAddrs,
    uint[] memory _tokenIds
  ) internal pure {
    address lastAddress;
    int256 lastTokenId = -1;
    for (uint i = 0; i < _tokenAddrs.length; i++) {
      if (_tokenAddrs[i] > lastAddress) {
        lastTokenId = -1;
      }

      if (_tokenAddrs[i] < lastAddress || int(_tokenIds[i]) <= lastTokenId) {
        revert InvalidArrayOrder(i);
      }
      lastAddress = _tokenAddrs[i];
      lastTokenId = int(_tokenIds[i]);
    }
  }

  function toSingleValueDoubleArray(
    uint[] memory _vals
  ) internal pure returns (uint[][] memory result) {
    result = new uint[][](_vals.length);
    for (uint i = 0; i < _vals.length; i++) {
      result[i] = ArrayUtils.toMemoryArray(_vals[i], 1);
    }
  }

  function toMemoryArray(
    uint _value,
    uint _length
  ) internal pure returns (uint[] memory result) {
    result = new uint[](_length);
    for (uint i = 0; i < _length; i++) {
      result[i] = _value;
    }
  }

  function toMemoryArray(
    uint[] calldata _value
  ) internal pure returns (uint[] memory result) {
    result = new uint[](_value.length);
    for (uint i = 0; i < _value.length; i++) {
      result[i] = _value[i];
    }
  }

  function toMemoryArray(
    address _address,
    uint _length
  ) internal pure returns (address[] memory result) {
    result = new address[](_length);
    for (uint i = 0; i < _length; i++) {
      result[i] = _address;
    }
  }

  function toMemoryArray(
    address[] calldata _addresses
  ) internal pure returns (address[] memory result) {
    result = new address[](_addresses.length);
    for (uint i = 0; i < _addresses.length; i++) {
      result[i] = _addresses[i];
    }
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: Unlicensed

import "../lib/FloatingPointConstants.sol";

uint256 constant MASK_128 = ((1 << 128) - 1);
uint128 constant MASK_64 = ((1 << 64) - 1);

library Epoch {
  // Converts a given timestamp to an epoch using the specified duration and offset.
  // Example for battle timers resetting at noon UTC is: _duration = 1 days; _offset = 12 hours;
  function toEpochNumber(
    uint256 _timestamp,
    uint256 _duration,
    uint256 _offset
  ) internal pure returns (uint256) {
    return (_timestamp + _offset) / _duration;
  }

  // Here we assume that _config is a packed _duration (left 64 bits) and _offset (right 64 bits)
  function toEpochNumber(uint256 _timestamp, uint128 _config) internal pure returns (uint256) {
    return (_timestamp + (_config & MASK_64)) / ((_config >> 64) & MASK_64);
  }

  // Returns a value between 0 and ONE_HUNDRED which is the percentage of "completeness" of the epoch
  // result variable is reused for memory efficiency
  function toEpochCompleteness(
    uint256 _timestamp,
    uint128 _config
  ) internal pure returns (uint256 result) {
    result = (_config >> 64) & MASK_64;
    result = (ONE_HUNDRED * ((_timestamp + (_config & MASK_64)) % result)) / result;
  }

  // Converts a given epoch to a timestamp at the start of the epoch
  function epochToTimestamp(
    uint256 _epoch,
    uint128 _config
  ) internal pure returns (uint256 result) {
    result = _epoch * ((_config >> 64) & MASK_64);
    if (result > 0) {
      result -= (_config & MASK_64);
    }
  }

  // Create a config for the function above
  function toConfig(uint64 _duration, uint64 _offset) internal pure returns (uint128) {
    return (uint128(_duration) << 64) | uint128(_offset);
  }

  // Pack the epoch number with the config into a single uint256 for mappings
  function packEpoch(uint256 _epochNumber, uint128 _config) internal pure returns (uint256) {
    return (uint256(_config) << 128) | uint128(_epochNumber);
  }

  // Convert timestamp to Epoch and pack it with the config into a single uint256 for mappings
  function packTimestampToEpoch(
    uint256 _timestamp,
    uint128 _config
  ) internal pure returns (uint256) {
    return packEpoch(toEpochNumber(_timestamp, _config), _config);
  }

  // Unpack packedEpoch to epochNumber and config
  function unpack(
    uint256 _packedEpoch
  ) internal pure returns (uint256 epochNumber, uint128 config) {
    config = uint128(_packedEpoch >> 128);
    epochNumber = _packedEpoch & MASK_128;
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

import "./Epoch.sol";
import "../Manager/ManagerModifier.sol";
import "./IEpochConfigurable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract EpochConfigurable is Pausable, ManagerModifier, IEpochConfigurable {
  uint128 public EPOCH_CONFIG;

  constructor(
    address _manager,
    uint64 _epochDuration,
    uint64 _epochOffset
  ) ManagerModifier(_manager) {
    EPOCH_CONFIG = Epoch.toConfig(_epochDuration, _epochOffset);
  }

  function currentEpoch() public view returns (uint) {
    return epochAtTimestamp(block.timestamp);
  }

  function epochAtTimestamp(uint _timestamp) public view returns (uint) {
    return Epoch.toEpochNumber(_timestamp, EPOCH_CONFIG);
  }

  //=======================================
  // Admin
  //=======================================
  function pause() external onlyAdmin {
    _pause();
  }

  function unpause() external onlyAdmin {
    _unpause();
  }

  function updateEpochConfig(uint64 duration, uint64 offset) external onlyAdmin {
    EPOCH_CONFIG = Epoch.toConfig(duration, offset);
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IEpochConfigurable {
  function currentEpoch() external view returns (uint);

  function epochAtTimestamp(uint _timestamp) external view returns (uint);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./ArrayUtils.sol";

library Totals {
  /*
   * @dev Calculate the total value of an array of uints
   * @param _values An array of uints
   * @return sum The total value of the array
   */

  function calculateTotal(uint[] memory _values) internal pure returns (uint) {
    return calculateSubTotal(_values, 0, _values.length);
  }

  function calculateSubTotal(
    uint[] memory _values,
    uint _indexStart,
    uint _indexEnd
  ) internal pure returns (uint sum) {
    for (uint i = _indexStart; i < _indexEnd; i++) {
      sum += _values[i];
    }
  }

  function calculateTotalWithNonZeroCount(
    uint[] memory _values
  ) internal pure returns (uint total, uint nonZeroCount) {
    return calculateSubTotalWithNonZeroCount(_values, 0, _values.length);
  }

  function calculateSubTotalWithNonZeroCount(
    uint[] memory _values,
    uint _indexStart,
    uint _indexEnd
  ) internal pure returns (uint total, uint nonZeroCount) {
    for (uint i = _indexStart; i < _indexEnd; i++) {
      if (_values[i] > 0) {
        total += _values[i];
        nonZeroCount++;
      }
    }
  }

  /*
   * @dev Calculate the total value of an the current state and an array of gains, but only if the value is greater than 0 at any given point of time
   * @param _values An array of uints
   * @return sum The total value of the array
   */
  function calculateTotalBasedOnDeltas(
    uint currentValue,
    int[] memory _deltas
  ) internal pure returns (uint sum) {
    int signedCurrent = int(currentValue);
    for (uint i = _deltas.length; i > 0; i--) {
      signedCurrent -= _deltas[i - 1];
      sum += uint(currentValue);
    }
  }

  function calculateTotalBasedOnGainsAndLosses(
    uint currentValue,
    uint[] memory _gains,
    uint[] memory _losses
  ) internal pure returns (uint sum) {
    ArrayUtils.ensureSameLength(_gains.length, _losses.length);

    for (uint i = _gains.length; i > 0; i--) {
      currentValue += _losses[i - 1];
      currentValue -= _gains[i - 1];
      sum += currentValue;
    }
  }

  function calculateAverageBasedOnGainsAndLosses(
    uint currentValue,
    uint[] memory _gains,
    uint[] memory _losses
  ) internal pure returns (uint sum) {
    ArrayUtils.ensureSameLength(_gains.length, _losses.length);

    for (uint i = _gains.length; i > 0; i--) {
      currentValue += _losses[i - 1];
      currentValue -= _gains[i - 1];
      sum += currentValue;
    }
    sum = sum / _gains.length;
  }

  function calculateEachDayValueBasedOnDeltas(
    uint currentValue,
    int[] memory _deltas
  ) internal pure returns (uint[] memory values) {
    values = new uint[](_deltas.length);
    int signedCurrent = int(currentValue);
    for (uint i = _deltas.length; i > 0; i--) {
      signedCurrent -= _deltas[i - 1];
      values[i - 1] = uint(signedCurrent);
    }
  }

  function calculateEachDayValueBasedOnGainsAndLosses(
    uint currentValue,
    uint[] memory _gains,
    uint[] memory _losses
  ) internal pure returns (uint[] memory values) {
    ArrayUtils.ensureSameLength(_gains.length, _losses.length);

    values = new uint[](_gains.length);
    uint signedCurrent = currentValue;
    for (uint i = _gains.length; i > 0; i--) {
      signedCurrent += _losses[i - 1];
      signedCurrent -= _gains[i - 1];
      values[i - 1] = uint(signedCurrent);
    }
  }
}