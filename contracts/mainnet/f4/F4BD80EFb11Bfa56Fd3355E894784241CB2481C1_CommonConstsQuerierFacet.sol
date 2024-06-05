// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase
pragma solidity 0.8.23;

import { LibCommonConsts } from "../libraries/LibCommonConsts.sol";
import { ICommonConstsQuerier } from "../interfaces/ICommonConstsQuerier.sol";

contract CommonConstsQuerierFacet is ICommonConstsQuerier {
    function BURN_ADDRESS() external pure override returns (address) {
        return LibCommonConsts.BURN_ADDRESS;
    }

    function BASIS_POINTS() external pure override returns (uint256) {
        return LibCommonConsts.BASIS_POINTS;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase
pragma solidity 0.8.23;

interface ICommonConstsQuerier {
    function BURN_ADDRESS() external pure returns (address);

    function BASIS_POINTS() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibCommonConsts {
    uint256 internal constant BASIS_POINTS = 10_000;
    address internal constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /**
        INNER_STRUCT is used for storing inner struct in mappings within diamond storage
     */
    bytes32 internal constant INNER_STRUCT = keccak256("floki.common.consts.inner.struct");
}