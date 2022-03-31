// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/FlagsInterface.sol";

import "../interfaces/ILiveFeedOracleId.sol";
import "../utils/OwnableWithEmergencyOracleId.sol";

/**
    Error codes:
    - C1 = Chainlink feeds are not being updated
 */
contract CrvUsdChainlinkL2OracleId is ILiveFeedOracleId, OwnableWithEmergencyOracleId {
    // Chainlink
    address constant private FLAG_ARBITRUM_SEQ_OFFLINE = address(bytes20(bytes32(uint256(keccak256("chainlink.flags.arbitrum-seq-offline")) - 1)));
    AggregatorV3Interface public priceFeed;
    FlagsInterface public chainlinkFlags;

    constructor(
        IOracleAggregator _oracleAggregator,
        uint256 _emergencyPeriod,
        AggregatorV3Interface _priceFeed,
        FlagsInterface _chainlinkFlags
    ) OwnableWithEmergencyOracleId(_oracleAggregator, _emergencyPeriod) {
        priceFeed = _priceFeed;
        chainlinkFlags = _chainlinkFlags;

        /*
        {
            "author": "Opium.Team",
            "description": "CRV/USD Oracle ID",
            "asset": "CRV/USD",
            "type": "onchain",
            "source": "chainlink",
            "logic": "none",
            "path": "latestAnswer()"
        }
        */
        emit LogMetadataSet("{\"author\":\"Opium.Team\",\"description\":\"CRV/USD Oracle ID\",\"asset\":\"CRV/USD\",\"type\":\"onchain\",\"source\":\"chainlink\",\"logic\":\"none\",\"path\":\"latestAnswer()\"}");
    }

    /** CHAINLINK */
    function getResult() public view override returns (uint256) {
        // Don't raise flag by default
        bool isRaised = false;

        // Check if flags contract was set and write flag value
        if (address(chainlinkFlags) != address(0)) {
            isRaised = chainlinkFlags.getFlag(FLAG_ARBITRUM_SEQ_OFFLINE);
        }

        // If flag was raised, revert
        if (isRaised) {
            revert ("C1");
        }

        ( , int256 price, , , ) = priceFeed.latestRoundData();

        // Data are provided with 8 decimals, adjust to 18 decimals
        uint256 result = uint256(price) * 1e10;

        return result;
    }
  
    /** RESOLVER */
    function _callback(uint256 _timestamp) external override {
        uint256 result = getResult();
        __callback(_timestamp, result);
    }

    /** GOVERNANCE */
    function setPriceFeed(AggregatorV3Interface _priceFeed) external onlyOwner {
        priceFeed = _priceFeed;
    }

    function setChainlinkFlags(FlagsInterface _chainlinkFlags) external onlyOwner {
        chainlinkFlags = _chainlinkFlags;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface FlagsInterface {
  function getFlag(address) external view returns (bool);

  function getFlags(address[] calldata) external view returns (bool[] memory);

  function raiseFlag(address) external;

  function raiseFlags(address[] calldata) external;

  function lowerFlags(address[] calldata) external;

  function setRaisingAccessController(address) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/// @title Opium.Interface.ILiveFeedOracleId is an interface that every LiveFeed oracleId should implement
interface ILiveFeedOracleId {
    /// @notice 
    /// @param timestamp - Timestamp at which data are needed
    function _callback(uint256 timestamp) external;

    /// @notice Returns current value of the oracle if possible, or last known value
    function getResult() external view returns (uint256 result);

    // Event with oracleId metadata JSON string (for Opium derivative explorer)
    event LogMetadataSet(string metadata);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "opium-protocol-v2/contracts/interfaces/IOracleAggregator.sol";

/**
    Error codes:
    - O1 = Only when no data and after timestamp allowed
    - O2 = Only when no data and after emergency period allowed
 */
contract OwnableWithEmergencyOracleId is Ownable {
    // Opium
    IOracleAggregator public oracleAggregator;

    // Governance
    uint256 public emergencyPeriod;

    constructor(IOracleAggregator _oracleAggregator, uint256 _emergencyPeriod) {
        // Opium
        oracleAggregator = _oracleAggregator;

        // Governance
        emergencyPeriod = _emergencyPeriod;
    }

    /** RESOLVER */
    function __callback(uint256 _timestamp, uint256 _result) internal {
        require(
            !oracleAggregator.hasData(address(this), _timestamp) &&
            _timestamp <= block.timestamp,
            "O1"
        );

        oracleAggregator.__callback(_timestamp, _result);
    }

    /** GOVERNANCE */
    /** 
        Emergency callback allows to push data manually in case `emergencyPeriod` elapsed and no data were provided
    */
    function emergencyCallback(uint256 _timestamp, uint256 _result) external onlyOwner {
        require(
            !oracleAggregator.hasData(address(this), _timestamp) &&
            _timestamp + emergencyPeriod <= block.timestamp,
            "O2"
        );

        oracleAggregator.__callback(_timestamp, _result);
    }

    function setEmergencyPeriod(uint256 _newEmergencyPeriod) external onlyOwner {
        emergencyPeriod = _newEmergencyPeriod;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

interface IOracleAggregator {
    function __callback(uint256 timestamp, uint256 data) external;

    function getData(address oracleId, uint256 timestamp) external view returns (uint256 dataResult);

    function hasData(address oracleId, uint256 timestamp) external view returns (bool);
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