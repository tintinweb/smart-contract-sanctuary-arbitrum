// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import { IOracle } from '../interfaces/IOracle.sol';

contract SettlementTokenOracle is IOracle {
    function getTwapPriceX128(uint32) external pure returns (uint256 priceX128) {
        priceX128 = 1 << 128;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IOracle {
    function getTwapPriceX128(uint32 twapDuration) external view returns (uint256 priceX128);
}