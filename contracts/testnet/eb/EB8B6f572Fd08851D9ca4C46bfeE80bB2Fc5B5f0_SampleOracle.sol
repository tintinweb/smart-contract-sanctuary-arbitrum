// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @dev MAKE SURE THIS HAS 10^18 decimals
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data)
        external
        returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data)
        external
        view
        returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/oracle/IOracle.sol";

contract SampleOracle is IOracle {
    uint256 public someNo;
    uint256 public price;
    bool public updated = true;

    constructor() {
        price = 1e18;
    }

    function setPriceForLiquidation() external {
        price = 5e17;
    }

    function setPriceForPossibleLiquidation() external {
        price = 8e17;
    }

    function setAVeryLowPrice() external {
        price = 1e17;
    }

    function setRateTo0() external {
        price = 0;
    }

    function setUpdatedToFalse() external {
        updated = false;
    }

    function get(bytes calldata)
        external
        override
        returns (bool success, uint256 rate)
    {
        someNo = 1; //to avoid "can be restricted to pure" compiler warning
        return (true, price);
    }

    function peek(bytes calldata)
        external
        view
        override
        returns (bool success, uint256 rate)
    {
        return (updated, price);
    }

    function peekSpot(bytes calldata data)
        external
        view
        override
        returns (uint256 rate)
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function symbol(bytes calldata data)
        external
        view
        override
        returns (string memory)
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function name(bytes calldata data)
        external
        view
        override
        returns (string memory)
    // solhint-disable-next-line no-empty-blocks
    {

    }
}