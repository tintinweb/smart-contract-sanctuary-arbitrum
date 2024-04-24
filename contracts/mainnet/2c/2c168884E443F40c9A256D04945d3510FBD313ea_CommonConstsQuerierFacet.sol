// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase
pragma solidity 0.8.23;

import { LibCommonConsts } from "../../libraries/CommonConsts.sol";
import { ICommonConstsQuerier } from "../interfaces/ICommonConstsQuerier.sol";

contract CommonConstsQuerierFacet is ICommonConstsQuerier {
    function BURN_ADDRESS() external pure override returns (address) {
        return LibCommonConsts.BURN_ADDRESS;
    }

    function BASIS_POINTS() external pure override returns (uint256) {
        return LibCommonConsts.BASIS_POINTS;
    }

    function MULTIPLIER_BASIS() external pure override returns (uint256) {
        return LibCommonConsts.MULTIPLIER_BASIS;
    }

    function REFERRER_BASIS_POINTS() external pure override returns (uint256) {
        return LibCommonConsts.REFERRER_BASIS_POINTS;
    }

    function BURN_BASIS_POINTS() external pure override returns (uint256) {
        return LibCommonConsts.BURN_BASIS_POINTS;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase
pragma solidity 0.8.23;

interface ICommonConstsQuerier {
    function BURN_ADDRESS() external pure returns (address);
    
    function BASIS_POINTS() external pure returns (uint256);

    function MULTIPLIER_BASIS() external pure returns (uint256);

    function REFERRER_BASIS_POINTS() external pure returns (uint256);

    function BURN_BASIS_POINTS() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibCommonConsts {
    uint256 internal constant BASIS_POINTS = 10_000;
    address internal constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 internal constant MULTIPLIER_BASIS = 1e4;
    uint256 internal constant REFERRER_BASIS_POINTS = 2_500;
    uint256 internal constant BURN_BASIS_POINTS = 5_000;
}