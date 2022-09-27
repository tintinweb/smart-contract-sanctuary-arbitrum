// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IInvestor} from "./interfaces/IInvestor.sol";
import {IERC20} from "./interfaces/IERC20.sol";

contract LiquidationHelper {
    error TransferFailed();

    function lifeBatched(uint256[] calldata positionIds, address investor) external view returns (uint256[] memory) {
        uint256 posLen = positionIds.length;
        uint256[] memory lifeArr = new uint256[](posLen);

        for (uint256 i = 0; i < posLen; i++) {
            (,,,, uint256 borrow) = IInvestor(investor).positions(positionIds[i]);

            if (borrow == 0) {
                lifeArr[i] = 0;
            } else {
                lifeArr[i] = IInvestor(investor).life(positionIds[i]);
            }
        }

        return lifeArr;
    }

    function killBatched(uint256[] calldata positionIds, address investor, address asset, address usr) external {
        for (uint256 i = 0; i < positionIds.length; i++) {
            investor.call(abi.encodeWithSignature("kill(uint256)", positionIds[i]));
        }

        uint256 assetBal = IERC20(asset).balanceOf(address(this));

        if (assetBal > 0) {
            push(usr, asset, assetBal);
        }
    }

    function push(address usr, address asset, uint256 amt) internal {
        if (!IERC20(asset).transfer(usr, amt)) {
            revert TransferFailed();
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

interface IInvestor {
    function asset() external view returns (address);
    function lastGain() external view returns (uint256);
    function supplyIndex() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function borrowIndex() external view returns (uint256);
    function totalBorrow() external view returns (uint256);
    function getUtilization() external view returns (uint256);
    function getSupplyRate(uint256) external view returns (uint256);
    function getBorrowRate(uint256) external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function life(uint256) external view returns (uint256);
    function positions(uint256) external view returns (address, address, uint256, uint256, uint256);
    function earn(address, uint256, uint256) external returns (uint256);
    function sell(uint256, uint256, uint256) external;
    function save(uint256, uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}