// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Denominations {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
  address public constant USD = address(840);
  address public constant GBP = address(826);
  address public constant EUR = address(978);
  address public constant JPY = address(392);
  address public constant KRW = address(410);
  address public constant CNY = address(156);
  address public constant AUD = address(36);
  address public constant CAD = address(124);
  address public constant CHF = address(756);
  address public constant ARS = address(32);
  address public constant PHP = address(608);
  address public constant NZD = address(554);
  address public constant SGD = address(702);
  address public constant NGN = address(566);
  address public constant ZAR = address(710);
  address public constant RUB = address(643);
  address public constant INR = address(356);
  address public constant BRL = address(986);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

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
pragma abicoder v2;

import "./AggregatorV2V3Interface.sol";

interface FeedRegistryInterface {
  struct Phase {
    uint16 phaseId;
    uint80 startingAggregatorRoundId;
    uint80 endingAggregatorRoundId;
  }

  event FeedProposed(
    address indexed asset,
    address indexed denomination,
    address indexed proposedAggregator,
    address currentAggregator,
    address sender
  );
  event FeedConfirmed(
    address indexed asset,
    address indexed denomination,
    address indexed latestAggregator,
    address previousAggregator,
    uint16 nextPhaseId,
    address sender
  );

  // V3 AggregatorV3Interface

  function decimals(address base, address quote) external view returns (uint8);

  function description(address base, address quote) external view returns (string memory);

  function version(address base, address quote) external view returns (uint256);

  function latestRoundData(address base, address quote)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function getRoundData(
    address base,
    address quote,
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

  // V2 AggregatorInterface

  function latestAnswer(address base, address quote) external view returns (int256 answer);

  function latestTimestamp(address base, address quote) external view returns (uint256 timestamp);

  function latestRound(address base, address quote) external view returns (uint256 roundId);

  function getAnswer(
    address base,
    address quote,
    uint256 roundId
  ) external view returns (int256 answer);

  function getTimestamp(
    address base,
    address quote,
    uint256 roundId
  ) external view returns (uint256 timestamp);

  // Registry getters

  function getFeed(address base, address quote) external view returns (AggregatorV2V3Interface aggregator);

  function getPhaseFeed(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (AggregatorV2V3Interface aggregator);

  function isFeedEnabled(address aggregator) external view returns (bool);

  function getPhase(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (Phase memory phase);

  // Round helpers

  function getRoundFeed(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (AggregatorV2V3Interface aggregator);

  function getPhaseRange(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (uint80 startingRoundId, uint80 endingRoundId);

  function getPreviousRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (uint80 previousRoundId);

  function getNextRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (uint80 nextRoundId);

  // Feed management

  function proposeFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  function confirmFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  // Proposed aggregator

  function getProposedFeed(address base, address quote)
    external
    view
    returns (AggregatorV2V3Interface proposedAggregator);

  function proposedGetRoundData(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function proposedLatestRoundData(address base, address quote)
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // Phases
  function getCurrentPhaseId(address base, address quote) external view returns (uint16 currentPhaseId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/Denominations.sol";
import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";

import "./base/PriceGateway.sol";
import "./lib/Constant.sol";

contract ArbitrumChainlinkPriceGateway is PriceGateway {
    /// @custom:oz-upgrades-unsafe-allow constructor
    string public constant override name = "Arbitrum Chainlink Price Gateway";

    error StaleRoundId(uint80 roundID, uint80 answeredInRound);
    error StaleTimestamp(uint256 currentTimeStamp, uint256 updatedAtTimeStamp);
    error InvaildDecimal(uint8 decimals);
    constructor() {
    }

    /// @notice inherited from PriceGateway, help to check the imported pair support or not
    /// @dev Custom price gateway is allowed, but need to implement priceGateway.sol and set by govern
    /// @param asset the asset token address, support ETH , WETH and other ERC20
    /// @param base the base token address, support ETH , WETH and other ERC20
    /// @return boolean Is support or not
    function isSupportedPair(address asset, address base)
        public
        virtual
        view
        override
        returns (bool)
    {
        return canResolvePrice(asset) && canResolvePrice(base);
    }

    /// @notice inherited from PriceGateway, to cal the asset price base on different token
    /// @dev For those outside contract , Please used this as the entry point
    /// @dev this Function will help to route the calculate to other cal function,
    /// @dev Please do not directly call the below cal function
    /// @param asset the asset token address, support ETH , WETH and other ERC20
    /// @param base the base token address, support ETH , WETH and other ERC20
    /// @param amount the amount of asset, in asset decimal
    /// @return uint256 the Asset Price in term of base token in base token decimal
    function assetPrice(
        address asset,
        address base,
        uint256 amount
    ) public view virtual override returns (uint256) {
        asset = asset == _WETH9() ? Denominations.ETH : asset;
        base = base == _WETH9() ? Denominations.ETH : base;
        // Feed Registry doesn't provide any WETH Price Feed, redirect to ETH case here

        if (asset == base) return amount;

        if (base == Denominations.USD) {
            return assetUSDPrice(asset, amount);
        }

        if (asset == Denominations.USD) {
            return usdAssetPrice(base, amount);
        }

        return derivedAssetPrice(asset, base, amount);
    }

    /// @notice Get Asset Price in Term of USD
    /// @dev Get the rate in Chainlink and scale the Price to decimal 8
    /// @param asset the asset token address, support ETH , WETH and other ERC20
    /// @param amount Asset Amount in term of asset's decimal
    /// @return uint256 the Asset Price in term of USD with hardcoded decimal 8
    function assetUSDPrice(address asset, uint256 amount)
        public
        view
        virtual
        returns (uint256)
    {
        if (asset == Denominations.USD) return amount;
        asset = asset == _WETH9() ? Denominations.ETH : asset;

        (
            uint80 roundID,
            int256 price,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = FeedRegistryInterface(Constant.FEED_REGISTRY).latestRoundData(
                asset,
                Denominations.USD
            );
        uint8 priceDecimals = FeedRegistryInterface(Constant.FEED_REGISTRY)
            .decimals(asset, Denominations.USD);


        if (answeredInRound < roundID) {
            revert StaleRoundId(roundID, answeredInRound);
        }
        if (block.timestamp > updatedAt + Constant.STALE_PRICE_DELAY) {
            revert StaleTimestamp(block.timestamp, updatedAt);
        }

        price = scalePrice(
            price,
            priceDecimals,
            8 /* USD decimals */
        );

        if (price > 0) {
            // return price with decimal = price Decimal (8) + amount decimal (Asset decimal) - Asset decimal = price decimal(8)
            return
                (uint256(price) * amount) /
                10**assetDecimals(asset);
        }

        return 0;
    }

    /// @notice Get USD Price in term of Asset
    /// @dev Get the rate in Chainlink and scale the Price to asset decimal
    /// @param asset the asset token address, support ETH , WETH and other ERC20, used as base token address
    /// @param usdAmount Usd Amount with 8 decimal (arbitrum)
    /// @return uint256 the price by using asset as base with assets decimal
    function usdAssetPrice(address asset, uint256 usdAmount)
        public
        view
        virtual
        returns (uint256)
    {
        if (asset == Denominations.USD) return usdAmount;
        asset = asset == _WETH9() ? Denominations.ETH : asset;
        (
            uint80 roundID,
            int256 price,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = FeedRegistryInterface(Constant.FEED_REGISTRY).latestRoundData(
                asset,
                Denominations.USD
            );
        uint8 priceDecimals = FeedRegistryInterface(Constant.FEED_REGISTRY)
            .decimals(asset, Denominations.USD);

        if (answeredInRound < roundID) {
            revert StaleRoundId(roundID, answeredInRound);
        }
        if (block.timestamp > updatedAt + Constant.STALE_PRICE_DELAY) {
            revert StaleTimestamp(block.timestamp, updatedAt);
        }

        price = scalePrice(
            price,
            priceDecimals,
            8 /* USD decimals */
        );
        if (price > 0) {
            // return price with decimal = 8 + asset Decimal - price Decimal (8) = asset Decimal
            return
                (usdAmount * (10**assetDecimals(asset))) /
                uint256(price);
        }

        return 0;
    }

    function derivedAssetPrice(
        address asset,
        address base,
        uint256 amount
    ) public view virtual returns (uint256) {
        int256 rate = getDerivedPrice(
            asset,
            base,
            18 /* ETH decimals */
        );

        if (rate > 0) {
            return
                uint256(
                    scalePrice(
                        int256(rate) * int256(amount),
                        18 + assetDecimals(asset),
                        assetDecimals(base)
                    )
                );
        }
        return 0;
    }

    function getDerivedPrice(
        address _base,
        address _quote,
        uint8 _decimals
    ) internal view virtual returns (int256) {
        if (_decimals <= uint8(0) || _decimals > uint8(18)) {
            revert InvaildDecimal(_decimals);
        }
        int256 decimals = int256(10**uint256(_decimals));
        (
            uint80 _baseRoundID,
            int256 basePrice,
            ,
            uint256 _baseUpdatedAt,
            uint80 _baseAnsweredInRound
        ) = FeedRegistryInterface(Constant.FEED_REGISTRY).latestRoundData(
                _base,
                Denominations.USD
            );

        if (_baseAnsweredInRound < _baseRoundID) {
            revert StaleRoundId(_baseAnsweredInRound, _baseRoundID);
        }
        if (block.timestamp > _baseUpdatedAt + Constant.STALE_PRICE_DELAY) {
            revert StaleTimestamp(block.timestamp, _baseUpdatedAt);
        }

        uint8 baseDecimals = FeedRegistryInterface(Constant.FEED_REGISTRY)
            .decimals(_base, Denominations.USD);
        basePrice = scalePrice(basePrice, baseDecimals, _decimals);
        (
            uint80 _quoteRoundID,
            int256 quotePrice,
            ,
            uint256 _quoteUpdatedAt,
            uint80 _quoteAnsweredInRound
        ) = FeedRegistryInterface(Constant.FEED_REGISTRY).latestRoundData(
                _quote,
                Denominations.USD
            );
        if (_quoteAnsweredInRound < _quoteRoundID) {
            revert StaleRoundId(_quoteAnsweredInRound, _quoteRoundID);
        }
        if (block.timestamp > _quoteUpdatedAt + Constant.STALE_PRICE_DELAY) {
            revert StaleTimestamp(block.timestamp, _quoteUpdatedAt);
        }

        uint8 quoteDecimals = FeedRegistryInterface(Constant.FEED_REGISTRY)
            .decimals(_quote, Denominations.USD);
        quotePrice = scalePrice(quotePrice, quoteDecimals, _decimals);

        return (basePrice * decimals) / quotePrice;
    }

    function scalePrice(
        int256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure virtual returns (int256) {
        
        if (_priceDecimals < _decimals) {
            return _price * int256(10**uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10**uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

    function canResolvePrice(address asset) internal view returns (bool) {
        if (asset == Denominations.USD) return true;

        if (asset == _WETH9()) {
            // Feed Registry doesn't provide any WETH Price Feed, redirect to ETH case here
            asset = Denominations.ETH;
        }

        try
            FeedRegistryInterface(Constant.FEED_REGISTRY).getFeed(
                asset,
                Denominations.USD
            )
        {
            return true;
        } catch (bytes memory) {
            return false;
        }
    }

    function assetDecimals(address asset) public view virtual returns (uint8) {
        if (asset == Denominations.ETH) return 18;
        if (asset == Denominations.USD) return 8;
        try IERC20Metadata(asset).decimals() returns (uint8 _decimals) {
            return _decimals;
        } catch {
            return 0;
        }
    }

    function _WETH9() internal pure returns (address) {
        return Constant.WETH_ADDRESS;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

abstract contract PriceGateway {
    function isSupportedPair(address asset, address base)
        public
        view
        virtual
        returns (bool)
    {}

    function assetPrice(
        address asset,
        address base,
        uint256 amount
    ) public view virtual returns (uint256) {}

    function name() external virtual returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

library Constant {
    bytes32 public constant BEACON_NAME_DAO = bytes32(keccak256("adam.dao"));
    bytes32 public constant BEACON_NAME_MEMBERSHIP = bytes32(keccak256("adam.dao.membership"));
    bytes32 public constant BEACON_NAME_MEMBER_TOKEN = bytes32(keccak256("adam.dao.member_token"));
    bytes32 public constant BEACON_NAME_LIQUID_POOL = bytes32(keccak256("adam.dao.liquid_pool"));
    bytes32 public constant BEACON_NAME_GOVERN = bytes32(keccak256("adam.dao.govern"));
    bytes32 public constant BEACON_NAME_TEAM = bytes32(keccak256("adam.dao.team"));
    bytes32 public constant BEACON_NAME_ACCOUNTING_SYSTEM = bytes32(keccak256("adam.dao.accounting_system"));

    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant UNISWAP_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address public constant FEED_REGISTRY = 0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf;
    address public constant BRIDGE_CURRENCY = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint public constant BLOCK_NUMBER_IN_SECOND = 12;
    uint public constant STALE_PRICE_DELAY = 86400;
}