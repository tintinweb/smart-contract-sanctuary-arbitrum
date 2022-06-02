// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/IOracleWrapper.sol";

/**
 * @notice Applies a simple moving average (SMA) smoothing function to the spot
 *          price of an underlying oracle.
 */
contract SMAOracle is IOracleWrapper {
    /*
     * A note on "ramping up":
     *
     * `SMAOracle` works by storing spot prices and calculating the average of
     * the most recent k prices. Obviously, we need to handle the case of insufficient
     * data: specifically, the case where the number of actual stored observations, n,
     * is strictly less than the number of sampling periods to use for averaging, k.
     *
     * To achieve this, `SMAOracle` needs to "ramp up". This means that the
     * number of sampling periods *actually used*, K, looks like this (w.r.t.
     * time, t):
     *
     *     K ^
     *       |
     *       |
     *       |
     *       |
     *       |
     * k --> |+++++++++++++++++++++++++++++++++-----------------------------
     *       |                                |
     *       |                                |
     *       |                     +----------+
     *       |                     |
     *       |                     |
     *       |          +----------+
     *       |          |
     *       |          |
     *       |----------+
     *       |
     *       |
     *       +---------------------------------------------------------------> t
     *
     *
     * Here, K is the `periods` instance variable and time, t, is an integer
     * representing successive calls to `SMAOracle::poll`.
     *
     */

    /**
     * @notice the stored spot prices by their period number
     * @dev Only the most recent `numPeriods` prices are stored. The rest are deleted,
     * which will result in a zero value for prices with index less than `periodCount - numPrices`.
     */
    mapping(int256 => int256) public prices;
    /// @notice the total number of periods that have occurred
    int256 public periodCount;

    /// Price feed to use for SMA
    address public immutable override oracle;

    // Deployer of the contract
    address public immutable override deployer;

    // Governance this contract is subject to (in any sane implementation, a
    // DAO)
    address public governance;

    /// Number of desired sampling periods to use -- this will differ from
    /// the actual number of periods used until the SMAOracle ramps up.
    int256 public immutable numPeriods;

    /// Duration between price updates in seconds
    uint256 public immutable updateInterval;

    /// Time of last successful price update
    uint256 public lastUpdate;

    int8 public constant MAX_PERIODS = 24;

    uint8 public constant override decimals = 18;
    int256 public immutable scaler;

    address public poolKeeper;

    constructor(
        address _inputOracle,
        int256 _numPeriods,
        uint256 _updateInterval,
        address _deployer,
        address _poolKeeper,
        address _gov
    ) {
        require(
            _inputOracle != address(0) && _deployer != address(0) && _poolKeeper != address(0) && _gov != address(0),
            "SMA: Null address forbidden"
        );
        require(_numPeriods > 0 && _numPeriods <= MAX_PERIODS, "SMA: Out of bounds");
        require(_updateInterval != 0, "SMA: Update interval cannot be 0");

        uint8 inputOracleDecimals = IOracleWrapper(_inputOracle).decimals();
        /* `scaler` is always <= 10^18 and >= 1 so this cast is safe */
        scaler = int256(10**(decimals - inputOracleDecimals));

        numPeriods = _numPeriods;
        updateInterval = _updateInterval;
        oracle = _inputOracle;
        deployer = _deployer;
        poolKeeper = _poolKeeper;
        governance = _gov;
    }

    /**
     * @notice Retrieves the current SMA price
     * @dev Recomputes SMA across sample size
     */
    function getPrice() external view override returns (int256) {
        return _calculateSMA();
    }

    /**
     * @notice Returns the current SMA price and an empty bytes array
     * @dev Required by the `IOracleWrapper` interface. The interface leaves
     *          the metadata as implementation-defined. For the SMA wrapper, there
     *          is no clear use case for additional data, so it's left blank
     */
    function getPriceAndMetadata() external view override returns (int256 _price, bytes memory _data) {
        _price = _calculateSMA();
        return (_price, _data);
    }

    /**
     * @notice Updates the SMA wrapper by retrieving a new price from the
     *          associated price observer contract (provided it's not too early)
     * @return Latest SMA price
     * @dev Throws if called within an update interval since last being called
     * @dev Essentially wraps `update()`
     */
    function poll() external override onlyPoolKeeper returns (int256) {
        if (block.timestamp >= lastUpdate + updateInterval) {
            _update();
        }
        return _calculateSMA();
    }

    /**
     * @notice Converts `wad` to a raw integer
     * @dev This is a no-op for `SMAOracle`
     * @param wad wad maths value
     * @return Raw (signed) integer
     */
    function fromWad(int256 wad) external view override returns (int256) {
        return wad / scaler;
    }

    /**
     * @notice Add a new spot price observation to the SMA Oracle
     * @dev O(1) complexity due to constant arithmetic
     */
    function _update() internal {
        /* query the underlying price feed */
        int256 latestPrice = IOracleWrapper(oracle).getPrice();

        /* store the latest price */
        prices[periodCount] = toWad(latestPrice);

        /* if we've filled the numPeriods amount, delete the oldest price */
        if (periodCount >= numPeriods) {
            delete prices[periodCount - numPeriods];
        }

        periodCount++;
        lastUpdate = block.timestamp;
    }

    /**
     * @notice Calculates the simple moving average of the provided dataset for the specified number of periods
     * @return Simple moving average based on the last `k` prices
     * @dev `k` is the lower value of `numPeriods` and `periodCount`
     * @dev O(k) complexity due to linear traversal of the final `k` elements of `prices`
     * @dev Note that the signedness of the return type is due to the signedness of the elements of `prices`
     */
    function _calculateSMA() internal view returns (int256) {
        int256 k = periodCount;

        if (k == 0) {
            return 0;
        }

        if (k > numPeriods) {
            k = numPeriods;
        }

        /* linear scan over the [n - k, n] subsequence */
        int256 sum;
        int256 _periodCount = periodCount;
        for (int256 i = _periodCount - k; i < _periodCount; i = unchecked_inc(i)) {
            sum += prices[i];
        }

        // This is safe because we know that `k` will be between 1 and MAX_PERIODS
        return sum / k;
    }

    /**
     * @notice Changes the address of the associated `PoolKeeper` contract
     * @param _poolKeeper Address of the new contract
     * @dev Only callable by governance
     */
    function setPoolKeeper(address _poolKeeper) public onlyGov {
        require(_poolKeeper != address(0), "SMA: Null address forbidden");
        poolKeeper = _poolKeeper;
    }

    /**
     * @notice Changes the address of the associated governance
     * @param _governance Address of the new governance
     * @dev Only callable by (existing) governance
     */
    function setGovernance(address _governance) public onlyGov {
        require(_governance != address(0), "SMA: Null address forbidden");
        governance = _governance;
    }

    /**
     * @notice Converts `x` to a wad value
     * @param x Number to convert to wad value
     * @return `x` but wad
     */
    function toWad(int256 x) private view returns (int256) {
        return x * scaler;
    }

    function unchecked_inc(int256 i) private pure returns (int256) {
        unchecked {
            return ++i;
        }
    }

    modifier onlyGov() {
        require(msg.sender == governance, "SMA: Only callable by governance");
        _;
    }

    modifier onlyPoolKeeper() {
        require(msg.sender == poolKeeper, "SMA: Only callable by PoolKeeper");
        _;
    }
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title The oracle wrapper contract interface
interface IOracleWrapper {
    function oracle() external view returns (address);

    function decimals() external view returns (uint8);

    function deployer() external view returns (address);

    // #### Functions

    /**
     * @notice Returns the current price for the asset in question
     * @return The latest price
     */
    function getPrice() external view returns (int256);

    /**
     * @return _price The latest round data price
     * @return _data The metadata. Implementations can choose what data to return here
     */
    function getPriceAndMetadata() external view returns (int256 _price, bytes memory _data);

    /**
     * @notice Converts from a WAD to normal value
     * @return Converted non-WAD value
     */
    function fromWad(int256 wad) external view returns (int256);

    /**
     * @notice Updates the underlying oracle state and returns the new price
     * @dev Spot oracles must implement but it will be a no-op
     */
    function poll() external returns (int256);
}