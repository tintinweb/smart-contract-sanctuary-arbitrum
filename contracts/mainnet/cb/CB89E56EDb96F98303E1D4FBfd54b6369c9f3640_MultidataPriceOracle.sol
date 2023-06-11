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

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

interface IPriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    function isPriceOracle() external view returns (bool);

    /**
      * @notice Get the underlying price of a cToken asset
      * @param cToken The cToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(address cToken) external view returns (uint);
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;

import "./IVersioned.sol";


/// @title Reader of Multidata core data.
interface ICoreMultidataFeedsReader is IVersioned {

    struct Metric {
        string name;    // unique, immutable in a contract
        string description;
        string currency;    // USD, ETH, PCT (for percent), BPS (for basis points), etc
        string[] tags;
    }

    struct Quote {
        uint256 value;
        uint32 updateTS;
    }

    event NewMetric(string name);
    event MetricInfoUpdated(string name);
    /// @notice updated one metric or all if metricId=type(uint256).max-1
    event MetricUpdated(uint indexed epochId, uint indexed metricId);


    /**
     * @notice Gets a list of metrics quoted by this oracle.
     * @return A list of metric info indexed by numerical metric ids.
     */
    function getMetrics() external view returns (Metric[] memory);

    /// @notice Gets a count of metrics quoted by this oracle.
    function getMetricsCount() external view returns (uint);

    /// @notice Gets metric info by a numerical id.
    function getMetric(uint256 id) external view returns (Metric memory);

    /**
     * @notice Checks if a metric is quoted by this oracle.
     * @param name Metric codename.
     * @return has `true` if metric exists.
     * @return id Metric numerical id, set if `has` is true.
     */
    function hasMetric(string calldata name) external view returns (bool has, uint256 id);

    /**
     * @notice Gets last known quotes for specified metrics.
     * @param names Metric codenames to query.
     * @return quotes Values and update timestamps for queried metrics.
     */
    function quoteMetrics(string[] calldata names) external view returns (Quote[] memory quotes);

    /**
     * @notice Gets last known quotes for specified metrics by internal numerical ids.
     * @dev Saves one storage lookup per metric.
     * @param ids Numerical metric ids to query.
     * @return quotes Values and update timestamps for queried metrics.
     */
    function quoteMetrics(uint256[] calldata ids) external view returns (Quote[] memory quotes);
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity ^0.8.0;


/// @title Contract supporting versioning using SemVer version scheme.
interface IVersioned {
    /// @notice Contract version, using SemVer version scheme.
    function VERSION() external view returns (string memory);
}

// SPDX-License-Identifier: bsl-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./compound/IPriceOracle.sol";
import "./ICoreMultidataFeedsReader.sol";

contract MultidataPriceOracle is IPriceOracle, Ownable {

    uint private constant MULTIDATA_FEEDS_COEFF = 2**112;

    ICoreMultidataFeedsReader public immutable multidataFeeds;
    uint32 public immutable timeout;

    struct CTokenConfig {
        uint8 decimals;
        string metricName;
    }

    mapping(address => CTokenConfig) public cTokenConfigs;

    constructor(address multidataFeeds_, uint32 timeout_) {
        require(multidataFeeds_ != address(0), "Invalid address");
        multidataFeeds = ICoreMultidataFeedsReader(multidataFeeds_);
        timeout = timeout_;
    }

    function getUnderlyingPrice(address cToken) external view returns (uint) {
        string memory metricName = cTokenConfigs[cToken].metricName;
        if (bytes(metricName).length == 0) {
            return 0;
        }

        uint256 underlyingDecimals = cTokenConfigs[cToken].decimals;

        string[] memory metrics = new string[](1);
        metrics[0] = metricName;
        try multidataFeeds.quoteMetrics(metrics)
            returns (ICoreMultidataFeedsReader.Quote[] memory quotes) {

            if (block.timestamp - timeout >= quotes[0].updateTS) {
                return 0;
            }

            // from the current oracle https://etherscan.io/address/0x50ce56A3239671Ab62f185704Caedf626352741e#code
            // Comptroller needs prices in the format: ${raw price} * 1e36 / baseUnit
            // The baseUnit of an asset is the amount of the smallest denomination of that asset per whole.
            // For example, the baseUnit of ETH is 1e18.

            return quotes[0].value // price from multidata oracle, which is adjusted as 2^112 for a whole
                * 10**(36 - underlyingDecimals) // adjustment of a comptroller price
                / MULTIDATA_FEEDS_COEFF; // remove multidata oracle adjustment
        } catch {
            return 0;
        }
    }

    function isPriceOracle() external pure returns (bool) {
        return true;
    }

    function setTokensConfig(address[] calldata tokens_, CTokenConfig[] calldata configs_) external onlyOwner {
        require(tokens_.length == configs_.length && tokens_.length != 0, "Invalid arrays length");

        for (uint i=0; i<tokens_.length; ++i) {
            require(tokens_[i] != address(0), "Invalid token address");

            cTokenConfigs[tokens_[i]] = configs_[i];
        }
    }
}