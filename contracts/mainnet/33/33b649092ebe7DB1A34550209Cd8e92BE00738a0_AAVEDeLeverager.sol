pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./IERC20.sol";

import "./ILendingPool.sol";

contract AAVEDeLeverager {
    using SafeMath for uint256;

    uint256 public constant BORROW_RATIO_DECIMALS = 4;

    /// @notice Lending Pool address
    ILendingPool public lendingPool;

    constructor(ILendingPool _lendingPool) {
        lendingPool = _lendingPool;
    }

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory) {
        return lendingPool.getConfiguration(asset);
    }

    /**
     * @dev Returns variable debt token address of asset
     * @param asset The address of the underlying asset of the reserve
     * @return varaiableDebtToken address of the asset
     **/
    function getVDebtToken(address asset) public view returns (address) {
        DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(asset);
        return reserveData.variableDebtTokenAddress;
    }

    /**
     * @dev Returns interest bearing token address of the token supplied
     * @param asset The address of the underlying asset of the reserve
     * @return aTokenAddress address of the asset
     **/
    function getAToken(address asset) public view returns (address) {
        DataTypes.ReserveData memory reserveData = lendingPool.getReserveData(asset);
        return reserveData.aTokenAddress;
    }

    /**
     * @dev Returns loan to value
     * @param asset The address of the underlying asset of the reserve
     * @return ltv of the asset
     **/
    function ltv(address asset) public view returns (uint256) {
        DataTypes.ReserveConfigurationMap memory conf =  lendingPool.getConfiguration(asset);
        return conf.data % (2 ** 16);
    }

    /**
     * @dev Loop the deposit and borrow of an asset
     * @param asset for loop
     * @param amount for the initial deposit
     * @param interestRateMode stable or variable borrow mode
     * @param borrowRatio Ratio of tokens to borrow
     * @param loopCount Repeat count for loop
     **/
    function loop(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint256 borrowRatio,
        uint256 loopCount
    ) external {
        uint16 referralCode = 0;
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        IERC20(asset).approve(address(lendingPool), type(uint256).max);
        lendingPool.deposit(asset, amount, msg.sender, referralCode);
        for (uint256 i = 0; i < loopCount; i += 1) {
            amount = amount.mul(borrowRatio).div(10 ** BORROW_RATIO_DECIMALS);
            lendingPool.borrow(asset, amount, interestRateMode, referralCode, msg.sender);
            lendingPool.deposit(asset, amount, msg.sender, referralCode);
        }
    }

    /**
     * @dev Select the minimum value between two values
     * @param a for first value
     * @param b for second value
     * @return min of the values
     **/
    function min(uint256 a, uint256 b) public pure returns (uint256)
    {
        return a < b ? a : b;
    }

    /**
     * @dev Unloop the deposit and borrow of an asset
     * @param asset for unloop
     * @param amount for the amount able to withdraw from deposits
     * @param returnRatio Ratio of tokens to return
     * @param loopCount Max repeat count for loop
     **/
    function VDebtUnloop(
        address asset,
        uint256 amount,
        uint256 returnRatio,
        uint256 loopCount
    ) external {
        address aAsset = getAToken(asset);
        address VDebtAsset = getVDebtToken(asset);
        uint256 totalVDebtToken = IERC20(VDebtAsset).balanceOf(msg.sender);
        IERC20(asset).approve(address(lendingPool), type(uint256).max);
        for (uint256 i = 0; i < loopCount; i += 1) {
            if (totalVDebtToken == 0)
            {
                amount = IERC20(aAsset).balanceOf(msg.sender);
                IERC20(aAsset).transferFrom(
                    msg.sender,
                    address(this),
                    amount
                );
                lendingPool.withdraw(asset, amount, address(this));
                break;
            }
            IERC20(aAsset).transferFrom(msg.sender, address(this), amount);
            lendingPool.withdraw(asset, amount, address(this));
            lendingPool.repay(asset, amount, 2, msg.sender);
            totalVDebtToken -= amount;
            amount = min(amount.mul(10 ** BORROW_RATIO_DECIMALS).div(returnRatio), totalVDebtToken);
        }
        IERC20(asset).transfer(msg.sender, IERC20(asset).balanceOf(address(this)));
    }
}