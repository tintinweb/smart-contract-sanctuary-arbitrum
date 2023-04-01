// SPDX-License-Identifier: GPL-3.0

/// The contract does the logical processing of customer purchase productst.

pragma solidity ^0.8.0;

import "../library/common/ConfigurationParam.sol";
import "../library/common/DataTypes.sol";
import "../library/common/ConfigurationParam.sol";
import "../product/interfaces/IProductPool.sol";
import "../product/interfaces/ICustomerPool.sol";

contract ApplyBuyIntent {
    /**
     * notice Customers purchase products.
     * @param amount Purchase quantity.
     * @param _pid Product id.
     * @param productPool ProductPool contract address.
     */
    function dealApplyBuyCryptoQuantity(
        uint256 amount,
        uint256 _pid,
        IProductPool productPool,
        address stableC
    ) external view returns (uint256, address) {
        DataTypes.ProductInfo memory product = productPool.getProductInfoByPid(_pid);
        uint256 cryptoQuantity;
        address etcToken;
        require(amount >= product.customerQuantity, "PurchaseManager: amount is below the minimum value");
        require(amount <= (product.saleTotalAmount - product.soldTotalAmount), "purchase volume is out of bounds");
        require(block.timestamp < product.sellEndTime, "PurchaseManager: exceeding the deadline for sale");
        require(
            DataTypes.ProgressStatus.UNDELIVERED == product.resultByCondition,
            "ProductManager: undelivered product"
        );
        (cryptoQuantity, etcToken) = _calculateCryptoQuantity(product, amount, stableC);
        return (cryptoQuantity, etcToken);
    }

    /**
     * notice Calculate the number of subscriptions.
     * @param amount Purchase amount.
     * @param product product info.
     */
    function dealSoldCryptoQuantity(
        uint256 amount,
        DataTypes.ProductInfo memory product,
        address stableC
    ) external pure returns (uint256) {
        uint256 cryptoQuantity;
        require(amount > 0, "BasePositionManager: amount must be greater than 0");
        (cryptoQuantity, ) = _calculateCryptoQuantity(product, amount, stableC);
        return cryptoQuantity;
    }

    /// @dev Handle subscription quantity calculation.
    function _calculateCryptoQuantity(
        DataTypes.ProductInfo memory product,
        uint256 amount,
        address stableC
    ) internal pure returns (uint256, address) {
        uint256 cryptoQuantity;
        address etcToken;
        if (ConfigurationParam.WBTC == product.cryptoType) {
            (cryptoQuantity, etcToken) = _calculateCryptoQuantityByWBTC(product, amount, stableC);
        } else if (ConfigurationParam.WETH == product.cryptoType) {
            (cryptoQuantity, etcToken) = _calculateCryptoQuantityByWETH(product, amount, stableC);
        }
        require(cryptoQuantity > 0 && etcToken != address(0), "BasePositionManager: product information exception");
        return (cryptoQuantity, etcToken);
    }

    /// @dev Handle WETH subscription quantity calculation.
    function _calculateCryptoQuantityByWETH(
        DataTypes.ProductInfo memory product,
        uint256 amount,
        address stableC
    ) private pure returns (uint256, address) {
        uint256 cryptoQuantity;
        address etcToken;
        if (product.productType == DataTypes.ProductType.BUY_LOW) {
            cryptoQuantity = _calculateBuyLow(amount, product.conditionAmount, ConfigurationParam.WETH_DECIMAL);
            etcToken = stableC;
        } else if (product.productType == DataTypes.ProductType.SELL_HIGH) {
            cryptoQuantity = _calculateSellHigh(amount, product.conditionAmount, ConfigurationParam.WETH_DECIMAL);
            etcToken = product.cryptoType;
        }
        return (cryptoQuantity, etcToken);
    }

    /// @dev Handle WBTC subscription quantity calculation.
    function _calculateCryptoQuantityByWBTC(
        DataTypes.ProductInfo memory product,
        uint256 amount,
        address stableC
    ) private pure returns (uint256, address) {
        uint256 cryptoQuantity;
        address etcToken;
        if (product.productType == DataTypes.ProductType.BUY_LOW) {
            cryptoQuantity = _calculateBuyLow(amount, product.conditionAmount, ConfigurationParam.WBTC_DECIMAL);
            etcToken = stableC;
        } else if (product.productType == DataTypes.ProductType.SELL_HIGH) {
            cryptoQuantity = _calculateSellHigh(amount, product.conditionAmount, ConfigurationParam.WBTC_DECIMAL);
            etcToken = product.cryptoType;
        }
        return (cryptoQuantity, etcToken);
    }

    /// @dev Buy type calculates the quantity available for purchase.
    function _calculateBuyLow(
        uint256 amount,
        uint256 conditionAmount,
        uint256 cryptoTypeDecimal
    ) private pure returns (uint256) {
        uint256 cryptoQuantity = (amount * cryptoTypeDecimal * ConfigurationParam.ORACLE_DECIMAL) /
            (conditionAmount * ConfigurationParam.STABLEC_DECIMAL);
        return cryptoQuantity;
    }

    /// @dev Sell type Calculates the quantity available for sale.
    function _calculateSellHigh(
        uint256 amount,
        uint256 conditionAmount,
        uint256 cryptoTypeDecimal
    ) private pure returns (uint256) {
        uint256 cryptoQuantity = (amount * conditionAmount * ConfigurationParam.STABLEC_DECIMAL) /
            (cryptoTypeDecimal * ConfigurationParam.ORACLE_DECIMAL);
        return cryptoQuantity;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library ConfigurationParam {
    address internal constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address internal constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address internal constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address internal constant WBTCCHAIN = 0xd0C7101eACbB49F3deCcCc166d238410D6D46d57;
    address internal constant WETHCHAIN = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
    address internal constant ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address internal constant GUARDIAN = 0x366e2E5Ed08AA510c45138035d0F502A13F4718A;
    uint256 internal constant STABLEC_DECIMAL = 1e6;
    uint256 internal constant WETH_DECIMAL = 1e18;
    uint256 internal constant WBTC_DECIMAL = 1e8;
    uint256 internal constant ORACLE_DECIMAL = 1e8;
    uint256 internal constant FEE_DECIMAL = 1e6;
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