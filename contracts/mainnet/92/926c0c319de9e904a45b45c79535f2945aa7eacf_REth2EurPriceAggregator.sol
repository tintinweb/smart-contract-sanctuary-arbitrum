// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../interfaces/IRETH.sol";

/*
 * @notice Returns the EUR price for 1 rETH.
 *
 * @dev Queries the rETH token for its rETH value/rate; then queries the rETH:ETH and ETH:EUR oracle for the price, and
 *      multiplies the results.
 */
contract REth2EurPriceAggregator is AggregatorV3Interface {
    AggregatorV3Interface rETHETHFeed;
    AggregatorV3Interface ETHUSDFeed;
    AggregatorV3Interface EURUSDFeed;
    uint8 rETHETHDecimals;
    uint8 ETHUSDDecimals;
    uint8 EURUSDDecimals;

    constructor(address _rethEthOracle, address _ethUsdOracle, address _eurUsdOracle) {
        rETHETHFeed = AggregatorV3Interface(_rethEthOracle);
        ETHUSDFeed = AggregatorV3Interface(_ethUsdOracle);
        EURUSDFeed = AggregatorV3Interface(_eurUsdOracle);

        // Getting the decimals from each feed
        rETHETHDecimals = rETHETHFeed.decimals();
        ETHUSDDecimals = ETHUSDFeed.decimals();
        EURUSDDecimals = EURUSDFeed.decimals();
    }

    function latestRoundData()
        public
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        // Getting the latest round data from each feed
        (, int256 rETHETHRate, uint256 startedAt_rETHETH, uint256 updatedAt_rETHETH,) = rETHETHFeed.latestRoundData();
        (, int256 ETHUSDRate, uint256 startedAt_ETHUSD, uint256 updatedAt_ETHUSD,) = ETHUSDFeed.latestRoundData();
        (, int256 EURUSDRate, uint256 startedAt_EURUSD, uint256 updatedAt_EURUSD,) = EURUSDFeed.latestRoundData();

        // Normalize the rates to 18 decimals
        rETHETHRate *= int256(10) ** (18 - rETHETHDecimals);
        ETHUSDRate *= int256(10) ** (18 - ETHUSDDecimals);
        EURUSDRate *= int256(10) ** (18 - EURUSDDecimals);

        // Calculate the rETH:EUR rate:
        answer = (rETHETHRate * ETHUSDRate) / EURUSDRate;

        // Earliest startedAt and updatedAt from all feeds
        startedAt = min(startedAt_rETHETH, min(startedAt_ETHUSD, startedAt_EURUSD));
        updatedAt = min(updatedAt_rETHETH, min(updatedAt_ETHUSD, updatedAt_EURUSD));

        // Note: Other return values are set to 0 for simplicity.
        roundId = 0;
        answeredInRound = 0;
    }

    function getRoundData(uint80)
        public
        pure
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        // Throw immediately due to combining price feeds with varied roundIds
        // Query not possible
        require(1 == 0, "No data present");

        // Suppress unused variables warning
        roundId = 0;
        answer = 0;
        startedAt = 0;
        updatedAt = 0;
        answeredInRound = 0;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    // Implementing other functions from AggregatorV3Interface to satisfy the interface requirements
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function description() public pure override returns (string memory) {
        return "rETH to EUR Price Feed";
    }

    function version() public pure override returns (uint256) {
        return 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
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
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRETH is IERC20 {
    function burn(uint256 _rethAmount) external;
    function depositExcess() external payable;
    function depositExcessCollateral() external;
    function getEthValue(uint256 _rethAmount) external view returns (uint256);
    function getRethValue(uint256 _ethAmount) external view returns (uint256);
    function getExchangeRate() external view returns (uint256);
    function getTotalCollateral() external view returns (uint256);
    function getCollateralRate() external view returns (uint256);
    function mint(uint256 _ethAmount, address _to) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}