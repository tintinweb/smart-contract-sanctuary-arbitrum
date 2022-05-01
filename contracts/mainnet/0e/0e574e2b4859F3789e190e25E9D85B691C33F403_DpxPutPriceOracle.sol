// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";

interface ICrv2Pool is IERC20 {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external returns (uint256);

    function get_virtual_price() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * NOTE: Modified to include symbols and decimals.
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICustomPriceOracle {
    function getPriceInUSD() external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPriceOracle {
    function getCollateralPrice() external view returns (uint256);

    function getUnderlyingPrice() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Interfaces
import {IPriceOracle} from "../../interfaces/IPriceOracle.sol";
import {ICrv2Pool} from "../../external/interfaces/ICrv2Pool.sol";
import {ICustomPriceOracle} from "../../interfaces/ICustomPriceOracle.sol";

contract DpxPutPriceOracle is IPriceOracle {
    /// @dev DPX Price Oracle
    ICustomPriceOracle public constant DPX_PRICE_ORACLE =
        ICustomPriceOracle(0x252C07E0356d3B1a8cE273E39885b094053137b9);

    ICrv2Pool public constant CRV_2POOL =
        ICrv2Pool(0x7f90122BF0700F9E7e1F688fe926940E8839F353);

    /// @notice Returns the collateral price
    function getCollateralPrice() external view returns (uint256) {
        return CRV_2POOL.get_virtual_price() / 1e10;
    }

    /// @notice Returns the underlying price
    function getUnderlyingPrice() external view returns (uint256) {
        return DPX_PRICE_ORACLE.getPriceInUSD();
    }
}