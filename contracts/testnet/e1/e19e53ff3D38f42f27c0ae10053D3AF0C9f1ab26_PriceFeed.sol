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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title A standard interface for asking for prices from an Oracle
 */
interface IPriceFeed {

    /// @dev Get the latest price for this price feed
    /// @return price The last price
    /// @return decimals The number of decimals in the price
    function lastPrice() external view returns (uint price, uint8 decimals);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStdReference {
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (ReferenceData memory);

    /// Similar to getReferenceData, but with multiple base/quote pairs at once.
    function getReferenceDataBulk(string[] memory _bases, string[] memory _quotes)
        external
        view
        returns (ReferenceData[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IPriceFeed.sol";
import "./interfaces/IStdReference.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title A standard interface for asking for prices from an Oracle
 */
contract PriceFeed is Ownable, IPriceFeed {
    
    enum PriceFeedType { CHAINLINK, BAND }

    address public priceFeedAddress;

    PriceFeedType public priceFeedType;
    string public bandBase;
    string public bandQuote;

    constructor(address _priceFeedAddress, PriceFeedType _priceFeedType, string memory _bandBase, string memory _bandQuote) {
        require(_priceFeedType == PriceFeedType.CHAINLINK || _priceFeedType == PriceFeedType.BAND, "Invalid price feed type");
        priceFeedType = _priceFeedType;
        priceFeedAddress = _priceFeedAddress;
        bandBase = _bandBase;
        bandQuote = _bandQuote;
    }

    /// @dev Get the latest price for this price feed
    /// @return price The last price
    /// @return decimals The number of decimals in the price
    function lastPrice() external view returns (uint price, uint8 decimals) {
        if (priceFeedType == PriceFeedType.CHAINLINK) {
            AggregatorV3Interface chainlinkPriceFeed = AggregatorV3Interface(priceFeedAddress);
            (, int256 aggPrice, , , ) = chainlinkPriceFeed.latestRoundData();
            price = uint(aggPrice);
            decimals = chainlinkPriceFeed.decimals();
        } else if (priceFeedType == PriceFeedType.BAND) {
            IStdReference bandPriceFeed = IStdReference(priceFeedAddress);
            price = bandPriceFeed.getReferenceData(bandBase, bandQuote).rate;
            decimals = 18;
        }
    }

    function setPriceFeedChainlink(address _priceFeedAddress) public onlyOwner {
        priceFeedType = PriceFeedType.CHAINLINK;
        priceFeedAddress = _priceFeedAddress;
    }

    function setPriceFeedBand(address _priceFeedAddress, string calldata _bandBase, string calldata _bandQuote) public onlyOwner {
        priceFeedType = PriceFeedType.BAND;
        priceFeedAddress = _priceFeedAddress;
        bandBase = _bandBase;
        bandQuote = _bandQuote;
    }    
}