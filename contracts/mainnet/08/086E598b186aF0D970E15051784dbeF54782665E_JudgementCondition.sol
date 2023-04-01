// SPDX-License-Identifier: GPL-3.0

/// This contract deals with product retire judgment processing.

pragma solidity ^0.8.0;

import "../library/interfaces/IPriceFeed.sol";
import "../library/common/DataTypes.sol";
import "../product/interfaces/IProductPool.sol";

contract JudgementCondition {
    /**
     * notice Judge the product retire result.
     * @param productPoolAddress ProductPool contract address.
     * @param productId product id.
     */
    function judgementConditionAmount(
        address productPoolAddress,
        uint256 productId
    ) external view returns (DataTypes.ProgressStatus) {
        IProductPool productPool = IProductPool(productPoolAddress);
        DataTypes.ProductInfo memory product = productPool.getProductInfoByPid(productId);
        require(
            DataTypes.ProgressStatus.UNDELIVERED == product.resultByCondition,
            "ProductManager: non-repeatable delivery"
        );
        require(block.number >= product.releaseHeight, "ProductManager: release height error");
        return _getResultByCondition(product.cryptoExchangeAddress, product.conditionAmount, product.productType);
    }

    /// @dev The seer gets the coin price.
    function getTokenPrice(address token) external view returns (uint256) {
        IPriceFeed priceFeed = IPriceFeed(token);
        int256 price = priceFeed.latestAnswer();
        require(price > 0, "TokenManager: invalid price");
        return uint256(price);
    }

    function _getResultByCondition(
        address cryptoExchangeAddress,
        uint256 conditionAmount,
        DataTypes.ProductType productType
    ) private view returns (DataTypes.ProgressStatus) {
        uint256 currentValue = this.getTokenPrice(cryptoExchangeAddress);
        if (DataTypes.ProductType.BUY_LOW == productType && currentValue >= conditionAmount) {
            return DataTypes.ProgressStatus.UNREACHED;
        } else if (DataTypes.ProductType.BUY_LOW == productType && currentValue < conditionAmount) {
            return DataTypes.ProgressStatus.REACHED;
        } else if (DataTypes.ProductType.SELL_HIGH == productType && currentValue > conditionAmount) {
            return DataTypes.ProgressStatus.REACHED;
        } else {
            return DataTypes.ProgressStatus.UNREACHED;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library DataTypes {
    struct PurchaseProduct {
        uint256 customerId;
        address customerAddress;
        uint256 amount;
        uint256 releaseHeight;
        address tokenAddress;
        uint256 customerReward;
        uint256 cryptoQuantity;
    }

    struct CustomerByCrypto {
        address customerAddress;
        address cryptoAddress;
        uint256 amount;
    }

    struct ExchangeTotal {
        address tokenIn;
        address tokenOut;
        uint256 tokenInAmount;
        uint256 tokenOutAmount;
    }

    struct ProductInfo {
        uint256 productId;
        uint256 conditionAmount;
        uint256 customerQuantity;
        address cryptoType;
        ProgressStatus resultByCondition;
        address cryptoExchangeAddress;
        uint256 releaseHeight;
        ProductType productType;
        uint256 soldTotalAmount;
        uint256 sellStartTime;
        uint256 sellEndTime;
        uint256 saleTotalAmount;
        uint256 maturityDate;
    }

    struct HedgingAggregatorInfo {
        uint256 customerId;
        uint256 productId;
        address customerAddress;
        uint256 amount;
        uint256 releaseHeight;
    }

    struct TransferHelperInfo {
        address from;
        address to;
        uint256 amount;
        address tokenAddress;
        TransferHelperStatus typeValue;
    }

    enum ProductType {
        BUY_LOW,
        SELL_HIGH
    }

    enum ProgressStatus {
        UNDELIVERED,
        REACHED,
        UNREACHED
    }

    //typeValue 0: customer to this, 1: this to customer principal, 2: this to customer reward, 3: this to valut, 4: this to manageWallet, 5 guardian withdraw
    enum TransferHelperStatus {
        TOTHIS,
        TOCUSTOMERP,
        TOCUSTOMERR,
        TOVALUT,
        TOMANAGE,
        GUARDIANW
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IPriceFeed {
    function description() external view returns (string memory);

    function aggregator() external view returns (address);

    function latestAnswer() external view returns (int256);

    function latestRound() external view returns (uint80);

    function getRoundData(uint80 roundId) external view returns (uint80, int256, uint256, uint256, uint80);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../../library/common/DataTypes.sol";

interface IProductPool {
    function getProductInfoByPid(uint256 productId) external view returns (DataTypes.ProductInfo memory);

    function getProductInfoList() external view returns (DataTypes.ProductInfo[] memory);

    function _s_retireProductAndUpdateInfo(
        uint256 productId,
        DataTypes.ProgressStatus resultByCondition
    ) external returns (bool);

    function updateSoldTotalAmount(uint256 productId, uint256 sellAmount) external returns (bool);
}