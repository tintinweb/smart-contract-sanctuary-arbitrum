// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IStrategyVelodrome} from "../interfaces/beefy/IStrategyVelodrome.sol";
import {IStrategyUniswapV3} from "../interfaces/beefy/IStrategyUniswapV3.sol";

interface IStrategy {
    function lastPositionAdjustment() external view returns (uint256);
}

// Beefy Position Mulicall
// Contract that returns needed data for our position adjuster
contract BeefyPositionMulticall {

    /**
     * @notice Check if the position of the strategy is in range
     * @param _strategies an array of strategies to check
     * @return inRange an array of booleans indicating if the position is in range
     */
    function isPositionInRange(address[] memory _strategies) external view returns (bool[] memory) {
        bool[] memory inRange = new bool[](_strategies.length);
        for (uint256 i; i < _strategies.length;) {
            IStrategyUniswapV3 _uniStrategy = IStrategyUniswapV3(_strategies[i]);

            try _uniStrategy.positionMain() returns (int24 lowerTick, int24 upperTick) {
                int24 currentTick = _uniStrategy.currentTick();    
                if (currentTick >= lowerTick && currentTick <= upperTick) {
                    inRange[i] = true;
                } else {
                    inRange[i] = false;
                }
            } catch {
                IStrategyVelodrome _veloStrategy = IStrategyVelodrome(_strategies[i]);
                (, int24 lowerTick, int24 upperTick) = _veloStrategy.positionMain();
                int24 currentTick = _veloStrategy.currentTick();
                if (currentTick >= lowerTick && currentTick <= upperTick) {
                    inRange[i] = true;
                } else {
                    inRange[i] = false;
                }
            }
            unchecked { ++i; }
        }
        return inRange;
    }

    /**
     * @notice Check the last time the positions were adjusted
     * @param _strategies an array of strategies to check
     * @return lastAdjustments an array of uint256 indicating the last time the position was adjusted
     */
    function lastPositionAdjustments(address[] memory _strategies) external view returns (uint256[] memory) {
        uint256[] memory lastAdjustments = new uint256[](_strategies.length);
        for (uint256 i; i < _strategies.length;) {
            IStrategy _strategy = IStrategy(_strategies[i]);
            lastAdjustments[i] = _strategy.lastPositionAdjustment();
            unchecked { ++i; }
        }
        return lastAdjustments;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @notice Interface for the Uniswap V3 strategy contract.
interface IStrategyUniswapV3 {

    /// @notice The sqrt price of the pool.
    function sqrtPrice() external view returns (uint160 sqrtPriceX96);
    
    /// @notice The range covered by the strategy.
    function range() external view returns (uint256 lowerPrice, uint256 upperPrice);

    /// @notice Returns the route to swap the first token to the native token for fee harvesting.
    function lpToken0ToNativePath() external view returns (bytes memory);

    /// @notice Returns the route to swap the second token to the native token for fee harvesting.
    function lpToken1ToNativePath() external view returns (bytes memory);

    /// @notice Returns the main position range
    function positionMain() external view returns (int24 lowerTick, int24 upperTick);

    /// @notice Returns the current tick of the pool
    function currentTick() external view returns (int24 tick);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @notice Interface for the Uniswap V3 strategy contract.
interface IStrategyVelodrome {
    /// @notice The sqrt price of the pool.
    function sqrtPrice() external view returns (uint160 sqrtPriceX96);
    
    /// @notice The range covered by the strategy.
    function range() external view returns (uint256 lowerPrice, uint256 upperPrice);

     /// @notice Returns the main position range
    function positionMain() external view returns (uint256 nftId, int24 lowerTick, int24 upperTick);

    /// @notice Returns the current tick of the pool
    function currentTick() external view returns (int24 tick);
}