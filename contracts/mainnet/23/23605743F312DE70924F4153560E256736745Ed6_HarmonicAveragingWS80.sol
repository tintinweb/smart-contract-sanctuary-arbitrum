// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin-v4/contracts/utils/introspection/IERC165.sol";

import "./IAveragingStrategy.sol";

/**
 * @title AbstractAveraging
 * @notice An abstract contract for averaging strategies that implements ERC165.
 */
abstract contract AbstractAveraging is IERC165, IAveragingStrategy {
    // @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAveragingStrategy).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "./AbstractAveraging.sol";

/// @title HarmonicAveraging
/// @notice A strategy for calculating weighted averages using the harmonic mean.
contract HarmonicAveraging is AbstractAveraging {
    /// @inheritdoc IAveragingStrategy
    /// @dev Zero values are replaced with one as we cannot divide by zero.
    function calculateWeightedValue(uint256 value, uint256 weight) external pure override returns (uint256) {
        return _calculateWeightedValue(value, weight);
    }

    /// @inheritdoc IAveragingStrategy
    function calculateWeightedAverage(
        uint256 totalWeightedValues,
        uint256 totalWeight
    ) external pure override returns (uint256) {
        return _calculateWeightedAverage(totalWeightedValues, totalWeight);
    }

    function _calculateWeightedValue(uint256 value, uint256 weight) internal pure virtual returns (uint256) {
        if (value == 0) {
            // We cannot divide by 0, so we use 1 as a substitute
            value = 1;
        }

        return weight / value;
    }

    function _calculateWeightedAverage(
        uint256 totalWeightedValues,
        uint256 totalWeight
    ) internal pure virtual returns (uint256) {
        if (totalWeight == 0) {
            // Ambiguous result, so we revert
            revert TotalWeightCannotBeZero();
        }

        if (totalWeightedValues == 0) {
            // If the total weighted values are 0, then the average must be zero as we know that the total weight is not
            // zero. i.e. all of the values are zero so the average must be zero.
            return 0;
        }

        return totalWeight / totalWeightedValues;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "./HarmonicAveraging.sol";

/// @title HarmonicAveragingWS80
/// @notice A strategy for calculating weighted averages using the harmonic mean, with weights shifted to the left by
///   80 bits.
contract HarmonicAveragingWS80 is HarmonicAveraging {
    function _calculateWeightedValue(uint256 value, uint256 weight) internal pure override returns (uint256) {
        return super._calculateWeightedValue(value, weight << 80);
    }

    function _calculateWeightedAverage(
        uint256 totalWeightedValues,
        uint256 totalWeight
    ) internal pure override returns (uint256) {
        return super._calculateWeightedAverage(totalWeightedValues, totalWeight << 80);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/// @title IAveragingStrategy
/// @notice An interface defining a strategy for calculating weighted averages.
interface IAveragingStrategy {
    /// @notice An error that is thrown when we try calculating a weighted average with a total weight of zero.
    /// @dev A total weight of zero is ambiguous, so we throw an error.
    error TotalWeightCannotBeZero();

    /// @notice Calculates a weighted value.
    /// @param value The value to weight.
    /// @param weight The weight to apply to the value.
    /// @return The weighted value.
    function calculateWeightedValue(uint256 value, uint256 weight) external pure returns (uint256);

    /// @notice Calculates a weighted average.
    /// @param totalWeightedValues The sum of the weighted values.
    /// @param totalWeight The sum of the weights.
    /// @return The weighted average.
    /// @custom:throws TotalWeightCannotBeZero if the total weight is zero.
    function calculateWeightedAverage(uint256 totalWeightedValues, uint256 totalWeight) external pure returns (uint256);
}