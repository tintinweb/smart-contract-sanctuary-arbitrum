// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================= SfrxEthUsdDualOracle =======================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// ====================================================================
import { Timelock2Step } from "frax-std/access-control/v1/Timelock2Step.sol";
import { ITimelock2Step } from "frax-std/access-control/v1/interfaces/ITimelock2Step.sol";
import { DualOracleBase, ConstructorParams as DualOracleBaseParams } from "src/contracts/DualOracleBase.sol";
import { CurvePoolEmaPriceOracleWithMinMax, ConstructorParams as CurvePoolEmaPriceOracleWithMinMaxParams } from "../abstracts/CurvePoolEmaPriceOracleWithMinMax.sol";
import { EthUsdChainlinkOracleWithMaxDelay, ConstructorParams as EthUsdChainlinkOracleWithMaxDelayParams } from "../abstracts/EthUsdChainlinkOracleWithMaxDelay.sol";
import { FraxUsdChainlinkOracleWithMaxDelay, ConstructorParams as FraxUsdChainlinkOracleWithMaxDelayParams } from "../abstracts/FraxUsdChainlinkOracleWithMaxDelay.sol";
import { UniswapV3SingleTwapOracle, ConstructorParams as UniswapV3SingleTwapOracleParams } from "../abstracts/UniswapV3SingleTwapOracle.sol";
import { IDualOracle } from "interfaces/IDualOracle.sol";
import { IPriceSource } from "../frax-oracle/interfaces/IPriceSource.sol";
import { IPriceSourceReceiver } from "../frax-oracle/interfaces/IPriceSourceReceiver.sol";
import { ISfrxEth } from "interfaces/ISfrxEth.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

struct ConstructorParams {
    // = DualOracleBase
    address baseToken0; // sfrxEth
    uint8 baseToken0Decimals;
    address quoteToken0; // usd
    uint8 quoteToken0Decimals;
    address baseToken1; // sfrxEth
    uint8 baseToken1Decimals;
    address quoteToken1; // usd
    uint8 quoteToken1Decimals;
    // = UniswapV3SingleTwapOracle
    address frxEthErc20;
    address fraxErc20;
    address uniV3PairAddress;
    uint32 twapDuration;
    // = FraxUsdChainlinkOracleWithMaxDelay
    address fraxUsdChainlinkFeedAddress;
    uint256 fraxUsdMaximumOracleDelay;
    // = EthUsdChainlinkOracleWithMaxDelay
    address ethUsdChainlinkFeed;
    uint256 maxEthUsdOracleDelay;
    // = CurvePoolEmaPriceOracleWithMinMax
    address curvePoolEmaPriceOracleAddress;
    uint256 minimumCurvePoolEma;
    uint256 maximumCurvePoolEma;
    // = Timelock2Step
    address timelockAddress;
    // = sfrxEth Erc4626
    address sfrxEthErc4626Address;
}

/// @title FrxEthWethDualOracle
/// @notice This price source feeds prices to the FraxOracle system
/// @dev Returns prices of Frax assets in Ether
contract SfrxEthUsdDualOracle is
    DualOracleBase,
    CurvePoolEmaPriceOracleWithMinMax,
    UniswapV3SingleTwapOracle,
    FraxUsdChainlinkOracleWithMaxDelay,
    EthUsdChainlinkOracleWithMaxDelay,
    IPriceSource,
    Timelock2Step
{
    /// @notice The address of the Erc4626 token contract for sfrxEth
    address public immutable SFRXETH_FRXETH_CHAINLINK_ORACLE;

    constructor(
        ConstructorParams memory _params
    )
        DualOracleBase(
            DualOracleBaseParams({
                baseToken0: _params.baseToken0,
                baseToken0Decimals: _params.baseToken0Decimals,
                quoteToken0: _params.quoteToken0,
                quoteToken0Decimals: _params.quoteToken0Decimals,
                baseToken1: _params.baseToken1,
                baseToken1Decimals: _params.baseToken1Decimals,
                quoteToken1: _params.quoteToken1,
                quoteToken1Decimals: _params.quoteToken1Decimals
            })
        )
        CurvePoolEmaPriceOracleWithMinMax(
            CurvePoolEmaPriceOracleWithMinMaxParams({
                curvePoolEmaPriceOracleAddress: _params.curvePoolEmaPriceOracleAddress,
                minimumCurvePoolEma: _params.minimumCurvePoolEma,
                maximumCurvePoolEma: _params.maximumCurvePoolEma
            })
        )
        UniswapV3SingleTwapOracle(
            UniswapV3SingleTwapOracleParams({
                uniswapV3PairAddress: _params.uniV3PairAddress,
                twapDuration: _params.twapDuration,
                baseToken: _params.frxEthErc20,
                quoteToken: _params.fraxErc20
            })
        )
        EthUsdChainlinkOracleWithMaxDelay(
            EthUsdChainlinkOracleWithMaxDelayParams({
                ethUsdChainlinkFeedAddress: _params.ethUsdChainlinkFeed,
                maxEthUsdOracleDelay: _params.maxEthUsdOracleDelay
            })
        )
        FraxUsdChainlinkOracleWithMaxDelay(
            FraxUsdChainlinkOracleWithMaxDelayParams({
                fraxUsdChainlinkFeedAddress: _params.fraxUsdChainlinkFeedAddress,
                fraxUsdMaximumOracleDelay: _params.fraxUsdMaximumOracleDelay
            })
        )
        Timelock2Step()
    {
        _setTimelock({ _newTimelock: _params.timelockAddress });
        _registerInterface({ interfaceId: type(IDualOracle).interfaceId });
        _registerInterface({ interfaceId: type(ITimelock2Step).interfaceId });
        _registerInterface({ interfaceId: type(IPriceSource).interfaceId });

        SFRXETH_FRXETH_CHAINLINK_ORACLE = _params.sfrxEthErc4626Address;
    }

    // ====================================================================
    // Metadata
    // ====================================================================

    /// @notice The ```name``` function returns the name of the contract
    /// @return _name The name of the contract
    function name() external pure virtual returns (string memory _name) {
        _name = "v2 sfrxEth Dual Oracle In USD with Curve Pool (WETH) EMA and Uniswap v3 TWAP and Frax and ETH Chainlink";
    }

    /// @notice The ```version``` function returns the version of the contract
    /// @return _major The major version of the contract
    /// @return _minor The minor version of the contract
    /// @return _patch The patch version of the contract
    function version() external pure virtual returns (uint256 _major, uint256 _minor, uint256 _patch) {
        _major = 2;
        _minor = 0;
        _patch = 0;
    }

    // ====================================================================
    // Configuration Setters
    // ====================================================================

    /// @notice The ```setMinimumCurvePoolEma``` function sets the minimum price of frxEth in Ether units of the EMA
    /// @dev Must match precision of the EMA
    /// @param _minimumPrice The minimum price of frxEth in Ether units of the EMA
    function setMinimumCurvePoolEma(uint256 _minimumPrice) external override {
        _requireTimelock();
        _setMinimumCurvePoolEma({ _minimumPrice: _minimumPrice });
    }

    /// @notice The ```setMaximumCurvePoolEma``` function sets the maximum price of frxEth in Ether units of the EMA
    /// @dev Must match precision of the EMA
    /// @param _maximumPrice The maximum price of frxEth in Ether units of the EMA
    function setMaximumCurvePoolEma(uint256 _maximumPrice) external override {
        _requireTimelock();
        _setMaximumCurvePoolEma({ _maximumPrice: _maximumPrice });
    }

    /// @notice The ```setTwapDuration``` function sets the TWAP duration for the Uniswap V3 oracle
    /// @dev Must be called by the timelock
    /// @param _newTwapDuration The new TWAP duration
    function setTwapDuration(uint32 _newTwapDuration) external override {
        _requireTimelock();
        _setTwapDuration({ _newTwapDuration: _newTwapDuration });
    }

    /// @notice The ```setMaximumOracleDelay``` function sets the max oracle delay to determine if Chainlink data is stale
    /// @dev Requires msg.sender to be the timelock address
    /// @param _newMaxOracleDelay The new max oracle delay
    function setMaximumEthUsdOracleDelay(uint256 _newMaxOracleDelay) external override {
        _requireTimelock();
        _setMaximumEthUsdOracleDelay({ _newMaxOracleDelay: _newMaxOracleDelay });
    }

    /// @notice The ```setMaximumFraxUsdOracleDelay``` function sets the max oracle delay to determine if Chainlink data is stale
    /// @dev Must be called by the timelock
    /// @param _newMaxOracleDelay The new max oracle delay
    function setMaximumFraxUsdOracleDelay(uint256 _newMaxOracleDelay) external override {
        _requireTimelock();
        _setMaximumFraxUsdOracleDelay({ _newMaxOracleDelay: _newMaxOracleDelay });
    }

    // ====================================================================
    // Price Source Function
    // ====================================================================

    /// @notice The ```addRoundData``` adds new price data to a FraxOracle
    /// @dev This contract must be whitelisted on the receiver address
    /// @param _fraxOracle Address of a FraxOracle that has this contract set as its priceSource
    function addRoundData(IPriceSourceReceiver _fraxOracle) external {
        (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) = getPrices();
        // Authorization is handled on fraxOracle side
        _fraxOracle.addRoundData({
            isBadData: _isBadData,
            priceLow: uint104(_priceLow),
            priceHigh: uint104(_priceHigh),
            timestamp: uint40(block.timestamp)
        });
    }

    // ====================================================================
    // Price Functions
    // ====================================================================

    /// @notice The ```getWethPerFrxEthCurveEma``` function gets the EMA price of frxEth in weth units
    /// @dev normalized to match precision of oracle
    /// @return _wethPerFrxEth
    function getWethPerFrxEthCurveEma() public view returns (uint256 _wethPerFrxEth) {
        _wethPerFrxEth = _getCurvePoolToken1EmaPrice();

        // Note: ORACLE_PRECISION == CURVE_POOL_EMA_PRICE_ORACLE_PRECISION
        // _wethPerFrxEth = (ORACLE_PRECISION * _getCurvePoolToken1EmaPrice()) / CURVE_POOL_EMA_PRICE_ORACLE_PRECISION;
    }

    /// @notice The ```getUsdPerFraxChainlink``` function gets the Chainlink price of frax in usd units
    /// @dev normalized to match precision of oracle
    /// @return _isBadData Whether the Chainlink data is stale
    /// @return _usdPerFrax
    function getUsdPerFraxChainlink() public view returns (bool _isBadData, uint256 _usdPerFrax) {
        (bool _isBadDataChainlink, , uint256 _usdPerFraxRaw) = _getFraxUsdChainlinkPrice();

        // Set return values
        _isBadData = _isBadDataChainlink;
        _usdPerFrax = (ORACLE_PRECISION * _usdPerFraxRaw) / FRAX_USD_CHAINLINK_FEED_PRECISION;
    }

    /// @notice The ```getUsdPerEthChainlink``` function returns USD per ETH using the Chainlink oracle
    /// @return _isBadData If the Chainlink oracle is stale
    /// @return _usdPerEth The Eth Price is usd units
    function getUsdPerEthChainlink() public view returns (bool _isBadData, uint256 _usdPerEth) {
        (bool _isBadDataChainlink, , uint256 _usdPerEthChainlinkRaw) = _getEthUsdChainlinkPrice();

        // Set return values
        _isBadData = _isBadDataChainlink;
        _usdPerEth = (ORACLE_PRECISION * _usdPerEthChainlinkRaw) / ETH_USD_CHAINLINK_FEED_PRECISION;
    }

    /// @notice The ```getFraxPerFrxEthUniV3Twap``` function gets the TWAP price of frxEth in frax units
    /// @return _fraxPerFrxEthTwap The TWAP price of frxEth in frax units
    function getFraxPerFrxEthUniV3Twap() public view returns (uint256 _fraxPerFrxEthTwap) {
        _fraxPerFrxEthTwap = _getUniswapV3Twap();
    }

    /// @notice The ```getFrxEthPerSfrxEthErc4626Vault``` function gets the price of sfrxEth in frxEth units from the ERC4626 vault
    /// @return _isBadData If the data is stale
    /// @return _frxEthPerSfrxEth The price of sfrxEth in frxEth units
    function getFrxEthPerSfrxEthErc4626Vault() public view returns (bool _isBadData, uint256 _frxEthPerSfrxEth) {
        (bool _isBadData, , uint256 _sfrxEthPerFrxEthChainlinkRaw) = _getFrxEthPerSfrxEthChainlinkPrice();
        _frxEthPerSfrxEth = _sfrxEthPerFrxEthChainlinkRaw;
    }

    /// @notice The ```_getEthUsdChainlinkPrice``` function is called to get the eth/usd price from Chainlink
    /// @dev If data is stale or negative, set bad data to true and return
    /// @return _isBadData If the data is stale
    /// @return _updatedAt The timestamp of the last update
    /// @return _usdPerEth The eth/usd price
    function _getFrxEthPerSfrxEthChainlinkPrice()
        internal
        view
        returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerEth)
    {
        (, int256 _answer, , uint256 _ethUsdChainlinkUpdatedAt, ) = AggregatorV3Interface(
            SFRXETH_FRXETH_CHAINLINK_ORACLE
        ).latestRoundData();

        // If data is stale or negative, set bad data to true and return
        _isBadData = _answer <= 0 || ((block.timestamp - _ethUsdChainlinkUpdatedAt) > maximumEthUsdOracleDelay);
        _updatedAt = _ethUsdChainlinkUpdatedAt;
        _usdPerEth = uint256(_answer);
    }

    /// @notice The ```calculatePrices``` function calculates the normalized prices in a pure function
    /// @return _isBadData True if any of the oracles return stale data
    /// @return _priceLow The normalized low price
    /// @return _priceHigh The normalized high price
    function calculatePrices(
        uint256 _wethPerFrxEthCurveEma,
        uint256 _fraxPerFrxEthTwap,
        bool _isBadDataEthUsdChainlink,
        uint256 _usdPerEthChainlink,
        bool _isBadDataFraxUsdChainlink,
        uint256 _usdPerFraxChainlink,
        bool _isBadDataSfrxEthFrxEthChainlink,
        uint256 _frxEthPerSfrxEth
    ) public view virtual returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        uint256 _frxEthPerUsdCurveChainlink = (ORACLE_PRECISION * ORACLE_PRECISION * ORACLE_PRECISION) /
            (_wethPerFrxEthCurveEma * _usdPerEthChainlink);

        uint256 _frxEthPerUsdTwapChainlink = (ORACLE_PRECISION * ORACLE_PRECISION * ORACLE_PRECISION) /
            (_fraxPerFrxEthTwap * _usdPerFraxChainlink);

        // NOTE: break out these steps to prevent potential overflow
        uint256 _sfrxEthPerUsdCurveChainlink = (ORACLE_PRECISION * _frxEthPerUsdCurveChainlink) / _frxEthPerSfrxEth;
        uint256 _sfrxEthPerUsdTwapChainlink = (ORACLE_PRECISION * _frxEthPerUsdTwapChainlink) / _frxEthPerSfrxEth;

        // Set return values
        _isBadData = _isBadDataEthUsdChainlink || _isBadDataFraxUsdChainlink || _isBadDataSfrxEthFrxEthChainlink;
        _priceLow = _sfrxEthPerUsdCurveChainlink < _sfrxEthPerUsdTwapChainlink
            ? _sfrxEthPerUsdCurveChainlink
            : _sfrxEthPerUsdTwapChainlink;
        _priceHigh = _sfrxEthPerUsdCurveChainlink > _sfrxEthPerUsdTwapChainlink
            ? _sfrxEthPerUsdCurveChainlink
            : _sfrxEthPerUsdTwapChainlink;
    }

    /// @notice The ```getPrices``` function is intended to return two prices from different oracles
    /// @notice Returns the number of wei of the quote token equivalent to 1e18 wei of base token
    /// @return _isBadData is true when data is stale or otherwise bad
    /// @return _priceLow is the lower of the two prices
    /// @return _priceHigh is the higher of the two prices
    function getPrices() public view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        uint256 _wethPerFrxEthCurveEma = getWethPerFrxEthCurveEma();
        uint256 _fraxPerFrxEthTwap = getFraxPerFrxEthUniV3Twap();
        (bool _isBadDataEthUsdChainlink, uint256 _usdPerEthChainlink) = getUsdPerEthChainlink();
        (bool _isBadDataFraxUsdChainlink, uint256 _usdPerFraxChainlink) = getUsdPerFraxChainlink();
        (bool _isBadDataSfrxEthFrxEthChainlink, uint256 _frxEthPerSfrxEth) = getFrxEthPerSfrxEthErc4626Vault();

        (_isBadData, _priceLow, _priceHigh) = calculatePrices({
            _wethPerFrxEthCurveEma: _wethPerFrxEthCurveEma,
            _fraxPerFrxEthTwap: _fraxPerFrxEthTwap,
            _isBadDataEthUsdChainlink: _isBadDataEthUsdChainlink,
            _usdPerEthChainlink: _usdPerEthChainlink,
            _isBadDataFraxUsdChainlink: _isBadDataFraxUsdChainlink,
            _usdPerFraxChainlink: _usdPerFraxChainlink,
            _isBadDataSfrxEthFrxEthChainlink: _isBadDataSfrxEthFrxEthChainlink,
            _frxEthPerSfrxEth: _frxEthPerSfrxEth
        });
    }

    /// @notice The ```getPricesNormalized``` function returns the normalized prices in human readable form
    /// @dev decimals of underlying tokens match so we can just return _getPrices()
    /// @return _isBadDataNormal If the oracle is stale
    /// @return _priceLowNormal The normalized low price
    /// @return _priceHighNormal The normalized high price
    function getPricesNormalized()
        external
        view
        override
        returns (bool _isBadDataNormal, uint256 _priceLowNormal, uint256 _priceHighNormal)
    {
        // NOTE: because precision of both tokens is the same, we can just return the prices
        (_isBadDataNormal, _priceLowNormal, _priceHighNormal) = getPrices();
    }
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.8.0;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================== Timelock2Step ===========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

/// @title Timelock2Step
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @dev Inspired by the OpenZeppelin's Ownable2Step contract
/// @notice  An abstract contract which contains 2-step transfer and renounce logic for a timelock address
abstract contract Timelock2Step {
    /// @notice The pending timelock address
    address public pendingTimelockAddress;

    /// @notice The current timelock address
    address public timelockAddress;

    constructor() {
        timelockAddress = msg.sender;
    }

    /// @notice Emitted when timelock is transferred
    error OnlyTimelock();

    /// @notice Emitted when pending timelock is transferred
    error OnlyPendingTimelock();

    /// @notice The ```TimelockTransferStarted``` event is emitted when the timelock transfer is initiated
    /// @param previousTimelock The address of the previous timelock
    /// @param newTimelock The address of the new timelock
    event TimelockTransferStarted(address indexed previousTimelock, address indexed newTimelock);

    /// @notice The ```TimelockTransferred``` event is emitted when the timelock transfer is completed
    /// @param previousTimelock The address of the previous timelock
    /// @param newTimelock The address of the new timelock
    event TimelockTransferred(address indexed previousTimelock, address indexed newTimelock);

    /// @notice The ```_isSenderTimelock``` function checks if msg.sender is current timelock address
    /// @return Whether or not msg.sender is current timelock address
    function _isSenderTimelock() internal view returns (bool) {
        return msg.sender == timelockAddress;
    }

    /// @notice The ```_requireTimelock``` function reverts if msg.sender is not current timelock address
    function _requireTimelock() internal view {
        if (msg.sender != timelockAddress) revert OnlyTimelock();
    }

    /// @notice The ```_isSenderPendingTimelock``` function checks if msg.sender is pending timelock address
    /// @return Whether or not msg.sender is pending timelock address
    function _isSenderPendingTimelock() internal view returns (bool) {
        return msg.sender == pendingTimelockAddress;
    }

    /// @notice The ```_requirePendingTimelock``` function reverts if msg.sender is not pending timelock address
    function _requirePendingTimelock() internal view {
        if (msg.sender != pendingTimelockAddress) revert OnlyPendingTimelock();
    }

    /// @notice The ```_transferTimelock``` function initiates the timelock transfer
    /// @dev This function is to be implemented by a public function
    /// @param _newTimelock The address of the nominated (pending) timelock
    function _transferTimelock(address _newTimelock) internal {
        pendingTimelockAddress = _newTimelock;
        emit TimelockTransferStarted(timelockAddress, _newTimelock);
    }

    /// @notice The ```_acceptTransferTimelock``` function completes the timelock transfer
    /// @dev This function is to be implemented by a public function
    function _acceptTransferTimelock() internal {
        pendingTimelockAddress = address(0);
        _setTimelock(msg.sender);
    }

    /// @notice The ```_setTimelock``` function sets the timelock address
    /// @dev This function is to be implemented by a public function
    /// @param _newTimelock The address of the new timelock
    function _setTimelock(address _newTimelock) internal {
        emit TimelockTransferred(timelockAddress, _newTimelock);
        timelockAddress = _newTimelock;
    }

    /// @notice The ```transferTimelock``` function initiates the timelock transfer
    /// @dev Must be called by the current timelock
    /// @param _newTimelock The address of the nominated (pending) timelock
    function transferTimelock(address _newTimelock) external virtual {
        _requireTimelock();
        _transferTimelock(_newTimelock);
    }

    /// @notice The ```acceptTransferTimelock``` function completes the timelock transfer
    /// @dev Must be called by the pending timelock
    function acceptTransferTimelock() external virtual {
        _requirePendingTimelock();
        _acceptTransferTimelock();
    }

    /// @notice The ```renounceTimelock``` function renounces the timelock after setting pending timelock to current timelock
    /// @dev Pending timelock must be set to current timelock before renouncing, creating a 2-step renounce process
    function renounceTimelock() external virtual {
        _requireTimelock();
        _requirePendingTimelock();
        _transferTimelock(address(0));
        _setTimelock(address(0));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface ITimelock2Step {
    event TimelockTransferStarted(address indexed previousTimelock, address indexed newTimelock);
    event TimelockTransferred(address indexed previousTimelock, address indexed newTimelock);

    function acceptTransferTimelock() external;

    function pendingTimelockAddress() external view returns (address);

    function renounceTimelock() external;

    function timelockAddress() external view returns (address);

    function transferTimelock(address _newTimelock) external;
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================== DualOracleBase ==========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// ====================================================================

import "interfaces/IDualOracle.sol";

struct ConstructorParams {
    address baseToken0;
    uint8 baseToken0Decimals;
    address quoteToken0;
    uint8 quoteToken0Decimals;
    address baseToken1;
    uint8 baseToken1Decimals;
    address quoteToken1;
    uint8 quoteToken1Decimals;
}

/// @title DualOracleBase
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  Base Contract for Frax Dual Oracles
abstract contract DualOracleBase is IDualOracle {
    /// @notice The precision of the oracle
    uint256 public constant ORACLE_PRECISION = 1e18;

    /// @notice The first quote token
    address public immutable QUOTE_TOKEN_0;

    /// @notice The first quote token decimals
    uint256 public immutable QUOTE_TOKEN_0_DECIMALS;

    /// @notice The second quote token
    address public immutable QUOTE_TOKEN_1;

    /// @notice The second quote token decimals
    uint256 public immutable QUOTE_TOKEN_1_DECIMALS;

    /// @notice The first base token
    address public immutable BASE_TOKEN_0;

    /// @notice The first base token decimals
    uint256 public immutable BASE_TOKEN_0_DECIMALS;

    /// @notice The second base token
    address public immutable BASE_TOKEN_1;

    /// @notice The second base token decimals
    uint256 public immutable BASE_TOKEN_1_DECIMALS;

    /// @notice The first normalization factor which accounts for different decimals across ERC20s
    /// @dev Normalization = quoteTokenDecimals - baseTokenDecimals
    int256 public immutable NORMALIZATION_0;

    /// @notice The second normalization factor which accounts for different decimals across ERC20s
    /// @dev Normalization = quoteTokenDecimals - baseTokenDecimals
    int256 public immutable NORMALIZATION_1;

    constructor(ConstructorParams memory _params) {
        QUOTE_TOKEN_0 = _params.quoteToken0;
        QUOTE_TOKEN_0_DECIMALS = _params.quoteToken0Decimals;
        QUOTE_TOKEN_1 = _params.quoteToken1;
        QUOTE_TOKEN_1_DECIMALS = _params.quoteToken1Decimals;
        BASE_TOKEN_0 = _params.baseToken0;
        BASE_TOKEN_0_DECIMALS = _params.baseToken0Decimals;
        BASE_TOKEN_1 = _params.baseToken1;
        BASE_TOKEN_1_DECIMALS = _params.baseToken1Decimals;
        NORMALIZATION_0 = int256(QUOTE_TOKEN_0_DECIMALS) - int256(BASE_TOKEN_0_DECIMALS);
        NORMALIZATION_1 = int256(QUOTE_TOKEN_1_DECIMALS) - int256(BASE_TOKEN_1_DECIMALS);
    }

    // ====================================================================
    // View Helpers
    // ====================================================================

    function decimals() external pure returns (uint8) {
        return 18;
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ================ CurvePoolEmaPriceOracleWithMinMax =================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

import { ERC165Storage } from "src/contracts/utils/ERC165Storage.sol";
import { ICurvePoolEmaPriceOracleWithMinMax } from "interfaces/oracles/abstracts/ICurvePoolEmaPriceOracleWithMinMax.sol";
import { IEmaPriceOracleStableSwap } from "interfaces/IEmaPriceOracleStableSwap.sol";

struct ConstructorParams {
    address curvePoolEmaPriceOracleAddress;
    uint256 minimumCurvePoolEma;
    uint256 maximumCurvePoolEma;
}

/// @title CurvePoolEmaPriceOracleWithMinMax
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An oracle for getting EMA prices from Curve
abstract contract CurvePoolEmaPriceOracleWithMinMax is ERC165Storage, ICurvePoolEmaPriceOracleWithMinMax {
    /// @notice Curve pool, source of EMA
    address public immutable CURVE_POOL_EMA_PRICE_ORACLE;

    /// @notice Precision of Curve pool price_oracle()
    uint256 public constant CURVE_POOL_EMA_PRICE_ORACLE_PRECISION = 1e18;

    /// @notice Maximum price of token1 in token0 units of the EMA
    /// @dev Must match precision of EMA
    uint256 public minimumCurvePoolEma;

    /// @notice Maximum price of token1 in token0 units of the EMA
    /// @dev Must match precision of EMA
    uint256 public maximumCurvePoolEma;

    constructor(ConstructorParams memory _params) {
        _registerInterface({ interfaceId: type(ICurvePoolEmaPriceOracleWithMinMax).interfaceId });

        CURVE_POOL_EMA_PRICE_ORACLE = _params.curvePoolEmaPriceOracleAddress;
        minimumCurvePoolEma = _params.minimumCurvePoolEma;
        maximumCurvePoolEma = _params.maximumCurvePoolEma;
    }

    /// @notice The ```setMaximumCurvePoolEma``` function sets the maximum price of the EMA
    /// @dev Must match precision of the EMA
    /// @param _maximumPrice The maximum price of the EMA
    function _setMaximumCurvePoolEma(uint256 _maximumPrice) internal {
        emit SetMaximumCurvePoolEma({ oldMaximum: maximumCurvePoolEma, newMaximum: _maximumPrice });
        maximumCurvePoolEma = _maximumPrice;
    }

    function setMaximumCurvePoolEma(uint256 _maximumPrice) external virtual;

    /// @notice The ```setEmaMinimum``` function sets the minimum price of the EMA
    /// @dev Must match precision of the EMA
    /// @param _minimumPrice The minimum price of the EMA
    function _setMinimumCurvePoolEma(uint256 _minimumPrice) internal {
        emit SetMinimumCurvePoolEma({ oldMinimum: minimumCurvePoolEma, newMinimum: _minimumPrice });
        minimumCurvePoolEma = _minimumPrice;
    }

    function setMinimumCurvePoolEma(uint256 _minimumPrice) external virtual;

    function _getCurvePoolToken1EmaPrice() internal view returns (uint256 _token1Price) {
        uint256 _priceRaw = IEmaPriceOracleStableSwap(CURVE_POOL_EMA_PRICE_ORACLE).price_oracle();
        uint256 _price = _priceRaw > maximumCurvePoolEma ? maximumCurvePoolEma : _priceRaw;

        _token1Price = _price < minimumCurvePoolEma ? minimumCurvePoolEma : _price;
    }

    /// @notice The ```getCurvePoolToken1EmaPrice``` function gets the price of the second token in the Curve pool (token1)
    /// @dev Returned in units of the first token (token0)
    /// @return _emaPrice The price of the second token in the Curve pool
    function getCurvePoolToken1EmaPrice() external view returns (uint256 _emaPrice) {
        return _getCurvePoolToken1EmaPrice();
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ================ EthUsdChainlinkOracleWithMaxDelay =================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { ERC165Storage } from "src/contracts/utils/ERC165Storage.sol";
import { IEthUsdChainlinkOracleWithMaxDelay } from "interfaces/oracles/abstracts/IEthUsdChainlinkOracleWithMaxDelay.sol";

struct ConstructorParams {
    address ethUsdChainlinkFeedAddress;
    uint256 maxEthUsdOracleDelay;
}

/// @title EthUsdChainlinkOracleWithMaxDelay
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An abstract oracle for getting eth/usd prices from Chainlink
abstract contract EthUsdChainlinkOracleWithMaxDelay is ERC165Storage, IEthUsdChainlinkOracleWithMaxDelay {
    /// @notice Chainlink aggregator
    address public immutable ETH_USD_CHAINLINK_FEED_ADDRESS;

    /// @notice Decimals of ETH/USD chainlink feed
    uint8 public immutable ETH_USD_CHAINLINK_FEED_DECIMALS;

    /// @notice Precision of ETH/USD chainlink feed
    uint256 public immutable ETH_USD_CHAINLINK_FEED_PRECISION;

    /// @notice Maximum delay of Chainlink data, after which it is considered stale
    uint256 public maximumEthUsdOracleDelay;

    constructor(ConstructorParams memory _params) {
        _registerInterface({ interfaceId: type(IEthUsdChainlinkOracleWithMaxDelay).interfaceId });

        ETH_USD_CHAINLINK_FEED_ADDRESS = _params.ethUsdChainlinkFeedAddress;
        ETH_USD_CHAINLINK_FEED_DECIMALS = AggregatorV3Interface(ETH_USD_CHAINLINK_FEED_ADDRESS).decimals();
        ETH_USD_CHAINLINK_FEED_PRECISION = 10 ** uint256(ETH_USD_CHAINLINK_FEED_DECIMALS);
        maximumEthUsdOracleDelay = _params.maxEthUsdOracleDelay;
    }

    /// @notice The ```_setMaximumEthUsdOracleDelay``` function sets the max oracle delay to determine if Chainlink data is stale
    /// @param _newMaxOracleDelay The new max oracle delay
    function _setMaximumEthUsdOracleDelay(uint256 _newMaxOracleDelay) internal {
        emit SetMaximumEthUsdOracleDelay({
            oldMaxOracleDelay: maximumEthUsdOracleDelay,
            newMaxOracleDelay: _newMaxOracleDelay
        });
        maximumEthUsdOracleDelay = _newMaxOracleDelay;
    }

    function setMaximumEthUsdOracleDelay(uint256 _newMaxOracleDelay) external virtual;

    /// @notice The ```_getEthUsdChainlinkPrice``` function is called to get the eth/usd price from Chainlink
    /// @dev If data is stale or negative, set bad data to true and return
    /// @return _isBadData If the data is stale
    /// @return _updatedAt The timestamp of the last update
    /// @return _usdPerEth The eth/usd price
    function _getEthUsdChainlinkPrice()
        internal
        view
        returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerEth)
    {
        (, int256 _answer, , uint256 _ethUsdChainlinkUpdatedAt, ) = AggregatorV3Interface(
            ETH_USD_CHAINLINK_FEED_ADDRESS
        ).latestRoundData();

        // If data is stale or negative, set bad data to true and return
        _isBadData = _answer <= 0 || ((block.timestamp - _ethUsdChainlinkUpdatedAt) > maximumEthUsdOracleDelay);
        _updatedAt = _ethUsdChainlinkUpdatedAt;
        _usdPerEth = uint256(_answer);
    }

    /// @notice The ```getEthUsdChainlinkPrice``` function is called to get the eth/usd price from Chainlink
    /// @return _isBadData If the data is stale
    /// @return _updatedAt The timestamp of the last update
    /// @return _usdPerEth The eth/usd price
    function getEthUsdChainlinkPrice()
        external
        view
        virtual
        returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerEth)
    {
        (_isBadData, _updatedAt, _usdPerEth) = _getEthUsdChainlinkPrice();
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ================ FraxUsdChainlinkOracleWithMaxDelay =================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { ERC165Storage } from "src/contracts/utils/ERC165Storage.sol";
import { IFraxUsdChainlinkOracleWithMaxDelay } from "interfaces/oracles/abstracts/IFraxUsdChainlinkOracleWithMaxDelay.sol";

struct ConstructorParams {
    address fraxUsdChainlinkFeedAddress;
    uint256 fraxUsdMaximumOracleDelay;
}

/// @title FraxUsdChainlinkOracleWithMaxDelay
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An abstract oracle for getting frax/usd prices from Chainlink
abstract contract FraxUsdChainlinkOracleWithMaxDelay is ERC165Storage, IFraxUsdChainlinkOracleWithMaxDelay {
    /// @notice Chainlink aggregator
    address public immutable FRAX_USD_CHAINLINK_FEED_ADDRESS;

    /// @notice Decimals of FRAX/USD chainlink feed
    uint8 public immutable FRAX_USD_CHAINLINK_FEED_DECIMALS;

    /// @notice Precision of FRAX/USD chainlink feed
    uint256 public immutable FRAX_USD_CHAINLINK_FEED_PRECISION;

    /// @notice Maximum delay of Chainlink data, after which it is considered stale
    uint256 public maximumFraxUsdOracleDelay;

    constructor(ConstructorParams memory _params) {
        _registerInterface({ interfaceId: type(IFraxUsdChainlinkOracleWithMaxDelay).interfaceId });

        FRAX_USD_CHAINLINK_FEED_ADDRESS = _params.fraxUsdChainlinkFeedAddress;
        FRAX_USD_CHAINLINK_FEED_DECIMALS = AggregatorV3Interface(FRAX_USD_CHAINLINK_FEED_ADDRESS).decimals();
        FRAX_USD_CHAINLINK_FEED_PRECISION = 10 ** uint256(FRAX_USD_CHAINLINK_FEED_DECIMALS);
        maximumFraxUsdOracleDelay = _params.fraxUsdMaximumOracleDelay;
    }

    /// @notice The ```_setMaximumFraxUsdOracleDelay``` function sets the max oracle delay to determine if Chainlink data is stale
    /// @param _newMaxOracleDelay The new max oracle delay
    function _setMaximumFraxUsdOracleDelay(uint256 _newMaxOracleDelay) internal {
        emit SetMaximumFraxUsdOracleDelay({
            oldMaxOracleDelay: maximumFraxUsdOracleDelay,
            newMaxOracleDelay: _newMaxOracleDelay
        });
        maximumFraxUsdOracleDelay = _newMaxOracleDelay;
    }

    function setMaximumFraxUsdOracleDelay(uint256 _newMaxOracleDelay) external virtual;

    /// @notice The ```_getFraxUsdChainlinkPrice``` function is called to get the frax/usd price from Chainlink
    /// @dev If data is stale or negative, set bad data to true and return
    /// @return _isBadData If the data is stale
    /// @return _updatedAt The timestamp of the last update
    /// @return _usdPerFrax The frax/usd price
    function _getFraxUsdChainlinkPrice()
        internal
        view
        returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerFrax)
    {
        (, int256 _answer, , uint256 _fraxUsdChainlinkUpdatedAt, ) = AggregatorV3Interface(
            FRAX_USD_CHAINLINK_FEED_ADDRESS
        ).latestRoundData();

        // If data is stale or negative, set bad data to true and return
        _isBadData = _answer <= 0 || ((block.timestamp - _fraxUsdChainlinkUpdatedAt) > maximumFraxUsdOracleDelay);
        _updatedAt = _fraxUsdChainlinkUpdatedAt;
        _usdPerFrax = uint256(_answer);
    }

    /// @notice The ```getFraxUsdChainlinkPrice``` function is called to get the frax/usd price from Chainlink
    /// @return _isBadData If the data is stale
    /// @return _updatedAt The timestamp of the last update
    /// @return _usdPerFrax The frax/usd price
    function getFraxUsdChainlinkPrice()
        external
        view
        virtual
        returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerFrax)
    {
        (_isBadData, _updatedAt, _usdPerFrax) = _getFraxUsdChainlinkPrice();
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ==================== UniswapV3SingleTwapOracle =====================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

import { IStaticOracle } from "@mean-finance/uniswap-v3-oracle/solidity/interfaces/IStaticOracle.sol";
import { ERC165Storage } from "src/contracts/utils/ERC165Storage.sol";
import { IUniswapV3SingleTwapOracle } from "interfaces/oracles/abstracts/IUniswapV3SingleTwapOracle.sol";

struct ConstructorParams {
    address uniswapV3PairAddress;
    uint32 twapDuration;
    address baseToken;
    address quoteToken;
}

/// @title UniswapV3SingleTwapOracle
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An oracle for UniV3 Twap prices
/// @dev When Utilizing this abstract contract ensure that the call to `slot0` returns an `observationCardinality`
///      that is > `twapDuration`/`chainBlockTime`. If this is not the case call `increaseObservationCardinalityNext`
///      with a parameter which satisfies the above requirement. Failing to do so will result in the oracle
///      being suceptible to ddos.
abstract contract UniswapV3SingleTwapOracle is ERC165Storage, IUniswapV3SingleTwapOracle {
    /// @notice address of the Uniswap V3 pair
    address public immutable UNI_V3_PAIR_ADDRESS;

    /// @notice The precision of the twap
    uint128 public constant TWAP_PRECISION = 1e18;

    /// @notice The base token of the twap
    address public immutable UNISWAP_V3_TWAP_BASE_TOKEN;

    /// @notice The quote token of the twap
    address public immutable UNISWAP_V3_TWAP_QUOTE_TOKEN;

    /// @notice The duration of the twap
    uint32 public twapDuration;

    constructor(ConstructorParams memory _params) {
        _registerInterface({ interfaceId: type(IUniswapV3SingleTwapOracle).interfaceId });

        UNI_V3_PAIR_ADDRESS = _params.uniswapV3PairAddress;
        twapDuration = _params.twapDuration;
        UNISWAP_V3_TWAP_BASE_TOKEN = _params.baseToken;
        UNISWAP_V3_TWAP_QUOTE_TOKEN = _params.quoteToken;
    }

    /// @notice The ```_setTwapDuration``` function sets duration of the twap
    /// @param _newTwapDuration The new twap duration
    function _setTwapDuration(uint32 _newTwapDuration) internal {
        emit SetTwapDuration({ oldTwapDuration: twapDuration, newTwapDuration: _newTwapDuration });
        twapDuration = _newTwapDuration;
    }

    function setTwapDuration(uint32 _newTwapDuration) external virtual;

    /// @notice The ```_getUniswapV3Twap``` function is called to get the twap
    /// @return _twap The twap price
    function _getUniswapV3Twap() internal view returns (uint256 _twap) {
        address[] memory _pools = new address[](1);
        _pools[0] = UNI_V3_PAIR_ADDRESS;

        _twap = IStaticOracle(0xB210CE856631EeEB767eFa666EC7C1C57738d438).quoteSpecificPoolsWithTimePeriod({
            baseAmount: TWAP_PRECISION,
            baseToken: UNISWAP_V3_TWAP_BASE_TOKEN,
            quoteToken: UNISWAP_V3_TWAP_QUOTE_TOKEN,
            pools: _pools,
            period: twapDuration
        });
    }

    /// @notice The ```getUniswapV3Twap``` function is called to get the twap
    /// @return _twap The twap price
    function getUniswapV3Twap() external view virtual returns (uint256 _twap) {
        _twap = _getUniswapV3Twap();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IDualOracle is IERC165 {
    function ORACLE_PRECISION() external view returns (uint256);

    function BASE_TOKEN_0() external view returns (address);

    function BASE_TOKEN_0_DECIMALS() external view returns (uint256);

    function BASE_TOKEN_1() external view returns (address);

    function BASE_TOKEN_1_DECIMALS() external view returns (uint256);

    function decimals() external view returns (uint8);

    function getPricesNormalized() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh);

    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh);

    function name() external view returns (string memory);

    function NORMALIZATION_0() external view returns (int256);

    function NORMALIZATION_1() external view returns (int256);

    function QUOTE_TOKEN_0() external view returns (address);

    function QUOTE_TOKEN_0_DECIMALS() external view returns (uint256);

    function QUOTE_TOKEN_1() external view returns (address);

    function QUOTE_TOKEN_1_DECIMALS() external view returns (uint256);
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20;

import { IPriceSourceReceiver } from "./IPriceSourceReceiver.sol";

interface IPriceSource {
    function addRoundData(IPriceSourceReceiver _fraxOracle) external;
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20;

interface IPriceSourceReceiver {
    function addRoundData(bool isBadData, uint104 priceLow, uint104 priceHigh, uint40 timestamp) external;

    function getPrices() external view returns (bool isBadData, uint256 priceLow, uint256 priceHigh);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

// NOTE: This file generated from sfrxEth contract at https://etherscan.io/address/0xac3e018457b222d93114458476f3e3416abbe38f#code
interface ISfrxEth {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function asset() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function decimals() external view returns (uint8);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function depositWithSignature(
        uint256 assets,
        address receiver,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 shares);

    function lastRewardAmount() external view returns (uint192);

    function lastSync() external view returns (uint32);

    function maxDeposit(address) external view returns (uint256);

    function maxMint(address) external view returns (uint256);

    function maxRedeem(address owner) external view returns (uint256);

    function maxWithdraw(address owner) external view returns (uint256);

    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function previewDeposit(uint256 assets) external view returns (uint256);

    function previewMint(uint256 shares) external view returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);

    function previewWithdraw(uint256 assets) external view returns (uint256);

    function pricePerShare() external view returns (uint256);

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

    function rewardsCycleEnd() external view returns (uint32);

    function rewardsCycleLength() external view returns (uint32);

    function symbol() external view returns (string memory);

    function syncRewards() external;

    function totalAssets() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)
pragma solidity ^0.8.0;

import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ICurvePoolEmaPriceOracleWithMinMax is IERC165 {
    event SetMaximumCurvePoolEma(uint256 oldMaximum, uint256 newMaximum);
    event SetMinimumCurvePoolEma(uint256 oldMinimum, uint256 newMinimum);

    function CURVE_POOL_EMA_PRICE_ORACLE() external view returns (address);

    function CURVE_POOL_EMA_PRICE_ORACLE_PRECISION() external view returns (uint256);

    function getCurvePoolToken1EmaPrice() external view returns (uint256 _emaPrice);

    function maximumCurvePoolEma() external view returns (uint256);

    function minimumCurvePoolEma() external view returns (uint256);

    function setMaximumCurvePoolEma(uint256 _maximumPrice) external;

    function setMinimumCurvePoolEma(uint256 _minimumPrice) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

interface IEmaPriceOracleStableSwap {
    function price_oracle() external view returns (uint256);
}

interface IEmaPriceOracleStableSwapNG {
    function price_oracle(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IEthUsdChainlinkOracleWithMaxDelay is IERC165 {
    event SetMaximumEthUsdOracleDelay(uint256 oldMaxOracleDelay, uint256 newMaxOracleDelay);

    function ETH_USD_CHAINLINK_FEED_ADDRESS() external view returns (address);

    function ETH_USD_CHAINLINK_FEED_DECIMALS() external view returns (uint8);

    function ETH_USD_CHAINLINK_FEED_PRECISION() external view returns (uint256);

    function maximumEthUsdOracleDelay() external view returns (uint256);

    function getEthUsdChainlinkPrice() external view returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerEth);

    function setMaximumEthUsdOracleDelay(uint256 _newMaxOracleDelay) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IFraxUsdChainlinkOracleWithMaxDelay is IERC165 {
    event SetMaximumFraxUsdOracleDelay(uint256 oldMaxOracleDelay, uint256 newMaxOracleDelay);

    function FRAX_USD_CHAINLINK_FEED_ADDRESS() external view returns (address);

    function FRAX_USD_CHAINLINK_FEED_DECIMALS() external view returns (uint8);

    function FRAX_USD_CHAINLINK_FEED_PRECISION() external view returns (uint256);

    function maximumFraxUsdOracleDelay() external view returns (uint256);

    function getFraxUsdChainlinkPrice()
        external
        view
        returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerFrax);

    function setMaximumFraxUsdOracleDelay(uint256 _newMaxOracleDelay) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6 <0.9.0;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';

/// @title Uniswap V3 Static Oracle
/// @notice Oracle contract for calculating price quoting against Uniswap V3
interface IStaticOracle {
  /// @notice Returns the address of the Uniswap V3 factory
  /// @dev This value is assigned during deployment and cannot be changed
  /// @return The address of the Uniswap V3 factory
  function UNISWAP_V3_FACTORY() external view returns (IUniswapV3Factory);

  /// @notice Returns how many observations are needed per minute in Uniswap V3 oracles, on the deployed chain
  /// @dev This value is assigned during deployment and cannot be changed
  /// @return Number of observation that are needed per minute
  function CARDINALITY_PER_MINUTE() external view returns (uint8);

  /// @notice Returns all supported fee tiers
  /// @return The supported fee tiers
  function supportedFeeTiers() external view returns (uint24[] memory);

  /// @notice Returns whether a specific pair can be supported by the oracle
  /// @dev The pair can be provided in tokenA/tokenB or tokenB/tokenA order
  /// @return Whether the given pair can be supported by the oracle
  function isPairSupported(address tokenA, address tokenB) external view returns (bool);

  /// @notice Returns all existing pools for the given pair
  /// @dev The pair can be provided in tokenA/tokenB or tokenB/tokenA order
  /// @return All existing pools for the given pair
  function getAllPoolsForPair(address tokenA, address tokenB) external view returns (address[] memory);

  /// @notice Returns a quote, based on the given tokens and amount, by querying all of the pair's pools
  /// @dev If some pools are not configured correctly for the given period, then they will be ignored
  /// @dev Will revert if there are no pools available/configured for the pair and period combination
  /// @param baseAmount Amount of token to be converted
  /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
  /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
  /// @param period Number of seconds from which to calculate the TWAP
  /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
  /// @return queriedPools The pools that were queried to calculate the quote
  function quoteAllAvailablePoolsWithTimePeriod(
    uint128 baseAmount,
    address baseToken,
    address quoteToken,
    uint32 period
  ) external view returns (uint256 quoteAmount, address[] memory queriedPools);

  /// @notice Returns a quote, based on the given tokens and amount, by querying only the specified fee tiers
  /// @dev Will revert if the pair does not have a pool for one of the given fee tiers, or if one of the pools
  /// is not prepared/configured correctly for the given period
  /// @param baseAmount Amount of token to be converted
  /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
  /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
  /// @param feeTiers The fee tiers to consider when calculating the quote
  /// @param period Number of seconds from which to calculate the TWAP
  /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
  /// @return queriedPools The pools that were queried to calculate the quote
  function quoteSpecificFeeTiersWithTimePeriod(
    uint128 baseAmount,
    address baseToken,
    address quoteToken,
    uint24[] calldata feeTiers,
    uint32 period
  ) external view returns (uint256 quoteAmount, address[] memory queriedPools);

  /// @notice Returns a quote, based on the given tokens and amount, by querying only the specified pools
  /// @dev Will revert if one of the pools is not prepared/configured correctly for the given period
  /// @param baseAmount Amount of token to be converted
  /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
  /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
  /// @param pools The pools to consider when calculating the quote
  /// @param period Number of seconds from which to calculate the TWAP
  /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
  function quoteSpecificPoolsWithTimePeriod(
    uint128 baseAmount,
    address baseToken,
    address quoteToken,
    address[] calldata pools,
    uint32 period
  ) external view returns (uint256 quoteAmount);

  /// @notice Will initialize all existing pools for the given pair, so that they can be queried with the given period in the future
  /// @dev Will revert if there are no pools available for the pair and period combination
  /// @param tokenA One of the pair's tokens
  /// @param tokenB The other of the pair's tokens
  /// @param period The period that will be guaranteed when quoting
  /// @return preparedPools The pools that were prepared
  function prepareAllAvailablePoolsWithTimePeriod(
    address tokenA,
    address tokenB,
    uint32 period
  ) external returns (address[] memory preparedPools);

  /// @notice Will initialize the pair's pools with the specified fee tiers, so that they can be queried with the given period in the future
  /// @dev Will revert if the pair does not have a pool for a given fee tier
  /// @param tokenA One of the pair's tokens
  /// @param tokenB The other of the pair's tokens
  /// @param feeTiers The fee tiers to consider when searching for the pair's pools
  /// @param period The period that will be guaranteed when quoting
  /// @return preparedPools The pools that were prepared
  function prepareSpecificFeeTiersWithTimePeriod(
    address tokenA,
    address tokenB,
    uint24[] calldata feeTiers,
    uint32 period
  ) external returns (address[] memory preparedPools);

  /// @notice Will initialize all given pools, so that they can be queried with the given period in the future
  /// @param pools The pools to initialize
  /// @param period The period that will be guaranteed when quoting
  function prepareSpecificPoolsWithTimePeriod(address[] calldata pools, uint32 period) external;

  /// @notice Will increase observations for all existing pools for the given pair, so they start accruing information for twap calculations
  /// @dev Will revert if there are no pools available for the pair and period combination
  /// @param tokenA One of the pair's tokens
  /// @param tokenB The other of the pair's tokens
  /// @param cardinality The cardinality that will be guaranteed when quoting
  /// @return preparedPools The pools that were prepared
  function prepareAllAvailablePoolsWithCardinality(
    address tokenA,
    address tokenB,
    uint16 cardinality
  ) external returns (address[] memory preparedPools);

  /// @notice Will increase the pair's pools with the specified fee tiers observations, so they start accruing information for twap calculations
  /// @dev Will revert if the pair does not have a pool for a given fee tier
  /// @param tokenA One of the pair's tokens
  /// @param tokenB The other of the pair's tokens
  /// @param feeTiers The fee tiers to consider when searching for the pair's pools
  /// @param cardinality The cardinality that will be guaranteed when quoting
  /// @return preparedPools The pools that were prepared
  function prepareSpecificFeeTiersWithCardinality(
    address tokenA,
    address tokenB,
    uint24[] calldata feeTiers,
    uint16 cardinality
  ) external returns (address[] memory preparedPools);

  /// @notice Will increase all given pools observations, so they start accruing information for twap calculations
  /// @param pools The pools to initialize
  /// @param cardinality The cardinality that will be guaranteed when quoting
  function prepareSpecificPoolsWithCardinality(address[] calldata pools, uint16 cardinality) external;

  /// @notice Adds support for a new fee tier
  /// @dev Will revert if the given tier is invalid, or already supported
  /// @param feeTier The new fee tier to add
  function addNewFeeTier(uint24 feeTier) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IUniswapV3SingleTwapOracle is IERC165 {
    event SetTwapDuration(uint256 oldTwapDuration, uint256 newTwapDuration);

    function TWAP_PRECISION() external view returns (uint128);

    function UNISWAP_V3_TWAP_BASE_TOKEN() external view returns (address);

    function UNISWAP_V3_TWAP_QUOTE_TOKEN() external view returns (address);

    function UNI_V3_PAIR_ADDRESS() external view returns (address);

    function getUniswapV3Twap() external view returns (uint256 _twap);

    function twapDuration() external view returns (uint32);

    function setTwapDuration(uint32 _newTwapDuration) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

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
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}