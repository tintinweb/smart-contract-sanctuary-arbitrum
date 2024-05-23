// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IChainlinkAggregator} from "@stakewise-core/interfaces/IChainlinkAggregator.sol";
import {IChainlinkV3Aggregator} from "@stakewise-core/interfaces/IChainlinkV3Aggregator.sol";
import {IBalancerRateProvider} from "@stakewise-core/interfaces/IBalancerRateProvider.sol";
import {IPriceFeed} from "./interfaces/IPriceFeed.sol";

/**
 * @title PriceFeed
 * @author StakeWise
 * @notice The feed that receives the price from the canonical chain (e.g. mainnet)
 */
contract PriceFeed is Ownable2Step, IPriceFeed {
    error AccessDenied();
    error InvalidTimestamp();

    /// @inheritdoc IChainlinkV3Aggregator
    uint256 public constant override version = 0;

    /// @inheritdoc IChainlinkV3Aggregator
    string public override description;

    /// @inheritdoc IPriceFeed
    address public override rateReceiver;

    uint128 private _rate;
    uint128 private _updateTimestamp;

    /**
     * @dev Constructor
     * @param initialOwner The address of the contract owner
     * @param _description The description of the price feed
     */
    constructor(address initialOwner, string memory _description) Ownable(initialOwner) {
        description = _description;
    }

    /// @inheritdoc IBalancerRateProvider
    function getRate() public view override returns (uint256) {
        return _rate;
    }

    /// @inheritdoc IPriceFeed
    function setRate(uint128 timestamp, uint128 newRate) external override {
        if (msg.sender != rateReceiver) revert AccessDenied();
        if (timestamp <= _updateTimestamp) revert InvalidTimestamp();

        // update state
        _rate = newRate;
        _updateTimestamp = timestamp;
        emit RateUpdated(msg.sender, newRate, timestamp);
    }

    /// @inheritdoc IPriceFeed
    function setRateReceiver(address newRateReceiver) external override onlyOwner {
        rateReceiver = newRateReceiver;
        emit RateReceiverUpdated(newRateReceiver);
    }

    /// @inheritdoc IChainlinkAggregator
    function latestAnswer() public view override returns (int256) {
        // cannot overflow as _rate is uint128
        return int256(getRate());
    }

    /// @inheritdoc IChainlinkAggregator
    function latestTimestamp() external view returns (uint256) {
        return _updateTimestamp;
    }

    /// @inheritdoc IChainlinkV3Aggregator
    function decimals() public pure returns (uint8) {
        return 18;
    }

    /// @inheritdoc IChainlinkV3Aggregator
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        // SLOAD to memory
        uint256 updateTimestamp = _updateTimestamp;
        return (0, latestAnswer(), updateTimestamp, updateTimestamp, 0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.20;

import {Ownable} from "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

/**
 * @title IChainlinkAggregator
 * @author Chainlink
 * @dev Copied from https://github.com/smartcontractkit/chainlink/blob/master/contracts/src/v0.8/interfaces/AggregatorInterface.sol
 * @notice Interface for Chainlink aggregator contract
 */
interface IChainlinkAggregator {
  /**
   * @notice Returns the price of a unit of osToken (e.g price of osETH in ETH)
   * @return The price of a unit of osToken (with 18 decimals)
   */
  function latestAnswer() external view returns (int256);

  /**
   * @notice The last updated at block timestamp
   * @return The timestamp of the last update
   */
  function latestTimestamp() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

/**
 * @title IChainlinkAggregator
 * @author Chainlink
 * @dev Copied from https://github.com/smartcontractkit/chainlink/blob/master/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
 * @notice Interface for Chainlink V3 aggregator contract
 */
interface IChainlinkV3Aggregator {
  /**
   * @notice The number of decimals the price is formatted with
   */
  function decimals() external view returns (uint8);

  /**
   * @notice The description of the aggregator
   */
  function description() external view returns (string memory);

  /**
   * @notice The version number of the aggregator
   */
  function version() external view returns (uint256);

  /**
   * @notice Get the data from the latest round
   * @return roundId The round ID
   * @return answer The current price
   * @return startedAt The timestamp of when the round started
   * @return updatedAt The timestamp of when the round was updated
   * @return answeredInRound (Deprecated) Previously used when answers could take multiple rounds to be computed
   */
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

pragma solidity ^0.8.22;

interface IBalancerRateProvider {
  /**
   * @notice Returns the price of a unit of osToken (e.g price of osETH in ETH)
   * @return The price of a unit of osToken (with 18 decimals)
   */
  function getRate() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.22;

import {IChainlinkAggregator} from "@stakewise-core/interfaces/IChainlinkAggregator.sol";
import {IBalancerRateProvider} from "@stakewise-core/interfaces/IBalancerRateProvider.sol";
import {IChainlinkV3Aggregator} from "@stakewise-core/interfaces/IChainlinkV3Aggregator.sol";

/**
 * @title IPriceFeed
 * @author StakeWise
 * @notice Interface for the PriceFeed contract
 */
interface IPriceFeed is IChainlinkAggregator, IChainlinkV3Aggregator, IBalancerRateProvider {
    /**
     * @notice Emitted when the rate of the price feed is updated
     * @param caller The address of the caller who updated the rate
     * @param newRate The new rate of the price feed
     * @param newTimestamp The timestamp of the rate update
     */
    event RateUpdated(address indexed caller, uint128 newRate, uint128 newTimestamp);

    /**
     * @notice Emitted when the rate receiver address is updated
     * @param newRateReceiver The new rate receiver address
     */
    event RateReceiverUpdated(address newRateReceiver);

    /**
     * @notice Function to get the rate receiver address
     * @return The rate receiver address
     */
    function rateReceiver() external view returns (address);

    /**
     * @notice Updates the rate of the price feed. Can only be called by the owner.
     * @param timestamp The timestamp of the rate update
     * @param newRate The new rate of the price feed
     */
    function setRate(uint128 timestamp, uint128 newRate) external;

    /**
     * @notice Function to set the rate receiver address
     * @param newRateReceiver The new rate receiver address
     */
    function setRateReceiver(address newRateReceiver) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}