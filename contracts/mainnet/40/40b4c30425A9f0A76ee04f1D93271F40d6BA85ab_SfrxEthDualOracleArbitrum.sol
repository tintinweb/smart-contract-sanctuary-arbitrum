// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================= sDollaOracleAdapter ========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// ====================================================================

import { Timelock2Step } from "frax-std/access-control/v1/Timelock2Step.sol";
import { ITimelock2Step } from "frax-std/access-control/v1/interfaces/ITimelock2Step.sol";
import { DualOracleBase, ConstructorParams as DualOracleBaseParams } from "../DualOracleBase.sol";
import { ICurvePoolEmaPriceOracleWithMinMax } from "interfaces/oracles/abstracts/ICurvePoolEmaPriceOracleWithMinMax.sol";
import { IEmaPriceOracleStableSwapNG } from "interfaces/IEmaPriceOracleStableSwap.sol";
import { ERC165Storage } from "src/contracts/utils/ERC165Storage.sol";
import { ChainlinkOracleWithMaxDelay, ConstructorParams as ChainlinkOracleWithMaxDelayParams } from "../abstracts/ChainlinkOracleWithMaxDelay.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "interfaces/IDualOracle.sol";

struct ConstructorParams {
    address sFrxErc20;
    address chainlinkSfrxEthRate;
    address chainlinkFrxEthWethHigh;
    address chainlinkFrxEthWethLow;
    address chainlinkWethUSD;
    uint256 maxOracleDelay;
    address timelockAddress;
}

contract SfrxEthDualOracleArbitrum is DualOracleBase, Timelock2Step, ERC165Storage, ChainlinkOracleWithMaxDelay {
    address public immutable sFrxEth;
    AggregatorV3Interface sFrxEthFrxEthRateOracle;
    AggregatorV3Interface frxEthEthLow;
    AggregatorV3Interface frxEthEthHigh;

    constructor(
        ConstructorParams memory _params
    )
        DualOracleBase(
            DualOracleBaseParams({
                baseToken0: address(840),
                baseToken0Decimals: 18,
                quoteToken0: _params.sFrxErc20,
                quoteToken0Decimals: 18,
                baseToken1: address(840),
                baseToken1Decimals: 18,
                quoteToken1: _params.sFrxErc20,
                quoteToken1Decimals: 18
            })
        )
        Timelock2Step()
        ChainlinkOracleWithMaxDelay(
            ChainlinkOracleWithMaxDelayParams({
                chainlinkFeedAddress: _params.chainlinkWethUSD,
                maximumOracleDelay: _params.maxOracleDelay
            })
        )
    {
        _setTimelock({ _newTimelock: _params.timelockAddress });

        sFrxEth = _params.timelockAddress;
        _registerInterface({ interfaceId: type(IDualOracle).interfaceId });
        _registerInterface({ interfaceId: type(ITimelock2Step).interfaceId });
        sFrxEthFrxEthRateOracle = AggregatorV3Interface(_params.chainlinkSfrxEthRate);
        frxEthEthLow = AggregatorV3Interface(_params.chainlinkFrxEthWethLow);
        frxEthEthHigh = AggregatorV3Interface(_params.chainlinkFrxEthWethHigh);
    }

    // ====================================================================
    // View Helpers
    // ====================================================================

    function name() external pure returns (string memory) {
        return "SfrxEth/USD Oracle";
    }

    // ====================================================================
    // Setter Functions
    // ====================================================================

    /// @notice The ```setMaximumOracleDelay``` function sets the max oracle delay to determine if Chainlink data is stale
    /// @dev Requires msg.sender to be the timelock address
    /// @param _newMaxOracleDelay The new max oracle delay
    function setMaximumOracleDelay(uint256 _newMaxOracleDelay) external override {
        _requireTimelock();
        _setMaximumOracleDelay({ _newMaxOracleDelay: _newMaxOracleDelay });
    }

    // ====================================================================
    // Price Functions
    // ====================================================================

    /// @notice The ```getPricesNormalized``` function returns the normalized prices in human readable form
    /// @return _isBadDataNormal If the oracle is stale
    /// @return _priceLowNormal The normalized low price
    /// @return _priceHighNormal The normalized high price
    function getPricesNormalized()
        external
        view
        returns (bool _isBadDataNormal, uint256 _priceLowNormal, uint256 _priceHighNormal)
    {
        (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) = _getPrices();
        _isBadDataNormal = _isBadData;

        _priceLowNormal = NORMALIZATION_0 > 0
            ? _priceLow * 10 ** uint256(NORMALIZATION_0)
            : _priceLow / 10 ** (uint256(-NORMALIZATION_0));

        _priceHighNormal = NORMALIZATION_1 > 0
            ? _priceHigh * 10 ** uint256(NORMALIZATION_1)
            : _priceHigh / 10 ** (uint256(-NORMALIZATION_1));
    }

    /// @notice The ```getPrices``` function is intended to return two prices from different oracles
    /// @return _isBadData is true when data is stale or otherwise bad
    /// @return _priceLow is the lower of the two prices
    /// @return _priceHigh is the higher of the two prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        return _getPrices();
    }

    function _getPrices() internal view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        (bool _isBadDataUsdEth, , uint256 usdPerEth) = _getChainlinkPrice();
        _isBadData = _isBadDataUsdEth;

        /// @notice sfrxEth/frxEth oracle update at much slower frequency --> Fine for borrows
        (, int256 answerRate, , , ) = sFrxEthFrxEthRateOracle.latestRoundData();
        (, int256 answerLow, , , ) = frxEthEthLow.latestRoundData();
        (, int256 answerHigh, , , ) = frxEthEthHigh.latestRoundData();

        if (answerRate < 0) revert AnswerNegative();
        if (answerHigh < 0) revert AnswerNegative();
        if (answerLow < 0) revert AnswerNegative();

        uint256 sfrxEthEthLow = uint256(answerRate * answerLow) / ORACLE_PRECISION;
        uint256 sfrxEthEthHigh = uint256(answerRate * answerHigh) / ORACLE_PRECISION;

        uint256 usdPerSfrxEthLow = (sfrxEthEthLow * usdPerEth) / 1e8;
        uint256 usdPerSfrxEthHigh = (sfrxEthEthHigh * usdPerEth) / 1e8;

        _priceHigh = 1e36 / usdPerSfrxEthLow;
        _priceLow = 1e36 / usdPerSfrxEthHigh;

        /// @notice Chainlink Oracle cadence not fixed, ensure high low invariant
        if (_priceLow > _priceHigh) (_priceHigh, _priceLow) = (_priceLow, _priceHigh);
    }

    error AnswerNegative();
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
// =================== ChainlinkOracleWithMaxDelay ====================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { ERC165Storage } from "src/contracts/utils/ERC165Storage.sol";
import { IChainlinkOracleWithMaxDelay } from "interfaces/oracles/abstracts/IChainlinkOracleWithMaxDelay.sol";

struct ConstructorParams {
    address chainlinkFeedAddress;
    uint256 maximumOracleDelay;
}

/// @title ChainlinkOracleWithMaxDelay
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An abstract oracle for getting prices from Chainlink
abstract contract ChainlinkOracleWithMaxDelay is ERC165Storage, IChainlinkOracleWithMaxDelay {
    /// @notice Chainlink aggregator
    address public immutable CHAINLINK_FEED_ADDRESS;

    /// @notice Decimals of ETH/USD chainlink feed
    uint8 public immutable CHAINLINK_FEED_DECIMALS;

    /// @notice Precision of ETH/USD chainlink feed
    uint256 public immutable CHAINLINK_FEED_PRECISION;

    /// @notice Maximum delay of Chainlink data, after which it is considered stale
    uint256 public maximumOracleDelay;

    constructor(ConstructorParams memory _params) {
        _registerInterface({ interfaceId: type(IChainlinkOracleWithMaxDelay).interfaceId });

        CHAINLINK_FEED_ADDRESS = _params.chainlinkFeedAddress;
        CHAINLINK_FEED_DECIMALS = AggregatorV3Interface(CHAINLINK_FEED_ADDRESS).decimals();
        CHAINLINK_FEED_PRECISION = 10 ** uint256(CHAINLINK_FEED_DECIMALS);
        maximumOracleDelay = _params.maximumOracleDelay;
    }

    /// @notice The ```SetMaximumOracleDelay``` event is emitted when the max oracle delay is set
    /// @param oldMaxOracleDelay The old max oracle delay
    /// @param newMaxOracleDelay The new max oracle delay
    event SetMaximumOracleDelay(uint256 oldMaxOracleDelay, uint256 newMaxOracleDelay);

    /// @notice The ```_setMaximumOracleDelay``` function sets the max oracle delay to determine if Chainlink data is stale
    /// @param _newMaxOracleDelay The new max oracle delay
    function _setMaximumOracleDelay(uint256 _newMaxOracleDelay) internal {
        emit SetMaximumOracleDelay({ oldMaxOracleDelay: maximumOracleDelay, newMaxOracleDelay: _newMaxOracleDelay });
        maximumOracleDelay = _newMaxOracleDelay;
    }

    function setMaximumOracleDelay(uint256 _newMaxOracleDelay) external virtual;

    function _getChainlinkPrice() internal view returns (bool _isBadData, uint256 _updatedAt, uint256 _price) {
        (, int256 _answer, , uint256 _chainlinkUpdatedAt, ) = AggregatorV3Interface(CHAINLINK_FEED_ADDRESS)
            .latestRoundData();

        // If data is stale or negative, set bad data to true and return
        _isBadData = _answer <= 0 || ((block.timestamp - _chainlinkUpdatedAt) > maximumOracleDelay);
        _updatedAt = _chainlinkUpdatedAt;
        _price = uint256(_answer);
    }

    /// @notice The ```getChainlinkPrice``` function returns the chainlink price and the timestamp of the last update
    /// @dev Uses the same prevision as the chainlink feed, virtual so it can be overridden
    /// @return _isBadData True if the data is stale or negative
    /// @return _updatedAt The timestamp of the last update
    /// @return _price The price
    function getChainlinkPrice() external view virtual returns (bool _isBadData, uint256 _updatedAt, uint256 _price) {
        return _getChainlinkPrice();
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IChainlinkOracleWithMaxDelay is IERC165 {
    event SetMaximumOracleDelay(address oracle, uint256 oldMaxOracleDelay, uint256 newMaxOracleDelay);

    function CHAINLINK_FEED_ADDRESS() external view returns (address);

    function CHAINLINK_FEED_DECIMALS() external view returns (uint8);

    function CHAINLINK_FEED_PRECISION() external view returns (uint256);

    function getChainlinkPrice() external view returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerEth);

    function maximumOracleDelay() external view returns (uint256);

    function setMaximumOracleDelay(uint256 _newMaxOracleDelay) external;
}