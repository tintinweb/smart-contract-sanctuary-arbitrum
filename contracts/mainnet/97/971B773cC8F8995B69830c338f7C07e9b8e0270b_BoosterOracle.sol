// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IUniswapV3Pool.sol";
import "./interfaces/IUniswapV3Factory.sol";

contract BoosterOracle {
    address private constant FACTORY_ADDRESS = 0x1F98431c8aD98523631AE4a59f267346ea31F984; // Uniswap V3 Factory address on the Arbitrum network
    address private constant USDC_ADDRESS = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8; // USDC address on the Arbitrum network
    address private constant DUET_TOKEN_ADDRESS = 0x4d13a9b2E1C6784c6290350d34645DDc7e765808; // USDC address on the Arbitrum network

    uint24 public constant FEE = 10000;

    function getPrice(address token0) public view returns (uint256) {
        IUniswapV3Factory factory = IUniswapV3Factory(FACTORY_ADDRESS);
        address poolAddress = factory.getPool(DUET_TOKEN_ADDRESS, USDC_ADDRESS, FEE);

        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);

        (uint160 sqrtPrice, , , , , , ) = pool.slot0();

        uint256 price = (uint256(sqrtPrice) ** 2 * (10 ** 20)) / (2 ** (96 * 2));

        return price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswapV3Factory {
    function getPool(address, address, uint24) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswapV3Pool {
    function slot0() external view returns (uint160, int24, uint16, uint16, uint16, uint8, bool);
}