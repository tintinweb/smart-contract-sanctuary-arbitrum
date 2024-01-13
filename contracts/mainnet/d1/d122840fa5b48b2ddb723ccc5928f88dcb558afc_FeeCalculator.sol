// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IFeeCalculator} from "./interfaces/IFeeCalculator.sol";
import {ICollateralManager} from "./interfaces/ICollateralManager.sol";
import {Helpers} from "../libraries/Helpers.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Fee Calculator Contract for the USDs Protocol
/// @author Sperax Foundation
/// @dev A contract that calculates fees for minting and redeeming USDs.
contract FeeCalculator is IFeeCalculator {
    struct FeeData {
        uint32 nextUpdate;
        uint16 mintFee;
        uint16 redeemFee;
    }

    uint16 private constant LOWER_THRESHOLD = 5000;
    uint16 private constant UPPER_THRESHOLD = 15000;
    uint16 private constant DISCOUNT_FACTOR = 2;
    uint16 private constant PENALTY_MULTIPLIER = 2;
    uint32 private constant CALIBRATION_GAP = 1 days;

    ICollateralManager public immutable COLLATERAL_MANAGER;

    mapping(address => FeeData) public collateralFee;

    // Events
    event FeeCalibrated(address indexed collateral, uint16 mintFee, uint16 redeemFee);

    // Custom error messages
    error InvalidCalibration();

    constructor(address _collateralManager) {
        COLLATERAL_MANAGER = ICollateralManager(_collateralManager);
        calibrateFeeForAll();
    }

    /// @notice Calibrates fee for a particular collateral
    /// @param _collateral Address of the desired collateral
    function calibrateFee(address _collateral) external {
        if (block.timestamp < collateralFee[_collateral].nextUpdate) {
            revert InvalidCalibration();
        }
        _calibrateFee(_collateral);
    }

    /// @inheritdoc IFeeCalculator
    function getMintFee(address _collateral) external view returns (uint256) {
        return collateralFee[_collateral].mintFee;
    }

    /// @inheritdoc IFeeCalculator
    function getRedeemFee(address _collateral) external view returns (uint256) {
        return collateralFee[_collateral].redeemFee;
    }

    /// @notice Calibrates fee for all the collaterals registered
    function calibrateFeeForAll() public {
        address[] memory collaterals = COLLATERAL_MANAGER.getAllCollaterals();
        uint256 collateralsLength = collaterals.length;
        for (uint256 i; i < collateralsLength;) {
            if (block.timestamp > collateralFee[collaterals[i]].nextUpdate) {
                _calibrateFee(collaterals[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Helper function for calibrating fee for a collateral
    /// @param _collateral Address of the desired collateral
    function _calibrateFee(address _collateral) private {
        // get current stats
        uint256 tvl = IERC20(Helpers.USDS).totalSupply();
        (uint16 baseMintFee, uint16 baseRedeemFee, uint16 composition, uint256 totalCollateral) =
            COLLATERAL_MANAGER.getFeeCalibrationData(_collateral);

        // compute segments
        uint256 desiredCollateralAmt = (tvl * composition) / (Helpers.MAX_PERCENTAGE);
        uint256 lowerLimit = (desiredCollateralAmt * LOWER_THRESHOLD) / (Helpers.MAX_PERCENTAGE);
        uint256 upperLimit = (desiredCollateralAmt * UPPER_THRESHOLD) / (Helpers.MAX_PERCENTAGE);

        FeeData memory updatedFeeData;
        if (totalCollateral < lowerLimit) {
            updatedFeeData = FeeData({
                nextUpdate: uint32(block.timestamp) + CALIBRATION_GAP,
                mintFee: baseMintFee / DISCOUNT_FACTOR,
                redeemFee: baseRedeemFee * PENALTY_MULTIPLIER
            });
        } else if (totalCollateral < upperLimit) {
            updatedFeeData = FeeData({
                nextUpdate: uint32(block.timestamp) + CALIBRATION_GAP,
                mintFee: baseMintFee,
                redeemFee: baseRedeemFee
            });
        } else {
            updatedFeeData = FeeData({
                nextUpdate: uint32(block.timestamp) + CALIBRATION_GAP,
                mintFee: baseMintFee * PENALTY_MULTIPLIER,
                redeemFee: baseRedeemFee / DISCOUNT_FACTOR
            });
        }
        collateralFee[_collateral] = updatedFeeData;
        emit FeeCalibrated(_collateral, updatedFeeData.mintFee, updatedFeeData.redeemFee);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFeeCalculator {
    /// @notice Calculates fee to be collected for minting
    /// @param _collateralAddr Address of the collateral
    /// @return (uint256) baseFeeIn
    function getMintFee(address _collateralAddr) external view returns (uint256);

    /// @notice Calculates fee to be collected for redeeming
    /// @param _collateralAddr Address of the collateral
    /// @return (uint256) baseFeeOut
    function getRedeemFee(address _collateralAddr) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICollateralManager {
    struct CollateralBaseData {
        bool mintAllowed;
        bool redeemAllowed;
        bool allocationAllowed;
        uint16 baseMintFee;
        uint16 baseRedeemFee;
        uint16 downsidePeg;
        uint16 desiredCollateralComposition;
    }

    struct CollateralMintData {
        bool mintAllowed;
        uint16 baseMintFee;
        uint16 downsidePeg;
        uint16 desiredCollateralComposition;
        uint256 conversionFactor;
    }

    struct CollateralRedeemData {
        bool redeemAllowed;
        address defaultStrategy;
        uint16 baseRedeemFee;
        uint16 desiredCollateralComposition;
        uint256 conversionFactor;
    }

    /// @notice Update existing collateral configuration
    /// @param _collateral Address of the collateral
    /// @param _updateData Updated configuration for the collateral
    function updateCollateralData(address _collateral, CollateralBaseData memory _updateData) external;

    function updateCollateralDefaultStrategy(address _collateral, address _strategy) external;

    /// @notice Validate allocation for a collateral
    /// @param _collateral Address of the collateral
    /// @param _strategy Address of the desired strategy
    /// @param _amount Amount to be allocated.
    /// @return True for valid allocation request.
    function validateAllocation(address _collateral, address _strategy, uint256 _amount) external view returns (bool);

    /// @notice Get the required data for mint
    /// @param _collateral Address of the collateral
    /// @return Base fee config for collateral (baseMintFee, baseRedeemFee, composition, totalCollateral)
    function getFeeCalibrationData(address _collateral) external view returns (uint16, uint16, uint16, uint256);

    /// @notice Get the required data for mint
    /// @param _collateral Address of the collateral
    /// @return mintData
    function getMintParams(address _collateral) external view returns (CollateralMintData memory mintData);

    /// @notice Get the required data for USDs redemption
    /// @param _collateral Address of the collateral
    /// @return redeemData
    function getRedeemParams(address _collateral) external view returns (CollateralRedeemData memory redeemData);

    /// @notice Gets list of all the listed collateral
    /// @return address[] of listed collaterals
    function getAllCollaterals() external view returns (address[] memory);

    /// @notice Get the amount of collateral in all Strategies
    /// @param _collateral Address of the collateral
    /// @return amountInStrategies
    function getCollateralInStrategies(address _collateral) external view returns (uint256 amountInStrategies);

    /// @notice Get the amount of collateral in vault
    /// @param _collateral Address of the collateral
    /// @return amountInVault
    function getCollateralInVault(address _collateral) external view returns (uint256 amountInVault);

    /// @notice Verify if a strategy is linked to a collateral
    /// @param _collateral Address of the collateral
    /// @param _strategy Address of the strategy
    /// @return boolean true if the strategy is linked to the collateral
    function isValidStrategy(address _collateral, address _strategy) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title A standard library for errors and constant values
/// @author Sperax Foundation
library Helpers {
    // Constants
    uint16 internal constant MAX_PERCENTAGE = 10000;
    address internal constant SPA = 0x5575552988A3A80504bBaeB1311674fCFd40aD4B;
    address internal constant USDS = 0xD74f5255D557944cf7Dd0E45FF521520002D5748;

    // Errors
    error CustomError(string message);
    error InvalidAddress();
    error GTMaxPercentage(uint256 actual);
    error InvalidAmount();
    error MinSlippageError(uint256 actualAmt, uint256 minExpectedAmt);
    error MaxSlippageError(uint256 actualAmt, uint256 maxExpectedAmt);

    /// @notice Checks the expiry of a transaction's deadline
    /// @param _deadline Deadline specified by the sender of the transaction
    /// @dev Reverts if the current block's timestamp is greater than `_deadline`
    function _checkDeadline(uint256 _deadline) internal view {
        if (block.timestamp > _deadline) revert CustomError("Deadline passed");
    }

    /// @notice Checks for a non-zero address
    /// @param _addr Address to be validated
    /// @dev Reverts if `_addr` is equal to `address(0)`
    function _isNonZeroAddr(address _addr) internal pure {
        if (_addr == address(0)) revert InvalidAddress();
    }

    /// @notice Checks for a non-zero amount
    /// @param _amount Amount to be validated
    /// @dev Reverts if `_amount` is equal to `0`
    function _isNonZeroAmt(uint256 _amount) internal pure {
        if (_amount == 0) revert InvalidAmount();
    }

    /// @notice Checks for a non-zero amount with a custom error message
    /// @param _amount Amount to be validated
    /// @param _err Custom error message
    /// @dev Reverts if `_amount` is equal to `0` with the provided custom error message
    function _isNonZeroAmt(uint256 _amount, string memory _err) internal pure {
        if (_amount == 0) revert CustomError(_err);
    }

    /// @notice Checks whether the `_percentage` is less than or equal to `MAX_PERCENTAGE`
    /// @param _percentage The percentage to be checked
    /// @dev Reverts if `_percentage` is greater than `MAX_PERCENTAGE`
    function _isLTEMaxPercentage(uint256 _percentage) internal pure {
        if (_percentage > MAX_PERCENTAGE) revert GTMaxPercentage(_percentage);
    }

    /// @notice Checks whether the `_percentage` is less than or equal to `MAX_PERCENTAGE` with a custom error message
    /// @param _percentage The percentage to be checked
    /// @param _err Custom error message
    /// @dev Reverts with the provided custom error message if `_percentage` is greater than `MAX_PERCENTAGE`
    function _isLTEMaxPercentage(uint256 _percentage, string memory _err) internal pure {
        if (_percentage > MAX_PERCENTAGE) revert CustomError(_err);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}