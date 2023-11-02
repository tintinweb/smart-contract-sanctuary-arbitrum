// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IDIAOracleV2 {
    function getValue(
        string memory key
    ) external view returns (uint128, uint128);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPriceOracle {
    function getCollateralPrice() external view returns (uint256);

    function getUnderlyingPrice() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IDIAOracleV2} from "../../../interfaces/IDIAOracleV2.sol";
import {IPriceOracle} from "../../../interfaces/IPriceOracle.sol";

contract RdpxCallPriceOracleV2 is IPriceOracle {
    /// @dev DIA Oracle V2
    IDIAOracleV2 public constant DIA_ORACLE_V2 =
        IDIAOracleV2(0xe871E9BD0ccc595A626f5e1657c216cE457CEa43);

    /// @dev RDPX value key
    string public constant RDPX_VALUE_KEY = "RDPX/USD";

    error HeartbeatNotFulfilled();

    /// @notice Returns the collateral price
    function getCollateralPrice() external view returns (uint256) {
        return getUnderlyingPrice();
    }

    /// @notice Returns the underlying price
    function getUnderlyingPrice() public view returns (uint256) {
        (uint128 price, uint128 updatedAt) = DIA_ORACLE_V2.getValue(
            RDPX_VALUE_KEY
        );

        if ((block.timestamp - uint256(updatedAt)) > 86400) {
            revert HeartbeatNotFulfilled();
        }

        return uint256(price);
    }
}