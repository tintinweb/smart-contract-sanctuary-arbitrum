// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "../interfaces/IDerivativeLogic.sol";
import "../libs/LibDerivative.sol";

contract PayoutHelper {
    struct ExecutionPayout {
        uint256 buyerPayout;
        uint256 sellerPayout;
    }

    function getExecutionPayouts(LibDerivative.Derivative calldata _derivative, uint256[] calldata _results)
        external
        view
        returns (ExecutionPayout[] memory executionPayouts)
    {
        IDerivativeLogic logic = IDerivativeLogic(_derivative.syntheticId);

        executionPayouts = new ExecutionPayout[](_results.length);

        for (uint256 i = 0; i < _results.length; i++) {
            (uint256 buyerPayout, uint256 sellerPayout) = logic.getExecutionPayout(_derivative, _results[i]);
            executionPayouts[i] = ExecutionPayout(buyerPayout, sellerPayout);
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "../libs/LibDerivative.sol";

/// @title Opium.Interface.IDerivativeLogic is an interface that every syntheticId should implement
interface IDerivativeLogic {
    // Event with syntheticId metadata JSON string (for DIB.ONE derivative explorer)
    event LogMetadataSet(string metadata);

    /// @notice Validates ticker
    /// @param _derivative Derivative Instance of derivative to validate
    /// @return Returns boolean whether ticker is valid
    function validateInput(LibDerivative.Derivative memory _derivative) external view returns (bool);

    /// @return Returns the custom name of a derivative ticker which will be used as part of the name of its positions
    function getSyntheticIdName() external view returns (string memory);

    /// @notice Calculates margin required for derivative creation
    /// @param _derivative Derivative Instance of derivative
    /// @return buyerMargin uint256 Margin needed from buyer (LONG position)
    /// @return sellerMargin uint256 Margin needed from seller (SHORT position)
    function getMargin(LibDerivative.Derivative memory _derivative)
        external
        view
        returns (uint256 buyerMargin, uint256 sellerMargin);

    /// @notice Calculates payout for derivative execution
    /// @param _derivative Derivative Instance of derivative
    /// @param _result uint256 Data retrieved from oracleId on the maturity
    /// @return buyerPayout uint256 Payout in ratio for buyer (LONG position holder)
    /// @return sellerPayout uint256 Payout in ratio for seller (SHORT position holder)
    function getExecutionPayout(LibDerivative.Derivative memory _derivative, uint256 _result)
        external
        view
        returns (uint256 buyerPayout, uint256 sellerPayout);

    /// @notice Returns syntheticId author address for Opium commissions
    /// @return authorAddress address The address of syntheticId address
    function getAuthorAddress() external view returns (address authorAddress);

    /// @notice Returns syntheticId author commission in base of COMMISSION_BASE
    /// @return commission uint256 Author commission
    function getAuthorCommission() external view returns (uint256 commission);

    /// @notice Returns whether thirdparty could execute on derivative's owner's behalf
    /// @param _derivativeOwner address Derivative owner address
    /// @return Returns boolean whether _derivativeOwner allowed third party execution
    function thirdpartyExecutionAllowed(address _derivativeOwner) external view returns (bool);

    /// @notice Sets whether thirds parties are allowed or not to execute derivative's on msg.sender's behalf
    /// @param _allow bool Flag for execution allowance
    function allowThirdpartyExecution(bool _allow) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

/// @title Opium.Lib.LibDerivative contract should be inherited by contracts that use Derivative structure and calculate derivativeHash
library LibDerivative {
    enum PositionType {
        SHORT,
        LONG
    }

    // Opium derivative structure (ticker) definition
    struct Derivative {
        // Margin parameter for syntheticId
        uint256 margin;
        // Maturity of derivative
        uint256 endTime;
        // Additional parameters for syntheticId
        uint256[] params;
        // oracleId of derivative
        address oracleId;
        // Margin token address of derivative
        address token;
        // syntheticId of derivative
        address syntheticId;
    }

    /// @notice Calculates hash of provided Derivative
    /// @param _derivative Derivative Instance of derivative to hash
    /// @return derivativeHash bytes32 Derivative hash
    function getDerivativeHash(Derivative memory _derivative) internal pure returns (bytes32 derivativeHash) {
        derivativeHash = keccak256(
            abi.encodePacked(
                _derivative.margin,
                _derivative.endTime,
                _derivative.params,
                _derivative.oracleId,
                _derivative.token,
                _derivative.syntheticId
            )
        );
    }
}