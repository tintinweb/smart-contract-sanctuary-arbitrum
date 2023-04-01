// SPDX-License-Identifier: GPL-3.0

/// This contract deals with the customer exercise logic.

pragma solidity ^0.8.0;

import "../library/common/DataTypes.sol";
import "../product/interfaces/IProductPool.sol";
import "../product/interfaces/ICustomerPool.sol";

contract Execution {
    /**
     * notice Exercise incentive calculation.
     * @param productPoolAddress ProductPool contract address.
     * @param customerId Customer id.
     * @param customerAddress Customer's wallet address.
     * @param productId product id.
     * @param pool CustomerPool contract address.
     */
    function executeWithRewards(
        address productPoolAddress,
        uint256 customerId,
        address customerAddress,
        uint256 productId,
        ICustomerPool pool,
        address stableC
    ) external view returns (DataTypes.CustomerByCrypto memory, DataTypes.CustomerByCrypto memory) {
        IProductPool productPool = IProductPool(productPoolAddress);
        DataTypes.ProductInfo memory product = productPool.getProductInfoByPid(productId);
        DataTypes.PurchaseProduct memory purchaseProduct = pool.getSpecifiedProduct(productId, customerId);
        _validatePurchaseProduct(purchaseProduct, customerAddress);
        DataTypes.CustomerByCrypto memory principal;
        DataTypes.CustomerByCrypto memory rewards;
        if (DataTypes.ProgressStatus.UNREACHED == product.resultByCondition) {
            principal = DataTypes.CustomerByCrypto(
                customerAddress,
                purchaseProduct.tokenAddress,
                purchaseProduct.amount
            );
        } else if (DataTypes.ProgressStatus.REACHED == product.resultByCondition) {
            if (DataTypes.ProductType.BUY_LOW == product.productType) {
                principal = DataTypes.CustomerByCrypto(
                    customerAddress,
                    product.cryptoType,
                    purchaseProduct.cryptoQuantity
                );
            } else {
                principal = DataTypes.CustomerByCrypto(customerAddress, stableC, purchaseProduct.cryptoQuantity);
            }
        }
        rewards = DataTypes.CustomerByCrypto(customerAddress, stableC, purchaseProduct.customerReward);
        return (principal, rewards);
    }

    /// @dev Check product status.
    function _validatePurchaseProduct(
        DataTypes.PurchaseProduct memory customerProduct,
        address customerAddress
    ) private pure returns (bool) {
        require(
            customerProduct.customerAddress == customerAddress,
            "CustomerManager: The user has not purchased the product"
        );
        require(
            customerProduct.amount > 0 && customerProduct.releaseHeight > 0,
            "CustomerManager: The user has not purchased the product"
        );
        return true;
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
import "../../library/common/DataTypes.sol";

interface ICustomerPool {
    function deleteSpecifiedProduct(uint256 _prod, uint256 _customerId) external returns (bool);

    function addCustomerByProduct(
        uint256 _pid,
        uint256 _customerId,
        address _customerAddress,
        uint256 _amount,
        address _token,
        uint256 _customerReward,
        uint256 _cryptoQuantity
    ) external returns (bool);

    function updateCustomerReward(uint256 _pid, uint256 _customerId, uint256 _customerReward) external returns (bool);

    function getProductList(uint256 _prod) external view returns (DataTypes.PurchaseProduct[] memory);

    function getSpecifiedProduct(
        uint256 _pid,
        uint256 _customerId
    ) external view returns (DataTypes.PurchaseProduct memory);
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