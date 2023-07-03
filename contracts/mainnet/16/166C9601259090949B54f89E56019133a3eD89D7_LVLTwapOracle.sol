// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FixedPoint} from "../lib/FixedPoint.sol";
import {PairOracleTWAP, PairOracle} from "../lib/PairOracleTWAP.sol";
import {IUniswapV2Pair} from "../interfaces/IUniswapV2Pair.sol";

contract LVLTwapOracle {
    using PairOracleTWAP for PairOracle;

    uint256 private constant PRECISION = 1e6;

    address public updater;
    uint256 public lastTWAP;

    PairOracle public lvlUsdtPair;

    constructor(address _lvl, address _lvlUsdtPair, address _updater) {
        require(_lvl != address(0), "invalid address");
        require(_lvlUsdtPair != address(0), "invalid address");
        require(_updater != address(0), "invalid address");
        lvlUsdtPair = PairOracle({
            pair: IUniswapV2Pair(_lvlUsdtPair),
            token: _lvl,
            priceAverage: FixedPoint.uq112x112(0),
            lastBlockTimestamp: 0,
            priceCumulativeLast: 0,
            lastTWAP: 0
        });
        updater = _updater;
    }

    // =============== VIEW FUNCTIONS ===============

    function getCurrentTWAP() public view returns (uint256) {
        // round to 1e12
        return lvlUsdtPair.currentTWAP() * PRECISION;
    }

    // =============== USER FUNCTIONS ===============

    function update() external {
        require(msg.sender == updater, "!updater");
        lvlUsdtPair.update();
        lastTWAP = lvlUsdtPair.lastTWAP;
        emit PriceUpdated(block.timestamp, lastTWAP);
    }

    // ===============  EVENTS ===============
    event PriceUpdated(uint256 timestamp, uint256 price);
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

pragma solidity 0.8.18;

import "./Babylonian.sol";

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = uint256(1) << RESOLUTION;
    uint256 private constant Q224 = Q112 << RESOLUTION;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z;
        require(y == 0 || (z = uint256(self._x) * y) / y == uint256(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, "FixedPoint: ZERO_RECIPROCAL");
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}

pragma solidity 0.8.18;

import {FixedPoint} from "./FixedPoint.sol";
import {IUniswapV2Pair} from "../interfaces/IUniswapV2Pair.sol";
import {UniswapV2OracleLibrary} from "./UniswapV2OracleLibrary.sol";

struct PairOracle {
    IUniswapV2Pair pair;
    address token;
    FixedPoint.uq112x112 priceAverage;
    uint256 lastBlockTimestamp;
    uint256 priceCumulativeLast;
    uint256 lastTWAP;
}

library PairOracleTWAP {
    using FixedPoint for *;

    uint256 constant PRECISION = 1e18; // 1 LVL

    function currentTWAP(PairOracle storage self) internal view returns (uint256) {
        if (self.lastBlockTimestamp == 0) {
            return 0;
        }

        (uint256 price0Cumulative, uint256 price1Cumulative,) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(self.pair));

        // Overflow is desired, casting never truncates
        unchecked {
            uint256 currentBlockTimestamp = block.timestamp % 2 ** 32;
            uint256 timeElapsed = currentBlockTimestamp - self.lastBlockTimestamp; // Overflow is desired
            FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
                uint224(
                    (
                        (self.token == self.pair.token0() ? price0Cumulative : price1Cumulative)
                            - self.priceCumulativeLast
                    ) / timeElapsed
                )
            );
            return priceAverage.mul(PRECISION).decode144();
        }
    }

    function update(PairOracle storage self) internal {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint256 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(self.pair));

        uint256 newPriceCumulativeLast = self.token == self.pair.token0() ? price0Cumulative : price1Cumulative;

        // Overflow is desired, casting never truncates
        unchecked {
            uint256 timeElapsed = blockTimestamp - self.lastBlockTimestamp; // Overflow is desired
            // Cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
            self.priceAverage =
                FixedPoint.uq112x112(uint224((newPriceCumulativeLast - self.priceCumulativeLast) / timeElapsed));
            self.priceCumulativeLast = newPriceCumulativeLast;
        }

        if (self.lastBlockTimestamp != 0) {
            self.lastTWAP = self.priceAverage.mul(PRECISION).decode144();
        }
        self.lastBlockTimestamp = blockTimestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

pragma experimental ABIEncoderV2;

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function getTokenWeights() external view returns (uint32 tokenWeight0, uint32 tokenWeight1);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

pragma solidity 0.8.18;

import {FixedPoint} from "./FixedPoint.sol";
import {IUniswapV2Pair} from "../interfaces/IUniswapV2Pair.sol";

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(address pair)
        internal
        view
        returns (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp)
    {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint256(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}