// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Interfaces
import { IVersionFacet } from "../interfaces/IVersionFacet.sol";

/// @title VersionFacet
contract VersionFacet is IVersionFacet {
    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVersionFacet
    function version() external pure returns (string memory) {
        return "6.2.0";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

/// @title IVersionFacet
/// @notice Returns the current implementation version
interface IVersionFacet {
    /// @notice Returns the current implementation version
    function version() external pure returns (string memory);
}