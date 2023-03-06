// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../dex/DexAggregatorInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BatchQueryHelper {

    constructor ()
    {
    }

    struct PriceVars {
        uint256 price;
        uint8 decimal;
    }

    struct LiqVars {
        uint256 token0Liq;
        uint256 token1Liq;
        uint256 token0TwaLiq;
        uint256 token1TwaLiq;
    }

    struct PoolVars {
        uint128 liquidity;
        TicketVars[] tickets;
    }

    struct TicketVars {
        int128 liquidityNet;
        int24 tick;
    }

    function getPrices(DexAggregatorInterface dexAgg, address[] calldata token0s, address[] calldata token1s, bytes[] calldata dexDatas) external view returns (PriceVars[] memory results){
        results = new PriceVars[](token0s.length);
        for (uint i = 0; i < token0s.length; i++) {
            PriceVars memory item;
            (item.price, item.decimal) = dexAgg.getPrice(token0s[i], token1s[i], dexDatas[i]);
            results[i] = item;
        }
        return results;
    }

    function getLiqs(IOPBorrowing opBorrowing, uint16[] calldata markets, address[] calldata pairs, address[] calldata token0s, address[] calldata token1s) external view returns (LiqVars[] memory results){
        require(markets.length == pairs.length && token0s.length == token1s.length && markets.length == token0s.length, "length error");
        results = new LiqVars[](markets.length);
        for (uint i = 0; i < markets.length; i++) {
            LiqVars memory item;
            item.token0Liq = IERC20(token0s[i]).balanceOf(pairs[i]);
            item.token1Liq = IERC20(token1s[i]).balanceOf(pairs[i]);
            (item.token0TwaLiq, item.token1TwaLiq) = opBorrowing.twaLiquidity(markets[i]);
            results[i] = item;
        }
        return results;
    }

    function getV3Tickets(IUniswapV3Pool[] calldata pairs, uint16[] calldata spacings, int24[] calldata minTickets, int24[] calldata maxTickets) external view returns (PoolVars[] memory results){
        uint length = pairs.length;
        require(minTickets.length == length && maxTickets.length == length && spacings.length == length, "length error");
        results = new PoolVars[](length);
        for (uint i = 0; i < length; i++) {
            PoolVars memory item;
            IUniswapV3Pool pair = pairs[i];
            item.liquidity = pair.liquidity();
            uint ticketsLength = (uint256)(maxTickets[i] - minTickets[i])/spacings[i];
            TicketVars[] memory tickets = new TicketVars[](ticketsLength);
            for(uint j = 0; j < ticketsLength; j++){
                TicketVars memory t;
                t.tick = minTickets[i] + (int24)(j * spacings[i]);
                t.liquidityNet = pair.ticks(t.tick);
                tickets[j] = t;
            }
            item.tickets = tickets;
            results[i] = item;
        }
        return results;
    }

    function getV3CurTickets(IUniswapV3Pool[] calldata pairs) external view returns (int24[] memory results){
        results = new int24[](pairs.length);
        for (uint i = 0; i < pairs.length; i++) {
            (,int24 tick,,,,,) = pairs[i].slot0();
            results[i] = tick;
        }
        return results;
    }

}

interface IOPBorrowing {
    function twaLiquidity(uint16 marketId) external view returns (uint token0Liq, uint token1Liq);
}

interface IUniswapV3Pool {
    function liquidity() external view returns (uint128);
    function ticks(int24) external view returns (int128 liquidityNet);
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

interface DexAggregatorInterface {

    function sell(address buyToken, address sellToken, uint sellAmount, uint minBuyAmount, bytes memory data) external returns (uint buyAmount);

    function sellMul(uint sellAmount, uint minBuyAmount, bytes memory data) external returns (uint buyAmount);

    function buy(address buyToken, address sellToken, uint24 buyTax, uint24 sellTax, uint buyAmount, uint maxSellAmount, bytes memory data) external returns (uint sellAmount);

    function calBuyAmount(address buyToken, address sellToken, uint24 buyTax, uint24 sellTax, uint sellAmount, bytes memory data) external view returns (uint);

    function calSellAmount(address buyToken, address sellToken, uint24 buyTax, uint24 sellTax, uint buyAmount, bytes memory data) external view returns (uint);

    function getPrice(address desToken, address quoteToken, bytes memory data) external view returns (uint256 price, uint8 decimals);

    function getAvgPrice(address desToken, address quoteToken, uint32 secondsAgo, bytes memory data) external view returns (uint256 price, uint8 decimals, uint256 timestamp);

    //cal current avg price and get history avg price
    function getPriceCAvgPriceHAvgPrice(address desToken, address quoteToken, uint32 secondsAgo, bytes memory dexData) external view returns (uint price, uint cAvgPrice, uint256 hAvgPrice, uint8 decimals, uint256 timestamp);

    function updatePriceOracle(address desToken, address quoteToken, uint32 timeWindow, bytes memory data) external returns(bool);

    function updateV3Observation(address desToken, address quoteToken, bytes memory data) external;

    function setDexInfo(uint8[] memory dexName, IUniswapV2Factory[] memory factoryAddr, uint16[] memory fees) external;

    function getToken0Liquidity(address token0, address token1, bytes memory dexData) external view returns (uint);

    function getPairLiquidity(address token0, address token1, bytes memory dexData) external view returns (uint token0Liq, uint token1Liq);
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}